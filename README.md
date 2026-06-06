# mrmarket.ai MCP server

**A purpose-built analytical engine for financial research, exposed over MCP. Ask hard questions about US-listed equities in plain English and get structured, reproducible results back.**

[mrmarket.ai](https://mrmarket.ai) is a remote MCP server. Connect it to Claude, ChatGPT, or Gemini and your assistant gains a dedicated engine for resolving financial questions against clean, structured market data. It is not a language model with a database bolted on, and it is not an API wrapper. You describe the analysis; the engine computes it and returns rows, columns, and the assumptions it applied.

The interesting questions in equity research require joins that no single API endpoint will run for you. "Stocks where insiders bought over $1M, free cash flow grew four quarters running, and the price sits below the 200-day moving average" spans insider filings, quarterly cash flow statements, and daily prices at once. mrmarket.ai is built for exactly that class of question.

---

## Why it is different

* **Computed, not predicted.** Answers are derived from the underlying data, not generated from a model's recollection. The same question returns the same answer every time.
* **Cross-dataset by design.** Fundamentals, prices, earnings, and insider activity are resolved together in a single question, with time dimensions aligned across differing data frequencies.
* **Point-in-time aware.** Historical and as-of questions respect the information available on the date in question, so backward-looking studies do not leak future data.
* **Built to fail loud.** When a question falls outside coverage, the engine returns an explicit error rather than fabricating a plausible number.
* **Transparent.** Every result carries the assumptions and defaults that were applied, so they can be inspected and adjusted.

---

## Connect

mrmarket.ai is a remote MCP server reachable at:

```
https://mcp.mrmarket.ai/mcp
```

Each connection is tied to a free account so that credit balance and rate limits apply correctly. Authorization happens over OAuth on first use. Create an account and manage connections at [mrmarket.ai/connect](https://mrmarket.ai/connect).

### Claude Code

```bash
claude mcp add --transport http mrmarket https://mcp.mrmarket.ai/mcp
```

### Claude Desktop

Open Settings, go to **Connectors**, choose **Add custom connector**, and paste the endpoint:

```
https://mcp.mrmarket.ai/mcp
```

Claude prompts for authorization on first use. Note that editing `claude_desktop_config.json` by hand does not work for this server; that file only accepts local, command-based servers, and mrmarket.ai is remote.

### ChatGPT

In Settings, open **Connectors**, choose **Add custom connector**, and point it at the same endpoint.

### Gemini

Add it as a remote MCP extension when prompted by Gemini's MCP onboarding, using the same endpoint.

---

## Tools

| Tool | Cost | Purpose |
|------|------|---------|
| `query_data` | metered | The workhorse. A natural-language financial question in; structured rows and columns out. Screens, rankings, comparisons, time-series, cohort studies, and event studies are all single calls. |
| `describe_data` | free | The data catalog. Browse categories and fields, or search for a specific metric, before composing a question. |
| `get_symbols` | free | Fast ticker, sector, and industry resolution. Name to ticker, sector membership, or the full universe in under 50ms. |
| `getting_started` | free | A structured orientation tour with verified example prompts, grouped by use case. |
| `recent_queries` | free | Your recent queries, for context and re-runs. |
| `get_account_status` | free | Connected account, plan tier, credit balance, and rate limits. A useful first call in any new session. |
| `report_issue` | free | Flag a result that looks wrong or a feature that is missing. Pass the `query_id` from the response so the trace can be investigated. |

Five of the seven tools cost zero credits. Only `query_data` consumes credits, priced by query complexity. Start with `getting_started` or `describe_data`, then move to `query_data`.

---

## What you can ask

Every prompt below resolves in a single `query_data` call. Phrase questions the way an analyst would speak them, not as a list of column filters.

### Screens

```
Technology stocks with ROIC above 20%, debt-to-equity below 0.5, and 5-year revenue CAGR above 10%.
Healthcare companies with positive free cash flow and gross margin above 50%.
Companies with four consecutive quarters of growing free cash flow.
```

### Rankings

```
Top 20 stocks by ROIC, excluding financials.
Top 15 companies by smoothness of year-over-year revenue growth over the last five fiscal years.
Bottom 10 consumer discretionary stocks by 1-year total return.
```

### Comparisons

```
Compare AAPL, MSFT, and GOOGL on revenue and net income over the last five years.
AMZN versus WMT operating margin trend over the last decade.
NVDA quarterly EPS surprise history.
```

### Cohort-relative analysis

```
Stocks whose ROIC is at least one standard deviation above their sector average.
Companies with a net profit margin more than twice their sector average.
Companies with revenue growth in the top quartile of their industry.
```

### Time-series and overlays

```
AAPL daily closes for the last five years with earnings dates overlaid.
MSFT price with insider buy and sell markers over the past two years.
50-day and 200-day moving averages for TSLA.
```

### Event studies

```
Average 30-day return after companies beat earnings by more than 10 percent.
Forward 3-month returns following insider purchases above $1M, grouped by sector.
Across the large-cap universe, the correlation between monthly insider purchase count and the next 3-month return.
```

### Multi-step research, driven by your assistant

Larger studies decompose into several calls that your assistant orchestrates while mrmarket.ai supplies the ground truth at each step:

```
For every large-cap stock that gapped down 5 percent or more after earnings in the
past two years, what is the 30, 60, and 90-day recovery rate, and is it statistically
significant against random 90-day windows?
```

```
Backtest this signal: buy stocks with insider purchases above $500K within 30 days
before earnings that then beat EPS estimates, hold for 63 trading days, and report
CAGR, maximum drawdown, and win rate against buying every post-beat stock.
```

```
Build a pre-earnings watchlist: companies reporting in the next two weeks where
insiders bought in the last 90 days, the stock trades below its 200-day moving
average, and they beat estimates last quarter.
```

---

## Coverage

| | |
|---|---|
| **Universe** | 11,000+ US-listed stocks and ETFs (NYSE, NASDAQ, AMEX) |
| **History** | 20+ years of financials on US equities |
| **Response time** | Under 10 seconds for typical questions |

Data spans daily adjusted prices, annual and quarterly financial statements (income statement, balance sheet, cash flow), earnings actuals against estimates, insider transactions, and valuation snapshots, alongside computed metrics such as ROIC, free cash flow, debt-to-equity, ROE, margins, returns, and earnings surprise. Sourced with point-in-time accuracy and curated for cross-dataset queries.

## Scope

mrmarket.ai is a research and analysis layer, not a brokerage and not a real-time feed. Prices are end-of-day. The following are out of scope: intraday and tick data, options chains, news and transcript text, raw filing text, macro series, FX, crypto, bonds, and futures. When a question reaches an edge, the engine reports it rather than guessing.

---

## Links

* Product and sign-up: [mrmarket.ai](https://mrmarket.ai)
* Connect your assistant: [mrmarket.ai/connect](https://mrmarket.ai/connect)
* Endpoint: `https://mcp.mrmarket.ai/mcp`
