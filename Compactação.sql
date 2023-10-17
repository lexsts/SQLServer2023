/*
Verifica tamanho dos Datafiles
*/
SELECT '### INFORMAÇÕES DO TAMANHO E TAXA DE CONSUMO DO DATAFILE ###'

SELECT	Name, Physical_name,
CONVERT(Decimal(15,2),ROUND(a.Size/128.000,2)) [Currently Allocated Space (MB)],
CONVERT(Decimal(15,2),ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2)) AS [Space Used (MB)],
CONVERT(Decimal(15,2),ROUND((a.Size-FILEPROPERTY(a.Name,'SpaceUsed'))/128.000,2)) AS [Available Space (MB)],
CONVERT(Decimal(15,2),ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2))/CONVERT(Decimal(15,2),ROUND(a.Size/128.000,2))*100 AS [Percentual Used],
CASE
WHEN CONVERT(Decimal(15,2),ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2))/CONVERT(Decimal(15,2),ROUND(a.Size/128.000,2))*100 <50
THEN 'Possible Assessment' ELSE 'No Action' END [Recommendations]
FROM sys.database_files a (NOLOCK)
WHERE Physical_name NOT LIKE '%ldf%'
GO

SELECT (SUM(CONVERT(Decimal(15,2),ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2)))) AS [Space Used Total (MB)]
FROM sys.database_files a (NOLOCK)
WHERE Physical_name NOT LIKE '%ldf%'
GO

/*
Verificar se existem Tabelas/Partições com compressão
*/

/*
Verificar quantidade de Tabelas | Tabelas Heaps | Indices | Clustered | Nonclustered | Columnstore
*/

SELECT '### QUANTIDADE DE TABELAS E TIPOS DE INDICES ###'

IF(OBJECT_ID('tempdb..#COUNT_TABLES_INDEX') IS NOT NULL) 
DROP TABLE #COUNT_TABLES_INDEX
GO
CREATE TABLE #COUNT_TABLES_INDEX
(
Qtd_Tables INT
,QTd_index INT
,Qtd_Table_Heap INT
,Qtd_Clustered INT
,Qtd_Nonclustered INT
,Qtd_Columnstore INT
)
GO

INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Tables)
SELECT COUNT(NAME) as Qtd_tables 
FROM  sys.tables
GO
INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Index)
select count(i.type_desc) QTd_Index
FROM  sys.tables t,sys.indexes i
WHERE t.object_id=i.object_id
GO
INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Table_Heap)
select count(i.type_desc) Qtd_Heap
FROM  sys.tables t,sys.indexes i
WHERE t.object_id=i.object_id
AND i.type_desc='Heap'
GO

INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Clustered)
select count(i.type_desc) Qtd_Clustered
FROM  sys.tables t,sys.indexes i
WHERE t.object_id=i.object_id
AND i.type_desc='Clustered'
GO
INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Nonclustered)
select count(i.type_desc) Qtd_Nonclustered
FROM  sys.tables t,sys.indexes i
WHERE t.object_id=i.object_id
AND i.type_desc='Nonclustered'
GO
INSERT INTO #COUNT_TABLES_INDEX
(Qtd_Columnstore)
select count(i.type_desc) Qtd_Columnstore
FROM  sys.tables t,sys.indexes i
WHERE t.object_id=i.object_id
AND i.type_desc='Clustered Columnstore'
GO
SELECT  
 MAX(Qtd_Tables) AS Qtd_Tables
 ,MAX(Qtd_Table_Heap) AS Qtd_Table_Heap
,MAX(Qtd_Index) AS Qtd_Index
,MAX(Qtd_Clustered) AS Qtd_Clustered
,MAX(Qtd_Nonclustered) AS Qtd_Nonclustered
,MAX(Qtd_Columnstore) AS Qtd_Columnstore
,ROUND (MAX(Qtd_Table_Heap)*100,1)/MAX(Qtd_Index) AS 'Table Heap %'
,ROUND (MAX(Qtd_Clustered)*100,1)/MAX(Qtd_Index) AS 'Clustered %'
,ROUND (MAX(Qtd_Nonclustered)*100,1)/MAX(Qtd_Index) AS 'Nonclustered %'
,ROUND (MAX(Qtd_Columnstore)*100,1)/MAX(Qtd_Index) AS 'Columnstore %'
FROM #COUNT_TABLES_INDEX
GO

