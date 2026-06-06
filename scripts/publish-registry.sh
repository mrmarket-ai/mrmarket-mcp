#!/usr/bin/env bash
#
# publish-registry.sh — publish (or update) ai.mrmarket/mrmarket-mcp on the
# official MCP Registry, using the Ed25519 key stored in AWS Secrets Manager.
#
# It pulls the publish credential from Secrets Manager, authenticates via DNS,
# and publishes the server.json in the repo root. Nothing secret is written to
# disk except a short-lived 0600 temp key that is shredded on exit.
#
# Usage:
#   scripts/publish-registry.sh                 # publish current server.json version
#   scripts/publish-registry.sh 1.1.0           # bump server.json to 1.1.0, then publish
#
# Requirements: aws (profile below), python3, an OpenSSL 3 binary, and the
# mcp-publisher CLI (auto-downloaded to a cache dir if not on PATH).
#
# Prereq that lives outside this script: the apex TXT record on mrmarket.ai
#   v=MCPv1; k=ed25519; p=<public key>
# must still be present (it is what proves domain ownership at login time).

set -euo pipefail

AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-mrmarket}"
AWS_REGION_NAME="${AWS_REGION_NAME:-us-east-1}"
SECRET_ID="${SECRET_ID:-mrmarket/mcp-registry/ed25519-publish-key}"
DOMAIN="mrmarket.ai"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

log() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# --- locate dependencies ----------------------------------------------------

command -v aws >/dev/null     || die "aws CLI not found"
command -v python3 >/dev/null || die "python3 not found"

find_openssl() {
  for c in /opt/homebrew/opt/openssl@3/bin/openssl \
           /usr/local/opt/openssl@3/bin/openssl \
           openssl; do
    if command -v "$c" >/dev/null 2>&1; then
      # macOS LibreSSL can't do Ed25519; require an OpenSSL build.
      if "$c" version 2>/dev/null | grep -qi '^OpenSSL'; then echo "$c"; return 0; fi
    fi
  done
  return 1
}
OSSL="$(find_openssl)" || die "OpenSSL 3 not found (macOS: brew install openssl@3)"

find_publisher() {
  if command -v mcp-publisher >/dev/null 2>&1; then command -v mcp-publisher; return 0; fi
  local cache="${HOME}/.mcp-registry/bin"
  if [[ -x "${cache}/mcp-publisher" ]]; then echo "${cache}/mcp-publisher"; return 0; fi
  log "mcp-publisher not found; downloading latest release to ${cache}" >&2
  mkdir -p "$cache"
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
  curl -fsSL "https://github.com/modelcontextprotocol/registry/releases/latest/download/mcp-publisher_${os}_${arch}.tar.gz" \
    | tar xz -C "$cache" mcp-publisher >&2 || die "failed to download mcp-publisher"
  echo "${cache}/mcp-publisher"
}
PUBLISHER="$(find_publisher)"

[[ -f server.json ]] || die "server.json not found in ${repo_root}"

# --- optional version bump --------------------------------------------------

if [[ "${1:-}" != "" ]]; then
  NEW_VERSION="$1"
  log "Bumping server.json version -> ${NEW_VERSION}"
  python3 - "$NEW_VERSION" <<'PY'
import json, sys
p = "server.json"
d = json.load(open(p))
d["version"] = sys.argv[1]
json.dump(d, open(p, "w"), indent=2)
open(p, "a").write("\n")
PY
fi
CURRENT_VERSION="$(python3 -c 'import json;print(json.load(open("server.json"))["version"])')"

# --- fetch key, log in, publish --------------------------------------------

KEYFILE="$(mktemp -t mcp-reg-key.XXXXXX)"
cleanup() { rm -f "$KEYFILE" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
chmod 600 "$KEYFILE"

log "Fetching publish key from Secrets Manager (${SECRET_ID})"
aws --profile "$AWS_PROFILE_NAME" --region "$AWS_REGION_NAME" \
    secretsmanager get-secret-value --secret-id "$SECRET_ID" \
    --query SecretString --output text \
  | python3 -c 'import sys,json; open(sys.argv[1],"w").write(json.load(sys.stdin)["private_key_pem"])' "$KEYFILE"

[[ -s "$KEYFILE" ]] || die "failed to extract private key from secret"

PRIVATE_KEY="$("$OSSL" pkey -in "$KEYFILE" -noout -text | grep -A3 'priv:' | tail -n +2 | tr -d ' :\n')"
[[ -n "$PRIVATE_KEY" ]] || die "failed to derive private key hex"

log "Authenticating with the registry via DNS (${DOMAIN})"
"$PUBLISHER" login dns --domain "$DOMAIN" --private-key "$PRIVATE_KEY" >/dev/null \
  || die "login failed (is the apex TXT record on ${DOMAIN} still present?)"

log "Publishing ai.mrmarket/mrmarket-mcp v${CURRENT_VERSION}"
"$PUBLISHER" publish

log "Done. Verify:"
echo "  curl -s 'https://registry.modelcontextprotocol.io/v0/servers?search=mrmarket' | python3 -m json.tool"
