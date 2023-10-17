SELECT 'ALTER INDEX ALL ON ' + A.NAME + ' REBUILD;', -- WITH(ONLINE = ON), esta op��o gera erro para alguns tipos de �ndices
	   'UPDATE STATISTICS ' + A.NAME + ' WITH FULLSCAN' + CASE A.TYPE WHEN 'V' THEN ', NORECOMPUTE;' ELSE ';' END, 
	A.*
  FROM SYS.OBJECTS A
 WHERE A.TYPE IN ('U', 'V')
   AND A.NAME NOT LIKE 'sys%'
ORDER BY A.NAME;