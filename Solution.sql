
select * from city;
select * from products;
select * from customers;
select * from sales;

-- Report & Data Analysis

-- Q1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does ?

SELECT 
    city_name,
    ROUND(population * 0.25 / 1000000, 2) AS coffe_consumers_in_millions,
    city_rank
FROM
    city
ORDER BY population DESC; 


-- Q2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023 ?

SELECT 
    c.city_name, SUM(s.total) AS total_revenue
FROM
    sales AS s
        JOIN
    customers cst ON s.customer_id = cst.customer_id
        JOIN
    city c ON c.city_id = cst.city_id
WHERE
    YEAR(s.sale_date) = 2023
        AND QUARTER(s.sale_date) = 4
GROUP BY c.city_name;


-- Q3 Sales Count for Each Product
-- How many units of each coffee product have been sold ?

SELECT 
    p.product_name, COUNT(s.sale_id) AS total_orders
FROM
    products p
        LEFT JOIN
    sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;


-- Q4 Average Sales Amount per City
-- What is the average sales amount per customer in each city ?

SELECT 
    ci.city_name,
    SUM(s.total) AS Total_revenue,
    COUNT(DISTINCT s.customer_id) AS Total_cus,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS avg_sale_per_cus
FROM
    sales s
        JOIN
    customers AS c ON c.customer_id = s.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers ?

with city_table as (
					select 
							city_name , round( (population * 0.25) / 1000000 , 2 ) as coffe_consumers_in_millions 
					from city 
),
customers_table as (
					select  
							ci.city_name , count(distinct c.customer_id) as unique_cx  
					from sales s 
					join customers c on c.customer_id = s.customer_id
					join city ci on c.city_id = ci.city_id
					group by 1 
) 
select cit.city_name , cit.coffe_consumers_in_millions , ct.unique_cx from customers_table ct 
join city_table cit on cit.city_name = ct.city_name 
;


-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

with total_orders as (
		select 
				ci.city_name , p.product_name , count(s.sale_id) as total_orders
		from sales s
		join products p on s.product_id = p.product_id
		join customers c on c.customer_id = s.customer_id
		join city ci on c.city_id = ci.city_id 
		group by 1,2
		order by 1
) 
select * from (	
				select 
					city_name , product_name , total_orders , 
                    dense_rank() over (partition by city_name order by total_orders desc) as top_3_pro_sales 
				from total_orders ) as pro_rank 
                where top_3_pro_sales <=3;


-- Q7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
    ci.city_name, COUNT(DISTINCT c.customer_id) AS unique_cx
FROM
    city ci
        LEFT JOIN
    customers c ON c.city_id = ci.city_id
        JOIN
    sales s ON s.customer_id = c.customer_id
WHERE
    s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1
;


-- Q8  Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer ?


 with city_table as (
					select ci.city_name,
						   sum(s.total) as total_revenue ,
						   COUNT(DISTINCT s.customer_id) AS Total_cus, 
                           ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),2) AS avg_sale_per_cus
					FROM
						city ci
					LEFT JOIN
					customers c ON c.city_id = ci.city_id
					JOIN
					sales s ON s.customer_id = c.customer_id
					group by 1
) , 
city_rent as (
				select city_name , 
					   estimated_rent from city 
)
select ct.city_name , 
	   cr.estimated_rent,
       ct.total_cus,
       ct.avg_sale_per_cus,
       round( cr.estimated_rent / ct.total_cus, 2) as avg_rent_per_cus
from city_rent cr
join city_table ct on cr.city_name = ct.city_name
order by 5 desc ;


-- Q9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) 
-- by each city

with monthly_sale as
( 
		select ci.city_name ,
       month(s.sale_date) as month ,
       year(s.sale_date) as year,
       sum(s.total) as total_Sale 
from sales as s
join customers c on c.customer_id = s.customer_id
join city ci on c.city_id = ci.city_id
group by 1 , 2 , 3
order by 1 , 3 , 2
), 

growth_rate as 
(
			select city_name ,
			month ,
			year,
			total_sale as cr_month_sale ,
			lag(total_sale, 1) over (partition by city_name order by year , month) as prev_month_sale
from monthly_sale 
)

select city_name ,
	   month,
       year,
       cr_month_sale ,
       prev_month_sale , 
       round( (cr_month_sale - prev_month_sale ) / prev_month_sale * 100 , 2 ) as growth_ratio
from growth_rate
where prev_month_sale is not null;


-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, 
-- total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total) / COUNT(DISTINCT s.customer_id) 
		,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent / ct.total_cx , 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC ;


-- Recommendations
-- After analyzing the data, the recommended top three cities for new store openings are:

-- City 1: Pune

-- Average rent per customer is very low.
-- Highest total revenue.
-- Average sales per customer is also high.


-- City 2: Delhi

-- Highest estimated coffee consumers at 7.7 million.
-- Highest total number of customers, which is 68.
-- Average rent per customer is 330 (still under 500).


-- City 3: Jaipur

-- Highest number of customers, which is 69.
-- Average rent per customer is very low at 156.
-- Average sales per customer is better at 11.6k.










