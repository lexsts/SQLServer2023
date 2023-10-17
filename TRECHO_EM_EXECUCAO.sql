
declare @spid int

declare @sql nvarchar(4000)
declare @EventType nvarchar(30)
declare @Parameters Int
declare @EventInfo nvarchar(255)

declare @sql_text varchar(8000)
declare @sql_handle varbinary(20)
declare @stmt_start int
declare @stmt_end int

set @spid = 967

/*****
* DBCC INPUTBUFFER
*****/
create table #tmp
(
EventType nvarchar(30),
Parameters Int,
EventInfo nvarchar(792)
)

set @sql = '
set nocount on
insert into #tmp
(
EventType,
Parameters,
EventInfo
)
exec(''dbcc inputbuffer('+cast(@spid as varchar(20))+')'')'

exec sp_executesql @sql

select
	@EventType = EventType,
	@Parameters = Parameters,
	@EventInfo = EventInfo
from
	#tmp

drop table #tmp

-- select @EventType as EventType, @Parameters as Parameters, @EventInfo as EventInfo -- debug

/*****
* FN_GET_SQL
*****/
select
	@sql_handle = sql_handle,
	@stmt_start = stmt_start / 2,
	@stmt_end = stmt_end / 2
from
	master..sysprocesses
where
	spid = @spid and
	ecid = 0

-- select @@rowcount as 'rowcount', @sql_handle as handle, @stmt_start as start, @stmt_end as 'end' -- debug

select
	@sql_text = substring(text, (@stmt_start), (case @stmt_end when 0 then datalength(text) else @stmt_end end) - (@stmt_start))
from
	::fn_get_sql(@sql_handle)

/*****
* IMPRIME OS RESULTADOS
*****/

PRINT ''
PRINT 'SPID: ' + CAST(@SPID AS VARCHAR(20))
PRINT ''
PRINT 'RESULTADO DO DBCC INPUTBUFFER:'
PRINT '=============================='
PRINT 'EVENTTYPE: ' + CAST(@EVENTTYPE AS VARCHAR(30))
PRINT 'PARAMETERS: ' + CAST(@PARAMETERS AS VARCHAR(20))
PRINT 'EVENTINFO: ' + CAST(replace(replace(replace(@EVENTINFO, char(10), ' '), char(09), ' '), '  ', ' ') AS VARCHAR(255))
PRINT 'EVENTINFO: ' + CAST(@EVENTINFO AS VARCHAR(255))
PRINT ''
PRINT ''
PRINT 'TRECHO DE CÓDIGO EM EXECUÇÃO:'
PRINT '============================='
PRINT @SQL_TEXT
/*
SELECT  *
FROM 
    (SELECT QS.*, 
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
    ((CASE statement_end_offset 
        WHEN -1 THEN DATALENGTH(ST.text)
        ELSE QS.statement_end_offset END 
            - QS.statement_start_offset)/2) + 1) AS statement_text
     FROM sys.dm_exec_query_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST
     WHERE QS.sql_handle = @sql_handle) as query_stats

--SP_WHO2 ACTIVE

*/