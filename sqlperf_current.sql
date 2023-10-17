USE tempdb
GO

--Check if the table exists. If it does,
--dDrop it first.
IF OBJECT_ID('dbo.#tbl_DBLogSpaceUsage') IS NOT  NULL
BEGIN
	DROP TABLE dbo.#tbl_DBLogSpaceUsage
END
go
--Creating table to store the output 
--DBCC SQLPERF command
CREATE TABLE dbo.#tbl_DBLogSpaceUsage
(
	DatabaseName NVARCHAR(128)
	,LogSize NVARCHAR(25)
	,LogSpaceUsed NVARCHAR(25)
	,Status TINYINT
)
go
INSERT INTO dbo.#tbl_DBLogSpaceUsage
EXECUTE ('DBCC SQLPERF(LOGSPACE)')
go
--Retriving log space details for 
-- all databases.
SELECT 
	DatabaseName
	,LogSize
	,LogSpaceUsed
	,Status
FROM dbo.#tbl_DBLogSpaceUsage
GO

--Retriving log space details for 
-- a specific databases.
SELECT 
	DatabaseName
	,LogSize AS LogSizeInMB
	,LogSpaceUsed As LogspaceUsed_In_Percent
	,Status
FROM dbo.#tbl_DBLogSpaceUsage
WHERE DatabaseName = 'AdventureWorks2012'
GO