SELECT '### STATUS DE COMPRESSAO DAS TABELAS ###'
GO

IF(OBJECT_ID('tempdb..#COUNT_COMPRESS') IS NOT NULL) 
DROP TABLE #COUNT_COMPRESS
GO
CREATE TABLE #COUNT_COMPRESS
(
[Row_Compress] INT  
,[Page_Compress] INT 
,[None_Compress] INT
,[Columstore] INT
)
GO
INSERT INTO #COUNT_COMPRESS
([None_Compress])
SELECT COUNT (P.DATA_COMPRESSION_DESC) AS 'None compress'
 FROM SYS.PARTITIONS P, SYS.TABLES T 
WHERE T.TYPE = 'U' 
AND P.DATA_COMPRESSION_DESC = 'NONE'
AND T.OBJECT_ID = P.OBJECT_ID
GO
INSERT INTO #COUNT_COMPRESS
([Row_Compress])
SELECT COUNT (P.DATA_COMPRESSION_DESC) AS 'Row compress'
 FROM SYS.PARTITIONS P, SYS.TABLES T 
WHERE T.TYPE = 'U' 
AND P.DATA_COMPRESSION_DESC = 'ROW'
AND T.OBJECT_ID = P.OBJECT_ID
GO
INSERT INTO #COUNT_COMPRESS
([Page_Compress])
SELECT COUNT (P.DATA_COMPRESSION_DESC) AS 'Page compress'
 FROM SYS.PARTITIONS P, SYS.TABLES T 
WHERE T.TYPE = 'U' 
AND P.DATA_COMPRESSION_DESC = 'PAGE'
AND T.OBJECT_ID = P.OBJECT_ID
GO
INSERT INTO #COUNT_COMPRESS
([Columstore])
SELECT COUNT (P.DATA_COMPRESSION_DESC) AS 'Columstore'
 FROM SYS.PARTITIONS P, SYS.TABLES T 
WHERE T.TYPE = 'U' 
AND P.DATA_COMPRESSION_DESC = 'COLUMNSTORE'
AND T.OBJECT_ID = P.OBJECT_ID
GO
SELECT 
 MAX(None_Compress)+MAX(Row_Compress)+MAX(Page_Compress)+MAX(Columstore) as Total_Index
,MAX(None_Compress) AS None_Compress
,MAX(Row_Compress) AS Row_Compress 
,MAX(Page_Compress) AS Page_Compress 
,MAX(Columstore) AS Columstore
,ROUND(MAX(None_Compress)*100,1)/NULLIF(MAX(None_Compress)+(MAX(Row_Compress)+MAX(Page_Compress)+MAX(Columstore)),0) AS 'None_Compress %'
,ROUND(MAX(Row_Compress)*100,1)/NULLIF(MAX(None_Compress)+(MAX(Row_Compress)+MAX(Page_Compress)+MAX(Columstore)),0) AS 'Row_Compress %'
,ROUND(MAX(Page_Compress)*100,1)/NULLIF(MAX(None_Compress)+(MAX(Row_Compress)+MAX(Page_Compress)+MAX(Columstore)),0) AS 'Page_Compress %'
,ROUND(MAX(Columstore)*100,1)/NULLIF(MAX(None_Compress)+(MAX(Row_Compress)+MAX(Page_Compress)+MAX(Columstore)),0) AS 'Columstore %'
FROM #COUNT_COMPRESS
GO

/*

*/

