DECLARE  @rowcnt INT
DECLARE  @iterator INT
DECLARE  @dbname VARCHAR(200)
DECLARE  @exec_sql VARCHAR(500)
SET @rowcnt = 0
SET @iterator = 1
CREATE TABLE #db_file_info (
  [Database_Name]    SYSNAME    NOT NULL,
  [File_ID]          SMALLINT    NOT NULL,
  [File_Type]        VARCHAR(10)    NOT NULL,
  [File_Name]        SYSNAME    NOT NULL,
  [File_Path]        VARCHAR(500)    NOT NULL,
  [File_Size_in_MB]  INT    NOT NULL,
  [Space_Used_in_MB] INT    NOT NULL,
  [Space_Left_in_MB] INT    NOT NULL,
  MAXSIZE INT,
  GROWTH INT)

CREATE TABLE #db (
  dbid INT,
  name VARCHAR(200))
INSERT INTO #db
SELECT dbid,
       name
FROM   MASTER.dbo.sysdatabases
WHERE NAME NOT IN (SELECT NAME FROM SYS.DATABASES A WHERE STATE<>0 OR NAME IN ('CORPORE_RM','RMCORPORE','CORPORATIVO_TB_ContratosNegociadosPregao'))
SELECT @rowcnt=MAX(A.DATABASE_ID)
  FROM SYS.DATABASES A
  WHERE STATE=0
WHILE @iterator <= @rowcnt
  BEGIN
    SELECT @dbname = name
    FROM   #db
    WHERE  dbid = @iterator
    
    SET @exec_sql = ' USE "' + @dbname + '"; Insert into #DB_FILE_INFO
Select db_name(),fileid,case when groupid = 0 then ''log file'' else ''data file'' end,
name,filename, 

[file_size] = 
convert(int,round((sysfiles.size*1.000)/128.000,0)),
[space_used] =
convert(int,round(fileproperty(sysfiles.name,''SpaceUsed'')/128.000,0)),
[space_left] =
convert(int,round((sysfiles.size-fileproperty(sysfiles.name,''SpaceUsed''))/128.000,0)),MAXSIZE,GROWTH
from
dbo.sysfiles;
'

    EXEC( @exec_sql)
    
    SET @iterator = @iterator + 1
  END

SELECT DISTINCT Database_name,File_type,File_name,File_Path,File_Size_in_MB,Space_Used_in_MB,Space_Left_in_MB,MAXSIZE,GROWTH
FROM   #db_file_info A
WHERE FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS07\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados28\%'
or FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS03\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados33\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados10\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados23\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados11\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados20\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados09\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados36\%'
or FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS15\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados29\%'
or FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS02\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados31\%'
or FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS12\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados30\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados40\%'
or FILE_PATH LIKE 'L:\SQLSINFEP_L_DADOS16\%'
or FILE_PATH LIKE 'N:\SQLSINFEP_N_Dados21\%'


DROP TABLE #db
DROP TABLE #db_file_info




SELECT DISTINCT dovs.logical_volume_name AS LogicalName,
dovs.volume_mount_point AS Drive,
CONVERT(INT,dovs.available_bytes/1048576.0) AS FreeSpaceInMB,
CONVERT(INT,dovs.total_bytes/1048576.0) AS TotalSpaceInMB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
WHERE dovs.volume_mount_point LIKE 'L:\SQLSINFEP_L_DADOS07\%'
ORDER BY FreeSpaceInMB ASC
GO



Select db_name(),fileid,case when groupid = 0 then 'log file' else 'data file' end,
name,filename, 
[file_size] = 
convert(int,round((sysfiles.size*1.000)/128.000,0)),
[space_used] =
convert(int,round(fileproperty(sysfiles.name,'SpaceUsed')/128.000,0)),
[space_left] =
convert(int,round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/128.000,0))
from
dbo.sysfiles



--USO DA TEMPDB

SELECT * FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds DESC; --TRANSAÇÕES ANTIGAS

SELECT database_transaction_log_bytes_reserved,session_id 
  FROM sys.dm_tran_database_transactions AS tdt 
  INNER JOIN sys.dm_tran_session_transactions AS tst 
  ON tdt.transaction_id = tst.transaction_id 
  WHERE database_id = 2; --TRANSAÇÕES ANTIGAS 

