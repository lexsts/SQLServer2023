SELECT	er.session_id,
		er.status, -- Background, Running, Runnable, Sleeping, Pending and Suspended.
		er.start_time,
		er.total_elapsed_time, -- Total time elapsed in milliseconds since the request arrived. (tempo decorrido)
		er.cpu_time, -- CPU time in milliseconds that is used by the request.
		er.estimated_completion_time, -- Internal only.
		er.percent_complete, -- Percent of work completed for certain operations, rollbacks included (This does not provide progress data for queries)
		er.command, 
		DB_NAME(database_id) AS 'DatabaseName', 
		user_id,
		er.wait_resource, -- If the request is blocked, this column returns the resource for which the request is waiting.
		er.wait_time, -- If the request is blocked, this column returns the duration in milliseconds, of the current wait.
		er.blocking_session_id, -- ID of the session that is blocking the request. 0 = is not blocked, or information for blocking session is not available or cannot be identified.   
		er.lock_timeout, -- Lock time-out period in milliseconds for this request.
		er.open_resultset_count,
		er.row_count,
		er.reads,
		er.writes,
		er.logical_reads,
		st.text
  FROM sys.dm_exec_requests AS er
       CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
 -- WHERE er.session_id = 140;