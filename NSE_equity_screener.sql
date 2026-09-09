-- STEP 1: CREATE SCHEMA AND USE IT

create database if not exists nse_equity_screener;
use nse_equity_screener;

-- STEP 2: CREATE THREE TABLES

create table if not exists companies ( 
ticker varchar(20) Primary key, -- make sure to use the same varchar for ticker across tables.
company_name varchar(100), 
sector varchar(50), 
industry varchar(50),
market_cap_category varchar (20)
);
CREATE TABLE IF NOT EXISTS financials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticker VARCHAR(50),
    fiscal_year INT,
    revenue DECIMAL(20,4) not NULL,
    tax decimal (20,4) not NULL,
    net_profit DECIMAL(20,4) not NULL,
    interest DECIMAL(20,4) not NULL,
    equity_share_capital DECIMAL(20,4)not NULL,
    borrowings DECIMAL(20,4) not NULL,
    total_assets DECIMAL(20,4) not NULL,
    reserves DECIMAL(20,4) not NULL,
    FOREIGN KEY (ticker) REFERENCES companies(ticker)
);

CREATE TABLE IF NOT EXISTS ratios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticker VARCHAR(50),
    fiscal_year INT,
    roe DECIMAL(10,2),
    roa DECIMAL(10,2),
    debt_to_equity DECIMAL(10,2),
    interest_coverage DECIMAL(10,2),
    net_profit_margin DECIMAL(10,2),
    FOREIGN KEY (ticker) REFERENCES companies(ticker)
);

-- STEP 3: INSERT COMPANIES MASTER DATA

INSERT INTO companies (ticker, company_name, sector, industry, market_cap_category) VALUES
('HDFC Bank', 'HDFC Bank Ltd', 'Banking & Finance', 'Private Sector Bank', 'Large'),
('Axis Bank', 'Axis Bank Ltd', 'Banking & Finance', 'Private Sector Bank', 'Large'),
('Kotak Mah. Bank', 'Kotak Mahindra Bank', 'Banking & Finance', 'Private Sector Bank', 'Large'),
('TCS', 'Tata Consultancy Services', 'IT', 'IT Services', 'Large'),
('Infosys', 'Infosys Ltd', 'IT', 'IT Services', 'Large'),
('Wipro', 'Wipro Ltd', 'IT', 'IT Services', 'Large'),
('Hind. Unilever', 'Hindustan Unilever Ltd', 'FMCG', 'Consumer Goods', 'Large'),
('Dabur India', 'Dabur India Ltd', 'FMCG', 'Consumer Goods', 'Large'),
('Nestle India', 'Nestle India Ltd', 'FMCG', 'Consumer Goods', 'Large'),
('Maruti Suzuki', 'Maruti Suzuki India Ltd', 'Auto', 'Passenger Vehicles', 'Large'),
('Bajaj Auto', 'Bajaj Auto Ltd', 'Auto', 'Two Wheelers', 'Large'),
('Eicher Motors', 'Eicher Motors Ltd', 'Auto', 'Two Wheelers', 'Large'),
('Sun Pharma.Inds', 'Sun Pharmaceutical Industries', 'Pharma', 'Pharmaceuticals', 'Large'),
("Dr Reddy's Labs", 'Dr Reddys Laboratories', 'Pharma', 'Pharmaceuticals', 'Large'),
('Cipla', 'Cipla Ltd', 'Pharma', 'Pharmaceuticals', 'Large'),
('Reliance Industries', 'Reliance Industries Ltd', 'Energy', 'Oil & Gas', 'Large'),
('O N G C', 'Oil & Natural Gas Corporation', 'Energy', 'Oil & Gas', 'Large'),
('Larsen & Toubro', 'Larsen & Toubro Ltd', 'Infra', 'Engineering & Construction', 'Large'),
('Adani Ports', 'Adani Ports & SEZ Ltd', 'Infra', 'Ports & Logistics', 'Large'),
('Bharti Airtel', 'Bharti Airtel Ltd', 'Telecom', 'Telecommunications', 'Large');

-- STEP 4: LOAD FINANCIALS DATA FROM CSV

