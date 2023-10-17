--GET QUERY_ID FROM QUERY STORE
SELECT q.query_id, qt.query_sql_text
FROM sys.query_store_query_text qt 
INNER JOIN sys.query_store_query q ON 
    qt.query_text_id = q.query_text_id 
--WHERE query_sql_text like N'%ORDER BY ListingPrice DESC%'  
--  AND query_sql_text not like N'%query_store%';


--APPLY THE HINT
EXEC sys.sp_query_store_set_hints @query_id= 39, @query_hints = N'OPTION(USE HINT(''FORCE_LEGACY_CARDINALITY_ESTIMATION''))';