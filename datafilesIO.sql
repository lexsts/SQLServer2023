--Monitor the database files lor all databases.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,VFS.num_of_reads AS TotalReadOperations
	,VFS.num_of_bytes_read TotalBytesRead
	,VFS.num_of_writes AS TotalWriteOperations
	,VFS.num_of_bytes_written AS TotalBytesWritten
	,VFS.io_stall_read_ms AS TotalWaitTimeForRead
	,VFS.io_stall_write_ms AS TotalWaitTimeForWrite
	,VFS.io_stall AS TotalWaitTimeForIO	
	,VFS.size_on_disk_bytes AS FileSizeInBytes
FROM sys.dm_io_virtual_file_stats(NULL,NULL) AS VFS
INNER JOIN sys.master_files AS MF
	ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
ORDER BY VFS.database_id DESC
GO


--Monitor the actual database files.
--Observe the read operations.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,VFS.num_of_reads AS TotalReadOperations
	,VFS.num_of_bytes_read TotalBytesRead
	,VFS.num_of_writes AS TotalWriteOperations
	,VFS.num_of_bytes_written AS TotalBytesWritten
	,VFS.io_stall_read_ms AS TotalWaitTimeForRead
	,VFS.io_stall_write_ms AS TotalWaitTimeForWrite
	,VFS.io_stall AS TotalWaitTimeForIO	
	,VFS.size_on_disk_bytes AS FileSizeInBytes
FROM sys.dm_io_virtual_file_stats(DB_ID(),NULL) AS VFS
INNER JOIN sys.master_files AS MF
	ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
ORDER BY VFS.database_id DESC
GO



--Monitor database files for any 
--pending I/O requests.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,PIOR.io_type AS InputOutputOperationType
	,PIOR.io_pending AS Is_Request_Pending	
	,PIOR.io_handle
	,PIOR.scheduler_address 
FROM sys.dm_io_pending_io_requests AS PIOR
INNER JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS VFS
ON PIOR.io_handle = VFS.file_handle 
INNER JOIN sys.master_files AS MF
ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
GO

