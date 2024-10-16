--Retrieve the top 5 sales orders with the highest subtotal.
SELECT TOP 5 WITH TIES SOH.SalesOrderID,SOH.SubTotal
FROM Sales.SalesOrderHeader AS SOH 
ORDER BY SOH.SubTotal DESC


-- Retrieve the first 5 orders for customer with ID 12345, ordered by order date.SELECT SOH.SalesOrderID ,SOH.CustomerID,SOH.OrderDateFROM Sales.Customer AS cusINNER JOIN Sales.SalesOrderHeader AS SOH ON SOH.CustomerID=cus.CustomerIDWHERE cus.CustomerID = 12345ORDER BY SOH.OrderDateOFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY--List the top 5 most recently hired employees.SELECT TOP 5 emp.BusinessEntityID,emp.HireDateFROM HumanResources.Employee AS emp ORDER BY emp.HireDate DESC--Retrieve products from the 3rd page (rows 21 to 30) for each category, ordered by category name and product name.
SELECT pc.Name,p.Name
FROM Production.Product AS p
INNER JOIN Production.ProductSubcategory AS ps
ON p.ProductSubcategoryID=ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
ON pc.ProductCategoryID=ps.ProductCategoryID
ORDER BY pc.Name,p.Name
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY


--Retrieve customers who are not in territories 1, 2, or 3, including their customer ID and territory ID, and order by customer ID.
SELECT cus.CustomerID,cus.TerritoryID
FROM Sales.Customer AS cus
WHERE cus.TerritoryID NOT IN (1,2,3)
ORDER BY cus.CustomerID


--- Retrieve the product IDs and the last four characters of the product number.
SELECT p.ProductID ,p.ProductNumber , RIGHT(p.ProductNumber,4)
FROM Production.Product AS p 


--Retrieve the product IDs and a substring of the first five characters of the product name.
SELECT p.ProductID,p.Name,SUBSTRING(p.Name,1,5)
FROM Production.Product AS p


--Retrieve product IDs and names for products introduced in the last year
SELECT p.ProductID,p.Name,P.SellStartDate
FROM Production.Product AS p 
WHERE DATEDIFF(year, p.SellStartDate ,GETDATE()) =1



--Retrieve the business entity IDs and email addresses of persons whose email addresses end with '.com'.SELECT p.BusinessEntityID,ea.EmailAddressFROM Person.Person AS pINNER JOIN Person.EmailAddress AS eaON p.BusinessEntityID=ea.BusinessEntityIDWHERE ea.EmailAddress LIKE '%.com'--Retrieve the product IDs and names of products whose names contain the word 'Touring'SELECT p.ProductID,p.NameFROM Production.Product AS pWHERE p.Name LIKE '%Touring%'--Convert the product list price to a string for display purposes.
SELECT CAST(ListPrice AS varchar),ListPrice
FROM Production.Product


--Display order totals, casting null values to 0 for consistency.SELECT soh.TotalDue, ISNULL(soh.TotalDue , 0)FROM Sales.SalesOrderHeader sohWHERE soh.TotalDue IS NULL--Classify orders as 'Large' or 'Small' based on order total.SELECT SOH.TotalDue , IIF(SOH.TotalDue > 10000 ,'Large','Small')FROM Sales.SalesOrderHeader SOH--Determine hire date month name based on the hire date.SELECT EMP.HireDate,MONTH(EMP.HireDate),DATENAME(month,EMP.HireDate)FROM HumanResources.Employee EMP--Display either the product color or 'No Color' if color is null.SELECT p.Color,IIF(p.Color IS NULL,'No Color',p.Color)FROM Production.Product p --Customers with More Than 5 Orders.SELECT CUS.CustomerID,COUNT(SOH.SalesOrderID)FROM Sales.Customer CUSINNER JOIN Sales.SalesOrderHeader SOHON CUS.CustomerID=SOH.CustomerIDGROUP BY CUS.CustomerIDHAVING COUNT(SOH.SalesOrderID) > 5--Total Sales Amount by Year and QuarterSELECT YEAR(SOH.DueDate), DATENAME(QUARTER,soh.DueDate),COUNT(SOH.SalesOrderID)FROM Sales.SalesOrderHeader SOHGROUP BY YEAR(SOH.DueDate),DATENAME(QUARTER,soh.DueDate)--Number of Orders by Customer TypeSELECT P.PersonType, COUNT(SOH.SalesOrderID)FROM Sales.Customer cusINNER JOIN Sales.SalesOrderHeader SOH ON cus.CustomerID=SOH.CustomerIDINNER JOIN Person.Person PON CUS.PersonID=P.BusinessEntityIDGROUP BY P.PersonType/*Create an product table with columns: ID (using a sequence object), Name, Color, type, Status.
Create an new_products table with the same schema as the 
product table.
Synchronize the product table with the new_products
table, updating existing records and inserting new ones using a sequence object.*/


