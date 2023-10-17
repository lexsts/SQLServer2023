--Partition on field int
CREATE PARTITION FUNCTION particao_registros_orderm (INT) AS
RANGE LEFT FOR VALUES (500, 1000, 1500, 2000, 2500,3000,3500,4000,4500);
GO
--drop partition function particao_registros_orderm


--Partition schema
CREATE PARTITION SCHEME particao_schema_registros_orderm AS
 PARTITION particao_registros_orderm
TO ([PRIMARY], [INDEX],[PRIMARY], [INDEX],[PRIMARY], [INDEX],[PRIMARY], [INDEX],[PRIMARY],[INDEX])
GO
--drop partition scheme particao_schema_registros_orderm


--Alter table to use a partition
CREATE UNIQUE CLUSTERED INDEX [PK_REGISTROS] ON registros(orderm) WITH(DROP_EXISTING = ON)ON particao_schema_registros_orderm(orderm)

--Query partition information
--Partitions
SELECT * FROM sys.partition_schemes

SELECT * FROM sys.partition_range_values
WHERE FUNCTION_ID=65541

SELECT * FROM sys.partitions AS p
JOIN sys.tables AS t
    ON  p.object_id = t.object_id
WHERE p.partition_id IS NOT NULL
    AND t.name = 'registros';

--Which partition is the data
SELECT *,$partition.particao_registros_orderm(orderm) as nr_particao
FROM dbo.registros
where orderm in (400,700,1200,1600,2100,2800,3050,3750,4150,4700)

--Amount of rows in which partition
SELECT * FROM sys.partitions
WHERE object_id = OBJECT_ID(dbo.registros)
and   sys.partitions.index_id =
(select sys.indexes.index_id from sys.indexes
where object_id = OBJECT_ID(registros)
and sys.indexes.name = orderm)

--Filegroup VS Partition schema
select sys.partition_schemes.name as name_scheme, sys.data_spaces.name as name_filegroup
from sys.partition_schemes
inner join sys.destination_data_spaces on sys.destination_data_spaces.partition_scheme_id = sys.partition_schemes.data_space_id
inner join sys.data_spaces on sys.data_spaces.data_space_id = sys.destination_data_spaces.data_space_id
where sys.partition_schemes.name = 'particao_schema_registros_orderm'



--Limit partitions
SELECT t.name AS TableName, i.name AS IndexName, p.partition_number, p.partition_id, i.data_space_id, f.function_id, f.type_desc, r.boundary_id, r.value AS BoundaryValue 
FROM sys.tables AS t
JOIN sys.indexes AS i
    ON t.object_id = i.object_id
JOIN sys.partitions AS p
    ON i.object_id = p.object_id AND i.index_id = p.index_id 
JOIN  sys.partition_schemes AS s 
    ON i.data_space_id = s.data_space_id
JOIN sys.partition_functions AS f 
    ON s.function_id = f.function_id
LEFT JOIN sys.partition_range_values AS r 
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number
WHERE t.name = 'registros' AND i.type <= 1
ORDER BY p.partition_number;

--Column partition
SELECT t.object_id AS Object_ID, t.name AS TableName, ic.column_id as PartitioningColumnID, col.COLUMN_NAME AS PartitioningColumnName 
FROM sys.tables AS t
JOIN sys.indexes AS i
    ON t.object_id = i.object_id
JOIN sys.columns AS c
    ON t.object_id = c.object_id
JOIN sys.partition_schemes AS ps
    ON ps.data_space_id = i.data_space_id
JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.partition_ordinal > 0
JOIN INFORMATION_SCHEMA.COLUMNS col
    ON col.TABLE_NAME = t.name
     AND col.ORDINAL_POSITION = ic.column_id
WHERE t.name = 'registros'
AND i.type <= 1;


--INCREASE NUMBER OF PARTITIONS NO SQL2008
EXEC sp_db_increased_partitions @dbname = 'SI_DW'
GO
EXEC sp_db_increased_partitions @dbname = 'SI_DW', @increased_partitions = 'ON'
GO
EXEC sp_db_increased_partitions @dbname = 'SI_DW'
GO


--http://www.devmedia.com.br/particionando-tabelas-e-indices-no-sql-server-2005/5347
--http://www.devmedia.com.br/particionamento-de-tabelas-no-sql-server-2008-r2/24237




--DDL PARTITION FUNCTION
SELECT
      N'CREATE PARTITION FUNCTION ' 
    + QUOTENAME(pf.name)
    + N'(' + t.name  + N')'
    + N' AS RANGE ' 
    + CASE WHEN pf.boundary_value_on_right = 1 THEN N'RIGHT' ELSE N'LEFT' END
    + ' FOR VALUES('
    +
    (SELECT
        STUFF((SELECT
            N','
            + CASE
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') IN(N'char', N'varchar') 
                    THEN QUOTENAME(CAST(r.value AS nvarchar(4000)), '''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') IN(N'nchar', N'nvarchar') 
                    THEN N'N' + QUOTENAME(CAST(r.value AS nvarchar(4000)), '''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'date' 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS date), 'yyyy-MM-dd'),'''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'datetime' 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS datetime), 'yyyy-MM-ddTHH:mm:ss'),'''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') IN(N'datetime', N'smalldatetime') 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS datetime), 'yyyy-MM-ddTHH:mm:ss.fff'),'''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'datetime2' 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS datetime2), 'yyyy-MM-ddTHH:mm:ss.fffffff'),'''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'datetimeoffset' 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS datetimeoffset), 'yyyy-MM-dd HH:mm:ss.fffffff K'),'''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'time' 
                    THEN QUOTENAME(FORMAT(CAST(r.value AS time), 'hh\:mm\:ss\.fffffff'),'''') --'HH\:mm\:ss\.fffffff'
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') = N'uniqueidentifier' 
                    THEN QUOTENAME(CAST(r.value AS nvarchar(4000)), '''')
                  WHEN SQL_VARIANT_PROPERTY(r.value, 'BaseType') IN (N'binary', N'varbinary') 
                    THEN CONVERT(nvarchar(4000), r.value, 1)
                  ELSE CAST(r.value AS nvarchar(4000))
              END
    FROM sys.partition_range_values AS r
    WHERE pf.[function_id] = r.[function_id]
    FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)'),1,1,N'')
    )
    + N');'
FROM sys.partition_functions pf
JOIN sys.partition_parameters AS pp ON
    pp.function_id = pf.function_id
JOIN sys.types AS t ON
    t.system_type_id = pp.system_type_id
    AND t.user_type_id = pp.user_type_id
WHERE pf.name = N'MeterPartitionFunction';

--DDL PARTITION SCHEMA
SELECT
      N'CREATE PARTITION SCHEME ' + QUOTENAME(ps.name)
    + N' AS PARTTITION ' + QUOTENAME(pf.name)
    + N' TO ('
    +
    (SELECT
        STUFF((SELECT
            N',' + QUOTENAME(fg.name)
    FROM sys.data_spaces ds
    JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = ps.data_space_id
    JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id
    WHERE ps.data_space_id = ds.data_space_id
    ORDER BY dds.destination_id
    FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)'),1,1,N'')
    )
    + N');'
FROM sys.partition_schemes AS ps
JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
WHERE ps.name = N'MeterPartitionSchema';
