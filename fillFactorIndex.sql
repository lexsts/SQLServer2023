-- 1.) Sys.Indexes catalog view to know the Fill Factor value –- of particular Index
--find fill factor value in index
SELECT 
	OBJECT_NAME(OBJECT_ID) AS TableName
	,Name as IndexName
	,Type_Desc
	,Fill_Factor
FROM 
	sys.indexes
WHERE
	--ommiting HEAP table by following condition therefore
	--it only displays clustered and nonclustered index details
	type_desc<>'HEAP'


--2.) Sys.Configurations catalog view to know the default Fill -- Factor value of serverfind default value of fill factor in -- database
SELECT 
	Description
	,Value_in_use
FROM 
	sys.configurations
WHERE 
	Name ='fill factor (%)' 







--altering Index for FillFactor 80%
ALTER INDEX [idx_refno] ON [ordDemo]
REBUILD PARTITION=ALL WITH (FILLFACTOR= 80)
GO
-- If there is a need to change the default value of Fill 
-- Factor at server level, have a use of following TSQL

--setting default value server wide for Fill Factor

--turning on advanced configuration option
Sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO

--setting up default value for fill factor
sp_configure 'fill factor', 90
GO
RECONFIGURE
GO



