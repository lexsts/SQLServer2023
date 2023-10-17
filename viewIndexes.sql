--creating view
CREATE VIEW POView 
WITH SCHEMABINDING 
AS
SELECT
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name AS VendorName
	,SUM(POD.OrderQty) AS OrderQty
	,SUM(POD.OrderQty*POD.UnitPrice) AS Amount
	,COUNT_BIG(*) AS Count
FROM 
	[Purchasing].[PurchaseOrderHeader] AS POH 
JOIN 
	[Purchasing].[PurchaseOrderDetail] AS POD
ON
	POH.PurchaseOrderID = POD.PurchaseOrderID
JOIN 
	[HumanResources].[Employee] AS EMP
ON
	POH.EmployeeID=EMP.BusinessEntityID
JOIN 
	[Purchasing].[Vendor] AS V
ON
	POH.VendorID=V.BusinessEntityID
GROUP BY
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name 
GO

--creating clustered Index on View to make POView Indexed View
CREATE UNIQUE CLUSTERED INDEX IndexPOView ON POView (PurchaseOrderID)
GO


--The query is using the index from table (wrong)
SELECT POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name AS VendorName
	,SUM(POD.OrderQty) AS OrderQty
	,SUM(POD.OrderQty*POD.UnitPrice) AS Amount
FROM 
	[Purchasing].[PurchaseOrderHeader] AS POH 
JOIN 
	[Purchasing].[PurchaseOrderDetail] AS POD
ON
	POH.PurchaseOrderID = POD.PurchaseOrderID
JOIN 
	[HumanResources].[Employee] AS EMP
ON
	POH.EmployeeID=EMP.BusinessEntityID
JOIN 
	[Purchasing].[Vendor] AS V
ON
	POH.VendorID=V.BusinessEntityID
GROUP BY
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name 
GO



--Forcing to use index from view (NOEXPAND)
SELECT * FROM POView WITH (NOEXPAND)
GO




