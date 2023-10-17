--following query will show you which index is never used
SELECT
      ind.Index_id,
      obj.Name as TableName,
      ind.Name as IndexName,
      ind.Type_Desc,
      indUsage.user_seeks,
      indUsage.user_scans,
      indUsage.user_lookups,
      indUsage.user_updates,
      indUsage.last_user_seek,
      indUsage.last_user_scan,
      'drop index [' + ind.name + '] ON [' + obj.name + ']' as DropIndexCommand
FROM
	Sys.Indexes as ind 
JOIN 
	Sys.Objects as obj 
ON 
	ind.object_id=obj.Object_ID
LEFT JOIN  
	sys.dm_db_index_usage_stats indUsage
ON
	ind.object_id = indUsage.object_id
AND 
	ind.Index_id=indUsage.Index_id
WHERE
    ind.type_desc<>'HEAP' and obj.type<>'S'
AND 
	objectproperty(obj.object_id,'isusertable') = 1
AND 
	(isnull(indUsage.user_seeks,0)=0 
AND 
	isnull(indUsage.user_scans,0)=0 
AND
	isnull(indUsage.user_lookups,0)=0)
ORDER BY 
	obj.name,ind.Name
GO

