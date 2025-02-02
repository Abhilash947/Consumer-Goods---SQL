/** ad-hoc request   **/

/*  1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region. */
select distinct (market)
 from dim_customer 
 where customer ="Atliq Exclusive" and region="APAC";
 
 /* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
 */
 
 with cte1 as (
SELECT count(distinct(product_code)) as unique_product_2020
FROM fact_sales_monthly
where fiscal_year=2020),
 cte2 as (
SELECT count(distinct(product_code)) as unique_product_2021
FROM fact_sales_monthly
where fiscal_year=2021)
select 
unique_product_2020,
unique_product_2021,
(unique_product_2021 - unique_product_2020)*100/unique_product_2020 as percentage_chg
from cte1
cross join cte2

 /* 3. Provide a report with all the unique product counts for each segment and
	   sort them in descending order of product counts. The final output contains 2 fields,
       --> segment
       --> product_count  */
       
	Select segment,
    count(distinct(product_code)) as unique_product_count
    from dim_product
    group by segment 
    order by unique_product_count desc
    
    /*Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment, product_count_2020, product_count_2021, difference    */


with unique_product as(
select
p.segment,
count(distinct(case when fiscal_year=2020 then s.product_code end)) as product_count_2020,
count(distinct(case when fiscal_year=2021 then s.product_code end)) as product_count_2021
from fact_sales_monthly s
join dim_product p
on
p.product_code = s.product_code 
group by p.segment
)
select *,
( product_count_2021- product_count_2020) as difference
from unique_product 
order by difference desc;
  
/*  5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
--> product_code
--> product
--> manufacturing_cost   */  

select 
m.product_code,
p.product, 
round(m.manufacturing_cost,2) as manufacturing_cost
from fact_manufacturing_cost m 
join dim_product p
on p.product_code = m.product_code
where 
m.manufacturing_cost = (select min(manufacturing_cost)from fact_manufacturing_cost)
or
m.manufacturing_cost = (select max(manufacturing_cost)from fact_manufacturing_cost)
order by m.manufacturing_cost desc;
 
 /* 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

with top5Customer as
 (select * from fact_pre_invoice_deductions
join dim_customer c using(customer_code)
where fiscal_year=2021 and c.market='India')

select
customer_code,
customer,
concat(round(avg(pre_invoice_discount_pct)*100,2) ,"%")as avg_disct_pct
from top5Customer
group by customer_code,customer
order by avg_disct_pct desc limit 5;

/* 
7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
 This analysis helps to get an idea of low and high-performing months and take strategic decisions.
 The final report contains these columns: Month, Year, Gross sales Amount
*/

select 
monthname(S.date) as month,
s.fiscal_year as year,
round(sum(gp.gross_price * S.sold_quantity/1000000),2) as gross_sale
from fact_sales_monthly  S
join fact_gross_price gp on S.product_code=gp.product_code
join dim_customer C on C.customer_code = S.customer_code
where customer="Atliq Exclusive"
group by month,year
order by year;

/* 
8. In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity,
Quarter, total_sold_quantity
*/

select (
case
  when month(date) in (9,10,11) then "Q1"
  when month(date) in (12,1,2) then "Q2"
  when month(date) in (3,4,5) then  "Q3"
  when month(date) in (6,7,8) then   "Q4"
end
) as quaters,
sum(sold_quantity) as total_sold_Qty
from fact_sales_monthly
where fiscal_year=2020
group by quaters
order by total_sold_Qty desc;

/* 
 9. Which channel helped to bring more gross sales in the fiscal year 2021and the percentage of contribution?
 The final output contains these fields: channel ,gross_sales_mln,percentage
*/

with cte1 as(
select 
C.channel,
round(sum((S.sold_Quantity * G.gross_price)/1000000),2) as gross_sales_mln
 from dim_customer C
 join fact_sales_monthly S on 
 C.customer_code=S.customer_code
 
 join fact_gross_price G on 
 S.product_code=G.product_code
 where S.fiscal_year=2021
 group by C.channel
)
select *,
 round(gross_sales_mln*100 / (select sum(gross_sales_mln) from cte1),2) as pct_contribution
from cte1
order by  pct_contribution desc;


/* 
 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
 The final output contains these  fields:  division, product_code,product ,total_sold_quantity,rank_order
*/
with rank_ as(
select 
prd.division as division,
sm.product_code as product_code,
prd.product as product,
sum(sold_quantity) as total_sold_quantity,
dense_rank() over(partition by prd.division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly sm
join dim_product prd
on prd.product_code = sm.product_code
where sm.fiscal_year = 2021
group by division, product_code, product
)
select division, product_code, product, total_sold_quantity, rank_order
from rank_
where rank_order <= 3;




