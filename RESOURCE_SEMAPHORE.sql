SELECT * FROM sys.dm_exec_query_resource_semaphores
--GRANTEE_COUNT: sessões que conseguiram memória e estão executando
--WAITER_COUNT: sessões que estão aguardando memória


SELECT * FROM sys.dm_exec_query_memory_grants order by granted_memory_kb desc
--GRANTED_MEMORY_KB: quantidade de memória reservada por sessão