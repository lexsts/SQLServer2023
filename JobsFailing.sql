SELECT  SysJobs.name as 'JOB_NAME' 
		,SysJobs.job_id        
        ,SysJobSteps.step_name as 'STEP_NAME'
        ,Job.run_status
        ,Job.sql_message_id
        ,Job.sql_severity
        ,Job.message
        ,Job.exec_date
        ,Job.run_duration
        ,Job.server
        ,SysJobSteps.output_file_name
    FROM    (SELECT Instance.instance_id
        ,DBSysJobHistory.job_id
        ,DBSysJobHistory.step_id
        ,DBSysJobHistory.sql_message_id
        ,DBSysJobHistory.sql_severity
        ,DBSysJobHistory.message
        ,(CASE DBSysJobHistory.run_status
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Successed'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Canceled'
            WHEN 4 THEN 'In progress'
        END) as run_status
        ,((SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 5, 2) + '/'
        + SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 7, 2) + '/'
        + SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 1, 4) + ' '
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS varchar)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 1, 2) + ':'
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS VARCHAR)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 3, 2) + ':'
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time as varchar)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 5, 2))) AS 'exec_date'
        ,DBSysJobHistory.run_duration
        ,DBSysJobHistory.retries_attempted
        ,DBSysJobHistory.server
        FROM msdb.dbo.sysjobhistory DBSysJobHistory
        JOIN (SELECT DBSysJobHistory.job_id
            ,DBSysJobHistory.step_id
            ,MAX(DBSysJobHistory.instance_id) as instance_id
            FROM msdb.dbo.sysjobhistory DBSysJobHistory
            GROUP BY DBSysJobHistory.job_id
            ,DBSysJobHistory.step_id
            ) AS Instance ON DBSysJobHistory.instance_id = Instance.instance_id
        --WHERE DBSysJobHistory.run_status=0
        ) AS Job
    JOIN msdb.dbo.sysjobs SysJobs
       ON (Job.job_id = SysJobs.job_id)
    JOIN msdb.dbo.sysjobsteps SysJobSteps
       ON (Job.job_id = SysJobSteps.job_id AND Job.step_id = SysJobSteps.step_id)
	ORDER BY JOB_NAME,SysJobs.job_id 
    GO



--JOB_ID
Select CONVERT(binary(16), job_id),* FROM msdb.dbo.sysjobs


--Angela
use MSDB 
GO 
SELECT  A.ORIGINATING_SERVER, 
                A.NAME AS [NOME DO JOB], 
                A.ENABLED, 
                B.COMMAND, 
                B.LAST_RUN_DATE,                
                C.NEXT_RUN_DATE 
FROM MSDB..SYSJOBS_VIEW A 
INNER JOIN MSDB..SYSJOBSTEPS B ON A.JOB_ID= B.JOB_ID 
INNER JOIN MSDB..SYSJOBSCHEDULES C ON A.JOB_ID=C.JOB_ID 
--WHERE A.ENABLED = 1 
ORDER BY A.NAME,C.NEXT_RUN_TIME




--Data creation of job
SELECT 
    [sJOB].[job_id] AS [JobID]
    , [sJOB].[name] AS [JobName]
    , [sDBP].[name] AS [JobOwner]
    , [sCAT].[name] AS [JobCategory]
    , [sJOB].[description] AS [JobDescription]
    , CASE [sJOB].[enabled]
        WHEN 1 THEN 'Yes'
        WHEN 0 THEN 'No'
      END AS [IsEnabled]
    , [sJOB].[date_created] AS [JobCreatedOn]
    , [sJOB].[date_modified] AS [JobLastModifiedOn]
    , [sSVR].[name] AS [OriginatingServerName]
    , [sJSTP].[step_id] AS [JobStartStepNo]
    , [sJSTP].[step_name] AS [JobStartStepName]
    , CASE
        WHEN [sSCH].[schedule_uid] IS NULL THEN 'No'
        ELSE 'Yes'
      END AS [IsScheduled]
    , [sSCH].[schedule_uid] AS [JobScheduleID]
    , [sSCH].[name] AS [JobScheduleName]
    , CASE [sJOB].[delete_level]
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
      END AS [JobDeletionCriterion]
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].[sys].[servers] AS [sSVR]
        ON [sJOB].[originating_server_id] = [sSVR].[server_id]
    LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT]
        ON [sJOB].[category_id] = [sCAT].[category_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
        ON [sJOB].[job_id] = [sJSTP].[job_id]
        AND [sJOB].[start_step_id] = [sJSTP].[step_id]
    LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP]
        ON [sJOB].[owner_sid] = [sDBP].[sid]
    LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH]
        ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH]
        ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
ORDER BY [JobName]