CREATE TABLE product 
(
ID INT DEFAULT NEXT VALUE FOR GlobalID,
Name NVARCHAR,
Color VARCHAR,
type VARCHAR,
Status VARCHAR
)

CREATE SEQUENCE GlobalID AS INT START WITH 1 INCREMENT BY 1;

CREATE TABLE new_product 
(
ID INT DEFAULT NEXT VALUE FOR GlobalID,
Name NVARCHAR,
Color VARCHAR,
type VARCHAR,
Status VARCHAR
)

MERGE INTO new_product AS NP
USING product AS P
ON 	NP.ID=P.ID
WHEN MATCHED THEN 
	UPDATE SET
	NP.Name=P.Name,
	NP.Color=P.Color,
	NP.type=P.type,
	NP.Status=P.Status
WHEN NOT MATCHED THEN 
	INSERT(ID,Name,Color,type,Status)
	VALUES(P.ID,P.Name,P.Color,P.type,P.Status);



--Create a new table Bikes Products with product who have the bike in their subcategory name
SELECT p.Name,p.ProductID,p.ProductNumber
INTO Production.Bike_Product
FROM Production.Product P
INNER JOIN Production.ProductSubcategory PSC
ON P.ProductSubcategoryID=PSC.ProductSubcategoryID
WHERE PSC.Name LIKE '%bike%'

SELECT * FROM Production.Bike_Product


/* Calculate Average Lead Time for Each Vendor
Columns to Select:
businessentityid: Identifier for the vendor.
productid: Identifier for the product.
averageleadtime: Average lead time for the product.
AvgLeadTimePerVendor: Average lead time across all products supplied by the vendor
*/

SELECT PV.BusinessEntityID,PV.ProductID,PV.AverageLeadTime,AVG(PV.AverageLeadTime) OVER(PARTITION BY PV.BusinessEntityID) AS AvgLeadTimePerVendor
FROM Purchasing.ProductVendor PV



/*Create a TVF that returns all orders for a specified customer*/
CREATE FUNCTION ord_for_cust
(@id int)
RETURNS @all_ord_cust TABLE (SalesOrderID int , OrderDate DATETIME,SalesOrderNumber nvarchar(25))
AS 
BEGIN
INSERT INTO @all_ord_cust
SELECT soh.SalesOrderID,soh.OrderDate,soh.SalesOrderNumber
FROM Sales.Customer CUS
JOIN Sales.SalesOrderHeader SOH
ON CUS.CustomerID=SOH.CustomerID
WHERE CUS.CustomerID=@id
RETURN
END

/*Create a view that provides a summary of sales for each product.( p.ProductID, p.Name, SUM(od.OrderQty) , SUM(od.LineTotal) )*/
CREATE VIEW summary
AS
SELECT P.ProductID,P.Name,SUM(SOD.OrderQty) AS ORDER_QTY,SUM(SOD.LineTotal) AS ALL_LineTotal
FROM Production.Product P
JOIN Sales.SalesOrderDetail SOD
ON SOD.ProductID=P.ProductID
GROUP BY P.ProductID,P.Name

/*List Vendors Who Have Never Supplied Any Products*/
SELECT * 
FROM Purchasing.Vendor V
WHERE V.BusinessEntityID NOT IN(
	SELECT V.BusinessEntityID
	FROM Purchasing.Vendor V
	JOIN Purchasing.ProductVendor PV
	ON V.BusinessEntityID=PV.BusinessEntityID
)

/*List Products That Have Been Reviewed
*/
SELECT PR.ProductID,P.Name,PR.ReviewDate
FROM Production.ProductReview PR
JOIN Production.Product P
ON P.ProductID=PR.ProductID

