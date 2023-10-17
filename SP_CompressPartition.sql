select  'GuardAppEvent:Start'
,'GuardAppEventType:METADADO'
,'GuardAppEventStrValue:METADADO';
go
/*
Eduardo de Oliveira Gomes
PROC para comprimir partições
09-03-2018
*/
go
IF EXISTS (SELECT 1 FROM SYS.PROCEDURES WHERE NAME = 'SP_COMPRESS_PARTITION')
  DROP PROCEDURE SP_COMPRESS_PARTITION
GO
CREATE PROCEDURE SP_COMPRESS_PARTITION (@QTD_MES_RETENCAO INT, @TABLENAME VARCHAR(MAX))
AS
BEGIN
  DECLARE @CMD VARCHAR(MAX)
  DECLARE @RANGE VARCHAR(MAX)
  DECLARE @DESC_ERRO VARCHAR(MAX)
  DECLARE C_COMPRESS CURSOR LOCAL FOR
                                     SELECT
                                       'ALTER TABLE ['+schema_name(t.schema_id)+'].['+OBJECT_NAME(idx.object_id)+'] REBUILD PARTITION = '+cast(part.partition_number as varchar(max))+' WITH(DATA_COMPRESSION = PAGE )' AS 'CMD',
                                       CAST(value AS VARCHAR(MAX)) AS 'Range'
                                     FROM 
                                       sys.partitions part 
                                       INNER JOIN sys.indexes idx ON part.object_id = idx.object_id
                                     							 AND part.index_id = idx.index_id 
                                       INNER JOIN sys.partition_schemes psh ON psh.data_space_id = idx.data_space_id
                                       INNER JOIN sys.partition_functions fnc ON fnc.function_id = psh.function_id 
                                       LEFT JOIN sys.partition_range_values prv ON fnc.function_id = prv.function_id
                                     										   AND part.partition_number = prv.boundary_id
                                       INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = psh.data_space_id
                                     											 AND dds.destination_id = part.partition_number
                                       INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
                                       INNER JOIN (SELECT 
                                                     container_id, 
                                     				sum(total_pages) as total_pages
                                                   FROM
                                                     sys.allocation_units 
                                     			  GROUP BY 
                                     			    container_id) AS au ON au.container_id = part.partition_id 
                                       INNER JOIN sys.tables t ON part.object_id = t.object_id 
                                     WHERE 
                                       idx.index_id < 2
									   AND ROWS > 0
                                       AND [data_compression_desc] = 'NONE'
									   AND (
									        CASE 
											  WHEN @TABLENAME = 'ALL' THEN OBJECT_NAME(idx.object_id)
											  ELSE @TABLENAME
											END
										   ) = OBJECT_NAME(idx.object_id)

  OPEN C_COMPRESS FETCH NEXT FROM C_COMPRESS INTO @CMD, @RANGE
  WHILE @@FETCH_STATUS = 0
  BEGIN
    BEGIN TRY
      IF ISDATE(@RANGE) = 1
	    IF CAST(@RANGE AS DATETIME) <= DATEADD(MM,-@QTD_MES_RETENCAO,GETDATE())	    
	      EXEC (@CMD)
	END TRY
	BEGIN CATCH
	  SELECT @DESC_ERRO = ('**Procedure SP_COMPRESS_PARTITION** - ' + ERROR_MESSAGE())
      RAISERROR(@DESC_ERRO, 16, 1)
	END CATCH
    FETCH NEXT FROM C_COMPRESS INTO @CMD, @RANGE
  END
  CLOSE C_COMPRESS
  DEALLOCATE C_COMPRESS
END
GO
select	'GuardAppEvent:Released';
go

--EXEC SP_COMPRESS_PARTITION 3, 'ALL'
--EXEC SP_COMPRESS_PARTITION 3, 'TDWTM_ALOCACAO_DEFINITIVA'