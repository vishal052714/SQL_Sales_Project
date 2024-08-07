-- 1. Retrieve: --
-- All customers with their contact information. --
SELECT first_name, last_name, phone FROM sales.customers;
-- All productions with their category and brand. --
SELECT product_id,product_name,category_name,brand_name FROM sales.products AS p
INNER JOIN sales.categories AS c on p.category_id=c.category_id
INNER JOIN sales.brands AS b on p.brand_id=b.brand_id;
-- All orders placed in a specific(10-October) month. --
SELECT * FROM sales.orders WHERE month(order_date)= 10;
-- All stores located in a specific(Rowlett) city. --
SELECT * FROM sales.stores WHERE city = 'Rowlett';
-- All staff members who work at a particular store(Baldwin Bikes). --
SELECT first_name,last_name FROM sales.staffs AS s
LEFT JOIN sales.stores AS st ON s.store_id= st.store_id
WHERE st.store_name= 'Baldwin Bikes';
-- 2. Count: --
-- The total number of customers. --
SELECT count(*) FROM sales.customers;
-- The number of production in each category. --
SELECT c.category_name, count(p.product_id) AS number_of_products 
FROM sales.categories AS c
JOIN sales.products AS p ON c.category_id=p.category_id 
GROUP BY c.category_name;
-- The number of orders per customer. --
SELECT c.first_name,c.last_name,count(o.order_id) AS number_of_orders
FROM sales.customers AS c
JOIN sales.orders AS o ON c.customer_id=o.customer_id
GROUP BY c.first_name,c.last_name;
-- The total number of orders for a specific(Ritchey Timberwolf Frameset - 2016) product. --
SELECT count(o.order_id) FROM sales.order_items AS o
JOIN sales.products AS p ON p.product_id=o.product_id
WHERE p.product_name='Ritchey Timberwolf Frameset - 2016';
-- 3. Sum: --
-- The total sales amount for all orders. --
SELECT sum(quantity*(list_price-discount)) AS Total_sales_amount FROM sales.order_items;
-- The total quantity of productions in stock. --
SELECT sum(quantity) AS Total_quantity_production FROM sales.stocks;
-- The total number of orders for each store. --
SELECT s.store_name,count(o.order_id) AS total_orders
FROM sales.stores AS s
JOIN sales.orders AS o ON s.store_id=o.store_id
GROUP BY s.store_id;
-- 4. Average: --
-- The average order value. --
WITH OrderTotals AS (
SELECT o.order_id, sum(oi.quantity*oi.list_price) AS total_price
FROM sales.order_items AS oi
JOIN sales.orders AS o on oi.order_id = o.order_id
GROUP BY o.order_id)
SELECT avg(total_price) AS average_order_value FROM OrderTotals;
-- The average number of produtions per order. --
WITH number_of_production AS (
SELECT oi.order_id,count(p.product_id) AS count_production FROM sales.order_items AS oi
INNER JOIN sales.products AS p ON p.product_id=oi.product_id
GROUP BY oi.order_id)
SELECT avg(count_production) AS average_number_of_production FROM number_of_production;  
-- The average number of orders per customer. --
WITH CustomerOrderCount AS (
SELECT customer_id,count(order_id) AS total_orders FROM sales.orders 
GROUP BY customer_id )
SELECT avg(total_orders) AS average_orderders_per_customer FROM CustomerOrderCount;
-- 5. Joins: --
-- List the customers and their corresponding orders. --
SELECT c.customer_id,c.first_name,c.last_name,o.order_id,o.order_date FROM sales.customers AS c
LEFT JOIN sales.orders AS o ON o.customer_id=c.customer_id; 
-- Show product details(name,brand,category) for each order item. --
SELECT DISTINCT oi.item_id,p.product_name,b.brand_name,c.category_name FROM sales.order_items AS oi
JOIN sales.products AS p ON oi.product_id=p.product_id
JOIN sales.categories AS c ON c.category_id=p.category_id
JOIN sales.brands AS b ON b.brand_id=p.brand_id;
-- Find the total sales for each store. --
SELECT s.store_id,s.store_name,sum(oi.quantity*oi.list_price-oi.discount) AS total_sales
FROM sales.stores AS s
JOIN sales.orders AS o ON s.store_id=o.store_id
JOIN sales.order_items AS oi ON o.order_id=oi.order_id
GROUP BY s.store_id,s.store_name;
-- Determine the best-selling product for each category. --
WITH ProductSales AS (
  SELECT p.product_id, p.product_name, p.category_id, 
    SUM(oi.quantity) AS total_quantity
  FROM sales.products AS p 
  JOIN sales.order_items AS oi ON p.product_id = oi.product_id
  GROUP BY p.product_id, p.product_name, p.category_id
)
SELECT category_id, product_name, total_quantity
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY total_quantity DESC) AS rn
  FROM ProductSales
) ranked WHERE rn = 1;
-- 6. Grouping and Aggregating: --
-- Find the top 5 customers by total purchase amount. --
SELECT
  c.customer_id,c.first_name, c.last_name,
  SUM(oi.quantity * oi.list_price) AS total_purchase
