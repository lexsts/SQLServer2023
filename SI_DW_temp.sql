use tempdb
go
dbcc dropcleanbuffers
go
dbcc freesystemcache('ALL')
go
dbcc freesessioncache
go
dbcc freeproccache