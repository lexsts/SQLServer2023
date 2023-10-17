drop table #stats_with_stream
go

 CREATE TABLE #stats_with_stream
(
       stream VARBINARY(MAX) NOT NULL
       , rows INT NOT NULL
       , pages INT NOT NULL
);
go

INSERT INTO #stats_with_stream --SELECT * FROM #stats_with_stream
EXEC ('DBCC SHOW_STATISTICS (N''SI_DW.stg.[ADWCONTA_CONSOLIDADA_D0]'',IC01_ADWCONTA_CONSOLIDADA_D0 )
  WITH STATS_STREAM,NO_INFOMSGS');

    DECLARE @sql NVARCHAR(MAX);
SET @sql = (SELECT 'UPDATE STATISTICS SI_DW.stg.[ADWCONTA_CONSOLIDADA_D0](IC01_ADWCONTA_CONSOLIDADA_D0) WITH
STATS_STREAM = 0x' + CAST('' AS XML).value('xs:hexBinary(sql:column("stream"))',
'NVARCHAR(MAX)') FROM #stats_with_stream );


PRINT (@sql);