use nse_equity_screener;
load data infile 'D:/ProgramData/MySQL/MySQL Server 8.0/Uploads/financials_final_data.csv'
into table financials
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(ticker, fiscal_year, revenue, tax, net_profit, interest, equity_share_capital, borrowings, total_assets, reserves);

-- STEP 5: VERIFY DATA LOADED

SELECT COUNT(*) as total_companies FROM companies;
SELECT COUNT(*) as total_financial_rows FROM financials;
SELECT * FROM financials LIMIT 10;

-- STEP 6: CALCULATE AND INSERT RATIOS

insert into ratios (ticker, fiscal_year, roe, roa, debt_to_equity, interest_coverage, net_profit_margin)
select 
ticker, 
fiscal_year,
round((net_profit/nullif(equity_share_capital + reserves,0))*100,2) as roe, 
round((net_profit/nullif(total_assets,0))*100,2) as roa,
round(borrowings/nullif(equity_share_capital + reserves,0),2) as debt_to_equity,
round((net_profit+interest+tax)/nullif(interest,0),2) as interest_coverage,
round((net_profit/nullif(revenue,0))*100,2) as net_profit_margin
from financials; 

-- Verify ratios
SELECT * FROM ratios LIMIT 10;

-- STEP 7: BASIC SCREENING QUERIES

-- Query 1: Most proitable companies in 2025
select 
f.ticker,c.sector,f.net_profit as net_profit_crores
from financials f
join companies c on f.ticker = c.ticker
where f.fiscal_year = 2025
order by net_profit_crores desc;

-- Query 2: Average revenue and profit by sector in 2025
select 
c.sector,  
round(avg(revenue), 2) as avg_revenue, 
round(avg(net_profit), 2) as avg_profit,
count(f.ticker) as no_of_companies
from financials f
join companies c on f.ticker = c.ticker
where f.fiscal_year = 2025
group by c.sector-- 
order by avg_revenue desc;

-- STEP 8: RATIO ANALYSIS FROM RATIOS TABLE

-- Query 3: ROE ranking in 2025

select
r.ticker, 
c.sector,
r.roe as roe_percent 
from ratios r 
join companies c on r.ticker = c.ticker
where r.fiscal_year = 2025 
order by r.roe desc;

-- Query 4: Lowest debt companies in 2025

SELECT
    r.ticker,
    c.sector,
    r.debt_to_equity
FROM ratios r
JOIN companies c ON r.ticker = c.ticker
WHERE r.fiscal_year = 2025
ORDER BY r.debt_to_equity ASC;

-- Query 5: Interest coverage in 2025

select 
r.ticker, 
c.sector, 
r.interest_coverage
from ratios r
join companies c on r.ticker = c.ticker 
where r.fiscal_year = 2025 and interest_coverage>1.5
order by r.interest_coverage desc;

-- STEP 9: WINDOW FUNCTIONS

-- Query 6: Rank companies by ROE within each sector

select 
r.ticker, 
c.sector,
r.debt_to_equity,
rank() over(partition by c.sector order by debt_to_equity desc) as debt_sector
from ratios r 
join companies c on r.ticker = c.ticker 
where r.fiscal_year = 2025;

-- Query 7: Year on year profit growth

select 
ticker, 
fiscal_year,
round(net_profit,2) as net_profit,
round(lag(net_profit) over(partition by ticker order by fiscal_year), 2) as prev_yr_NP,
ROUND(((net_profit - LAG(net_profit) OVER (PARTITION BY ticker ORDER BY fiscal_year))
    / NULLIF(LAG(net_profit) OVER (PARTITION BY ticker ORDER BY fiscal_year), 0)) * 100, 2) as yoy_growth_pct 
from financials
order by ticker, fiscal_year;

-- Query 8: Revenue growth from 2017 to 2025

select 
ticker,
max(case when fiscal_year = 2017 then revenue end) as revenue_2017,
max(case when fiscal_year = 2025 then revenue end) as revenue2025,
ROUND(((MAX(CASE WHEN fiscal_year = 2025 THEN revenue END) -
            MAX(CASE WHEN fiscal_year = 2017 THEN revenue END)) /
            NULLIF(MAX(CASE WHEN fiscal_year = 2017 THEN revenue END), 0)) * 100, 2) as growth_pct
from financials 
group by ticker 
order by growth_pct desc;

