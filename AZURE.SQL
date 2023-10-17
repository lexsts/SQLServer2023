select
     r.session_id,
     s.login_name,
     c.client_net_address,
     s.host_name,
     s.program_name,
     st.text, s.status
 from sys.dm_exec_requests r
 inner join sys.dm_exec_sessions s
 on r.session_id = s.session_id
 left join sys.dm_exec_connections c
 on r.session_id = c.session_id
 outer apply sys.dm_exec_sql_text(r.sql_handle) st
 where client_net_address is not null and text is not null and s.status = 'running'

 SELECT actual_state, actual_state_desc, readonly_reason,
    current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;

SELECT * FROM sys.database_query_store_options;


SELECT TOP 10 qt.query_sql_text, q.query_id,
    qt.query_text_id, p.plan_id, rs.last_execution_time
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
ORDER BY rs.last_execution_time DESC;


-- Monitor running queries
SELECT * FROM sys.dm_pdw_exec_requests WHERE status = 'Running';

-- Find 10 queries which ran the longest
SELECT TOP 10 * FROM sys.dm_pdw_exec_requests ORDER BY total_elapsed_time DESC;


SELECT waits.session_id,
      waits.request_id,  
      requests.command,
      requests.status,
      requests.start_time,  
      waits.type,  
      waits.object_type,
      waits.object_name,  
      waits.state  
FROM   sys.dm_pdw_waits waits
   JOIN  sys.dm_pdw_exec_requests requests
   ON waits.request_id=requests.request_id
WHERE waits.request_id = 'QID13355883'
ORDER BY waits.object_name, waits.object_type, waits.state;


SELECT * FROM sys.dm_pdw_request_steps
WHERE request_id = 'QID13356035'
ORDER BY step_index;


SELECT * FROM sys.dm_pdw_sql_requests
WHERE request_id = 'QID13355755' AND step_index = 2;

DBCC PDW_SHOWEXECUTIONPLAN(QID13355900, SID3024897);
