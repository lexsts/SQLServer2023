
/***********************************************************************************************************************************************/
/***********************************************************************************************************************************************/
--                                                                        CONSULTA PLANO DE EXECUÇÃO

-- Criado por: Marcelo Hideki Kuamoto
-- Data: 02/03/2015
-- Objetivo: Capturar o último plano de execução de uma procedure que esta armazenado no Cache do SQL 
/***********************************************************************************************************************************************/
/***********************************************************************************************************************************************/
 
USE MASTER
GO
--sp_helptext 'SON6_RVDER.SP_ON6_SEL_LANC_LIQU_FINN'
/*Pega os parametros do chache das procedures*/
SELECT top 1 object_name(objectid,dbid)obj, qp.query_plan, cp.plan_handle 
INTO #t
FROM SYS.dm_exec_cached_plans cp
CROSS APPLY SYS.dm_exec_query_plan(plan_handle) qp
WHERE qp.objectid = 1424788929 AND dbid = (select database_id from sys.databases where name = 'DBTC100')
 
SELECT obj, plan_handle, query_plan FROM #t;
WITH XMLNAMESPACES  (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT DISTINCT 
     n2.value('(@Column)[1]','sysname') AS ParameterName 
    ,n2.value('(@ParameterCompiledValue)[1]','varchar(max)') AS ParameterValue 
FROM #t  
    CROSS APPLY query_plan.nodes('//ParameterList') AS q1(n1) 
    CROSS APPLY n1.nodes('ColumnReference') as q2(n2)
DROP TABLE #t
 



select q.last_execution_time,q.execution_count,statement_start_offset, statement_end_offset, command = SUBSTRING (txt.text, q.statement_start_offset/2, 
(CASE WHEN q.statement_end_offset = -1
        THEN LEN(CONVERT(NVARCHAR(MAX), txt.text)) * 2
        ELSE q.statement_end_offset
END - q.statement_start_offset)/2),
  last_worker_time/1000000. last_secs,  
  min_worker_time/1000000. min_secs,
  max_worker_time/1000000. max_secs,
  total_worker_time/1000000. total_secs,  
  last_dop,
  min_dop,
  max_dop,
  last_spills,
  min_spills,
  max_spills,
  cast(p.query_plan as xml) SQLPLAN
from sys.dm_exec_query_stats q
cross apply sys.dm_exec_sql_text (sql_handle)txt
cross apply sys.dm_exec_text_query_plan (plan_handle, statement_start_offset, statement_end_offset) p
where q.plan_handle = 0x05000F003BE5234A507E2E3C2810000001000000000000000000000000000000000000000000000000000000
 