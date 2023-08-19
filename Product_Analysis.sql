--Q1 - Country Sales by Age Group (CTE's and CASE WHEN statement)

with country_sales_group as 
(
select T3.EnglishCountryRegionName,
       DATEDIFF(year,BirthDate,OrderDate) as AGE,
       SalesOrderNumber
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimCustomer T2
ON T1.customerkey = T2.customerkey
JOIN AdventureWorksDW2019.dbo.DimGeography T3
ON T2.GeographyKey = T3.GeographyKey
)

select EnglishCountryRegionName,
        CASE WHEN AGE < 30 THEN 'A: Under 30'
        WHEN AGE BETWEEN 30 AND 40 THEN 'B: 30 - 40'
        WHEN AGE BETWEEN 40 AND 50 THEN 'C: 40 - 50'
        WHEN AGE BETWEEN 50 AND 60 THEN 'D: 50 - 60' 
        WHEN AGE > 60 THEN 'E: Over 60'
        ELSE 'F: Other'
        END AS age_group,
        count(SalesOrderNumber) as sales_country
from country_sales_group
group by EnglishCountryRegionName,
        CASE WHEN AGE < 30 THEN 'A: Under 30'
        WHEN AGE BETWEEN 30 AND 40 THEN 'B: 30 - 40'
        WHEN AGE BETWEEN 40 AND 50 THEN 'C: 40 - 50'
        WHEN AGE BETWEEN 50 AND 60 THEN 'D: 50 - 60' 
        WHEN AGE > 60 THEN 'E: Over 60'
        ELSE 'F: Other'
        END
order by EnglishCountryRegionName,age_group;

--Q2 - Product Sales by Age Group (CTE's, CASE WHEN statement and Date Function)

with product_sales_group as 
(
select T4.EnglishProductSubcategoryName,
       DATEDIFF(MONTH,BirthDate,OrderDate)/12 as AGE,
       SalesOrderNumber
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimCustomer T2
ON T1.customerkey = T2.customerkey
JOIN AdventureWorksDW2019.dbo.DimProduct T3
ON T1.ProductKey = T3.ProductKey
JOIN AdventureWorksDW2019.dbo.DimProductSubcategory T4
ON T4.ProductSubcategoryKey = T3.ProductSubcategoryKey
)

select  EnglishProductSubcategoryName AS product_type,
        CASE WHEN AGE < 30 THEN 'A: Under 30'
        WHEN AGE BETWEEN 30 AND 40 THEN 'B: 30 - 40'
        WHEN AGE BETWEEN 40 AND 50 THEN 'C: 40 - 50'
        WHEN AGE BETWEEN 50 AND 60 THEN 'D: 50 - 60' 
        WHEN AGE > 60 THEN 'E: Over 60'
        ELSE 'F: Other'
        END AS age_group,
        count(SalesOrderNumber) as Sales
from product_sales_group
group by EnglishProductSubcategoryName,
        CASE WHEN AGE < 30 THEN 'A: Under 30'
        WHEN AGE BETWEEN 30 AND 40 THEN 'B: 30 - 40'
        WHEN AGE BETWEEN 40 AND 50 THEN 'C: 40 - 50'
        WHEN AGE BETWEEN 50 AND 60 THEN 'D: 50 - 60' 
        WHEN AGE > 60 THEN 'E: Over 60'
        ELSE 'F: Other'
        END
order by product_type,age_group;

--Q3 - Sales in USA and Australia Comparison (String and Date Functions)

select substring(cast(OrderDateKey as char),1,6) as Month_Wise_Data,
        SalesOrderNumber,
        OrderDate,
        SalesTerritoryCountry
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimSalesTerritory T2
ON T1.SalesTerritoryKey = T2.SalesTerritoryKey
where SalesTerritoryCountry IN ('Australia','United States')
AND substring(cast(OrderDateKey as char),1,4) = '2012';

--Q4 - Products First reorder date (CTE's, Subquery, Window Function, Aggregate Functions, CASE WHEN statement)

with main_query AS
(
    select EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint,
            SUM(T1.OrderQuantity) as Sales
    from AdventureWorksDW2019.dbo.FactInternetSales T1
    JOIN AdventureWorksDW2019.dbo.DimProduct T2
    ON T1.ProductKey = T2.ProductKey
    group by EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint
),

reorder_date AS
(
    select *, 
            CASE WHEN (SafetyStockLevel - Running_Total_Sales) <= ReorderPoint THEN 1 ELSE 0 END AS reorder_flag
    from
    (
        select *, 
                SUM(Sales) OVER (Partition BY EnglishProductName Order By OrderDateKey) as Running_Total_Sales
        from main_query
        GROUP BY EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint,
            Sales
    ) AS sales_partition_by_name
)

select EnglishProductName,
        MIN(OrderDateKey) AS first_reorder_date
from reorder_date
where reorder_flag = 1
group by EnglishProductName;

--Q5 - Products with High Stock Levels

with main_query AS
(
    select EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint,
            SUM(T1.OrderQuantity) as Sales
    from AdventureWorksDW2019.dbo.FactInternetSales T1
    JOIN AdventureWorksDW2019.dbo.DimProduct T2
    ON T1.ProductKey = T2.ProductKey
    group by EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint
),

reorder_date AS
(
    select *, 
            CASE WHEN (SafetyStockLevel - Running_Total_Sales) <= ReorderPoint THEN 1 ELSE 0 END AS reorder_flag
    from
    (
        select *, 
                SUM(Sales) OVER (Partition BY EnglishProductName Order By OrderDateKey) as Running_Total_Sales
        from main_query
        GROUP BY EnglishProductName,
            OrderDateKey,
            SafetyStockLevel,
            ReorderPoint,
            Sales
    ) AS sales_partition_by_name
)


select EnglishProductName, 
        max(product_first_orderdate) as product_first_orderdate, 
        max(first_reorder_date) as first_reorder_date,
        datediff(day,max(cast(cast(product_first_orderdate as char) as date)),max(cast(cast(first_reorder_date as char) as date))) as days_to_reorder
from
(
    select EnglishProductName,
        MIN(OrderDateKey) AS product_first_orderdate,
        null as first_reorder_date
    from main_query
    group by EnglishProductName
    union all
    select EnglishProductName,
        null as product_first_orderdate,
        MIN(OrderDateKey) AS first_reorder_date
    from reorder_date
    where reorder_flag = 1
    group by EnglishProductName
) main_sub_query
group by EnglishProductName
having datediff(day,max(cast(cast(product_first_orderdate as char) as date)),max(cast(cast(first_reorder_date as char) as date))) > 365;

--Q6 - Sales on promotion and sales amount after 25% discount

select OrderDate, 
        SalesReasonName, 
        T1.SalesOrderNumber,
        SalesAmount,
        round((SalesAmount*0.75),2) as sales_amount_after_discount
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.FactInternetSalesReason T2
ON T1.SalesOrderNumber = T2.SalesOrderNumber
JOIN AdventureWorksDW2019.dbo.DimSalesReason T3
ON T2.SalesReasonKey = T3.SalesReasonKey
where SalesReasonName = 'On Promotion';

--Q7 - Customer's first and last order details

with first_purchase AS
(
    select CustomerKey,
            SalesAmount,
            OrderDate,
            ROW_NUMBER() OVER (PARTITION BY CustomerKey ORDER BY OrderDate) as purchase_num
    from AdventureWorksDW2019.dbo.FactInternetSales
),

last_purchase AS
(
    select CustomerKey,
            SalesAmount,
            OrderDate,
            ROW_NUMBER() OVER (PARTITION BY CustomerKey ORDER BY OrderDate desc) as purchase_num
    from AdventureWorksDW2019.dbo.FactInternetSales
)

select CustomerKey,
        sum(first_purchase_value) as first_purchase_value,
        sum(last_purchase_value) as last_purchase_value,
        (sum(last_purchase_value) - sum(first_purchase_value)) as difference_amount
from
(
    select CustomerKey, 
        SalesAmount as first_purchase_value,
        null as last_purchase_value
    from first_purchase
    where purchase_num = 1
    union all
    select CustomerKey, 
        null as first_purchase_value,
        SalesAmount as last_purchase_value
    from last_purchase
    where purchase_num = 1
) as main_sub_query
group by CustomerKey
having (sum(last_purchase_value) - sum(first_purchase_value)) <> 0
order by CustomerKey;




