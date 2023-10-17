--Search on Instance
select * from master.sys.syslogins 
where name like '%rlotta%'
OR name like '%gashibata%'
OR name like '%marisilva%'
OR name like '%cramalho%'
OR name like '%pvarlotta%'
OR name like '%saniceto%'
OR name like '%marsousa%'

--Search on Database
select * from HOP..sysusers where name like '%dmonteiro%'
OR name like '%gashibata%'
OR name like '%marisilva%'
OR name like '%cramalho%'
OR name like '%pvarlotta%'
OR name like '%saniceto%'
OR name like '%marsousa%'

EXEC sp_MSForeachdb '
select * from sysusers where name like ''%fcastro%'''