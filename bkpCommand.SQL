BACKUP DATABASE NCS TO DISK = 'D:\DBA\RETER\NCS_26-12-14_CRQ161688_Reter_5.BAK'
WITH  COPY_ONLY, NOFORMAT, INIT,  NAME = N'NCS-Full Database Backup CRQ161688', COMPRESSION, STATS = 5


BACKUP DATABASE NCS TO DISK = 'D:\DBA\RETER\NCS_26-12-14_CRQ161688_Reter_1.BAK', DISK = 'D:\DBA\RETER\NCS_26-12-14_CRQ161688_Reter_2.BAK'
WITH  COPY_ONLY, NOFORMAT, INIT,  NAME = N'NCS-Full Database Backup CRQ161688', COMPRESSION, STATS = 5


\\Bmfsv9601cifp\k$\EDMBKP\RETENCAO_14_DIAS

--Verificação CERTIFICADO_CRD:
RESTORE VERIFYONLY FROM DISK='D:\DBA\RETER\CERTIFICADO_CRD_13-03-15_CRQ165167_Reter_5.BAK' WITH STATS=10
RESTORE FILELISTONLY FROM DISK='D:\DBA\RETER\CERTIFICADO_CRD_13-03-15_CRQ165167_Reter_5.BAK' 
RESTORE HEADERONLY FROM DISK='D:\DBA\RETER\CERTIFICADO_CRD_13-03-15_CRQ165167_Reter_5.BAK' 


--Restore from multiple files
RESTORE DATABASE ReportServerComplteCopy FROM
DISK = 'D:\DBBackups\ReportServer\ReportServer.bak'
WITH REPLACE ,
MOVE 'ReportServer' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER11\MSSQL\DATA\ReportServerComplteCopy.mdf',
MOVE 'ReportServer_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER11\MSSQL\DATA\ReportServerComplteCopy_log.ldf'
- See more at: http://paresh-sqldba.blogspot.com.br/2012/02/restore-full-database-from-multiple.html#sthash.9CDFjjP0.dpuf



--Check the last duration
SELECT sdb.Name AS DatabaseName,
COALESCE(CONVERT(VARCHAR(20), MAX(bus.backup_start_date), 100),'-') AS StartTime,
COALESCE(CONVERT(VARCHAR(20), MAX(bus.backup_finish_date), 100),'-') AS EndTime,
isnull(datediff(mi,max(bus.backup_start_date),max(bus.backup_finish_date)),0) 'BackupDuration'
FROM sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
GROUP BY sdb.Name



--Check all execution backups (Full, differential, transaction log)
SET NOCOUNT ON
GO
SET quoted_identifier OFF
DECLARE @dbname AS VARCHAR(80)
DECLARE @msgdb AS VARCHAR(100)
DECLARE @dbbkpname AS VARCHAR(80)
DECLARE @dypart1 AS VARCHAR(2)
DECLARE @dypart2 AS VARCHAR(3)
DECLARE @dypart3 AS VARCHAR(4)
DECLARE @currentdate AS VARCHAR(10)
DECLARE @server_name AS VARCHAR(30)
SELECT @server_name = @@servername
SELECT @dypart1 = DATEPART(dd,GETDATE())
SELECT @dypart2 = DATENAME(mm,GETDATE())
SELECT @dypart3 = DATEPART(yy,GETDATE())
SELECT @currentdate= @dypart1 + @dypart2 + @dypart3
PRINT "#####################################################################"
PRINT "# SERVERNAME : "+ @server_name + " DATE : "+ @currentdate +"#"
PRINT "#####################################################################"
PRINT "DatabaseName Full Diff TranLog"
PRINT "##########################################################################################################################################"
SELECT SUBSTRING(s.name,1,50) AS 'DATABASE Name',
CONVERT(SYSNAME, DATABASEPROPERTYEX(S.name, 'Recovery')) RecoveryModel ,
b.backup_start_date AS 'Full DB Backup Status',
c.backup_start_date AS 'Differential DB Backup Status',
d.backup_start_date AS 'Transaction Log Backup Status'
FROM MASTER..sysdatabases s
LEFT OUTER JOIN msdb..backupset b
ON s.name = b.database_name
AND b.backup_start_date =
(SELECT MAX(backup_start_date)AS 'Full DB Backup Status'
FROM msdb..backupset
WHERE database_name = b.database_name
AND TYPE = 'D') -- full database backups only, not log backups
LEFT OUTER JOIN msdb..backupset c
ON s.name = c.database_name
AND c.backup_start_date =
(SELECT MAX(backup_start_date)'Differential DB Backup Status'
FROM msdb..backupset
WHERE database_name = c.database_name
AND TYPE = 'I')
LEFT OUTER JOIN msdb..backupset d
ON s.name = d.database_name
AND d.backup_start_date =
(SELECT MAX(backup_start_date)'Transaction Log Backup Status'
FROM msdb..backupset
WHERE database_name = d.database_name
AND TYPE = 'L')
WHERE s.name <>'tempdb'
ORDER BY s.name


