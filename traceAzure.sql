--Lista de eventos
SELECT classe.package PACKAGE,classe.name CLASSE,evento.name EVENTO
FROM sys.database_event_session_events classe join sys.database_event_session_actions evento 
on classe.event_id=evento.event_id
where classe.name ='sp_statement_completed' order by evento.name

--Cria Extended Event no database
--CREATE EVENT SESSION TRACE ON SERVER --2016 E ANTERIORES
--DROP EVENT SESSION TRACE ON DATABASE
CREATE EVENT SESSION TRACE ON DATABASE --AZURE
ADD EVENT sqlserver.sql_statement_completed (
    ACTION (
        sqlserver.session_id,
        sqlserver.username,        
		sqlserver.database_name,
		sqlserver.client_hostname,
		sqlserver.client_app_name,
		sqlserver.username,
        sqlserver.sql_text
		--WHERE
        --( sqlserver.like_i_sql_unicode_string(sqlserver.sql_text, N'%SELECT%HAVING%')        
)
)
ADD TARGET package0.ring_buffer
	(SET max_events_limit=(100)) --LIMITE DE EVENTOS)
	WITH (MAX_MEMORY=51200 KB) --LIMITE DE MEMORIA 50MB
--WITH (STARTUP_STATE=ON)
--GO

 
-- Ativa o Extended Event
ALTER EVENT SESSION TRACE ON DATABASE STATE = START
GO
 
-- Desativa o Extended Event
ALTER EVENT SESSION TRACE ON DATABASE STATE = STOP
GO


--LISTA AS SESSÕES EM EXECUÇÃO
select * from sys.dm_xe_database_session_event_actions
select * from sys.dm_xe_database_session_events
select * from sys.dm_xe_database_session_object_columns
select * from sys.dm_xe_database_session_targets
select * from sys.dm_xe_database_sessions

--CARREGA OS DADOS COLETADOS EM UMA TABELA TEMPORARIA (XML)
--DROP TABLE #XmlAsTable
SELECT CAST(TRACE.TargetXml AS XML)  AS RBufXml
	INTO #XmlAsTable FROM (
		SELECT	CAST(t.target_data AS XML)  AS TargetXml
			FROM sys.dm_xe_database_session_targets AS t JOIN sys.dm_xe_database_sessions AS s
			ON s.address = t.event_session_address
			WHERE t.target_name = 'ring_buffer'	AND	s.name = 'TRACE') AS TRACE;
SELECT * FROM #XmlAsTable;







-- https://akawn.com/blog/author/kevin/
DECLARE @session_name nvarchar(128);
/*only update this line with the name of the session to view*/
SET @session_name = 'your extended event session name';

/* temporary table variable */
DECLARE @sqlcmd_table TABLE (row_order int IDENTITY(1,1), row_text varchar(MAX));

