# Balanced-Tree-Clothing-Project
## Overview
Balanced Tree Clothing Co. needs to optimize its merchandising strategy and understand customer purchasing patterns. This project analyzes over 15,000 sales transactions to uncover actionable insights regarding revenue generation, product performance, and customer loyalty.

**Key outcomes:**
- Processed and modeled structured transaction data using PostgreSQL.
- Identified the most profitable product segments and frequent 3-item baskets to drive cross-selling campaigns.

## Tools & Techniques
- Database: PostgreSQL
- Visualization: Power BI [Insert link to dashboard if available]
- SQL Techniques: CTEs, Subqueries, Window Functions, Self-Joins

## Database Schema
[Insert ERD image here]
Note: Streamlined the original 4-table schema into a Fact-Dimension model for efficient Power BI integration.

## Analysis & SQL Queries

### 1. High Level Sales Analysis
**Q1. What was the total quantity for all products?**

```sql
SELECT SUM(qty) AS Total_quantity
FROM balanced_tree.sales;
```
<img width="930" height="209" alt="image" src="https://github.com/user-attachments/assets/95fbae1d-5d4c-4b2d-97f1-7be74eeaedb4" />

**Q2. What is the total generated revenue for all products before discounts?**
```sql
SELECT SUM(QTY*PRICE) AS Total_Gernerated_Revenue
FROM balanced_tree.sales
```
<img width="926" height="113" alt="image" src="https://github.com/user-attachments/assets/e58c051b-35ea-4fbf-ab16-975243a8a5c9" />

**Q3. What was the total discount amount for all products?**
```sql
SELECT SUM(QTY*PRICE*DISCOUNT/100) AS Total_Discount_Amount
FROM balanced_tree.sales
```
<img width="925" height="103" alt="image" src="https://github.com/user-attachments/assets/b5e075f3-57fc-483f-840f-7c1fc89b80a0" />

### 2. Transaction Analysis
**Q1. How many unique transactions were there?**
```sql
SELECT COUNT(DISTINCT txn_id) AS Unique_Transaction
FROM balanced_tree.sales
```
<img width="921" height="98" alt="image" src="https://github.com/user-attachments/assets/cea8306e-d0de-44db-905b-66bd1c332ae4" />

**Q2. What is the average unique products purchased in each transaction?**
```sql
WITH transaction_products AS(
 SELECT
   txn_id,
   COUNT(DISTINCT prod_id) AS Unique_Count
 FROM balanced_tree.sales
 GROUP BY txn_id
)
 SELECT
   ROUND(AVG(Unique_Count * 1.0),2) AS Avg_Unique_Products_Per_Transaction
 FROM transaction_products
```
<img width="912" height="99" alt="image" src="https://github.com/user-attachments/assets/7758931c-72b2-431b-b1ab-fab6be48e5e0" />

**Q3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**
```sql
WITH transaction_revenue AS(
  SELECT
    txn_id,
    SUM(QTY*PRICE) AS Total_Generated_Revenue
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT
   PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total_Generated_Revenue) AS percentile_25,
   PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Total_Generated_Revenue)
AS percentile_50,
   PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total_Generated_Revenue)
AS percentile_75
FROM transaction_revenue
```
<img width="924" height="88" alt="image" src="https://github.com/user-attachments/assets/457b740c-1a7b-48eb-906e-83371b2b8ade" />

**Q4. What is the average discount value per transaction?**
```sql
WITH transaction_discount AS(
  SELECT
    txn_id,
    SUM(QTY*PRICE*DISCOUNT/100) AS Total_Discount
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT AVG(Total_Discount)
FROM transaction_discount
```
<img width="918" height="86" alt="image" src="https://github.com/user-attachments/assets/697f0601-746f-4588-8036-1a647d41bb2b" />

**Q5. What is the percentage split of all transactions for members vs non-members?**
```sql
WITH member_transaction AS(
  SELECT
    MEMBER,
    COUNT(DISTINCT txn_id) AS Unique_Transaction_Count
  FROM balanced_tree.sales
  GROUP BY MEMBER
)
SELECT
  MEMBER,
  Unique_Transaction_Count,
  ROUND(Unique_Transaction_Count*100.0/SUM(Unique_Transaction_Count) OVER(), 2) AS Percentage_Split
  FROM member_transaction
```
<img width="929" height="154" alt="image" src="https://github.com/user-attachments/assets/ee452f4b-8c29-4032-879a-be526b4c4e4b" />

**Q6. What is the average revenue for member transactions and non-member transactions?**
```sql
WITH transaction_revenue AS(
  SELECT
    MEMBER,
    txn_id,
    SUM(QTY*PRICE) AS revenue_per_txn
  FROM balanced_tree.sales
  GROUP BY MEMBER, txn_id
)
  SELECT
    MEMBER,
    ROUND(AVG(revenue_per_txn), 2) AS avg_revenue
  FROM transaction_revenue
  GROUP BY MEMBER
```
<img width="930" height="150" alt="image" src="https://github.com/user-attachments/assets/3e429c05-0224-464f-bcc6-7fd7ecdb4cd8" />

