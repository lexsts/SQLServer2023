--Mostra bases (ONLINE) que n�o tiveram objetos atualizados desde que iniciamos a coleta - 27/10/2015 (Executar em GERCOR0603P,1433-ADM_INFO)
SELECT DISTINCT * FROM ADM_INFO.INFO.TB_DBNAMES TBN 
WHERE DBNAME NOT IN 
	(SELECT DBNAME FROM ADM_INFO.INFO.TB_DBUnunsed TBU 
	WHERE TBN.INSTANCE=TBU.INSTANCE AND TBN.DBNAME=TBU.DBNAME) 
AND DBNAME NOT IN ('MODEL','MSDB','MASTER','TEMPDB')
AND STATE_DESC='ONLINE'
ORDER BY TBN.INSTANCE

--Mostra bases (OFFLINE) que n�o tiveram objetos atualizados desde que iniciamos a coleta - 27/10/2015 (Executar em GERCOR0603P,1433-ADM_INFO)
SELECT DISTINCT * FROM ADM_INFO.INFO.TB_DBNAMES TBN 
WHERE DBNAME NOT IN 
	(SELECT DBNAME FROM ADM_INFO.INFO.TB_DBUnunsed TBU 
	WHERE TBN.INSTANCE=TBU.INSTANCE AND TBN.DBNAME=TBU.DBNAME) 
AND DBNAME NOT IN ('MODEL','MSDB','MASTER','TEMPDB')
AND STATE_DESC='OFFLINE'
ORDER BY TBN.INSTANCE

--Mostra bases (ONLINE) que n�o tiveram objetos atualizados nos �ltimos 10 dias (Executar em GERCOR0603P,1433-ADM_INFO)
SELECT DISTINCT * FROM ADM_INFO.INFO.TB_DBNAMES TBN 
WHERE DBNAME IN (
SELECT DISTINCT DBNAME FROM ADM_INFO.INFO.TB_DBUnunsed TBU
WHERE TBN.INSTANCE=TBU.INSTANCE AND TBN.DBNAME=TBU.DBNAME
GROUP BY INSTANCE,DBNAME,OBJNAME,OLDEST_USER_UPDATE,OLDEST_USER_SCAN,OLDEST_USER_SEEK,OLDEST_USER_LOOKUP
HAVING ((MAX(OLDEST_USER_SCAN) < GETDATE()-10 AND MAX(OLDEST_USER_SCAN)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_UPDATE) < GETDATE()-10 AND MAX(OLDEST_USER_UPDATE)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_SEEK) < GETDATE()-10 AND MAX(OLDEST_USER_SEEK)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_LOOKUP) < GETDATE()-10 AND MAX(OLDEST_USER_LOOKUP)<>'1900-01-01 00:00:00.000') AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
AND DBNAME NOT IN ('MODEL','MSDB','MASTER','TEMPDB'))
ORDER BY TBN.INSTANCE

--Mostra detalhes do objeto usado para mensurar a data da �ltima atualiza��o/utiliza��o (Executar em GERCOR0603P,1433-ADM_INFO)
SELECT DISTINCT * FROM ADM_INFO.INFO.TB_DBUnunsed TBU
--WHERE INSTANCE='BMFIN0092\BTSFXP' AND DBNAME='NETFRAMEWORK_BTS'
GROUP BY INSTANCE,DBNAME,OBJNAME,OLDEST_USER_UPDATE,OLDEST_USER_SCAN,OLDEST_USER_SEEK,OLDEST_USER_LOOKUP
HAVING ((MAX(OLDEST_USER_SCAN) < GETDATE()-10 AND MAX(OLDEST_USER_SCAN)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SCAN)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_UPDATE) < GETDATE()-10 AND MAX(OLDEST_USER_UPDATE)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_UPDATE)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_SEEK) < GETDATE()-10 AND MAX(OLDEST_USER_SEEK)<>'1900-01-01 00:00:00.000' AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_SEEK)>=(SELECT MAX(OLDEST_USER_LOOKUP) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
OR (MAX(OLDEST_USER_LOOKUP) < GETDATE()-10 AND MAX(OLDEST_USER_LOOKUP)<>'1900-01-01 00:00:00.000') AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_SCAN) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_UPDATE) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME) AND MAX(OLDEST_USER_LOOKUP)>=(SELECT MAX(OLDEST_USER_SEEK) FROM ADM_INFO.INFO.TB_DBUnunsed OUS WHERE OUS.INSTANCE=TBU.INSTANCE AND OUS.DBNAME=TBU.DBNAME))
AND DBNAME NOT IN ('MODEL','MSDB','MASTER','TEMPDB')
ORDER BY OLDEST_USER_SCAN DESC,OLDEST_USER_UPDATE DESC,OLDEST_USER_SEEK DESC,OLDEST_USER_LOOKUP DESC

--Mostra as estat�sticas de todos os objetos na base analisada (Executar na inst�ncia/base origem)
select --Top 1
DB_NAME() as dbname,object_name(ius.object_id) objectname,obj.type_desc,obj.type,ius.last_user_update last_user_update,
ius.last_user_scan last_user_scan,ius.last_user_seek last_user_seek,ius.last_user_lookup last_user_lookup,obj.create_date,obj.modify_date
from sys.dm_db_index_usage_stats ius join sys.objects obj on ius.object_id=obj.object_id 
where object_name(ius.object_id) is not null and obj.type NOT IN ('S','IT','SQ')
and (ius.last_user_seek is not null or ius.last_user_scan is not null or ius.last_user_lookup is not null or ius.last_user_update is not null) 
order by ius.last_user_scan DESC,ius.last_user_update DESC,ius.last_user_seek DESC,ius.last_user_lookup DESC
--SELECT COUNT(1) FROM SYS.OBJECTS WHERE TYPE<>'S' --total de objetos
--SELECT COUNT(1) FROM sys.dm_db_index_usage_stats ius join sys.objects obj on ius.object_id=obj.object_id where object_name(ius.object_id) is not null and obj.type<>'S' --total de objetos atualizados/usados


USE NEGOCIACAOCONTINGENCIA
/*Msg 924, Level 14, State 1, Line 1
Database 'NEGOCIACAOCONTINGENCIA' is already open and can only have one user at a time.
*/