/*
use tempdb
go
dbcc dropcleanbuffers
go
dbcc freesystemcache('ALL')
go
dbcc freesessioncache
go
dbcc freeproccache
*/
  

select 
   t1.session_id 
   , t1.request_id 
   , task_alloc_GB = cast((t1.task_alloc_pages * 8./1024./1024.) as numeric(10,1)) 
   , task_dealloc_GB = cast((t1.task_dealloc_pages * 8./1024./1024.) as numeric(10,1)) 
   , host= case when t1.session_id <= 50 then 'SYS' else s1.host_name end 
   , s1.login_name 
    , s1.status 
    , s1.last_request_start_time 
    , s1.last_request_end_time 
    , s1.row_count 
    , s1.transaction_isolation_level 
    , query_text= 
        coalesce((SELECT SUBSTRING(text, t2.statement_start_offset/2 + 1, 
          (CASE WHEN statement_end_offset = -1 
              THEN LEN(CONVERT(nvarchar(max),text)) * 2 
                   ELSE statement_end_offset 
              END - t2.statement_start_offset)/2) 
        FROM sys.dm_exec_sql_text(t2.sql_handle)) , 'Not currently executing') 
    , query_plan=(SELECT query_plan from sys.dm_exec_query_plan(t2.plan_handle)) 
from 
    (Select session_id, request_id 
    , task_alloc_pages=sum(internal_objects_alloc_page_count +   user_objects_alloc_page_count) 
    , task_dealloc_pages = sum (internal_objects_dealloc_page_count + user_objects_dealloc_page_count) 
    from sys.dm_db_task_space_usage 
    group by session_id, request_id) as t1 
left join sys.dm_exec_requests as t2 on 
    t1.session_id = t2.session_id 
    and t1.request_id = t2.request_id 
left join sys.dm_exec_sessions as s1 on 
    t1.session_id=s1.session_id 
where 
    t1.session_id > 50 -- ignore system unless you suspect there's a problem there 
    and t1.session_id <> @@SPID -- ignore this request itself 
order by t1.task_alloc_pages DESC; 




SELECT  SS.session_id ,        SS.database_id ,
        CAST(SS.user_objects_alloc_page_count / 128 AS DECIMAL(15, 2)) [Total Allocation User Objects MB] ,
        CAST(( SS.user_objects_alloc_page_count
               - SS.user_objects_dealloc_page_count ) / 128 AS DECIMAL(15, 2)) [Net Allocation User Objects MB] ,
        CAST(SS.internal_objects_alloc_page_count / 128 AS DECIMAL(15, 2)) [Total Allocation Internal Objects MB] ,
        CAST(( SS.internal_objects_alloc_page_count
               - SS.internal_objects_dealloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Net Allocation Internal Objects MB] ,
        CAST(( SS.user_objects_alloc_page_count
               + internal_objects_alloc_page_count ) / 128 AS DECIMAL(15, 2)) [Total Allocation MB] ,
        CAST(( SS.user_objects_alloc_page_count
               + SS.internal_objects_alloc_page_count
               - SS.internal_objects_dealloc_page_count
               - SS.user_objects_dealloc_page_count ) / 128 AS DECIMAL(15, 2)) [Net Allocation MB] ,
        T.text [Query Text]
FROM    sys.dm_db_session_space_usage SS
        LEFT JOIN sys.dm_exec_connections CN ON CN.session_id = SS.session_id
        OUTER APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) T

		
		
	 ;WITH s AS
(
    SELECT 
        s.database_id,db_name(s.database_id) 'DB_NAME',s.session_id,
        [Pages] = (SUM(s.user_objects_alloc_page_count 
          + s.internal_objects_alloc_page_count))*8/1024
    FROM sys.dm_db_session_space_usage AS s
    GROUP BY s.session_id,s.database_id,db_name(s.database_id)
    HAVING SUM(s.user_objects_alloc_page_count 
      + s.internal_objects_alloc_page_count) > 0
)
SELECT s.database_id,db_name(s.database_id) 'DB_NAME',s.session_id, s.[pages]*8/1024 'MB_TRANSACTION'
FROM s
LEFT OUTER JOIN 
sys.dm_exec_requests AS r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
ORDER BY s.[pages] DESC;

*/