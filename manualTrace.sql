--Verify the trace has been created.
SELECT * FROM sys.traces
GO


--Events codes
select * from sys.trace_events

--Column codes
select * from sys.trace_columns

--Event Bindings
select * from sys.trace_event_bindings



--Start the trace
DECLARE @ReturnCode INT
DECLARE @TraceID INT
DECLARE @Options INT = 2
DECLARE @TraceFile NVARCHAR(245) = 'C:\temp\SQL2012_Performance\Trace\FileAutoGrow'
DECLARE @MaxFileSize INT = 5
DECLARE @Event_DataFileAutoGrow INT = 92
DECLARE @Event_LogFileAutoGrow INT = 93
DECLARE @DataColumn_DatabaseName INT = 35
DECLARE @DataColumn_FileName INT = 36
DECLARE @DataColumn_StartTime INT = 14
DECLARE @DataColumn_EndTime INT = 15

DECLARE @On BIT = 1
DECLARE @Off BIT = 0

--Create a trace and collect the returned code.
EXECUTE @ReturnCode = sp_trace_create 
	@traceid = @TraceID OUTPUT
	,@options = @Options
	,@tracefile = @TraceFile
	
--Check returned code is zero and no error occurred.	
IF @ReturnCode = 0 
BEGIN
	BEGIN TRY
		--Add DatabaseName column to DataFileAutoGrow event.
		EXECUTE sp_trace_setevent  
		@traceid = @TraceID
		,@eventid = @Event_DataFileAutoGrow
		,@columnid = @DataColumn_DatabaseName
		,@on = @On
		
		--Add FileName column to DataFileAutoGrow event.
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_DataFileAutoGrow
			,@columnid = @DataColumn_FileName
			,@on = @On
			
		--Add StartTime column to DataFileAutoGrow event.	
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_DataFileAutoGrow
			,@columnid=@DataColumn_StartTime
			,@on = @On
			
		--Add EndTime column to DataFileAutoGrow event.
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_DataFileAutoGrow
			,@columnid = @DataColumn_EndTime
			,@on = @On
			
		--Add DatabaseName column to LogFileAutoGrow event.			
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_LogFileAutoGrow
			,@columnid = @DataColumn_DatabaseName
			,@on = @On
			
		--Add FileName column to LogFileAutoGrow event.		
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_LogFileAutoGrow
			,@columnid = @DataColumn_FileName
			,@on = @On
			
		--Add StartTime column to LogFileAutoGrow event.	
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_LogFileAutoGrow
			,@columnid=@DataColumn_StartTime
			,@on = @On
			
		--Add EndTime column to LogFileAutoGrow event.
		EXECUTE sp_trace_setevent 
			@traceid = @TraceID
			,@eventid = @Event_LogFileAutoGrow
			,@columnid = @DataColumn_EndTime
			,@on = @On
			
		--Start the trace. Status 1 corroponds to START.
		EXECUTE sp_trace_setstatus 
			@traceid = @TraceID
			,@status = 1
	END TRY
	BEGIN CATCH
		PRINT 'An error occured while creating trace.'
	END CATCH	
END
GO


--Stop the trace
DECLARE @TraceID INT
DECLARE @TraceFile NVARCHAR(245) = 'C:\temp\SQL2012_Performance\Trace\FileAutoGrow.trc'

--Get the TraceID for our trace.
SELECT @TraceID = id FROM sys.traces 
WHERE path = @TraceFile

IF @TraceID IS NOT NULL
BEGIN
	--Stop the trace. Status 0 corroponds to STOP.
	EXECUTE sp_trace_setstatus 
		@traceid = @TraceID
		,@status = 0
		
	--Closes the trace. Status 2 corroponds to CLOSE.
	EXECUTE sp_trace_setstatus 
		@traceid = @TraceID
		,@status = 2	
END
GO



--Retrieve the collected trace data.
SELECT
TE.name AS TraceEvent
,TD.DatabaseName
,TD.FileName
,TD.StartTime
,TD.EndTime
FROM fn_trace_gettable('C:\temp\SQL2012_Performance\Trace\FileAutoGrow.trc',default) AS
TD
LEFT JOIN sys.trace_events AS TE
ON TD.EventClass = TE.trace_event_id
