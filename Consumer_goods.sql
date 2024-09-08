-- Request 1
SELECT customer, market, region
FROM dim_customer  
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market;

-- Request 2
SELECT 
  SUM(CASE 
		WHEN fiscal_year = 2020 THEN 1 
        ELSE 0 
        END) AS unique_products_2020,
  SUM(CASE 
		WHEN fiscal_year = 2021 THEN 1 
        ELSE 0 
        END) AS unique_products_2021,
  ROUND((SUM(CASE 
		WHEN fiscal_year = 2021 THEN 1 
        ELSE 0 
        END) / 
   SUM(CASE 
		WHEN fiscal_year = 2020 THEN 1 
        ELSE 0 
        END) - 1),2) * 100 AS percentage_chg
FROM 
  (SELECT DISTINCT product_code, fiscal_year 
   FROM fact_sales_monthly) AS subq;
   
-- Request 3
SELECT segment, count(product) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Request 4
WITH CTE1 AS 
(SELECT p.segment AS Segment, COUNT(DISTINCT p.product_code) AS product_count_2020
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2020
GROUP BY p.segment
ORDER BY product_count_2020 DESC
),
CTE2 AS 
(SELECT p.segment AS Segment, COUNT(DISTINCT p.product_code) AS product_count_2021
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.segment
ORDER BY product_count_2021 DESC
)
SELECT CTE1.segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) AS difference
FROM CTE1 
JOIN CTE2 
ON CTE1.segment = CTE2.segment
ORDER BY difference DESC;

-- Request 5
SELECT p.product_code AS product_code, p.product AS product, 
       ROUND(fact_manufacturing_cost.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost 
ON p.product_code = fact_manufacturing_cost.product_code
WHERE fact_manufacturing_cost.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost) 
      OR fact_manufacturing_cost.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- Request 6
SELECT c.customer, p.customer_code, 
	   ROUND(AVG(p.pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
ON c.customer_code = p.customer_code
WHERE c.market = 'India' AND p.fiscal_year = 2021
GROUP BY c.customer, p.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Request 7
SELECT MONTHNAME(s.date) as Month, YEAR(s.date) as Year,
	   ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) AS Gross_sales_Amount_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g 
ON g.fiscal_year = s.fiscal_year and s.product_code = g.product_code 
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE c.customer = 'Atliq Exclusive' 
GROUP BY MONTHNAME(s.date), YEAR(s.date);

-- Request 8
SELECT 
CASE 
  WHEN s.date BETWEEN '2019-09-01' AND '2019-11-01' THEN "Q1"
  WHEN s.date BETWEEN '2019-12-01' AND '2020-02-01' THEN "Q2"
  WHEN s.date BETWEEN '2020-03-01' AND '2020-05-01' THEN "Q3"
  WHEN s.date BETWEEN '2020-06-01' AND '2020-08-01' THEN "Q4"
END AS quarter,
  SUM(s.sold_quantity) AS total_sold_quantity  
FROM fact_sales_monthly s
WHERE s.fiscal_year = '2020'
GROUP BY quarter
ORDER BY quarter;

-- Request 9
WITH CTE1 AS 
(SELECT d.channel AS channel, 
	    ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) AS gross_sales_mln
 FROM fact_sales_monthly s 
 JOIN fact_gross_price g
 ON g.fiscal_year = s.fiscal_year AND g.product_code = s.product_code
 JOIN dim_customer d
 ON d.customer_code = s.customer_code
 WHERE s.fiscal_year = '2021' 
 GROUP BY d.channel
 ORDER BY gross_sales_mln DESC
),
CTE2 AS (SELECT SUM(gross_sales_mln) AS total_gross_sales_mln
		  FROM CTE1)
SELECT CTE1.*, ROUND((gross_sales_mln*100/total_gross_sales_mln), 2) AS percentage
FROM CTE1 
JOIN CTE2;	

-- Request 10

WITH CTE1 AS 
(SELECT p.division AS division, p.product AS product, p.product_code AS product_code, 
       SUM(s.sold_quantity) AS total_sold_quantity
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.division, p.product, p.product_code
ORDER BY total_sold_quantity desc
LIMIT 1000000
),
CTE2 AS (SELECT *, DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
		 FROM CTE1
		)
SELECT *
FROM CTE2
WHERE rank_order <= 3;