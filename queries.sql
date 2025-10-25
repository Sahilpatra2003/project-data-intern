-- retail_performance_queries.sql
-- 1) Import & cleaning (pseudo - adjust to your SQL dialect and table names)
/* Create cleaned transactions table from raw source */
CREATE TABLE transactions_clean AS
SELECT
  transaction_id,
  transaction_date::date AS transaction_date,
  customer_id,
  region,
  product_id,
  product_name,
  category,
  sub_category,
  quantity::integer AS quantity,
  unit_price::numeric AS unit_price,
  cost_price::numeric AS cost_price,
  COALESCE(discount, 0)::numeric AS discount,
  COALESCE(shipping_cost, 0)::numeric AS shipping_cost,
  COALESCE(inventory_days, NULL) AS inventory_days
FROM raw_transactions
WHERE transaction_date IS NOT NULL
  AND product_id IS NOT NULL
  AND unit_price IS NOT NULL
  AND cost_price IS NOT NULL;

-- 2) Basic profit calculations (row-level)
ALTER TABLE transactions_clean ADD COLUMN revenue numeric;
ALTER TABLE transactions_clean ADD COLUMN profit numeric;
UPDATE transactions_clean
SET revenue = (unit_price * quantity) - discount + shipping_cost,
    profit = (unit_price - cost_price) * quantity - discount - shipping_cost;

-- 3) Profit margin by category & sub_category
-- margin = total_profit / total_revenue
SELECT
  category,
  sub_category,
  SUM(profit) AS total_profit,
  SUM(revenue) AS total_revenue,
  CASE WHEN SUM(revenue) = 0 THEN 0 ELSE SUM(profit) / SUM(revenue) END AS profit_margin,
  SUM(quantity) AS units_sold
FROM transactions_clean
GROUP BY category, sub_category
ORDER BY profit_margin ASC;  -- lowest margins first (profit-draining)

-- 4) Inventory turnover / days vs profitability (aggregate at product level)
-- Assumes a product_master table with avg_inventory (units) or use inventory_days in transactions_clean
SELECT
  tc.product_id,
  tc.product_name,
  AVG(tc.inventory_days) AS avg_inventory_days,
  SUM(tc.profit) AS product_profit,
  SUM(tc.revenue) AS product_revenue,
  CASE WHEN SUM(tc.revenue)=0 THEN 0 ELSE SUM(tc.profit)/SUM(tc.revenue) END AS product_margin,
  SUM(tc.quantity) AS total_units_sold
FROM transactions_clean tc
GROUP BY tc.product_id, tc.product_name;

-- 5) Seasonal product behavior (month-level)
SELECT
  category,
  sub_category,
  EXTRACT(MONTH FROM transaction_date) AS month,
  SUM(quantity) AS units_sold,
  SUM(revenue) AS revenue,
  SUM(profit) AS profit
FROM transactions_clean
GROUP BY category, sub_category, EXTRACT(MONTH FROM transaction_date)
ORDER BY category, sub_category, month;

-- 6) Slow-moving & overstock candidates
-- Products with high avg inventory days, low turnover, low demand
SELECT
  p.product_id,
  p.product_name,
  pm.avg_inventory_level,
  prod_stats.avg_inventory_days,
  prod_stats.total_units_sold,
  prod_stats.product_margin
FROM (
  SELECT
    product_id,
    AVG(inventory_days) AS avg_inventory_days,
    SUM(quantity) AS total_units_sold,
    CASE WHEN SUM(revenue)=0 THEN 0 ELSE SUM(profit)/SUM(revenue) END AS product_margin
  FROM transactions_clean
  GROUP BY product_id
) prod_stats
LEFT JOIN product_master pm ON pm.product_id = prod_stats.product_id
LEFT JOIN products p ON p.product_id = prod_stats.product_id
WHERE prod_stats.avg_inventory_days > 60   -- threshold: >60 days
  AND prod_stats.total_units_sold < 50     -- threshold: low sales
ORDER BY prod_stats.avg_inventory_days DESC;

-- 7) Region-wise performance snapshot
SELECT
  region,
  SUM(revenue) AS total_revenue,
  SUM(profit) AS total_profit,
  CASE WHEN SUM(revenue)=0 THEN 0 ELSE SUM(profit)/SUM(revenue) END AS profit_margin
FROM transactions_clean
GROUP BY region
ORDER BY profit_margin DESC;

-- 8) Export for Python analysis (example)
-- Use your SQL client to export the following view to CSV for Pandas analysis
CREATE OR REPLACE VIEW export_for_analysis AS
SELECT
  tc.*
FROM transactions_clean tc;