--Check history of backups
SELECT
SERVERPROPERTY('Servername') AS 'Servidor',
msdb.dbo.backupset.database_name As 'Database',
CASE msdb..backupset.type WHEN 'D' THEN 'Database' WHEN 'L' THEN 'Log' WHEN 'I' THEN 'Diferencial' WHEN 'F' THEN 'File ou Filegroup'
WHEN 'G' THEN 'Diferencial Arquivo' WHEN 'P' THEN 'Parcial' WHEN 'Q' THEN 'Diferencial Parcial' END AS 'Tipo do Backup',
msdb.dbo.backupset.backup_start_date As 'Data Execuo',
msdb.dbo.backupset.backup_finish_date As 'Data Encerramento',
msdb.dbo.backupset.expiration_date As 'Data de Expirao',
ROUND((msdb.dbo.backupset.backup_size / 1024/1024),2) As 'Tamanho do  Backup em GBs',
msdb.dbo.backupmediafamily.logical_device_name As 'Dispositivo ou Local de Backup',
msdb.dbo.backupmediafamily.physical_device_name As 'Caminho do Arquivo',
msdb.dbo.backupset.description As 'Descrio',
Case msdb.dbo.backupset.compatibility_level
When 80 Then 'SQL Server 2000'
When 90 Then 'SQL Server 2005'
When 100 Then 'SQL Server 2008 ou SQL Server 2008 R2'
When 110 Then 'SQL Server 2012'
End As 'Nvel de Compatibilidade',
msdb.dbo.backupset.name AS 'Backup Set'
FROM
msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset
ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 103) >= GETDATE()-60)
--AND msdb.dbo.backupset.database_name='TESOURO'
--AND msdb..backupset.type='I'
ORDER BY msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_finish_date desc



--Check last restore
SELECT [rs].[destination_database_name], 
[rs].[restore_date],
CASE rs.[restore_type]
 WHEN 'D' THEN 'Database'
 WHEN 'I' THEN 'Differential'
 WHEN 'L' THEN 'Log'
 WHEN 'F' THEN 'File'
 WHEN 'G' THEN 'Filegroup'
 WHEN 'V' THEN 'Verifyonlyl'
 END AS RestoreType,
[bs].[backup_start_date], 
[bs].[backup_finish_date], 
[bs].[database_name] as [source_database_name], 
[bmf].[physical_device_name] as [backup_file_used_for_restore] 
FROM msdb..restorehistory rs 
INNER JOIN msdb..backupset bs 
ON [rs].[backup_set_id] = [bs].[backup_set_id] 
INNER JOIN msdb..backupmediafamily bmf 
ON [bs].[media_set_id] = [bmf].[media_set_id] 
ORDER BY [rs].[restore_date] DESC


--Estimativa de crescimento

