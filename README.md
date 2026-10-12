NSE Fundamental Equity Screener

A SQL-based fundamental screener for 20 NSE large-cap stocks across 8 sectors, built entirely on financial statement data — no price data involved — with ratio calculations, multi-year trend analysis, and composite quality scoring, visualized in a connected Power BI dashboard.

Problem Statement

Most retail-facing stock screeners rank companies on price momentum or ratios pulled from a single data provider, with little visibility into how the ranking is actually computed. This project builds a screener from the ground up in SQL — every ratio, rank, and composite score is calculated transparently from raw financial statement line items (revenue, net profit, borrowings, reserves, etc.), so the logic behind "why this company ranks well" is fully traceable.

Dataset
Coverage: 20 NSE large-cap companies across 7 sectors — Banking & Finance, IT, FMCG, Auto, Pharma, Energy, Infra, Telecom
Source: Real financial statement data sourced from Screener.in
Time period: FY2017–FY2025 (9 years), enabling multi-year trend and CAGR analysis
Schema: Star schema with three tables —
companies — ticker, name, sector, industry, market cap category
financials — revenue, tax, net profit, interest, equity share capital, borrowings, total assets, reserves (per ticker, per fiscal year)
ratios — ROE, ROA, debt-to-equity, interest coverage, net profit margin (calculated directly from financials, not sourced externally)
Methodology
Schema design — normalized star schema with ticker as the foreign key linking all three tables
Data load — company master data inserted directly; financials loaded via LOAD DATA INFILE from CSV
Ratio calculation — all five core ratios (ROE, ROA, debt-to-equity, interest coverage, net profit margin) derived purely from financial statement fields, using NULLIF throughout to guard against division-by-zero
Query progression — 13 queries structured as a narrative, increasing in complexity:
Basic screening (most profitable companies, sector averages)
Ratio-based ranking (ROE, debt, interest coverage)
Window functions (RANK() OVER, LAG() OVER for sector ranking and YoY growth)
CTEs for multi-factor screening (high ROE + low debt + strong growth)
A composite "Fundamental Quality Score" ranking companies within sector across 5 ratios simultaneously
Multi-year stability model combining average ROE, a custom consistency score, and profit CAGR
Cross-sector comparison and a "best company per sector" benchmark model
Visualization — Power BI dashboard connected live to MySQL, with 7 custom DAX measures (including a consistency score built with SUMX) across two dashboard pages
Repository Structure
├── data/
│   └── financials_final_data.csv
├── NSE_equity_screener.sql
├── nse_equity_screener_bi.pbix
└── README.md
Tech Stack

MySQL · SQL (window functions, CTEs, star schema design) · Power BI 

How to Run
Run NSE_equity_screener.sql in MySQL Workbench (or any MySQL 8.0+ client) to create the schema, load the data, and generate the ratios table.
Update the LOAD DATA INFILE path in Step 4 of the script to point to your local copy of financials_final_data.csv.
Open nse_equity_screener_bi.pbix in Power BI Desktop and point the MySQL connector at your local database to refresh the dashboard.