FROM sales.customers AS c
INNER JOIN sales.orders AS o ON c.customer_id = o.customer_id
INNER JOIN sales.order_items AS oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name,c.last_name
ORDER BY total_purchase DESC LIMIT 5;
-- Calculate the total sales for each month for different years. --
SELECT year(o.order_date),monthname(o.order_date),sum(oi.list_price*oi.quantity-oi.discount) FROM sales.order_items AS oi
JOIN sales.orders AS o ON oi.order_id=o.order_id
GROUP BY year(o.order_date),month(o.order_date);
-- Determine the most popular product category. --
SELECT c.category_name,sum(oi.quantity) AS total_quantity FROM sales.order_items AS oi
JOIN sales.products AS p ON oi.product_id=p.product_id
JOIN sales.categories AS c ON p.category_id=c.category_id
GROUP BY c.category_name
ORDER BY total_quantity DESC LIMIT 1;
-- Find the least performing store based on total sales. --
SELECT s.store_id,s.store_name,sum(oi.quantity*oi.list_price) AS total_sales
FROM sales.stores AS s
JOIN sales.orders AS o ON s.store_id=o.store_id
JOIN sales.order_items AS oi ON o.order_id=oi.order_id
GROUP BY s.store_id, s.store_name
ORDER BY total_sales ASC LIMIT 1;
-- 7. Subqueries: --
-- Find customers who have placed more then 2 orders. --
SELECT c.customer_id, c.first_name, c.last_name, count(*) AS total_orders 
FROM sales.customers AS c
JOIN sales.orders AS o ON c.customer_id=o.customer_id
GROUP BY c.customer_id, c.first_name,c.last_name
HAVING count(*) > 2;
-- Identify products with a list price higher than the average list price. --
SELECT p.product_id, p.product_name,p.list_price FROM sales.products AS p
WHERE p.list_price > (SELECT avg(list_price) FROM sales.products);
-- Determine stores with total sales above the company average. --
WITH StoreSales AS (
SELECT s.store_id, sum(oi.quantity*oi.list_price) AS total_sales
FROM sales.stores AS s 
JOIN sales.orders AS o ON s.store_id=o.store_id
JOIN sales.order_items AS oi ON o.order_id=oi.order_id
GROUP BY s.store_id)
SELECT ss.store_id, ss.total_sales,
(SELECT avg(total_sales) FROM StoreSales) AS avg_sales FROM StoreSales AS ss
WHERE ss.total_sales > (SELECT avg(total_sales) FROM StoreSales); 
-- 8. Complex Joins: --
-- Find customers who have ordered a specific product from a particular store. --
SELECT DISTINCT c.customer_id, c.first_name, c.last_name FROM sales.customers AS c
JOIN sales.orders AS o ON c.customer_id=o.customer_id
JOIN sales.order_items AS oi ON oi.order_id=o.order_id
JOIN sales.products AS p ON oi.product_id=p.product_id
JOIN sales.stores AS s ON o.store_id=s.store_id
WHERE p.product_id= 3 AND s.store_id= 3;
-- Calculate the inventory value for each store. --
SELECT s.store_id, sum(p.list_price*st.quantity) AS inventory_value
FROM sales.stores AS s
JOIN sales.stocks AS st ON s.store_id=st.store_id
JOIN sales.products AS p ON st.product_id=p.product_id
GROUP BY s.store_id;
-- 9. Window Function: --
-- Rank prodction based on their total sales --
WITH ProductSales AS (
SELECT p.product_id,p.product_name,sum(oi.quantity*oi.list_price) AS total_sales
FROM sales.products AS p
JOIN sales.order_items AS oi ON p.product_id=oi.product_id
GROUP BY p.product_id,p.product_name)
SELECT product_id,product_name,total_sales, 
rank() OVER (ORDER BY total_sales DESC) AS sales_rank FROM ProductSales;
-- Calculate the running total of sales over time. --
WITH OrderTotals AS (
  SELECT 
    o.order_id, 
    SUM(oi.quantity*oi.list_price*(1 - oi.discount)) AS total_sale
  FROM sales.orders AS o
  JOIN sales.order_items AS oi ON o.order_id = oi.order_id
  GROUP BY o.order_id
)
SELECT o.order_date, ot.total_sale,
  SUM(ot.total_sale) OVER (ORDER BY o.order_date) AS running_total
FROM sales.orders AS o
JOIN OrderTotals AS ot ON o.order_id = ot.order_id
ORDER BY o.order_date;
-- 10. Set Operations: --
-- Find customers who have placed orders but not made any purchases. --
SELECT c.customer_id, c.first_name, c.last_name FROM sales.customers AS c
JOIN sales.orders AS o ON c.customer_id=o.customer_id
LEFT JOIN sales.order_items AS oi ON o.order_id=oi.order_id
WHERE oi.order_id IS NULL;
-- Identify products available in all stores. --
SELECT p.product_id, p.product_name FROM sales.products AS p
WHERE NOT EXISTS (
SELECT * FROM sales.stores AS s
WHERE NOT EXISTS (
SELECT * FROM sales.stocks AS st
WHERE st.product_id=p.product_id
AND st.store_id=s.store_id
));