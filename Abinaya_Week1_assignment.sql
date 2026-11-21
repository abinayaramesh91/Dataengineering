Use Voltkart 


-- Question 1:

with rank_cte as
(select order_id ,rank() over ( order by order_total desc) as rank_sales from fact_orders)

select fo.order_id, fo.order_date, c.customer_name, e.employee_name as sales_rep_name, fo.order_total from fact_orders fo
left join dim_customer c on fo.customer_id= c.customer_id
left join dim_employee e on fo.sales_rep_id=e.employee_id
where fo.order_id in (select order_id from rank_cte where rank_sales <21)
order by order_total desc

--Question 2:
select * from dim_customer d where not exists (select 1 customer_id from fact_orders f 
where d.customer_id=f.customer_id )

select c.*,f.order_total from dim_customer c left join fact_orders f on c.customer_id=f.customer_id
where f.order_total is null;

-- Questions 3

with top3_product as(select c.category_name, p.product_name,sum((p.unit_price-p.unit_cost)*fo.quantity) as total_Revenue,
rank () over( partition by c.category_name order by sum((p.unit_price-p.unit_cost)*fo.quantity) desc) as Rank_revenue
from fact_order_items fo
left join dim_product p on fo.product_id=p.product_id
left join dim_category c on c.category_id=p.category_id
group by c.category_name,
    p.product_name)

select * from top3_product where Rank_revenue <= 3;
    
--Questions 4

with cte1 as
(select order_date,FORMAT(f.order_date, 'yyyy-MM') AS order_month,year(order_Date) as order_year,
sum((p.unit_price-p.unit_cost)*fo.quantity) as total_Revenue
from fact_orders f
left join fact_order_items fo on f.order_id=fo.order_id
left join dim_product p on fo.product_id=p.product_id
left join dim_category c on c.category_id=p.category_id
group by order_date,FORMAT(f.order_date, 'yyyy-MM'),year(order_Date)
)

select order_month,order_year,total_Revenue,
sum(total_Revenue) over(partition by order_year 
order by order_year asc
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Rolling_total,
lag(total_Revenue) over(partition by order_year 
order by order_month asc) - total_revenue  as difference
from cte1
order by order_month


-- Questions 5

with customer_cte as 
( 
select customer_id,sum(order_total) as spend,
NTILE(4) over (order by sum(order_total) asc) as Quartile
from fact_orders group by customer_id
)

select Quartile, count( distinct customer_id) as Customer_count,avg(spend) as Average_Lifetime_Spend from customer_cte
group by Quartile

-- Questions 6

WITH OrgChartCTE AS (
    SELECT 
        category_id,
        category_name,
        1 AS HierarchyLevel, -- Start at Level 1
        CAST(category_name AS VARCHAR(MAX)) AS Categorypath
    FROM dbo.dim_category
    WHERE parent_category_id IS NULL

    UNION ALL

    -- Recursive Member: Join the table back to the CTE to find direct reports
    SELECT 
        c.category_id,
        c.category_name,
        cte.HierarchyLevel + 1,
        CAST(cte.Categorypath + ' -> ' + c.category_name AS VARCHAR(MAX))
    FROM dbo.dim_category c
    INNER JOIN OrgChartCTE cte 
        ON c.parent_category_id = cte.category_id -- The secret sauce: matching manager to employee
)

SELECT 
    category_id,
    REPLICATE('    ', HierarchyLevel - 1) + category_name AS IndentedName,
    HierarchyLevel,
    Categorypath
FROM OrgChartCTE
ORDER BY Categorypath;

question 7:

WITH OrgChartCTE AS
(
    -- Anchor Member
    SELECT 
        employee_id AS ManagerID,
        employee_id AS ReporteeID,
        employee_name AS ManagerName,
        employee_name AS ReporteeName,
        1 AS HierarchyLevel
    FROM dbo.dim_employee
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive Member
    SELECT 
        cte.ManagerID,
        e.employee_id AS ReporteeID,
        cte.ManagerName,
        e.employee_name AS ReporteeName,
        cte.HierarchyLevel + 1
    FROM dbo.dim_employee e
    INNER JOIN OrgChartCTE cte
        ON e.manager_id = cte.ReporteeID
)

SELECT
    cte.ManagerID AS EmployeeID,
    cte.ManagerName AS EmployeeName,
    sum(fo.order_total) AS TotalOrders
FROM OrgChartCTE cte
LEFT JOIN dbo.fact_orders fo
    ON cte.ReporteeID = fo.sales_rep_id
GROUP BY
    cte.ManagerID,
    cte.ManagerName
ORDER BY
    cte.ManagerName
OPTION (MAXRECURSION 100);

--Question 8:

MERGE INTO dbo.fact_orders AS tgt
USING dbo.stg_orders_incr AS src
ON tgt.order_id = src.order_id

WHEN MATCHED AND (
       ISNULL(tgt.order_status,'') <> ISNULL(src.order_status,'')
    OR ISNULL(tgt.order_total,'') <> ISNULL(src.order_total,'')
)
THEN UPDATE SET
    tgt.order_total = src.order_total,
    tgt.Order_status = src.Order_status

WHEN NOT MATCHED BY TARGET THEN
INSERT (order_id, order_date,customer_id,sales_rep_id,order_status,order_total)
VALUES (src.order_id, src.order_date,src.customer_id,src.sales_rep_id,src.order_status,src.order_total)


--Enable CDC 
ALTER TABLE dbo.dim_product
ADD CONSTRAINT PK_dim_product
PRIMARY KEY (product_id);


IF NOT EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = DB_NAME()
      AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END
GO
IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID('dbo.dim_product')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'dim_product',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO


-- UPDATE
UPDATE dbo.dim_product
SET product_name = 'Updated'
WHERE product_id = 900000;

UPDATE Person.Person
SET LastName = 'Updated'
WHERE BusinessEntityID = 15;

-- DELETE
DELETE FROM Person.Person
WHERE BusinessEntityID = 10;


SELECT
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE_BEFORE'
        WHEN 4 THEN 'UPDATE_AFTER'
    END AS OperationType,
    __$start_lsn
FROM cdc.dbo_dim_product_CT
WHERE BusinessEntityID = 30001
ORDER BY __$start_lsn;
GO


--Question 10:

SELECT o.customer_id, COUNT(*) AS orders_2024,
(SELECT SUM(oi.line_amount)
FROM fact_order_items oi
JOIN fact_orders o2 ON o2.order_id = oi.order_id
WHERE o2.customer_id = o.customer_id) AS lifetime_value
FROM fact_orders o
WHERE YEAR(o.order_date) = 2024
GROUP BY o.customer_id;

--Alternate query :


with cte1 as
(select order_id,sum(line_amount) as lifetime_amount from fact_order_items
group by order_id)

select fo.customer_id,count(c.order_id) as order_count,sum(c.lifetime_amount) as lifetime_amount from fact_orders fo
left join cte1 c on c.order_id=fo.order_id
where fo.order_date >= '20240101'
  AND fo.order_date < '20250101'
group by  fo.customer_id