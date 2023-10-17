exec sp_changedbowner 'sa'

--Check who is owner from a database
select name as database_name,suser_sname(owner_sid) as owner from sys.databases