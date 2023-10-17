--Page allocation details
SELECT 
	session_id
	,database_id
	,user_objects_alloc_page_count
	,user_objects_dealloc_page_count
	,internal_objects_alloc_page_count
	,internal_objects_dealloc_page_count 
FROM sys.dm_db_session_space_usage 
--WHERE session_id = @@SPID
GO

--Space utilization
SELECT 	
	DB_NAME(FSU.database_id) AS DatabaseName
	,MF.Name As LogicalFileName 
	,MF.physical_name AS PhysicalFilePath
	,SUM(FSU.unallocated_extent_page_count)*8.0/1024 
	AS Free_Space_In_MB,	
	SUM(
			FSU.version_store_reserved_page_count  
			 + FSU.user_object_reserved_page_count  
			 + FSU.internal_object_reserved_page_count  
			 + FSU.mixed_extent_page_count  
		)*8.0/1024 AS Used_Space_In_MB
	
FROM sys.dm_db_file_space_usage AS FSU
INNER JOIN sys.master_files AS MF
ON FSU.database_id = MF.database_id
	AND FSU.file_id = MF.file_id
GROUP BY FSU.database_id,FSU.file_id,MF.Name,MF.physical_name


--Tasks that are using TempDB
SELECT est.text, 
		tsu.session_id,
		tsu.database_id,
		der.start_time,*
FROM sys.dm_db_task_space_usage tsu
JOIN sys.dm_exec_requests der
on tsu.session_id=der.session_id
CROSS APPLY sys.dm_exec_sql_text (der.sql_handle) est