-- STEP 10: CTEs - MULTI FACTOR SCREENING

-- Query 9: Quality screen
-- High ROE + Low Debt + Strong profit growth

with roe_calc as (
select
r.ticker,
c.sector, 
r.roe
from ratios r
join companies c on r.ticker= c.ticker
where r.fiscal_year = 2025),
debt_calc as ( 
select 
ticker,
debt_to_equity as de_ratio
from ratios 
where fiscal_year = 2025),
growth_calc as ( 
select 
ticker,
        ROUND(((MAX(CASE WHEN fiscal_year = 2025 THEN net_profit END) -
                MAX(CASE WHEN fiscal_year = 2017 THEN net_profit END)) /
                NULLIF(MAX(CASE WHEN fiscal_year = 2017 THEN net_profit END), 0)) * 100, 2) as profit_growth_pct
from financials
group by ticker )

select 
r.ticker,
r.sector,
r.roe,
d.de_ratio,
g.profit_growth_pct
from roe_calc r 
join debt_calc d on r.ticker = d.ticker 
join growth_calc g on r.ticker = g.ticker
where r.roe> 15
and d.de_ratio< 1
and g.profit_growth_pct>20
order by r.roe desc;

-- Query 10:Short-term screener - “2025 Fundamental Quality Score”
-- Lower composite score = better overall quality stock

with metrics as (
select 
r.ticker,
c.sector,
c.company_name,
r.roa,
r.roe,
r.debt_to_equity,
r.interest_coverage,
r.net_profit_margin
from ratios r
join companies c on r.ticker = c.ticker 
where r.fiscal_year = 2025),

ranked as ( -- don't forget select * !!!
select *,
rank() over(partition by sector order by roe desc) as roe_rank,
rank() over(partition by sector order by roa desc) as roa_rank,
rank() over(partition by sector order by debt_to_equity asc) as debt_rank,
rank() over(partition by sector order by interest_coverage desc) as interest_rank,
rank() over(partition by sector order by net_profit_margin desc) as net_rank
from metrics)

select 
ticker,
sector,
company_name,
roa,
roe,
debt_to_equity,
interest_coverage,
net_profit_margin,
(roe_rank+ roa_rank+debt_rank+interest_rank+net_rank) as composite_score
from ranked
order by composite_score asc;

-- STEP 11: MULTI YEAR ANALYSIS QUERIES

-- Query : Long-term screener “Multi-Year Stability & Growth Model” (check these names though)
-- Combines 10 year average ROE, consistency score, and CAGR
-- It answers - which company has been the best quality business

WITH avg_ratios AS (
    SELECT
        r.ticker,
        c.sector,
        c.company_name,
        ROUND(AVG(r.roe), 2) as avg_roe,
        ROUND(AVG(r.roa), 2) as avg_roa,
        ROUND(AVG(r.debt_to_equity), 2) as avg_de,
        ROUND(AVG(r.net_profit_margin), 2) as avg_margin
    FROM ratios r
    JOIN companies c ON r.ticker = c.ticker
    GROUP BY r.ticker, c.sector, c.company_name
),
consistency AS ( -- an alt to nested in placement sql 
    WITH yoy AS (
        SELECT
            ticker,
            CASE
                WHEN net_profit > LAG(net_profit) OVER (PARTITION BY ticker ORDER BY fiscal_year)
                THEN 1
                ELSE 0
            END as grew
        FROM financials
    )
    SELECT
        ticker,
        SUM(grew) as consistency_score
    FROM yoy
    GROUP BY ticker
),
cagr AS (
    SELECT
        ticker,
        ROUND((POWER(
            MAX(CASE WHEN fiscal_year = 2025 THEN net_profit END) /
            NULLIF(MAX(CASE WHEN fiscal_year = 2017 THEN net_profit END), 0),
            1.0/8) - 1) * 100, 2) as profit_cagr
    FROM financials
    GROUP BY ticker
),
ranked AS ( -- windows no need group  by !!
    SELECT
        a.ticker,
        a.company_name,
        a.sector,
        a.avg_roe,
        a.avg_roa,
        a.avg_de,
        a.avg_margin,
        co.consistency_score,
        ca.profit_cagr,
        RANK() OVER (PARTITION BY a.sector ORDER BY a.avg_roe DESC) as roe_rank,
        RANK() OVER (PARTITION BY a.sector ORDER BY a.avg_de ASC) as debt_rank,
        RANK() OVER (PARTITION BY a.sector ORDER BY co.consistency_score DESC) as consistency_rank,
        RANK() OVER (PARTITION BY a.sector ORDER BY ca.profit_cagr DESC) as cagr_rank
    FROM avg_ratios a
    JOIN consistency co ON a.ticker = co.ticker
    JOIN cagr ca ON a.ticker = ca.ticker
)
SELECT
    ticker,
    company_name,
    sector,
    avg_roe,
    avg_roa,
    avg_de,
    avg_margin,
    consistency_score,
    profit_cagr,
    (roe_rank + debt_rank + consistency_rank + cagr_rank) as long_term_quality_score
