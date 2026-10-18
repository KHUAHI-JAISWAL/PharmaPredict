CREATE TABLE medicine_consumption (
    hf_pk BIGINT,
    name1 TEXT,
    date DATE,
    stockout INTEGER,
    received DOUBLE PRECISION,
    consumption DOUBLE PRECISION,
    closeBalance DOUBLE PRECISION,
    openBalance DOUBLE PRECISION,
    facility_type TEXT,
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    district TEXT,
    quarter TEXT,
    productID INTEGER,
    normAvg DOUBLE PRECISION,
    normStd DOUBLE PRECISION
);


SELECT COUNT(*) AS total_rows
FROM public.medicine_consumption;


select * from medicine_consumption;




-- Query 1: Total Records and Data Overview
-- Purpose: Count the total number of records in the dataset.

SELECT
    COUNT(*) AS total_records
FROM public.medicine_consumption;





-- Query 2: Total Medicines, Districts, and Products
-- Purpose: Identify the number of unique medicines, districts, and products.

SELECT
    COUNT(DISTINCT name1) AS total_medicines,
    COUNT(DISTINCT district) AS total_districts,
    COUNT(DISTINCT productID) AS total_products
FROM public.medicine_consumption;


-- Query 3: Top 10 Medicines by Total Consumption
-- Purpose: Identify the medicines with the highest overall consumption.

SELECT
    name1 AS medicine_name,
    SUM(consumption) AS total_consumption
FROM public.medicine_consumption
GROUP BY name1
ORDER BY total_consumption DESC
LIMIT 10;




-- Query 4: Top 10 Districts by Medicine Consumption
-- Purpose: Identify the districts with the highest medicine consumption.

SELECT
    district,
    SUM(consumption) AS total_consumption
FROM public.medicine_consumption
GROUP BY district
ORDER BY total_consumption DESC
LIMIT 10;


-- Query 5: District-wise Stockout Analysis
-- Purpose: Calculate stockout records and stockout rate for each district.

SELECT
    district,
    COUNT(*) AS total_records,
    SUM(CASE WHEN stockout = 1 THEN 1 ELSE 0 END) AS stockout_records,
    ROUND(
        100.0 * SUM(CASE WHEN stockout = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS stockout_rate_pct
FROM public.medicine_consumption
GROUP BY district
ORDER BY stockout_rate_pct DESC
LIMIT 10;



-- Query 6: Monthly Medicine Consumption Trend
-- Purpose: Analyze changes in medicine consumption over time.

SELECT
    DATE_TRUNC('month', date)::date AS month,
    SUM(consumption) AS total_consumption
FROM public.medicine_consumption
GROUP BY DATE_TRUNC('month', date)
ORDER BY month;






-- Query 7: Medicine Consumption by Facility Type
-- Purpose: Compare total and average consumption across facility types.

SELECT
    facility_type,
    SUM(consumption) AS total_consumption,
    ROUND(AVG(consumption)::numeric, 2) AS avg_consumption
FROM public.medicine_consumption
GROUP BY facility_type
ORDER BY total_consumption DESC;










-- Query 8: Consumption Analysis by Stockout Status
-- Purpose: Compare consumption for records with and without stockouts.

SELECT
    stockout,
    COUNT(*) AS total_records,
    ROUND(AVG(consumption)::numeric, 2) AS avg_consumption,
    SUM(consumption) AS total_consumption
FROM public.medicine_consumption
GROUP BY stockout
ORDER BY stockout;






-- Query 9: District-wise Inventory Balance Analysis
-- Purpose: Compare opening balance, closing balance, received stock, and consumption.

SELECT
    district,
    SUM(openBalance) AS total_opening_balance,
    SUM(closeBalance) AS total_closing_balance,
    SUM(received) AS total_received,
    SUM(consumption) AS total_consumption
FROM public.medicine_consumption
GROUP BY district
ORDER BY total_closing_balance ASC
LIMIT 10;






-- Query 10: Top 10 Medicines by Average Consumption
-- Purpose: Identify medicines with the highest average recorded consumption.

SELECT
    name1 AS medicine_name,
    COUNT(*) AS total_records,
    ROUND(AVG(consumption)::numeric, 2) AS avg_consumption,
    MAX(consumption) AS highest_consumption
FROM public.medicine_consumption
GROUP BY name1
ORDER BY avg_consumption DESC
LIMIT 10;







-- Query 11: Month-over-Month Consumption Growth
-- Purpose: Calculate monthly consumption and growth compared with the previous month.

WITH monthly_data AS (
    SELECT
        DATE_TRUNC('month', date)::date AS month,
        SUM(consumption) AS total_consumption
    FROM public.medicine_consumption
    GROUP BY DATE_TRUNC('month', date)
),
previous_month AS (
    SELECT
        month,
        total_consumption,
        LAG(total_consumption) OVER (ORDER BY month) AS previous_consumption
    FROM monthly_data
)
SELECT
    month,
    total_consumption,
    previous_consumption,
    ROUND(
        (
            100.0 * (total_consumption - previous_consumption)
            / NULLIF(previous_consumption, 0)
        )::numeric,
        2
    ) AS growth_percentage
FROM previous_month
ORDER BY month;



-- Query 12: District Ranking by Medicine Consumption
-- Purpose: Rank districts according to total medicine consumption.

SELECT
    district,
    SUM(consumption) AS total_consumption,
    RANK() OVER (
        ORDER BY SUM(consumption) DESC
    ) AS district_rank
FROM public.medicine_consumption
GROUP BY district
ORDER BY district_rank;





-- Query 13: Medicines with Low Closing Stock
-- Purpose: Identify medicine records with low closing inventory.

SELECT
    name1 AS medicine_name,
    district,
    date,
    closeBalance AS closing_stock
FROM public.medicine_consumption
WHERE closeBalance <= 10
ORDER BY closeBalance ASC, date DESC
LIMIT 20;




-- Query 14: Medicine Consumption Variability
-- Purpose: Measure variation in consumption for each medicine.

SELECT
    name1 AS medicine_name,
    COUNT(*) AS total_records,
    ROUND(AVG(consumption)::numeric, 2) AS avg_consumption,
    ROUND(STDDEV(consumption)::numeric, 2) AS consumption_stddev
FROM public.medicine_consumption
GROUP BY name1
HAVING COUNT(*) >= 10
ORDER BY consumption_stddev DESC
LIMIT 10;



-- Query 15: District-wise Inventory Risk Summary
-- Purpose: Summarize stockout frequency and low closing-stock records by district.

SELECT
    district,
    COUNT(*) AS total_records,
    SUM(CASE WHEN stockout = 1 THEN 1 ELSE 0 END) AS stockout_records,
    SUM(CASE WHEN closeBalance <= 10 THEN 1 ELSE 0 END) AS low_stock_records,
    ROUND(
        100.0 * SUM(CASE WHEN stockout = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS stockout_rate_pct
FROM public.medicine_consumption
GROUP BY district
ORDER BY stockout_rate_pct DESC, low_stock_records DESC;