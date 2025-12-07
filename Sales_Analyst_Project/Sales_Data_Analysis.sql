CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
);

SELECT * FROM sales_store;
SET DATEFORMAT dmy
BULK INSERT sales_store
FROM 'C:\Users\tbina\Downloads\store\sales\sales_store\sales.csv'
	With(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n'
	);

	--YYYY-MM-DD

	--Data cleaning ---Make a copy so that you'll not mess up original data
SELECT * FROM sales_store;

SELECT * INTO sales from sales_store;

SELECT * FROM sales;

--------------Data Cleaning

--Step 1:- Check duplicate

SELECT transaction_id,COUNT(*) FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id)>1;

--TXN240646
--TXN342128
--TXN855235
--TXN981773


WITH CTE AS (
SELECT *,
	ROW_NUMBER() 
	OVER(PARTITION BY transaction_id 
	ORDER BY transaction_id) AS Row_Num
FROM sales
)
--DELETE FROM CTE
--WHERE Row_Num=2
SELECT * FROM CTE
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

--Step 2 :- Correction of Headers
SELECT * FROM sales

EXEC sp_rename'sales.quantiy','quantity','COLUMN'

EXEC sp_rename'sales.prce','price','COLUMN'

--Step 3 :- Check Datatype

SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='sales'


--Step 4 :- Check Null Values    (Pre-defined query code)

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
    COUNT(*) AS NullCount 
    FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales 
    WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL', 
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;



--treating null values
SELECT * FROM sales
WHERE transaction_id is Null
OR
customer_id is Null
OR
customer_name is NULL
OR
customer_age IS NULL 
OR
gender IS NULL 
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
OR
price IS NULL
OR
payment_mode IS NULL
OR
purchase_date IS NULL
OR
time_of_purchase IS NULL
OR
status IS NULL;

--Deleting outlier-- NULL NULL NULL IN MOST COLUMN
DELETE FROM sales
WHERE transaction_id IS NULL

--Some customer have NULL in customer_id
--Checking if the customer has previously bought or not?
--If Yes, customer_id is shown
SELECT * FROM sales
WHERE Customer_name='Ehsaan Ram'

--Updating sales table,
--setting up their id based on their transaction_id
--where customer_id is NULL
UPDATE sales
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

--Next customer again
SELECT * FROM sales
WHERE Customer_name='Damini Raju'

UPDATE sales
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

--Customer_name,customer_age, gender column row is null
--Need to find their credentials using their customer_id
SELECT * FROM sales
WHERE customer_id='CUST1003'

UPDATE sales
SET customer_name='Mahika Saini',customer_age=35,gender='Male'
WHERE transaction_id='TXN432798'

SELECT * FROM sales

--Step 5:- Data Cleaning . 
-- Gender column contains 4 kinds of distinct values
--F, M, FEMALE, MALE

SELECT DISTINCT gender FROM sales

UPDATE sales
SET gender='M'
Where gender = 'Male'

UPDATE sales
SET gender='F'
Where gender = 'Female'

--payment_mode
--same payment mode is represented by different names
SELECT DISTINCT payment_mode FROM sales

UPDATE sales
SET payment_mode='Credit Card'
Where payment_mode = 'CC'

--Data Analysis--

--🔥1. What are the top 5 most selling products by quantity?

SELECT * FROM sales
SELECT DISTINCT status FROM sales;

--Some product status are cancelled or returned or pending,
--Only 'delivered' products are added
SELECT TOP 5 product_name,SUM(quantity) as Total_quantity_sold FROM sales
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY Total_quantity_sold desc;

--Business Problem: We don't know which products were more in demand.
--Business Impact: Helps prioritize stock and boost sales through targeted promotions.

--🔥2. Which products are most frequently cancelled?

SELECT TOP 5 product_name,COUNT(*) as Total_cancelled FROM sales
WHERE status = 'cancelled'
GROUP BY product_name
Order by Total_cancelled DESC;

--Business Problem: Frequent cancallations affect revenue and customer trust.
--Business Impact: Identify poor-performing produts to improve quality or remove from catalog.


--🔥3. What time of the day has the highest number of purchases?
SELECT 
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END AS time_of_day,
	COUNT(*) AS total_orders
FROM sales
GROUP BY
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END

--Business Problem solved:Find peak sales times.
--Business Impact: Optimize staffing, promotions, and server loads.


--🔥4. Who are the top 5 highest spending customers?
SELECT TOP 5 customer_name, 
	FORMAT(sum(price * quantity),'C0','en-GB') AS total_spend FROM sales
--WHERE status = 'delivered'
GROUP BY customer_name
ORDER BY sum(price*quantity) DESC;

--Business Problem Solved: Identify VIP customers.
--Business Impact: Personalized offers, loyalty rewards and retnetion.


--🔥 5. Which Product categories generate the highest revenue?
SELECT product_category,
	FORMAT(sum(price*quantity),'C0','en-GB') AS gen_REVENUE FROM sales
GROUP BY product_category
ORDER BY sum(price*quantity) DESC;

--business Problem Solved: Identify top-performing product categories.

--Business Impact: Refine product strategy, supply chain, and promition.
--Allowing the business to invest more in high-margin or high-demand categories.




--🔥6. What is the return/cancellation rate per product category?

SELECT * FROM sales;

--cancellation rate
SELECT product_category,
	FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

--return rate
SELECT product_category,
	FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS return_percent
FROM sales
GROUP BY product_category
ORDER BY return_percent DESC;

--Business Problem: Moniter dissatisfaction trends per catgory.

--Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.


--🔥7. What is the most preferred payment mode?

Select payment_mode,COUNT(payment_mode) AS COUNTT from sales
GROUP BY payment_mode
ORDER BY COUNTT DESC;

--Business Problem Solved:Know which payment options customers prefer.
--Business Impact: Streamline payment processing, prioritize popular modes.


--🔥 8. How does age group affect purchasing behavior?

SELECT 
	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END AS customer_age,
	FORMAT(SUM(price*quantity),'C0','en-GB') AS total_purchase
FROM sales
GROUP BY 
	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END
ORDER BY SUM(price*quantity) DESC;

--Business Problem Solved: Understand customer demographics.

--Business Impact: Targeted marketing and product recommendations by age group.




--🔥9. What's the monthly sales trend?

SELECT * FROM sales

--Method 1
SELECT
	FORMAT(purchase_date,'yyyy-MM') AS Month_Year,
	FORMAT(SUM(price*quantity),'C0','en-GB') AS total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY FORMAT(purchase_date,'yyyy-MM')



--METHOD 2

SELECT
	--YEAR(purchase_date) AS Years,
	MONTH(purchase_date) AS Months,
	FORMAT(SUM(price*quantity),'C0','en-GB') AS total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY MONTH(purchase_date)
ORDER BY Months;

--Business Problem: Sales fluctuation go unnoticed.
--Business Impact: Plan Inventory and marketing according to seasonal trends.


--🔥 10. Are certain genders buying more specific product categories?

--Method 1
SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY gender;

--Method 2
SELECT * 
FROM(
	SELECT gender, product_category 
	FROM sales
	) AS source_table
PIVOT (
	COUNT(gender)
	FOR gender IN ([Male],[Female])
	) AS pivot_table
ORDER BY product_category

--Business problem solved: Gender-based product preferences.
--Business Impact: Personalized ads, gender-focused campaigns.




