CREATE TABLE #SpaceUsed (name sysname,rows bigint,reserved sysname,data sysname,index_size sysname,unused sysname)

DECLARE @Counter int 
DECLARE @Max int 
DECLARE @Table sysname

SELECT  name, IDENTITY(int,1,1) ROWID 
INTO       #TableCollection 
FROM    sysobjects 
WHERE xtype = 'U' 
ORDER BY lower(name)

SET @Counter = 1 
SET @Max = (SELECT Max(ROWID) FROM #TableCollection)

WHILE (@Counter <= @Max) 
    BEGIN 
        SET @Table = (SELECT name FROM #TableCollection WHERE ROWID = @Counter) 
        INSERT INTO #SpaceUsed 
        EXECUTE sp_spaceused @Table 
        SET @Counter = @Counter + 1 
    END

SELECT * FROM #SpaceUsed

DROP TABLE #TableCollection 
DROP TABLE #SpaceUsed


/*
exec pr_corporativo..sp_tables NULL,NULL,N'pr_corporativo',N'''TABLE'',NULL,NULL'
*/