/*List Products Priced Above the Average Price in Their Subcategory*/
SELECT pro.ProductID,pro.ProductSubcategoryID,pro.Name,ListPrice,AVG_SUB.avg_pri
FROM Production.Product pro
JOIN 
	(SELECT PSC.ProductSubcategoryID, AVG(ListPrice) AS avg_pri
	 FROM Production.Product PRO
	 JOIN Production.ProductSubcategory PSC
	 ON PRO.ProductSubcategoryID=PSC.ProductSubcategoryID
	 GROUP BY PSC.ProductSubcategoryID
	)AS AVG_SUB
ON pro.ProductSubcategoryID=AVG_SUB.ProductSubcategoryID
WHERE pro.ListPrice>AVG_SUB.avg_pri

/*List Customers Who Have Placed Orders More Frequently Than the Average Customer*/
SELECT SOH.CustomerID ,COUNT (SOH.SalesOrderID) AS CNT_ORDER 
FROM Sales.SalesOrderHeader SOH
GROUP BY SOH.CustomerID 
HAVING COUNT(SOH.SalesOrderID) >
(
SELECT AVG(CNT_ORDER) AS AVG_PER_CUST 
FROM(
	SELECT SOH.CustomerID , COUNT (SOH.SalesOrderID) AS CNT_ORDER
	FROM Sales.SalesOrderHeader SOH
	GROUP BY SOH.CustomerID 
    ) AS ORDER_CNT_PER_CUST
)

/*Retrieve the products in the top 2 highest-priced categories(average prize for all products).(`ProductID`, `Name`, `CategoryName` , and `ListPrice`)*/
SELECT TOP 2 PRO.ProductID,PRO.Name,PROCAT.Name,PRO.ListPrice
FROM Production.Product AS PRO
JOIN Production.ProductSubcategory AS PROSC
ON PRO.ProductSubcategoryID= PROSC.ProductSubcategoryID
JOIN Production.ProductCategory AS PROCAT
ON PROCAT.ProductCategoryID=PROSC.ProductSubcategoryID
ORDER BY PRO.ListPrice DESC

/*Find the employee with the highest salary.(EmployeeID`, `FullName`, and `Salary`) */
SELECT EMP.BusinessEntityID,PER.FirstName+ ' '+ PER.MiddleName+ ' '+PER.LastName, EMP.Rate
FROM HumanResources.EmployeePayHistory AS EMP
JOIN Person.Person PER
ON EMP.BusinessEntityID=PER.BusinessEntityID
WHERE EMP.Rate=(SELECT MAX(Rate) FROM HumanResources.EmployeePayHistory)


/*Calculate Cumulative Freight Cost by Vendor Over Time
Columns to Select:
vendorid: Identifier for the vendor.
orderdate: Date when the order was placed.
freight: Freight cost for the order.
CumulativeFreight: Running total of freight costs for each vendor over time*/

SELECT POH.VendorID,POH.OrderDate,POH.Freight,SUM(POH.Freight) OVER(PARTITION BY POH.VendorID ORDER BY POH.OrderDate) AS CumulativeFreight
FROM Purchasing.PurchaseOrderHeader POH
ORDER BY POH.VendorID,POH.OrderDate

/*Calculate the Difference Between Each Order's Freight and the Average Freight for the Vendor
Columns to Select:
purchaseorderid: Identifier for the purchase order.
vendorid: Identifier for the vendor.
freight: Freight cost for the order.
AvgFreightPerVendor: Average freight cost for the vendor.
FreightDifference: Difference between the order's freight cost and the vendor's average freight cost*/
SELECT POH.PurchaseOrderID,POH.VendorID,POH.Freight,AVG_FRI.AvgFreightPerVendor,(POH.Freight-AVG_FRI.AvgFreightPerVendor) AS FreightDifference
FROM Purchasing.PurchaseOrderHeader AS POH 
JOIN(
	SELECT POH.VendorID,AVG(Freight) AS AvgFreightPerVendor
	FROM Purchasing.PurchaseOrderHeader POH
	GROUP BY POH.VendorID
)AS AVG_FRI
ON POH.VendorID=AVG_FRI.VendorID


