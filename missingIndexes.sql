--finding missing Index
SELECT
      avg_total_user_cost * avg_user_impact * (user_seeks + user_scans) AS PossibleImprovement
      ,last_user_seek
      ,last_user_scan
      ,statement AS Object
      ,'CREATE INDEX [IDX_' + CONVERT(VARCHAR,GS.Group_Handle) + '_' + CONVERT(VARCHAR,D.Index_Handle) + '_'
      + REPLACE(REPLACE(REPLACE([statement],']',''),'[',''),'.','') + ']'
      +' ON '
      + [statement]
      + ' (' + ISNULL (equality_columns,'')
    + CASE WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (inequality_columns, '')
    + ')'
    + ISNULL (' INCLUDE (' + included_columns + ')', '')
      AS Create_Index_Syntax
FROM
      sys.dm_db_missing_index_groups AS G
INNER JOIN
      sys.dm_db_missing_index_group_stats AS GS
ON
      GS.group_handle = G.index_group_handle
INNER JOIN
      sys.dm_db_missing_index_details AS D
ON
      G.index_handle = D.index_handle
Order By PossibleImprovement DESC


--Retrieving Missing Index Details
SELECT 
	MID.Statement AS ObjectName
	,MID.equality_columns
	,MID.inequality_columns
	,MID.included_columns 
	,MIGS.avg_user_impact As ExpectedPerformanceImprovement
	,(MIGS.user_seeks + MIGS.user_scans) * MIGS.avg_total_user_cost *
		MIGS.avg_user_impact AS PossibleImprovement 
FROM sys.dm_db_missing_index_details AS MID
INNER JOIN sys.dm_db_missing_index_groups AS MIG
ON MID.index_handle = MIG.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS MIGS
ON MIG.index_group_handle = MIGS.group_handle
GO



--Retrieving Index Usage Information 
SELECT 
	O.Name AS ObjectName	 
	,I.Name AS IndexName	
	,IUS.user_seeks
	,IUS.user_scans
	,IUS.last_user_seek
	,IUS.last_user_scan
FROM sys.dm_db_index_usage_stats AS IUS
INNER JOIN sys.indexes AS I
ON IUS.object_id = I.object_id AND IUS.index_id = I.index_id
INNER JOIN sys.objects AS O
ON IUS.object_id = O.object_id
GO



--Retrieving Index Fragmentation Details.
SELECT
	O.name AS ObjectName
	,I.name AS IndexName
	,IPS.avg_page_space_used_in_percent AS AverageSpaceUsedInPages
	,IPS.avg_fragmentation_in_percent AS AverageFragmentation
	,IPS.fragment_count AS FragmentCount
	,suggestedIndexOperation = CASE 
		WHEN IPS.avg_fragmentation_in_percent<=30 THEN 'REORGANIZE Index'
		ELSE 'REBUILD Index' END
	,suggestedIndexCommand = CASE 
		WHEN IPS.avg_fragmentation_in_percent<=30 THEN 'ALTER INDEX ' + I.name + ' ON ' + DB_NAME() + '..' + O.name + ' REORGANIZE;'
		ELSE 'ALTER INDEX ' + I.name + ' ON ' + DB_NAME() + '..' + O.name + ' REBUILD;' END
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'DETAILED') AS IPS
INNER JOIN sys.indexes AS I
ON IPS.object_id = I.object_id AND IPS.index_id = I.index_id
INNER JOIN sys.objects AS O
ON IPS.object_id = O.object_id 
WHERE IPS.avg_fragmentation_in_percent > 5
ORDER BY AverageFragmentation DESC
GO


SELECT 
	 SchemaName = s.name,
     TableName = t.name,
     IndexName = ind.name,
     IndexId = ind.index_id,
     ColumnId = ic.index_column_id,
     ColumnName = col.name,
     ind.*,
     ic.*,
     col.* 
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
INNER JOIN
	sys.schemas s ON t.schema_id=s.schema_id
WHERE 
	 ind.name='PK_Person_BusinessEntityID'
ORDER BY 
     t.name, ind.name, ind.index_id, ic.index_column_id 


ALTER INDEX IX_Person_LastName_FirstName_MiddleName ON AdventureWorks2012..Person REORGANIZE;
ALTER INDEX IX_Person_LastName_FirstName_MiddleName ON AdventureWorks2012.Person.Person REORGANIZE;
ALTER INDEX PK_TransactionHistoryArchive_TransactionID ON AdventureWorks2012.Production.TransactionHistoryArchive REBUILD;
ALTER INDEX PK_TransactionHistoryArchive_TransactionID ON AdventureWorks2012..TransactionHistoryArchive REBUILD;
