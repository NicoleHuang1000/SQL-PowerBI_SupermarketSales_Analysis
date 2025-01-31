DESCRIBE supermarket_sales;

SELECT COUNT(*) AS wrong_values
FROM supermarket_sales
WHERE ABS(`Unit price` * Quantity + `Tax 5%`- Total) > 0.01;

SELECT COUNT(*) AS same_values
FROM supermarket_sales
WHERE `gross income`=`Tax 5%`;

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN `Unit price` IS NULL THEN 1 ELSE 0 END) AS unit_price_missing,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS quantity_missing,
    SUM(CASE WHEN `Tax 5%` IS NULL THEN 1 ELSE 0 END) AS tax_missing,
    SUM(CASE WHEN Total IS NULL THEN 1 ELSE 0 END) AS total_missing
FROM supermarket_sales;


/* part 1: data overview */
/* 
convert text date into DATE format
*/
ALTER TABLE supermarket_sales
ADD COLUMN formatted_date DATE;

SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales
SET formatted_date = STR_TO_DATE(Date, '%m/%d/%Y');
SET SQL_SAFE_UPDATEs =  1;

ALTER TABLE supermarket_sales
ADD COLUMN formatted_time TIME;
SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales
SET formatted_time = STR_TO_DATE(Time, '%H:%i');
SET SQL_SAFE_UPDATEs =  1;

SELECT Date, formatted_date
FROM supermarket_sales
LIMIT 10;

SELECT formatted_time FROM supermarket_sales
LIMIT 10;

DESCRIBE supermarket_sales;

/*  check duplicates for invoice. result: no duplicates */
SELECT  COUNT(DISTINCT `Invoice ID`)
FROM supermarket_sales;

/* check negative or unrealistic values*/
SELECT * 
FROM supermarket_sales 
WHERE `Unit price` <0
OR Quantity <0
OR `Tax 5%`<0
OR total <0;



/* Business Question 1): Branch and City Performance */
/* (1)total sales by Branch and City */
SELECT City, Branch, SUM(Total) as Branch_sales
FROM supermarket_sales
GROUP BY City, Branch
ORDER BY Branch_sales DESC;

/* (2)Evaluate Growth patterns by time */
SELECT City, DATE_FORMAT(formatted_date, '%Y-%m') AS month_date, 
SUM(Total) as monthly_sales
FROM supermarket_sales
GROUP BY City, month_date
ORDER BY City, month_date;

/* Business Question 2): customer behavior search */
/* (1)sales distribution by customer type*/
SELECT 
    `Customer type`,
    COUNT(*) AS transaction_count,
    SUM(Total) AS total_sales,
    ROUND(SUM(Total) / (SELECT 
                    SUM(Total)
                FROM
                    supermarket_sales),
            2) AS percentage_contribution
FROM
    supermarket_sales
GROUP BY `Customer type`
ORDER BY total_sales DESC;

/* (2)Compare the average spending (AVG(total)) of male vs. female customers. */
SELECT 
    Gender,
    COUNT(*) AS transaction_count,
    AVG(Total) AS avg_sales,
    SUM(Total) AS total_sales
FROM
    supermarket_sales
GROUP BY Gender;

/* (3) analyze the interaction between gender and customer type.*/
SELECT 
    `Customer type`,
    Gender,
    COUNT(*) AS transaction_count,
    AVG(Total) AS avg_sales,
    SUM(Total) AS total_sales
FROM
    supermarket_sales
GROUP BY `Customer type`, Gender
ORDER BY total_sales DESC;


/* Business Question 3): product line insights */
/* (1) rank the top 3 product line by total revenue */
SELECT 
    `Product line`, SUM(Total) AS total_sales
FROM
    supermarket_sales
GROUP BY `Product line`
ORDER BY total_sales DESC
LIMIT 3;

/* (2) calculate the avarage unit price and quantity sold  for each product line */
SELECT 
    `Product line`,
    AVG(`Unit price`) AS avg_unitprice,
    AVG(Quantity) AS avg_quantity
FROM
    supermarket_sales
GROUP BY `Product line`
ORDER BY avg_unitprice DESC;

/*(3) combined query */ 
SELECT 
    `Product line`,
    SUM(Total) AS total_sales,
    AVG(`Unit price`) AS avg_unitprice,
    AVG(Quantity) AS avg_quantity
FROM
    supermarket_sales
GROUP BY `Product line`
ORDER BY total_sales DESC;

/* Business Question 4): tax contributions */
/* Compute total tax revenue generated per branch.*/
SELECT 
    Branch,City, SUM(`Tax 5%`) AS total_tax
FROM
    supermarket_sales
GROUP BY Branch, City
ORDER BY total_tax DESC;

/* Business Question 5): seasonal trends */
/*  analyse monthly revenue trends to identify peak sales periods*/
SELECT 
    DATE_FORMAT(formatted_date, '%Y-%m') AS month_date,
    SUM(Total) AS total_sales
FROM
    supermarket_sales
GROUP BY month_date
ORDER BY total_sales DESC;

/* 5: Advanced Insights*/
/* (1) Calculate the profit margin for each product line*/
SELECT 
    `Product line`,
    SUM(Total - `Unit price` * Quantity) AS profit,
    ROUND(SUM(Total - `Unit price` * Quantity) / SUM(Total),
            2) AS profit_margin
FROM
    supermarket_sales
GROUP BY `Product line`
ORDER BY profit DESC;

/* (2) Compare Average Revenue Per Transaction Across Branches*/
SELECT 
    branch,
    COUNT(`Invoice ID`) AS total_transactions,
    SUM(Total) AS total_revenue,
    ROUND(SUM(Total) / COUNT(`Invoice ID`), 2) AS avg_revenue_per_transaction
FROM
    supermarket_sales
GROUP BY Branch
ORDER BY avg_revenue_per_transaction DESC;



/* (3) count orders in each time period */
SELECT 
    CASE
        WHEN formatted_time BETWEEN '6:00:00' AND '11:59:59' THEN 'Morning'
        WHEN formatted_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        ELSE 'Night'
    END AS time_period,
    COUNT(`Invoice ID`) AS order_count,
    ROUND(COUNT(`Invoice ID`) / (SELECT 
                    COUNT(*)
                FROM
                    supermarket_sales),
            2) AS order_percent
FROM
    supermarket_sales
GROUP BY time_period
ORDER BY order_count;

/* (4)count orders in each time period for each city */
SELECT City,
    CASE
        WHEN formatted_time BETWEEN '6:00:00' AND '11:59:59' THEN 'Morning'
        WHEN formatted_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        ELSE 'Night'
    END AS time_period,
    COUNT(`Invoice ID`) AS order_count,
    ROUND((COUNT(`Invoice ID`) * 100.0) / SUM(COUNT(`Invoice ID`)) OVER (PARTITION BY City), 2) AS percentage_within_city
FROM
    supermarket_sales
GROUP BY City, time_period
ORDER BY City, order_count DESC;

/*use subquery to calculate percentage */
SELECT 
    City,
    CASE
        WHEN formatted_time BETWEEN '6:00:00' AND '11:59:59' THEN 'Morning'
        WHEN formatted_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        ELSE 'Night'
    END AS time_period,
    COUNT(`Invoice ID`) AS order_count,
    ROUND((COUNT(`Invoice ID`) * 100.0) / (SELECT COUNT(`Invoice ID`) 
                                           FROM supermarket_sales AS total_orders
                                           WHERE total_orders.City = supermarket_sales.City), 2) 
                                           AS percentage_within_city
FROM 
    supermarket_sales
GROUP BY 
    City, time_period
ORDER BY 
    City, order_count DESC;