### 3. Product Analysis
**Q1. What are the top 3 products by total revenue before discount?**
```sql
SELECT 
  prod_id,
  SUM(qty*price) AS Total_Generated_Revenue
FROM balanced_tree.sales
ORDER BY Total_Generated_Revenue DESC
GROUP BY prod_id
LIMIT 3
```
**Q2. What is the total quantity, revenue and discount for each segment?**
```sql
SELECT
 segment_name,
 SUM(s.QTY) AS Total_Quantity,
 SUM(QTY*s.PRICE) AS Total_Generated_Revenue,
 SUM(QTY*s.PRICE*DISCOUNT/100) AS Total_Discount
FROM balanced_tree.sales
JOIN balanced_tree.product_details ON p.product_id = s.prod_id
GROUP BY segment_name
```
**Q3. What is the top selling product for each segment?**
```sql
WITH ranked_prod AS(
  SELECT 
    p.segment_name,
    p.product_name,
    SUM(s.QTY) AS Total_Quantity,
    DENSE_RANK()OVER(PARTITION BY p.segment_name ORDER BY SUM(s.QTY) DESC) AS rank_number
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
  GROUP BY p.segment_name, p.product_name
)
SELECT
   rank_number,
   segment_name,
   product_name,
   Total_Quantity
FROM ranked_prod
WHERE rank_number = 1
```
**Q4. What is the total quantity, revenue and discount for each category?**
```sql
SELECT
 category_id,
 SUM(s.QTY) AS Total_Quantity,
 SUM(QTY*s.PRICE) AS Total_Generated_Revenue,
 SUM(QTY*s.PRICE*DISCOUNT/100) AS Total_Discount
FROM balanced_tree.sales AS s
JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
GROUP BY category_id
```
**Q5. What is the top selling product for each category?**
```sql
WITH ranked_prod AS(
  SELECT 
    p.category_id,
    p.product_name,
    SUM(s.QTY) AS Total_Quantity,
    DENSE_RANK()OVER(PARTITION BY p.category_id ORDER BY SUM(s.QTY) DESC) AS rank_number
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
  GROUP BY p.category_id, p.product_name
)
SELECT
   rank_number,
   category_id,
   product_name,
   Total_Quantity
FROM ranked_prod
WHERE rank_number = 1
```
**Q6. What is the percentage split of revenue by product for each segment?**
```sql
WITH product_revenue AS(
  SELECT 
    p.product_name,
    p.segment_name,
    SUM(QTY*s.PRICE) AS Total_Generated_Revenue
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
  GROUP BY p.segment_name, p.product_name
)
SELECT
   product_name,
   segment_name,
   ROUND(Total_Generated_Revenue*100.0/ SUM(Total_Generated_Revenue) OVER(PARTITION BY segment_name), 2 ) AS revenue_percentage
FROM product_revenue
ORDER BY revenue_percentage, segment_name DESC 
```
**Q7. What is the percentage split of revenue by segment for each category?**
```sql
WITH segment_revenue AS(
  SELECT 
    p.category_name,
    p.segment_name,
    SUM(QTY*s.PRICE) AS Total_Generated_Revenue
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
  GROUP BY p.category_name, p.segment_name
)
SELECT
   category_name,
   segment_name,
   ROUND(Total_Generated_Revenue*100.0/ SUM(Total_Generated_Revenue) OVER(PARTITION BY category_name), 2 ) AS revenue_percentage
FROM segment_revenue
ORDER BY category_name,revenue_percentage DESC
```
**Q8. What is the percentage split of total revenue by category?**
```sql
WITH category_revenue AS(
  SELECT
    p.category_name,
    SUM(s.QTY*s.PRICE) AS Total_Generated_Revenue
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p ON p.product_id = s.prod_id
  GROUP BY p.category_name
)
SELECT
  category_name ,
  ROUND(Total_Generated_Revenue*100.0/SUM(Total_Generated_Revenue) OVER(), 2) AS revenue_percentage
FROM category_revenue
ORDER BY revenue_percentage, category_name DESC
```
**Q9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**
```sql
SELECT 
  p.product_name,
  ROUND(
    COUNT(s.txn_id) * 100.0 /(SELECT COUNT(DISTINCT txn_id)FROM balanced_tree.sales), 2) AS penetration_percentage
FROM balanced_tree.sales AS s
JOIN balanced_tree.product_details AS p ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY penetration_percentage DESC
```
**Q10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**
```sql
WITH txn_products AS (
  SELECT 
    s.txn_id, 
    p.product_id, 
    p.product_name
  FROM balanced_tree.sales AS s
  JOIN balanced_tree.product_details AS p 
    ON s.prod_id = p.product_id
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
LIMIT 1
```











