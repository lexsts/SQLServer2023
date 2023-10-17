/*
Eduardo de Oliveira Gomes
12/11/2015
Retorna Ultima Execução de uma PROCEDURE
*/
use master

select 
  qs.last_execution_time AS Ultima_Execucao,
  st.text,
  OBJECT_NAME(objectid, st.dbid) Objeto,
  db_name(st.dbid) Banco,
  last_elapsed_time/1000 as 'Tempo ultima Execucao MS',
  (total_elapsed_time/execution_count)/1000 as 'Tempo Medio Execucao MS',
  max_elapsed_time/1000 AS 'Max tempo gasto MS',
  min_elapsed_time/1000 AS 'Min tempo gasto MS',
 (total_worker_time/execution_count)/1000 AS [Avg CPU Time in ms],execution_count,
 *
from 
sys.dm_exec_query_stats qs
             cross apply sys.dm_exec_sql_text (qs.sql_handle) st
where
  st.objectid in (441820686,195531780)
  --qs.plan_handle = 
  --qs.sql_handle
  --st.text like '%SPOP_CO_POSICAO_REGISTRADA%'
--select object_id('SPIG_SMPISO_RECUPERA_MSG_LOTE')
  
SELECT TOP 100
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS average_seconds,
    qs.total_elapsed_time / 1000000.0 AS total_seconds,
    qs.execution_count,
    SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS individual_query,
    o.name AS object_name,
    DB_NAME(qt.dbid) AS database_name
FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
WHERE qt.objectid = 409104548
ORDER BY average_seconds DESC;  

--2008

SELECT --TOP 10 
  
  D.OBJECT_ID, 
  DB_NAME(DATABASE_ID) DBNAME, 
  OBJECT_NAME(OBJECT_ID, DATABASE_ID) 'PROC NAME', 
  D.CACHED_TIME, 
  D.LAST_EXECUTION_TIME, 
  D.TOTAL_ELAPSED_TIME,
  D.TOTAL_ELAPSED_TIME/D.EXECUTION_COUNT AS [AVG_ELAPSED_TIME],
  D.LAST_ELAPSED_TIME, 
  D.EXECUTION_COUNT
  ,*
FROM 
  SYS.DM_EXEC_PROCEDURE_STATS AS D
WHERE
--  DB_NAME(DATABASE_ID) = 'IG'/*

 OBJECT_NAME(OBJECT_ID, DATABASE_ID) IN ('SPIG_SMPISO_RECUPERA_MSG_LOTE','SPIG_SMPISO_CONFIRMA_ENVIO')
		
--*/  
ORDER BY 
   D.TOTAL_ELAPSED_TIME/D.EXECUTION_COUNT  DESC;


