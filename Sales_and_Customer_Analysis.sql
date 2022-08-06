---inspecting Data
select *from[dbo].[Global_Superstore2]

--Checking order status
SELECT[Ship_Date],
    CASE 
       WHEN [Ship_Date] = getdate() THEN 'Not_Delivered'
       WHEN [Ship_Date] < getdate() THEN 'Shipped'
    End AS status
FROM[dbo].[Global_Superstore2]


---Extracting the date field into year

select DATEPART(YEAR,[Order_Date]) as Year_id
from [dbo].[Global_Superstore2]

---Checking unique values
select distinct status 
from 
(SELECT [Ship_Date],
    CASE 
       WHEN [Ship_Date] = getdate() THEN 'Not_Delivered'
       WHEN  [Ship_Date]< getdate() THEN 'Shipped'
    End AS status
FROM[dbo].[Global_Superstore2]) as Status;

select distinct Year_id 
from 
(select DATEPART(YEAR,[Order_Date]) as Year_id
from [dbo].[Global_Superstore2]) as year_id
select distinct [Product_Name]from [dbo].[Global_Superstore2]
select distinct[Category] from [dbo].[Global_Superstore2]
select distinct [Category], [Sub_Category] from [dbo].[Global_Superstore2]
select distinct country from [dbo].[Global_Superstore2]
select distinct region from[dbo].[Global_Superstore2]
select distinct [Ship_Mode] from [dbo].[Global_Superstore2]


---Analysis
---Let's start by grouping sales by Product and Category
select[Category], sum([Sales]) Revenue
from[dbo].[Global_Superstore2]
group by [Category]
order by 2 desc
select[Sub_Category], sum([Sales]) Revenue
from[dbo].[Global_Superstore2]
group by[Sub_Category] 
order by 2 desc
select [Product_Name], sum([Sales]) Revenue
from[dbo].[Global_Superstore2]
group by[Product_Name]
order by 2 desc

 
select DATEPART(YEAR,[Order_Date]) as Year_id, sum ([Sales]) Revenue
from [dbo].[Global_Superstore2]
group by DATEPART(YEAR,[Order_Date]) 
order by 2 desc

 select[Sub_Category], [Country], sum ([Sales]) Revenue
from[dbo].[Global_Superstore2]
group by [Country],[Sub_Category]
order by 3 desc

---What was the best month for sales in year 2014 where total sales was the highest? How much was earned that month?
select DATEPART(MONTH,[Order_Date]) as Month_id, DATEPART(YEAR,[Order_Date]) as Year_id, sum ([Sales]) Revenue
from[dbo].[Global_Superstore2]
where DATEPART(YEAR,[Order_Date]) = 2014
group by DATEPART(MONTH,[Order_Date]), DATEPART(YEAR,[Order_Date])
order by 3 desc

---November seems to be the best month, what items do they sell in November
select DATEPART(MONTH,[Order_Date]) as Month_id, 
       DATEPART(YEAR,[Order_Date]) as Year_id, 
	   [Product_Name],
	   [Category],
	   sum ([Sales]) Revenue
from [dbo].[Global_Superstore2]
where DATEPART(YEAR,[Order_Date]) = 2014 and DATEPART(MONTH,[Order_Date])= 11
group by  DATEPART(MONTH,[Order_Date]), DATEPART(YEAR,[Order_Date]), [Product_Name],[Category]
order by 5 desc


---Who is our best customer(this could be answered with RFM)
select
[Customer_Name],
sum (Sales) Monetary_Value,
avg( Sales) Avg_Monetary_Value,
count(Quantity) Frequency,
max(Order_date) last_order_date,
(select max(order_date) from[dbo].[Global_Superstore2]) max_order_date,
DATEDIFF(DD, max(Order_date), (select max(order_date) from[dbo].[Global_Superstore2])) Recency
from[dbo].[Global_Superstore2]
group by [Customer_Name];

---Creating an Ntile into 4buckets to group rows by rfm indexing with above query values and putting result in a local temp table
DROP TABLE IF EXISTS #RFM;
with RFM as
(
	select
		[Customer_Name],
		sum (Sales) Monetary_Value,
		avg( Sales) Avg_Monetary_Value,
		count(Quantity) Frequency,
		max(Order_date) last_order_date,
		(select max(order_date) from[dbo].[Global_Superstore2]) max_order_date,
		DATEDIFF(DD, max(Order_date), (select max(order_date) from[dbo].[Global_Superstore2])) Recency
from[dbo].[Global_Superstore2]
group by [Customer_Name]
),
RFM_Calc as
(
	select *,
	 NTILE(4) OVER (order by Recency desc) RFM_Recency,
	 NTILE(4) OVER (order by Frequency) RFM_Frequency,
	 NTILE(4) OVER (order by Monetary_Value) RFM_Monetary
	from RFM 
)
 select *,
 cast(RFM_Recency as varchar) + cast (RFM_Frequency as varchar) + cast(RFM_Monetary as varchar) RFM_Cell_String
 into #RFM
 from RFM_Calc 

 select * from #RFM

 select [Customer_Name], RFM_Recency, RFM_Frequency, RFM_Monetary,
 Case
	when RFM_Cell_String in (433, 434, 443,344,444) then 'Loyalists'
	when RFM_Cell_String in (334, 343, 333, 433, 424,324) then 'Potential loyalist'
	when RFM_Cell_String in (414,321, 314, 313, 312, 411, 311,412,422, 421,423,421,412, 411, 413) then 'New customers'
	when RFM_Cell_String in (331, 323, 322,324, 431,441,442,432,341,342,332) then 'Active/Regular customers'
	when RFM_Cell_String in (123,132,122,124,121,114,113,112,211,214,213,212,111) then 'lost customers'
	when RFM_Cell_String in (133, 134,244,243,234,144,324,233) then 'At risk customers'
	when RFM_Cell_String in (131,132,142,241,242,232,231,143,141) then 'lapsed customers'
	when RFM_Cell_String in (223,222,221,224) then 'potential churners'
	end 
from #RFM

---listing the number of customers in each country, ordered by the country with the most customers first.
select count([Customer_ID]), [Country]
from[dbo].[Global_Superstore2]
Group by[Country]
order by 1 desc

---Listing the top 3 cities with the highest sales for each country
WITH CTE AS 
(
    SELECT 
       [Country], City,
               SUM([Sales]) AS UnitsSold,
        RowNum = ROW_NUMBER() OVER (PARTITION BY[Country]  ORDER BY SUM(sales) DESC)
    FROM 
        [dbo].[Global_Superstore2]
    GROUP BY 
         [Country],[City]
)
SELECT * 
FROM CTE
WHERE CTE.RowNum <= 3

---Finding the top 3 products sold in each country
WITH CTE AS 
(
    SELECT 
       [Country], [Product_Name],
               SUM([Quantity]) AS UnitsSold,
        RowNum = ROW_NUMBER() OVER (PARTITION BY[Country]  ORDER BY SUM([Quantity]) DESC)
    FROM 
        [dbo].[Global_Superstore2]
    GROUP BY 
         [Country],[Product_Name]
)
SELECT * 
FROM CTE
WHERE CTE.RowNum <= 3
