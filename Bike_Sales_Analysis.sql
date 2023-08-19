--Q1 - Bike Sales by Country and Commute Distance

with bike_sales AS
(
    select OrderDateKey,
        OrderDate,
        T1.CustomerKey,
        BirthDate,
        YearlyIncome,
        TotalChildren,
        CommuteDistance,
        EnglishCountryRegionName as Country,
        EnglishProductSubcategoryName as Bike_Type,
        SalesAmount,
        SalesOrderNumber
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimCustomer T2
ON T1.CustomerKey = T2.CustomerKey
JOIN AdventureWorksDW2019.dbo.DimGeography T3
ON T2.GeographyKey = T3.GeographyKey
JOIN AdventureWorksDW2019.dbo.DimProduct T4
ON T4.ProductKey = T1.ProductKey
JOIN AdventureWorksDW2019.dbo.DimProductSubcategory T5
ON T5.ProductSubcategoryKey = T4.ProductSubcategoryKey
where EnglishProductSubcategoryName IN ('Mountain Bikes','Touring Bies','Road Bikes')
)

select Country, 
        CommuteDistance, 
        COUNT(distinct SalesOrderNumber) as Sales
from bike_sales
GROUP BY Country, CommuteDistance
ORDER BY Country, CommuteDistance;

--Q2 - Bike Sales by Income

with bike_sales AS
(
    select OrderDateKey,
        OrderDate,
        T1.CustomerKey,
        BirthDate,
        YearlyIncome,
        TotalChildren,
        CommuteDistance,
        EnglishCountryRegionName as Country,
        EnglishProductSubcategoryName as Bike_Type,
        SalesAmount,
        SalesOrderNumber
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimCustomer T2
ON T1.CustomerKey = T2.CustomerKey
JOIN AdventureWorksDW2019.dbo.DimGeography T3
ON T2.GeographyKey = T3.GeographyKey
JOIN AdventureWorksDW2019.dbo.DimProduct T4
ON T4.ProductKey = T1.ProductKey
JOIN AdventureWorksDW2019.dbo.DimProductSubcategory T5
ON T5.ProductSubcategoryKey = T4.ProductSubcategoryKey
where EnglishProductSubcategoryName IN ('Mountain Bikes','Touring Bies','Road Bikes')
)

select CustomerKey,
CASE WHEN YearlyIncome < 50000 THEN 'a: Less than $50k'
     WHEN YearlyIncome BETWEEN 50000 AND 75000 THEN 'b: $50k - $75k'
     WHEN YearlyIncome BETWEEN 75000 AND 100000 THEN 'c: $75k - $100k'
     WHEN YearlyIncome > 100000 THEN 'd: Greater than $100k'
     else 'Other'
     END AS Income,
     count(SalesOrderNumber) as Purchases
FROM bike_sales
GROUP BY CustomerKey, YearlyIncome;

--Q3 - Bike Sales based on number of children

with bike_sales AS
(
    select OrderDateKey,
        OrderDate,
        T1.CustomerKey,
        BirthDate,
        YearlyIncome,
        TotalChildren,
        CommuteDistance,
        EnglishCountryRegionName as Country,
        EnglishProductSubcategoryName as Bike_Type,
        SalesAmount,
        SalesOrderNumber
from AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimCustomer T2
ON T1.CustomerKey = T2.CustomerKey
JOIN AdventureWorksDW2019.dbo.DimGeography T3
ON T2.GeographyKey = T3.GeographyKey
JOIN AdventureWorksDW2019.dbo.DimProduct T4
ON T4.ProductKey = T1.ProductKey
JOIN AdventureWorksDW2019.dbo.DimProductSubcategory T5
ON T5.ProductSubcategoryKey = T4.ProductSubcategoryKey
where EnglishProductSubcategoryName IN ('Mountain Bikes','Touring Bies','Road Bikes')
)

select SUBSTRING(cast(OrderDateKey as char), 1, 6) as Month_Key,
        CASE WHEN TotalChildren = 0 THEN 'No Children'
        ELSE 'Has Children' END AS Children_Status,
        count(SalesOrderNumber) as Sales
from bike_sales
where SUBSTRING(cast(OrderDateKey as char), 1, 4) = '2012'
group by SUBSTRING(cast(OrderDateKey as char), 1, 6),
         TotalChildren;