use [master]
go

/*
/****************************************************/         
 Objetivo: Coleta do Profiler
 Data de Criação: 11/05/2018
/****************************************************/


--Stop
exec sp_trace_setstatus @traceid = 2 , @status = 0

--Close 
exec sp_trace_setstatus @traceid = 2 , @status = 2
*/

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 10240

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'c:\temp\TESTE_TRACE_VIEW2', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted
-------------------------------------------
-- Set the events
declare @on bit
set @on = 1
-------------------------------------------
--RPC:Starting
-------------------------------------------
exec sp_trace_setevent @TraceID, 11, 1, @on
exec sp_trace_setevent @TraceID, 11, 3, @on
exec sp_trace_setevent @TraceID, 11, 4, @on
exec sp_trace_setevent @TraceID, 11, 6, @on
exec sp_trace_setevent @TraceID, 11, 8, @on
exec sp_trace_setevent @TraceID, 11, 10, @on
exec sp_trace_setevent @TraceID, 11, 11, @on
exec sp_trace_setevent @TraceID, 11, 12, @on
exec sp_trace_setevent @TraceID, 11, 14, @on
exec sp_trace_setevent @TraceID, 11, 26, @on
exec sp_trace_setevent @TraceID, 11, 35, @on
exec sp_trace_setevent @TraceID, 11, 49, @on
exec sp_trace_setevent @TraceID, 11, 50, @on
exec sp_trace_setevent @TraceID, 11, 64, @on
-------------------------------------------
--SQL:Batchstarting
-------------------------------------------
exec sp_trace_setevent @TraceID, 13, 1, @on
exec sp_trace_setevent @TraceID, 13, 3, @on
exec sp_trace_setevent @TraceID, 13, 4, @on
exec sp_trace_setevent @TraceID, 13, 6, @on
exec sp_trace_setevent @TraceID, 13, 8, @on
exec sp_trace_setevent @TraceID, 13, 10, @on
exec sp_trace_setevent @TraceID, 13, 11, @on
exec sp_trace_setevent @TraceID, 13, 12, @on
exec sp_trace_setevent @TraceID, 13, 14, @on
exec sp_trace_setevent @TraceID, 13, 26, @on
exec sp_trace_setevent @TraceID, 13, 35, @on
exec sp_trace_setevent @TraceID, 13, 49, @on
exec sp_trace_setevent @TraceID, 13, 50, @on
exec sp_trace_setevent @TraceID, 13, 64, @on
-------------------------------------------
--SP:Cachemiss
-------------------------------------------
exec sp_trace_setevent @TraceID, 34, 1, @on
exec sp_trace_setevent @TraceID, 34, 3, @on
exec sp_trace_setevent @TraceID, 34, 4, @on
exec sp_trace_setevent @TraceID, 34, 6, @on
exec sp_trace_setevent @TraceID, 34, 8, @on
exec sp_trace_setevent @TraceID, 34, 10, @on
exec sp_trace_setevent @TraceID, 34, 11, @on
exec sp_trace_setevent @TraceID, 34, 12, @on
exec sp_trace_setevent @TraceID, 34, 14, @on
exec sp_trace_setevent @TraceID, 34, 26, @on
exec sp_trace_setevent @TraceID, 34, 35, @on
exec sp_trace_setevent @TraceID, 34, 49, @on
exec sp_trace_setevent @TraceID, 34, 50, @on
exec sp_trace_setevent @TraceID, 34, 64, @on
-------------------------------------------
--SP:Starting
-------------------------------------------
exec sp_trace_setevent @TraceID, 42, 1, @on
exec sp_trace_setevent @TraceID, 42, 3, @on
exec sp_trace_setevent @TraceID, 42, 4, @on
exec sp_trace_setevent @TraceID, 42, 6, @on
exec sp_trace_setevent @TraceID, 42, 8, @on
exec sp_trace_setevent @TraceID, 42, 10, @on
exec sp_trace_setevent @TraceID, 42, 11, @on
exec sp_trace_setevent @TraceID, 42, 12, @on
exec sp_trace_setevent @TraceID, 42, 14, @on
exec sp_trace_setevent @TraceID, 42, 26, @on
exec sp_trace_setevent @TraceID, 42, 35, @on
exec sp_trace_setevent @TraceID, 42, 49, @on
exec sp_trace_setevent @TraceID, 42, 50, @on
exec sp_trace_setevent @TraceID, 42, 64, @on
-------------------------------------------
--Audit Schema Object Access Event
-------------------------------------------
exec sp_trace_setevent @TraceID, 114, 1, @on
exec sp_trace_setevent @TraceID, 114, 3, @on
exec sp_trace_setevent @TraceID, 114, 4, @on
exec sp_trace_setevent @TraceID, 114, 6, @on
exec sp_trace_setevent @TraceID, 114, 8, @on
exec sp_trace_setevent @TraceID, 114, 10, @on
exec sp_trace_setevent @TraceID, 114, 11, @on
exec sp_trace_setevent @TraceID, 114, 12, @on
exec sp_trace_setevent @TraceID, 114, 14, @on
exec sp_trace_setevent @TraceID, 114, 26, @on
exec sp_trace_setevent @TraceID, 114, 35, @on
exec sp_trace_setevent @TraceID, 114, 49, @on
exec sp_trace_setevent @TraceID, 114, 50, @on
exec sp_trace_setevent @TraceID, 114, 64, @on
-------------------------------------------


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 35, 0, 6, N'ADM_BDADOS'
--exec sp_trace_setfilter @TraceID, 35, 1, 6, N'RISCO_ILIQUIDO_SIMULADO'

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go

