select * from sys.dm_os_wait_stats 
where waiting_tasks_count <> 0
and wait_type not like 'FT_%'
order by 3 desc


--http://msdn.microsoft.com/pt-br/library/ms179984.aspx