--Estimativa de crescimento
;WITH BKP_LAST AS (
SELECT
msdb.dbo.backupset.database_name As 'Data_base',
max(msdb.dbo.backupset.backup_start_date) As 'Data_Last'
FROM
msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset
ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
where msdb..backupset.type='D'
and (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 103) >= GETDATE()-90)
group by msdb.dbo.backupset.database_name
),
BKP_INITIAL AS (
SELECT
msdb.dbo.backupset.database_name As 'Data_base',
min(msdb.dbo.backupset.backup_start_date) As 'Data_Initial'
FROM
msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset
ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
where msdb..backupset.type='D'
and (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 103) >= GETDATE()-90)
group by msdb.dbo.backupset.database_name
),
BKP_SIZE_LAST AS (
SELECT
SERVERPROPERTY('Servername') AS 'Servidor',
msdb.dbo.backupset.database_name As 'Database_Name',
CASE msdb..backupset.type WHEN 'D' THEN 'Database' WHEN 'L' THEN 'Log' WHEN 'I' THEN 'Diferencial' WHEN 'F' THEN 'File ou Filegroup'
WHEN 'G' THEN 'Diferencial Arquivo' WHEN 'P' THEN 'Parcial' WHEN 'Q' THEN 'Diferencial Parcial' END AS 'Tipo do Backup',
msdb.dbo.backupset.backup_start_date As 'Data Execuo',
ROUND((msdb.dbo.backupset.backup_size / 1024/1024),2) As 'Tamanho do  Backup em GBs'
FROM
msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset
ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
JOIN BKP_LAST ON (BKP_LAST.Data_Last=msdb.dbo.backupset.backup_start_date AND BKP_LAST.Data_base=msdb.dbo.backupset.database_name)
WHERE msdb..backupset.type='D'
and (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 103) >= GETDATE()-90)
),
BKP_SIZE_INITIAL AS (
SELECT
SERVERPROPERTY('Servername') AS 'Servidor',
msdb.dbo.backupset.database_name As 'Database_Name',
CASE msdb..backupset.type WHEN 'D' THEN 'Database' WHEN 'L' THEN 'Log' WHEN 'I' THEN 'Diferencial' WHEN 'F' THEN 'File ou Filegroup'
WHEN 'G' THEN 'Diferencial Arquivo' WHEN 'P' THEN 'Parcial' WHEN 'Q' THEN 'Diferencial Parcial' END AS 'Tipo do Backup',
msdb.dbo.backupset.backup_start_date As 'Data Execuo',
ROUND((msdb.dbo.backupset.backup_size / 1024/1024),2) As 'Tamanho do  Backup em GBs'
FROM
msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset
ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
JOIN BKP_INITIAL ON (BKP_INITIAL.Data_Initial=msdb.dbo.backupset.backup_start_date AND BKP_INITIAL.Data_base=msdb.dbo.backupset.database_name)
WHERE msdb..backupset.type='D'
and (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 103) >= GETDATE()-90)
)
select BKP_SIZE_INITIAL.Servidor,BKP_SIZE_INITIAL.Database_Name,BKP_SIZE_INITIAL.[Data Execuo] as "Data Inicial",BKP_SIZE_INITIAL.[Tamanho do  Backup em GBs] as "Size Inicial (MB)",
 BKP_SIZE_LAST.[Data Execuo] as "Data Final",BKP_SIZE_LAST.[Tamanho do  Backup em GBs] as "Size Final (MB)" ,
 BKP_SIZE_LAST.[Tamanho do  Backup em GBs]-BKP_SIZE_INITIAL.[Tamanho do  Backup em GBs] AS "Crescimento (MB)"
 from BKP_SIZE_INITIAL JOIN BKP_SIZE_LAST ON (BKP_SIZE_INITIAL.Database_Name=BKP_SIZE_LAST.Database_Name)
 WHERE BKP_SIZE_INITIAL.Database_Name NOT IN ('ADM_BDADOS','MASTER','MODEL','MSDB')
 order by BKP_SIZE_INITIAL.Database_Name asc