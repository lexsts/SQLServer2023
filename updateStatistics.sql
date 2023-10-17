SELECT DISTINCT
	OBJECT_NAME(SI.object_id) as Table_Name
	,SI.[name] AS Statistics_Name
	,STATS_DATE(SI.object_id, SI.index_id) AS Last_Stat_Update_Date
	,SSI.rowmodctr AS RowModCTR
	,(SSI.rowmodctr*100)/SP.rows AS RowModPCT
	,SP.rows AS Total_Rows_In_Table	
	,'UPDATE STATISTICS ['+SCHEMA_NAME(SO.schema_id)+'].[' 
		+ object_name(SI.object_id) + ']' 
			+ SPACE(2) + SI.[name] AS Update_Stats_Script
FROM sys.indexes AS SI (nolock) JOIN sys.objects AS SO (nolock) 
ON SI.object_id=SO.object_id
JOIN sys.sysindexes SSI (nolock)
ON SI.object_id=SSI.id
AND SI.index_id=SSI.indid 
JOIN sys.partitions AS SP
ON SI.object_id=SP.object_id	
WHERE STATS_DATE(SI.object_id, SI.index_id) IS NOT NULL
AND SSI.rowmodctr>0
AND (SSI.rowmodctr*100)/SP.rows > 10
--AND SO.type='U' --Tabela de usuario
--AND SO.NAME='IVAPONTREGIST'
AND SCHEMA_NAME(SO.schema_id) <> 'SYS'
ORDER BY RowModPCT  DESC


--REORGANIZE ALL TABLES
SELECT 'ALTER INDEX ' + I.NAME + ' ON DBO.' + O.NAME + ' REORGANIZE;' 
FROM sys.indexes I JOIN sys.objects O on I.object_id=O.object_id where O.TYPE='U'

--UPDATE STATISTICS ALL TABLES
SELECT 'UPDATE STATISTICS DBO.' + O.NAME + ';' 
FROM sys.objects O where O.TYPE='U'


	--UPDATE STATISTICS [dbo].[ordDemo]  idx_orderdate_Included
	--UPDATE STATISTICS [dbo].[DatabaseLog]  PK_DatabaseLog_DatabaseLogID
	--EXEC sp_recompile N'HumanResources.uspGetAllEmployees';


	--sp_helpstats 'StatsTable', 'ALL' 
