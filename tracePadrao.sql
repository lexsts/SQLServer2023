-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 10240

exec @rc = sp_trace_create @TraceID output, 0, N'C:\temp\TRACE_teste76', @maxfilesize, NULL 
if (@rc != 0) goto error


declare @on bit
set @on = 1

exec sp_trace_setevent @TraceID, 11, 1, @on
exec sp_trace_setevent @TraceID, 11, 10, @on
exec sp_trace_setevent @TraceID, 11, 14, @on
exec sp_trace_setevent @TraceID, 11, 26, @on
exec sp_trace_setevent @TraceID, 11, 11, @on
exec sp_trace_setevent @TraceID, 11, 35, @on
exec sp_trace_setevent @TraceID, 11, 8, @on 
exec sp_trace_setevent @TraceID, 11, 64, @on 



exec sp_trace_setevent @TraceID, 42, 1, @on 
exec sp_trace_setevent @TraceID, 42, 10, @on
exec sp_trace_setevent @TraceID, 42, 14, @on
exec sp_trace_setevent @TraceID, 42, 26, @on
exec sp_trace_setevent @TraceID, 42, 11, @on
exec sp_trace_setevent @TraceID, 42, 35, @on
exec sp_trace_setevent @TraceID, 42, 8, @on 
exec sp_trace_setevent @TraceID, 42, 64, @on


exec sp_trace_setevent @TraceID, 13, 1, @on 
exec sp_trace_setevent @TraceID, 13, 10, @on
exec sp_trace_setevent @TraceID, 13, 14, @on
exec sp_trace_setevent @TraceID, 13, 26, @on
exec sp_trace_setevent @TraceID, 13, 11, @on
exec sp_trace_setevent @TraceID, 13, 35, @on
exec sp_trace_setevent @TraceID, 13, 8, @on 
exec sp_trace_setevent @TraceID, 13, 64, @on


declare @intfilter int
declare @bigintfilter bigint

--Alterar linha abaixo com o nome do banco
exec sp_trace_setfilter @TraceID, 35, 0, 6, N'ProfilerSML'

exec sp_trace_setstatus @TraceID, 1


select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go



--Stop
exec sp_trace_setstatus @traceid = 2 , @status = 0

--Close 
exec sp_trace_setstatus @traceid = 2 , @status = 2



DECLARE @sqlTrace varchar(250)
	set @sqlTrace = 'dbcc tracestatus'
	exec(@sqlTrace)
