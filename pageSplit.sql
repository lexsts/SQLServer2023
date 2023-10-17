--select * from ADM_BDADOS.DBO.PAGES_SPLIT WITH(NOLOCK) where data>'2022-04-19 02:08:59.940'
--select * from adm_bdados.dbo.os_waiting_tasks WITH(NOLOCK) where data>'2022-04-18 22:08:59.940'
--select * from ADM_BDADOS.DBO.dm_exec_requests WITH(NOLOCK) where data>'2022-04-19 02:08:59.960' and session_id=392 and object_name='SPU_INS_TDWCONTA' ORDER BY DATA

--WAIT RESOURCE

--WAIT RESOURCE
WHILE (1=1)
BEGIN
INSERT INTO ADM_BDADOS.DBO.dm_exec_requests
SELECT GETDATE() DATA,es.session_id, DB_NAME(er.database_id) AS [database_name],
OBJECT_NAME(qp.objectid, qp.dbid) AS [object_name], -- NULL if Ad-Hoc or Prepared statements
er.wait_type,
er.wait_resource,
er.status,
(SELECT CASE
WHEN pageid = 1 OR pageid % 8088 = 0 THEN 'Is_PFS_Page'
WHEN pageid = 2 OR pageid % 511232 = 0 THEN 'Is_GAM_Page'
WHEN pageid = 3 OR (pageid - 1) % 511232 = 0 THEN 'Is_SGAM_Page'
WHEN pageid IS NULL THEN NULL
ELSE 'Is Not PFS, GAM or SGAM page' END
FROM (SELECT CASE WHEN er.[wait_type] LIKE 'PAGE%LATCH%' AND er.[wait_resource] LIKE '%:%'
THEN CAST(RIGHT(er.[wait_resource], LEN(er.[wait_resource]) - CHARINDEX(':', er.[wait_resource], LEN(er.[wait_resource])-CHARINDEX(':', REVERSE(er.[wait_resource])))) AS INT)
ELSE NULL END AS pageid) AS latch_pageid
) AS wait_resource_type,er.last_wait_type,
er.wait_time AS wait_time_ms,
(SELECT qt.TEXT AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt
FOR XML PATH(''), TYPE) AS [running_batch],
(SELECT SUBSTRING(qt2.TEXT,
(CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END),
(CASE WHEN er.statement_end_offset = -1 THEN DATALENGTH(qt2.TEXT) ELSE er.statement_end_offset/2 END - (CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END))) AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt2
FOR XML PATH(''), TYPE) AS [running_statement],
qp.query_plan
--into ADM_BDADOS.DBO.dm_exec_requests
FROM sys.dm_exec_requests er
LEFT OUTER JOIN sys.dm_exec_sessions es ON er.session_id = es.session_id
CROSS APPLY sys.dm_exec_query_plan (er.plan_handle) qp
WHERE er.session_id <> @@SPID AND es.is_user_process = 1
ORDER BY er.total_elapsed_time DESC, er.logical_reads DESC, [database_name], session_id
WAITFOR DELAY '00:01:00';
END

--OS_WAITING_TASKS
WHILE (1=1)
BEGIN
insert into adm_bdados.dbo.os_waiting_tasks
select getdate() data,* from sys.dm_os_waiting_tasks
where resource_description like '2:%'
or resource_description like '0:%'
WAITFOR DELAY '00:00:30';
END

--SPLIT PAGES
WHILE (1=1)
BEGIN
INSERT INTO ADM_BDADOS.DBO.PAGES_SPLIT
SELECT
GETDATE() DATA,
IOS.INDEX_ID,
O.NAME AS OBJECT_NAME,
I.NAME AS INDEX_NAME,
IOS.LEAF_ALLOCATION_COUNT AS PAGE_SPLIT_FOR_INDEX,
IOS.NONLEAF_ALLOCATION_COUNT PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS(DB_ID(N'TEMPDB'),NULL,NULL,NULL) IOS
JOIN
SYS.INDEXES I
ON
IOS.INDEX_ID=I.INDEX_ID
AND IOS.OBJECT_ID = I.OBJECT_ID
JOIN
SYS.OBJECTS O
ON
IOS.OBJECT_ID=O.OBJECT_ID
WHERE O.TYPE_DESC='USER_TABLE'
AND O.NAME LIKE 'dw.#ADWCONTA%'
WAITFOR DELAY '00:00:03';
END
