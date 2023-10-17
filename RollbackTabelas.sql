--VERIFICA QUAIS SÃO AS TABELAS REFERENCIANDO A PK POR FK
select 
    t.name as TableWithForeignKey, 
    fk.constraint_column_id as FK_PartNo, c.
    name as ForeignKeyColumn 
from 
    sys.foreign_key_columns as fk
inner join 
    sys.tables as t on fk.parent_object_id = t.object_id
inner join 
    sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
where 
    fk.referenced_object_id = (select object_id 
                               from sys.tables 
                               where name = 'TCSDFCAO') --tabela verificada
order by 
    TableWithForeignKey, FK_PartNo

	
--GERA O CÓDIGO PARA DESATIVAR AS FK´s	
	select 'ALTER TABLE ' + TABLE_SCHEMA +'.'+TABLE_NAME+' noCHECK CONSTRAINT '+CONSTRAINT_NAME+';'  from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where table_name in (
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
                               where name = 'TCSDFCAO'))
AND constraint_name like 'FK%'



--APAGA A TABELA ORIGINAL
DELETE FROM TCSDFCAO

--ZERA O IDENTITY
DBCC CHECKIDENT ('[TCSDFCAO]', RESEED, 0);
GO

--HABILITA A INSERÇÃO NO IDENTITY
SET IDENTITY_INSERT TCSDFCAO on
go

--FAZ A INSERÇÃO DA TABELA PRINCIPAL A PARTIR DO BACKUP
INSERT INTO TCSDFCAO(COD_FCAO,
COD_MOD,
NOME_FCAO,
COD_MNEM_FCAO)
SELECT * FROM TCSDFCAO_CRQ000000428315
go

--DESABILITA A INSERÇÃO NO IDENTITY
SET IDENTITY_INSERT TCSDFCAO OFF



--GERA O CÓDIGO PARA REATIVAR AS FK´s	
	select 'ALTER TABLE ' + TABLE_SCHEMA +'.'+TABLE_NAME+' CHECK CONSTRAINT '+CONSTRAINT_NAME+';'  from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where table_name in (
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
                               where name = 'TCSDFCAO'))
AND constraint_name like 'FK%'