/*Find the BusinessEntityID of those who are both employees and job candidates.*/
SELECT EMP.BusinessEntityID
FROM HumanResources.Employee EMP 
WHERE EMP.BusinessEntityID IN (
	SELECT JC.BusinessEntityID
	FROM HumanResources.JobCandidate AS JC 
)

/*Retrieve employees and their recent department details by applying the EmployeeDepartmentHistory function or use Derived Table*/
SELECT EMP.BusinessEntityID,EDH.DepartmentID,EDH.StartDate,EDH.EndDate 
FROM HumanResources.Employee EMP 
CROSS APPLY 
(SELECT EDH.DepartmentID,EDH.StartDate,EDH.EndDate FROM HumanResources.EmployeeDepartmentHistory EDH WHERE EMP.BusinessEntityID=EDH.BusinessEntityID) EDH





--eate view that contain these columns AS OrderSalesPersonDetails 
--then display all columns in the view  order by product name
CREATE VIEW OrderSalesPersonDetails
AS
	SELECT SOD.SalesOrderID,SOH.SalesPersonID,P.Name ,PSC.Name AS 'Product Subcategory',PC.Name AS 'Product category',P.ListPrice AS 'Selling price per product',SOD.OrderQty AS 'Quantity ordered per product',YEAR(SOH.OrderDate) AS 'Order Year'
	FROM Production.Product P
	JOIN Sales.SalesOrderDetail SOD
	ON P.ProductID=SOD.ProductID
	JOIN Sales.SalesOrderHeader SOH
	ON SOH.SalesOrderID=SOD.SalesOrderID
	JOIN Production.ProductSubcategory PSC
	ON P.ProductSubcategoryID=PSC.ProductSubcategoryID
	JOIN Production.ProductCategory PC
	ON PSC.ProductCategoryID=PC.ProductCategoryID
	
SELECT * FROM OrderSalesPersonDetails
ORDER BY Name

--using OrderSalesPersonDetails   find  average unit price of products ordered by each salesperson for each category  and replace any NULL values in SalesPersonID with 'OTHER
SELECT ISNULL(CAST(SalesPersonID AS VARCHAR),'OTHERS') AS SalesPeronID,[Accessories],[Bikes],[Clothing],[Components]
FROM 
(
SELECT SalesPersonID,[Selling price per product],[Product category]
FROM OrderSalesPersonDetails
) AS F_1
PIVOT(AVG(F_1.[Selling price per product]) FOR F_1.[Product category] IN ([Accessories],[Bikes],[Clothing],[Components])) AS PVT
ORDER BY SalesPersonID

--  For each order, find the product with the highest selling price. The report should list the order ID, the product  name, and the selling price of that product order by product name.  
SELECT SalesOrderID,Name
,MAX([Selling price per product]) over(partition by Name order by Name) AS 'Selling price per product'
FROM OrderSalesPersonDetails
 
 --  Generate a report that ranks products based on their selling price per product for each product. The report should list each product along with its selling price and its rank.  

SELECT [Product category] ,Name, [Selling price per product]
,DENSE_RANK()  OVER(PARTITION BY [Product category] ORDER BY [Selling price per product] DESC)
FROM OrderSalesPersonDetails

--  Identify orders that contain the maximum quantity ordered per product. The report should list the order ID,  product name, and the quantity ordered for these orders.     order by  quantity ordered per product
WITH MaxQuantities AS
(
SELECT 
Name ,MAX([Quantity ordered per product]) AS MaxQuantity
FROM OrderSalesPersonDetails
GROUP BY Name
)
SELECT SalesOrderID,mq.Name,[Quantity ordered per product]
FROM OrderSalesPersonDetails OSPD
JOIN MaxQuantities mq 
ON mq.Name=OSPD.Name AND mq.MaxQuantity=OSPD.[Quantity ordered per product]
ORDER BY [Quantity ordered per product] DESC

--create a paginated TVF that lists orders. Each page should show @no_order orders sorted by order ID. The report should fetch after offset @offset
ALTER FUNCTION GetPaginatedOrders
(
    @no_order INT,  
    @offset INT     
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
	    Name,
        SalesOrderID,
        [Order Year]
    FROM 
        OrderSalesPersonDetails
    ORDER BY 
         SalesOrderID
    OFFSET @offset ROWS
    FETCH NEXT @no_order ROWS ONLY
)

SELECT * FROM GetPaginatedOrders(10,0)




