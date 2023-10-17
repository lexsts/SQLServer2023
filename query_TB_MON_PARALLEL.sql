/****** Script for SelectTopNRows command from SSMS  ******/

SELECT DATA,[background],[running],[sleeping],[suspended],CASE WHEN [runnable] IS NULL THEN 0 ELSE [runnable] END AS runnable, 
'140' AS LIMITE,
[background]+[running]+[sleeping]+[suspended] AS TOTAL
FROM
(SELECT [DATA]
      ,sum([Parallel]) TOTAL
      ,[status]
  FROM [ADM_BDADOS].[dbo].[TB_MON_PARALLEL]
  GROUP BY [DATA],[status]) LINHA
  pivot (sum(TOTAL) for STATUS in ([background],[running],[sleeping],[suspended],[runnable])) colunas
  order by 1