SELECT
     D.[name] AS SchemaName
	,C.[name] AS ObjectName
	,A.[index_id] AS Index_id
    ,A.[name] AS IndexName
	,E.[partition_number] AS PartitionNumber
	,E.[data_compression_desc] AS Data_Compression_Desc
    ,A.[type_desc] AS IndexType
    ,A.[fill_factor] AS [Fill_Factor]
	,SUM(E.[rows]) AS [row_count]
    ,CAST(ROUND(((SUM(F.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [size_mb]
    ,CAST(ROUND(((SUM(F.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [used_mb] 
    ,CAST(ROUND(((SUM(F.total_pages) - SUM(F.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [unused_mb]
	,(SUM(B.user_seeks) + SUM(B.user_scans))*100/(NULLIF(SUM(B.user_seeks) + SUM(B.user_scans)+SUM(B.user_lookups)+ SUM(B.user_updates),0)) AS 'Reads %'
	,SUM(B.user_updates)*100/(NULLIF(SUM(B.user_seeks) + SUM(B.user_scans)+SUM(B.user_lookups)+SUM(B.user_updates),0)) AS 'Updates %'
  into #Usage
  FROM	
    sys.indexes A
    LEFT JOIN sys.dm_db_index_usage_stats B ON A.[object_id] = B.[object_id] 
	AND A.index_id = B.index_id AND B.database_id = DB_ID()
    JOIN sys.objects C ON A.[object_id] = C.[object_id]
    JOIN sys.schemas D ON C.[schema_id] = D.[schema_id]
    JOIN sys.partitions E ON A.[object_id] = E.[object_id] 
	AND A.index_id = E.index_id
    JOIN sys.allocation_units F ON E.[partition_id] = F.container_id
WHERE
    C.is_ms_shipped = 0
	
GROUP BY
     D.[name]
	,C.[name]
    ,A.[name]
	,E.[partition_number]
	,E.[data_compression_desc]
	,A.[index_id]
	,A.[fill_factor]
	,B.[user_seeks]
	,B.[user_scans]
	,B.[user_updates]
	,A.[type_desc]
    ORDER BY
    7 desc
	
/*

*/

IF OBJECT_ID('tempdb.dbo.#RowSavings','U') IS NOT NULL
DROP TABLE #RowSavings;
GO

CREATE TABLE #RowSavings(
[object_name] sysname, 
[schema_name] sysname,
[index_id] int, 
[partition_number] int,
[current_size(KB)] bigint,
[Row_Compression_Size(KB)] bigint,
[sample_size_with_current_compression_setting(KB)] bigint,
[sample_size_with_requested_compression_setting(KB)] bigint
);

GO
IF OBJECT_ID('tempdb.dbo.#PageSavings','U') IS NOT NULL
DROP TABLE #PageSavings;
GO

CREATE TABLE #PageSavings(
[object_name] sysname, 
[schema_name] sysname,
[index_id] int, 
[partition_number] int,
[current_size(KB)] bigint,
[Page_Compression_Size(KB)] bigint,
[sample_size_with_current_compression_setting(KB)] bigint,
[sample_size_with_requested_compression_setting(KB)] bigint
);

DECLARE @SchemaName SYSNAME
DECLARE @TableName SYSNAME
DECLARE Tablelist CURSOR FAST_FORWARD FOR 
SELECT DISTINCT SchemaName, ObjectName
FROM #Usage;
OPEN TableList 
FETCH NEXT FROM TableList INTO @SchemaName, @TableName;
WHILE @@FETCH_STATUS = 0 
BEGIN 
 INSERT INTO #RowSavings
 EXEC sp_estimate_data_compression_savings @SchemaName, @TableName, NULL, NULL, 'ROW';
 INSERT INTO #PageSavings
 EXEC sp_estimate_data_compression_savings @SchemaName, @TableName, NULL, NULL, 'PAGE';
FETCH NEXT FROM TableList INTO @SchemaName, @TableName;
END;
CLOSE TableList;
DEALLOCATE TableList;

SELECT 
 #Usage.[SchemaName] AS [SchemaName]
,#Usage.[ObjectName] AS [TableName]
,#Usage.[IndexName] AS [IndexName]
,#Usage.[IndexType]  AS [TypeIndex]
,#Usage.[Partitionnumber] AS PartitionNumber
,#Usage.[Data_Compression_Desc] AS Data_Compression_Desc
,#RowSavings.[current_size(KB)] AS [SizeKB]
,#RowSavings.[Row_Compression_Size(KB)] AS [Row_Compression_Size_Estimation_KB]
,#PageSavings.[Page_Compression_Size(KB)] AS [Page_Compression_Size_Estimation_KB]
,#Usage.[Reads %] AS [% Percent Reads]
,#Usage.[Updates %] AS [% Percent Updates]
,CASE WHEN #Usage.[Reads %] > 75
THEN 
'Page Compression' 
WHEN #Usage.[Updates %] < 20
THEN
'Page Compression'
ELSE 
'Row Compression'
END AS'Compression Recomendation',
CASE WHEN #Usage.[Reads %] > 75
THEN 
'ALTER INDEX ['+#Usage.[IndexName]+']ON['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' 
WHEN #Usage.[Updates %] < 20
THEN
'ALTER INDEX ['+#Usage.[IndexName]+']ON['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)'
ELSE 
'ALTER INDEX ['+#Usage.[IndexName]+']ON['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW)'
END AS'Compression Comand for Index'

,CASE WHEN #Usage.[IndexType]='HEAP'
AND #Usage.[Reads %] > 75
THEN
'ALTER TABLE ['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)'
WHEN #Usage.[IndexType]='HEAP'
AND #Usage.[Updates %] < 20
THEN 'ALTER TABLE ['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)'
WHEN #Usage.[IndexType]='HEAP'
THEN 'ALTER TABLE ['+#Usage.[SchemaName]+'].['+#Usage.[ObjectName]+'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW)'
END AS'Compression Comand for Tables'

FROM #Usage 
JOIN #RowSavings 
ON #Usage.[SchemaName] = #RowSavings.[schema_name]
AND #Usage.[ObjectName] = #RowSavings.[object_name] 
AND #Usage.[Index_ID] = #RowSavings.[index_id]
AND #Usage.[Partitionnumber] = #RowSavings.[partition_number]
JOIN #PageSavings 
ON #Usage.[SchemaName] = #PageSavings.[schema_name]
AND #Usage.[ObjectName] = #PageSavings.[object_name] 
AND #Usage.[Index_ID] = #PageSavings.[index_id]
AND #Usage.[Partitionnumber]= #PageSavings.[partition_number]
ORDER BY #RowSavings.[current_size(KB)] DESC
GO


/*
*/
SELECT '### ESTIMATIVA GERAL DE POSSIVEIS GANHO DE ESPAÇO ###'
GO
SELECT 
SUM(#RowSavings.[current_size(KB)])/1024 AS [SizeMB]
,SUM(#RowSavings.[Row_Compression_Size(KB)])/1024 AS [Row_Compression_Size_Estimation_MB]
,SUM(#RowSavings.[current_size(KB)])/1024 -SUM(#RowSavings.[Row_Compression_Size(KB)])/1024 AS [Row_Gain_Space_MB]
,(SUM(#RowSavings.[current_size(KB)])/1024 -SUM(#RowSavings.[Row_Compression_Size(KB)])/1024) *100/(SUM(#RowSavings.[current_size(KB)])/1024)  AS [Row_Gain_%]
,SUM(#PageSavings.[Page_Compression_Size(KB)])/1024 AS [Page_Compression_Size_Estimation_MB]
,SUM(#RowSavings.[current_size(KB)])/1024 -SUM(#PageSavings.[Page_Compression_Size(KB)])/1024 AS [Page_Gain_Space_MB]
,(SUM(#RowSavings.[current_size(KB)])/1024 -SUM(#PageSavings.[Page_Compression_Size(KB)])/1024 ) *100/(SUM(#RowSavings.[current_size(KB)])/1024)  AS [Page_Gain_%]
FROM #Usage 
JOIN #RowSavings 
ON #Usage.[SchemaName] = #RowSavings.[schema_name]
AND #Usage.[ObjectName] = #RowSavings.[object_name] 
AND #Usage.[Index_ID] = #RowSavings.[index_id]
AND #Usage.[Partitionnumber] = #RowSavings.[partition_number]
JOIN #PageSavings 
ON #Usage.[SchemaName] = #PageSavings.[schema_name]
AND #Usage.[ObjectName] = #PageSavings.[object_name] 
AND #Usage.[Index_ID] = #PageSavings.[index_id]
AND #Usage.[Partitionnumber] = #PageSavings.[partition_number]
GO










