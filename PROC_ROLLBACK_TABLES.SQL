CREATE PROCEDURE PROC_ROLLBACK_TABLES (
@TB_ORIGEM NVARCHAR(256), @TB_DESTINO NVARCHAR(256))
AS
BEGIN
DECLARE @CHECK_FK_DESTINO INT
DECLARE @DISABLE_FK_DESTINO NVARCHAR(4000)
DECLARE @ENABLE_FK_DESTINO NVARCHAR(4000)
DECLARE @COLUNAS NVARCHAR(4000)
DECLARE @SQLCMD NVARCHAR(4000)
DECLARE @FK_cursor NVARCHAR(4000)
SET @COLUNAS=''

--VERIFICA SE A TABELA DESTINO POSSUI FK´s E DESABILITA ELAS
select @CHECK_FK_DESTINO=count(1) from sys.foreign_key_columns as fk inner join sys.tables as t on fk.parent_object_id = t.object_id
inner join sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
where fk.referenced_object_id = (select object_id from sys.tables where name = @TB_DESTINO) --tabela verificada

IF @CHECK_FK_DESTINO > 0
BEGIN
DECLARE FK_cursor CURSOR FOR  
SELECT TABLE_SCHEMA +'.'+TABLE_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where table_name in (
	select 
    t.name
from 
    sys.foreign_key_columns as fk
inner join 
    sys.tables as t on fk.parent_object_id = t.object_id
inner join 
    sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
where 
    fk.referenced_object_id = (select object_id 
                               from sys.tables 
                               where name = @TB_DESTINO))
AND constraint_type='FOREIGN KEY'
  
OPEN FK_cursor  
  
-- Perform the first fetch.  
FETCH NEXT FROM FK_cursor INTO @FK_cursor  
  
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   SELECT @SQLCMD='ALTER TABLE ' + @FK_cursor +' noCHECK CONSTRAINT ALL;'
   --PRINT 'EXEC sp_executesql '+ @SQLCMD 
   EXEC sp_executesql @SQLCMD 
   FETCH NEXT FROM FK_cursor INTO @FK_cursor 
END  
  
CLOSE FK_cursor  
DEALLOCATE FK_cursor 
END

--REMOVE OS REGISTROS DA TABELA DESTINO
SET @SQLCMD='DELETE FROM ' + @TB_DESTINO
exec (@SQLCMD)

--VERIFICA SE A TABELA DESTINO POSSUI IDENTITY. EM CASO POSITIVO, ZERA E HABILITA A INSERÇÃO
IF (OBJECTPROPERTY(OBJECT_ID(@TB_DESTINO), 'TableHasIdentity') = 1) 
BEGIN
DBCC CHECKIDENT (@TB_DESTINO, RESEED, 0)
SET @SQLCMD='SET IDENTITY_INSERT ' + @TB_DESTINO + ' ON'
exec (@SQLCMD)
END

--FAZ A INSERÇÃO NA TABELA PRINCIPAL A PARTIR DO BACKUP
SELECT @COLUNAS=@COLUNAS+'['+asa.COLUMN_NAME+'], '
FROM (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TB_DESTINO)asa
SET @COLUNAS=LEFT(@COLUNAS,len(@COLUNAS)-1)

SET @SQLCMD='INSERT INTO ' + @TB_DESTINO + '(' + @COLUNAS + ') SELECT * FROM ' + @TB_ORIGEM
exec (@SQLCMD)

--DESABILITA A INSERÇÃO NO IDENTITY
IF (OBJECTPROPERTY(OBJECT_ID(@TB_DESTINO), 'TableHasIdentity') = 1) 
BEGIN
SET @SQLCMD='SET IDENTITY_INSERT ' + @TB_DESTINO + ' OFF'
exec (@SQLCMD)
END

--VERIFICA SE A TABELA DESTINO POSSUI FK´s E HABILITA ELAS
IF @CHECK_FK_DESTINO > 0
BEGIN
DECLARE FK_cursor CURSOR FOR  
SELECT TABLE_SCHEMA +'.'+TABLE_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where table_name in (
	select 
    t.name
from 
    sys.foreign_key_columns as fk
inner join 
    sys.tables as t on fk.parent_object_id = t.object_id
inner join 
    sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
where 
    fk.referenced_object_id = (select object_id 
                               from sys.tables 
                               where name = @TB_DESTINO))
AND constraint_type='FOREIGN KEY'
  
OPEN FK_cursor  
  
-- Perform the first fetch.  
FETCH NEXT FROM FK_cursor INTO @FK_cursor  
  
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   SELECT @SQLCMD='ALTER TABLE ' + @FK_cursor +' CHECK CONSTRAINT ALL;'
   --PRINT 'EXEC sp_executesql '+ @SQLCMD 
   EXEC sp_executesql @SQLCMD 
   FETCH NEXT FROM FK_cursor INTO @FK_cursor 
END  
  
CLOSE FK_cursor  
DEALLOCATE FK_cursor 
END
END