/* select start */
INSERT INTO @sqlcmd_table (row_text) SELECT 'DECLARE @t1 TABLE (target_data xml);';
INSERT INTO @sqlcmd_table (row_text) SELECT 'INSERT INTO @t1 (target_data)';
INSERT INTO @sqlcmd_table (row_text) SELECT 'SELECT CAST(target_data AS xml) AS target_data';
INSERT INTO @sqlcmd_table (row_text) SELECT 'FROM sys.dm_xe_database_sessions a, sys.dm_xe_database_session_targets b';
INSERT INTO @sqlcmd_table (row_text) SELECT 'WHERE 1=1';
INSERT INTO @sqlcmd_table (row_text) SELECT 'AND a.[address] = b.event_session_address';
INSERT INTO @sqlcmd_table (row_text) SELECT 'AND b.target_name = ''ring_buffer''';
INSERT INTO @sqlcmd_table (row_text) SELECT 'AND a.[name]= '''+@session_name+''';';
INSERT INTO @sqlcmd_table (row_text) SELECT '';
INSERT INTO @sqlcmd_table (row_text) SELECT 'SELECT'
INSERT INTO @sqlcmd_table (row_text) SELECT ' c.value(''(@timestamp)[1]'',''datetime2'') AT TIME ZONE ''UTC'' AT TIME ZONE ''New Zealand Standard Time'' AS timestamp_nz';
INSERT INTO @sqlcmd_table (row_text) SELECT ',c.value(''(@name)[1]'',''nvarchar(128)'') AS event_name';
INSERT INTO @sqlcmd_table (row_text) SELECT ',c.value(''(@package)[1]'',''nvarchar(128)'') AS package_name';

/* action columns */
INSERT INTO @sqlcmd_table (row_text)
SELECT
',c.value(''(action[@name='''''+c.event_name+''''']/value)[1]'','''+ CASE WHEN d.[type_name] = 'duration' THEN ''
WHEN d.[type_name] = 'activity_id_xfer' THEN ''
WHEN d.[type_name] = 'ansi_string' THEN 'varchar(MAX)'
WHEN d.[type_name] = 'ansi_string_ptr' THEN 'varchar(MAX)'
WHEN d.[type_name] = 'binary_data' THEN 'varbinary(MAX)'
WHEN d.[type_name] = 'boolean' THEN 'bit'
WHEN d.[type_name] = 'callstack' THEN 'nvarchar(MAX)'
WHEN d.[type_name] = 'char' THEN 'char(1)'
WHEN d.[type_name] = 'cpu_cycle' THEN 'bigint'
WHEN d.[type_name] = 'filetime' THEN 'datetime'
WHEN d.[type_name] = 'float32' THEN 'float(24)'
WHEN d.[type_name] = 'float64' THEN 'float(53)'
WHEN d.[type_name] = 'guid' THEN 'nvarchar(MAX)'
WHEN d.[type_name] = 'guid_ptr' THEN 'bigint'
WHEN d.[type_name] = 'int16' THEN 'smallint'
WHEN d.[type_name] = 'int32' THEN 'int'
WHEN d.[type_name] = 'int64' THEN 'bigint'
WHEN d.[type_name] = 'int8' THEN 'tinyint'
WHEN d.[type_name] = 'null' THEN 'null'
WHEN d.[type_name] = 'ptr' THEN 'bigint'
WHEN d.[type_name] = 'uint16' THEN 'smallint'
WHEN d.[type_name] = 'uint32' THEN 'int'
WHEN d.[type_name] = 'uint64' THEN 'bigint'
WHEN d.[type_name] = 'uint8' THEN 'tinyint'
WHEN d.[type_name] = 'unicode_string' THEN 'nvarchar(MAX)'
WHEN d.[type_name] = 'unicode_string_ptr' THEN 'nvarchar(MAX)'
WHEN d.[type_name] = 'wchar' THEN 'nchar(2)'
WHEN d.[type_name] = 'xml' THEN 'xml'
ELSE 'nvarchar(MAX)' END + ''') AS ' + c.action_name
FROM
 sys.dm_xe_database_session_events b
,sys.dm_xe_database_session_event_actions c
,sys.dm_xe_objects d
WHERE 1=1
AND b.event_session_address = c.event_session_address
AND b.event_name = c.event_name
AND b.event_package_guid = d.package_guid
AND c.action_name = d.[name]
AND d.object_type = 'action'
ORDER BY b.event_name, c.action_name

/* event columns */
INSERT INTO @sqlcmd_table (row_text)
SELECT
',c.value(''(data[@name='''''+a.[name]+''''']/value)[1]'',''nvarchar(MAX)'') AS '+a.[name]
FROM 
sys.dm_xe_object_columns a JOIN sys.dm_xe_database_session_events b
 ON a.object_package_guid = b.event_package_guid
 AND a.[object_name] = b.[event_name]
LEFT OUTER JOIN sys.dm_xe_database_session_object_columns c
 ON c.object_package_guid = a.object_package_guid
 AND c.event_session_address = b.event_session_address
 AND c.[object_name] = a.[object_name]
  AND c.column_name = a.[name]
WHERE 1=1
AND a.column_type <> 'readonly'
AND (c.column_value IS NULL OR c.column_value = 'true') /* remove not selected */
ORDER BY b.event_name, a.column_id;

/* select end */
INSERT INTO @sqlcmd_table (row_text) SELECT 'FROM @t1 a' + CHAR(13) + CHAR(10) ;
INSERT INTO @sqlcmd_table (row_text) SELECT 'CROSS APPLY target_data.nodes(''RingBufferTarget/event'') AS b(c)'
INSERT INTO @sqlcmd_table (row_text) SELECT 'ORDER BY c.value(''(@timestamp)[1]'',''datetime2'') DESC;';

/* view sql command */
SELECT row_text AS sql_command
FROM @sqlcmd_table
ORDER BY row_order;

/* Make sure the extended event session is running and you run the the generated sql_command in the Azure SQL Database */ 