FROM ranked
ORDER BY long_term_quality_score ASC;

-- STEP 14: CROSS SECTOR COMPARISON QUERIES

-- Query 12: Sector vs Sector — which sector is strongest overall
-- Compares all sectors on average ROE, average debt, average margin
-- This is the sector level version of the master screener 
 
with sector_metrics as ( 
SELECT
        c.sector,
        ROUND(AVG(r.roe), 2) as avg_roe,
        ROUND(AVG(r.roa), 2) as avg_roa,
        ROUND(AVG(r.debt_to_equity), 2) as avg_debt_to_equity,
        ROUND(AVG(r.interest_coverage), 2) as avg_interest_coverage,
        ROUND(AVG(r.net_profit_margin), 2) as avg_net_profit_margin,
        count(distinct r.ticker) as no_of_companies
from ratios r 
join companies c on r.ticker = c.ticker
group by c.sector),

sector_ranked as(-- we don't need partition by since we have alr grouped by ?)
select *,
rank() over(order by s.avg_roe desc) as roe_rank,
rank() over(order by s.avg_debt_to_equity asc) as debt_rank,
rank() over(order by s.avg_interest_coverage desc) as coverage_rank,
rank() over(order by s.avg_net_profit_margin desc) as margin_rank
from sector_metrics s)

select  -- these are not agg funs!!
sector,
avg_roe,
avg_roa,
avg_roa,
avg_debt_to_equity,
avg_interest_coverage,
avg_net_profit_margin,
no_of_companies,
(roe_rank + debt_rank + margin_rank + coverage_rank) as sector_composite_score
FROM sector_ranked
ORDER BY sector_composite_score ASC;

-- Query 13: Sector benchmark model “Sector-wise Best Quality Companies” - Best company from each sector 
-- Picks the single best company from each sector
-- based on composite score from master screener
-- Answers — if you could pick only one stock per sector, which would it be?

WITH metrics AS (
    SELECT
        r.ticker,
        c.sector,
        c.company_name,
        r.roe,
        r.roa,
        r.debt_to_equity,
        r.interest_coverage,
        r.net_profit_margin
    FROM ratios r
    JOIN companies c ON r.ticker = c.ticker
    WHERE r.fiscal_year = 2025
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY sector ORDER BY roe DESC) as roe_rank,
        RANK() OVER (PARTITION BY sector ORDER BY roa DESC) as roa_rank,
        RANK() OVER (PARTITION BY sector ORDER BY debt_to_equity ASC) as debt_rank,
        RANK() OVER (PARTITION BY sector ORDER BY interest_coverage DESC) as coverage_rank,
        RANK() OVER (PARTITION BY sector ORDER BY net_profit_margin DESC) as margin_rank
    FROM metrics
),

final_rank AS (
    SELECT
        ticker,
        company_name,
        sector,
        roe,
        roa,
        debt_to_equity,
        interest_coverage,
        net_profit_margin,
        (roe_rank + roa_rank + debt_rank + coverage_rank + margin_rank) AS composite_score,
        RANK() OVER (
            PARTITION BY sector
            ORDER BY (roe_rank + roa_rank + debt_rank + coverage_rank + margin_rank)
        ) AS sector_position
    FROM ranked
)

SELECT *
FROM final_rank
WHERE sector_position = 1
ORDER BY composite_score;

    
    

