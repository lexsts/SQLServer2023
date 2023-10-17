alter PROCEDURE [dbo].[SP_MANUT_REINDEX]
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CMD VARCHAR(MAX)
	DECLARE @MENSAGEM VARCHAR (MAX)
	DECLARE @DATABASE VARCHAR(255)
	DECLARE @DIASRENTECAO SMALLINT

    /*
    RETEN플O LOG
    */
    SELECT @DIASRENTECAO = CAST(VALOR AS SMALLINT) FROM TB_MANUT_PARAMETROS WHERE PARAMETRO = 'RETENCAO LOG DIAS'
    
    DELETE TB_MANUT_LOG WHERE DATA < DATEADD(DD,-@DIASRENTECAO,GETDATE())

	DECLARE C_DATABASE CURSOR LOCAL FOR 
										  SELECT 
											NAME 
										  FROM 
											MASTER..SYSDATABASES 
										  WHERE
											DATABASEPROPERTYEX(NAME, 'STATUS') = 'ONLINE' AND  
											NAME NOT IN (SELECT BANCO FROM TB_MANUT_EXCECAO_BANCOS)
										  
	OPEN C_DATABASE FETCH NEXT FROM C_DATABASE INTO @DATABASE
	WHILE @@FETCH_STATUS = 0
	BEGIN
	  BEGIN TRY
		  SET @CMD = 'USE "'+ @DATABASE + '" ' + '	
		  	  		  
			DECLARE @TABELA VARCHAR(255)
			DECLARE @INDICE VARCHAR(255)
		    DECLARE @CMD_2 VARCHAR (MAX) 
		    DECLARE @MENSAGEM VARCHAR (MAX)
		    CREATE TABLE #FRAGLIST (
			   OBJECTNAME VARCHAR(255),
			   OBJECTID INT,
			   INDEXNAME VARCHAR(255),
			   INDEXID INT,
			   LVL INT,
			   COUNTPAGES INT,
			   COUNTROWS INT,
			   MINRECSIZE INT,
			   MAXRECSIZE INT,
			   AVGRECSIZE INT,
			   FORRECCOUNT INT,
			   EXTENTS INT,
			   EXTENTSWITCHES INT,
			   AVGFREEBYTES INT,
			   AVGPAGEDENSITY INT,
			   SCANDENSITY DECIMAL (20,5),
			   BESTCOUNT INT,
			   ACTUALCOUNT INT,
			   LOGICALFRAG DECIMAL (20,5),
			   EXTENTFRAG DECIMAL (20,5));
		    
			DECLARE C_DATABASE_2 CURSOR LOCAL FOR 	
												SELECT
												  SCHEMA_NAME(UID) + ''.'' + TB.NAME
												  ,IX.NAME
												FROM
												  SYSOBJECTS TB
												  INNER JOIN SYSINDEXES IX ON TB.ID = IX.ID
												WHERE
												  TB.TYPE = ''U'' AND
												  INDEXPROPERTY(TB.ID,IX.NAME,''ISSTATISTICS'') = 0 AND
												  IX.NAME IS NOT NULL AND
												  IX.ROOT IS NOT NULL
												ORDER BY
												  1,2      
												  
			OPEN C_DATABASE_2 FETCH NEXT FROM C_DATABASE_2 INTO @TABELA, @INDICE 
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
			  BEGIN TRY			  
				  SET @CMD_2 = ''
				  DECLARE @FRAG SMALLINT
				  DECLARE @MAXFRAG SMALLINT
				  
				  EXEC [ADM_BDADOS].[DBO].[SP_MANUT_RET_FRAG] ''''''+DB_NAME()+'''''',''''''+@TABELA+'''''',''''''+@INDICE+''''''
				  
				  SELECT 
				    @FRAG = LOGICALFRAG 
				  FROM 
				    #FRAGLIST 
				  WHERE 
				    OBJECTID = OBJECT_ID(''''''+@TABELA+'''''')
				    AND INDEXNAME = ''''''+@INDICE+''''''
				  
				  SELECT
				    @MAXFRAG = CAST(VALOR AS SMALLINT) 
				  FROM 
				    ADM_BDADOS..TB_MANUT_PARAMETROS 
				  WHERE 
				    PARAMETRO = ''''PORCENTAGEM FRAGMENTACAO''''
				  
				  IF NOT EXISTS (SELECT 
				                   ID 
				                 FROM 
				                   ADM_BDADOS..TB_MANUT_EXCECAO_INDICES 
				                 WHERE 
				                   BANCO = DB_NAME() 
				                   AND TABELA = ''''''+@TABELA+'''''' 
				                   AND INDICE = ''''''+@INDICE+'''''') AND
				                   @FRAG >= @MAXFRAG
				  BEGIN
				    
					DBCC INDEXDEFRAG(0,''''''+@TABELA+'''''',''''''+@INDICE+'''''') WITH NO_INFOMSGS
					
					INSERT INTO ADM_BDADOS..TB_MANUT_LOG (
						BANCO 
						,TABELA
						,INDICE
						,DATA
						,LOG_MENSAGEM    
				    ) 
				    VALUES (
						DB_NAME()
						,''''''+@TABELA+''''''
						,''''''+@INDICE+''''''
						,GETDATE()
						,''''INDICE RECRIADO COM SUCESSO''''
					)
				  END
				  ''				  
				  EXEC (@CMD_2)

				  
			  END TRY
			  
			  BEGIN CATCH
			  
				PRINT ''ERRO NA RECRIA플O DO INDICE: ''''''+@INDICE+'''''' DA TABELA: ''''''+@TABELA+'''''' DO BANCO: ''+ DB_NAME()
				PRINT ERROR_MESSAGE ()
				SELECT @MENSAGEM = ERROR_MESSAGE()
				INSERT INTO ADM_BDADOS..TB_MANUT_LOG (
					BANCO 
					,TABELA
					,INDICE
					,DATA
					,LOG_MENSAGEM    
				) 
				VALUES (
					DB_NAME()
					,''''+@TABELA+''''
					,''''+@INDICE+''''
					,GETDATE()
					,ERROR_MESSAGE()
					)
		        RAISERROR (@MENSAGEM,18,1)
			  END CATCH			    
			  FETCH NEXT FROM C_DATABASE_2 INTO @TABELA, @INDICE
			END
			CLOSE C_DATABASE_2
			DEALLOCATE C_DATABASE_2
			DROP TABLE #FRAGLIST
		  ' 
		  
		  EXEC (@CMD)
	  END TRY
	  BEGIN CATCH
	    SELECT @MENSAGEM = ERROR_MESSAGE()
	    
		PRINT 'ERRO NA RECRIA플O DOS INDICES DO BANCO: '+@DATABASE
		INSERT INTO TB_MANUT_LOG (
			BANCO 
			,TABELA
			,INDICE
			,DATA
			,LOG_MENSAGEM    
		) 
		VALUES (@DATABASE, NULL, NULL, GETDATE(), 'ERRO NA RECRIA플O DOS INDICES DO BANCO: '+@DATABASE)
		INSERT INTO TB_MANUT_LOG (
			BANCO 
			,TABELA
			,INDICE
			,DATA
			,LOG_MENSAGEM    
		) 
		VALUES (@DATABASE, NULL, NULL, GETDATE(), ERROR_MESSAGE())
		
    	RAISERROR (@MENSAGEM,18,1)
    	  
	  END CATCH
	  FETCH NEXT FROM C_DATABASE INTO @DATABASE
	END
	CLOSE C_DATABASE
	DEALLOCATE C_DATABASE
END


