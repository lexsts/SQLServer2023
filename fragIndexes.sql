 --for gathering information of all indexes on specified table
SELECT
	sysin.name as IndexName
	,sysIn.index_id
   ,func.avg_fragmentation_in_percent
   ,func.index_type_desc as IndexType
   ,func.page_count
FROM
   sys.dm_db_index_physical_stats (DB_ID(),OBJECT_ID(N'ordDemo'),NULL, NULL, NULL) AS func
JOIN
   sys.indexes AS sysIn
ON
   func.object_id = sysIn.object_id AND func.index_id = sysIn.index_id
--Clustered Index's Index_id MUST be 1
--nonclustered Index should have Index_id>1
--with following WHERE clause, we are eliminating HEAP tables
WHERE sysIn.index_id>0;


--for gathering information of all indexes available in 
--database This query may take long time to execute
SELECT
	sysin.name as IndexName
	,sysIn.index_id
   ,func.avg_fragmentation_in_percent
	,func.index_type_desc as IndexType
   ,func.page_count
FROM
   sys.dm_db_index_physical_stats (DB_ID(), NULL,NULL, NULL, NULL) AS func
JOIN
   sys.indexes AS sysIn
ON
   func.object_id = sysIn.object_id AND func.index_id = sysIn.index_id
WHERE sysIn.index_id>0
ORDER BY 3 DESC;

