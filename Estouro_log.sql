USE ATTSGR2
GO
exec sp_helpfile
DBCC SHRINKFILE(ATTSGR5_Log, 1)
BACKUP LOG ATTSGR2 WITH TRUNCATE_ONLY
DBCC SHRINKFILE(ATTSGR5_Log, 1)
GO 


--2008
BACKUP LOG [Tfs_Warehouse]
TO DISK = 'nul:' WITH STATS = 10