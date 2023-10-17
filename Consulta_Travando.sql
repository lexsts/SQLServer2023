--Quando o Roberto/Jose mandarem email de Consulta Discoverer travando basta rodar este comando na base do MIDAS(SAOSHDBP0064)
--
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname=>'MIDAS', tabname=>'TBMD_OPER', estimate_percent=>dbms_stats.auto_sample_size, cascade=>true);