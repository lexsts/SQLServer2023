SELECT  [ProcedureName]          =   OBJECT_NAME([ps].[object_id], [ps].[database_id]) 
       ,[ProcedureExecutes]      =   [ps].[execution_count] 
       ,[VersionOfPlan]          =   [qs].[plan_generation_num]
       ,[ExecutionsOfCurrentPlan]    =   [qs].[execution_count] 
       ,[Query Plan XML]         =   [qp].[query_plan]  

FROM       [sys].[dm_exec_procedure_stats] AS [ps]
       JOIN [sys].[dm_exec_query_stats] AS [qs] ON [ps].[plan_handle] = [qs].[plan_handle]
       CROSS APPLY [sys].[dm_exec_query_plan]([qs].[plan_handle]) AS [qp]
WHERE   [ps].[database_id] = DB_ID() 
       --AND  OBJECT_NAME([ps].[object_id], [ps].[database_id])  = 'TEST'