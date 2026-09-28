/* =================================================================
   CASE STUDY: BALANCED TREE CLOTHING CO.
   Project: Sales Performance & Financial Report
   ================================================================= */

-- =================================================================
-- A. HIGH LEVEL SALES ANALYSIS
-- =================================================================

-- 1. What was the total quantity for all products?
SELECT 
    SUM(qty) AS Total_quantity
FROM balanced_tree.sales;

-- 2. What is the total generated revenue for all products before discounts?
SELECT 
    SUM(qty * price) AS Total_Generated_Revenue
FROM balanced_tree.sales;

-- 3. What was the total discount amount for all products?
SELECT 
    SUM(qty * price * discount / 100.0) AS Total_Discount_Amount
FROM balanced_tree.sales;


-- =================================================================
-- B. TRANSACTION ANALYSIS
-- =================================================================

-- 1. How many unique transactions were there?
SELECT 
    COUNT(DISTINCT txn_id) AS Unique_Transaction
FROM balanced_tree.sales;

-- 2. What is the average unique products purchased in each transaction?
WITH transaction_products AS (
    SELECT
        txn_id,
        COUNT(DISTINCT prod_id) AS Unique_Count
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT 
    ROUND(AVG(Unique_Count * 1.0), 2) AS Avg_Unique_Products_Per_Transaction
FROM transaction_products;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH transaction_revenue AS (
    SELECT 
        txn_id,
        SUM(qty * price) AS Total_Generated_Revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total_Generated_Revenue) AS percentile_25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Total_Generated_Revenue) AS percentile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total_Generated_Revenue) AS percentile_75
FROM transaction_revenue;

-- 4. What is the average discount value per transaction?
WITH transaction_discount AS (
    SELECT 
        txn_id,
        SUM(qty * price * discount / 100.0) AS Total_Discount
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT 
    AVG(Total_Discount) AS Avg_Discount_Per_Transaction
FROM transaction_discount;

-- 5. What is the percentage split of all transactions for members vs non-members?
WITH member_transaction AS (
    SELECT 
        member,
        COUNT(DISTINCT txn_id) AS Unique_Transaction_Count
    FROM balanced_tree.sales
    GROUP BY member
)
SELECT 
    member,
    Unique_Transaction_Count, 
    ROUND(Unique_Transaction_Count * 100.0 / SUM(Unique_Transaction_Count) OVER(), 2) AS Percentage_Split
FROM member_transaction;
    
-- 6. What is the average revenue for member transactions and non-member transactions?
WITH transaction_revenue AS (
    SELECT 
        member,
        txn_id,
        SUM(qty * price) AS revenue_per_txn
    FROM balanced_tree.sales
    GROUP BY member, txn_id
)
SELECT
    member,
    ROUND(AVG(revenue_per_txn), 2) AS avg_revenue
FROM transaction_revenue
GROUP BY member;


-- =================================================================
-- C. PRODUCT ANALYSIS
-- =================================================================

-- 1. What are the top 3 products by total revenue before discount?
SELECT 
    prod_id,
    SUM(qty * price) AS Total_Generated_Revenue
FROM balanced_tree.sales
GROUP BY prod_id
ORDER BY Total_Generated_Revenue DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT
    p.segment_name,
    SUM(s.qty) AS Total_Quantity,
    SUM(s.qty * s.price) AS Total_Generated_Revenue,
    SUM(s.qty * s.price * s.discount / 100.0) AS Total_Discount
FROM balanced_tree.sales AS s
JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
GROUP BY p.segment_name;

-- 3. What is the top selling product for each segment?
WITH ranked_prod AS (
    SELECT 
        p.segment_name,
        p.product_name,
        SUM(s.qty) AS Total_Quantity,
        DENSE_RANK() OVER(PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS rank_number
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
    GROUP BY p.segment_name, p.product_name
)
SELECT
    segment_name,
    product_name,
    Total_Quantity
FROM ranked_prod
WHERE rank_number = 1;
    
-- 4. What is the total quantity, revenue and discount for each category?
SELECT
    p.category_id,
    SUM(s.qty) AS Total_Quantity,
    SUM(s.qty * s.price) AS Total_Generated_Revenue,
    SUM(s.qty * s.price * s.discount / 100.0) AS Total_Discount
FROM balanced_tree.sales AS s
JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
GROUP BY p.category_id;

-- 5. What is the top selling product for each category?
WITH ranked_prod AS (
    SELECT 
        p.category_id,
        p.product_name,
        SUM(s.qty) AS Total_Quantity,
        DENSE_RANK() OVER(PARTITION BY p.category_id ORDER BY SUM(s.qty) DESC) AS rank_number
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
    GROUP BY p.category_id, p.product_name
)
SELECT
    category_id,
    product_name,
    Total_Quantity
FROM ranked_prod
WHERE rank_number = 1;
    
-- 6. What is the percentage split of revenue by product for each segment?
WITH product_revenue AS (
    SELECT 
        p.product_name,
        p.segment_name,
        SUM(s.qty * s.price) AS Total_Generated_Revenue
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
    GROUP BY p.segment_name, p.product_name
)
SELECT
    product_name,
    segment_name,
    ROUND(Total_Generated_Revenue * 100.0 / SUM(Total_Generated_Revenue) OVER(PARTITION BY segment_name), 2) AS revenue_percentage
FROM product_revenue
ORDER BY segment_name DESC, revenue_percentage DESC; 

-- 7. What is the percentage split of revenue by segment for each category?
WITH segment_revenue AS (
    SELECT 
        p.category_name,
        p.segment_name,
        SUM(s.qty * s.price) AS Total_Generated_Revenue
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
    GROUP BY p.category_name, p.segment_name
)
SELECT
    category_name,
    segment_name,
    ROUND(Total_Generated_Revenue * 100.0 / SUM(Total_Generated_Revenue) OVER(PARTITION BY category_name), 2) AS revenue_percentage
FROM segment_revenue
ORDER BY category_name, revenue_percentage DESC; 

-- 8. What is the percentage split of total revenue by category?
WITH category_revenue AS (
    SELECT
        p.category_name,
        SUM(s.qty * s.price) AS Total_Generated_Revenue
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
    GROUP BY p.category_name
)
SELECT
    category_name,
    ROUND(Total_Generated_Revenue * 100.0 / SUM(Total_Generated_Revenue) OVER(), 2) AS revenue_percentage
FROM category_revenue
ORDER BY category_name DESC, revenue_percentage;

-- 9. What is the total transaction “penetration” for each product? 
SELECT 
    p.product_name,
    ROUND(COUNT(s.txn_id) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales), 2) AS penetration_percentage
FROM balanced_tree.sales AS s
JOIN balanced_tree.product_details AS p ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY penetration_percentage DESC;
-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH txn_products AS (
    SELECT 
        s.txn_id, 
        p.product_id, 
        p.product_name
    FROM balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS p ON s.prod_id = p.product_id
)
SELECT 
    a.product_name AS product_1,
    b.product_name AS product_2,
    c.product_name AS product_3,
    COUNT(*) AS times_bought_together
FROM txn_products AS a
JOIN txn_products AS b ON a.txn_id = b.txn_id AND a.product_id < b.product_id
JOIN txn_products AS c ON a.txn_id = c.txn_id AND b.product_id < c.product_id
GROUP BY 
    a.product_name, 
    b.product_name, 
    c.product_name
ORDER BY times_bought_together DESC
LIMIT 1;
