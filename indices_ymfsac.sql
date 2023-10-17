USE [YMFSAC_CBLC]
GO
CREATE NONCLUSTERED INDEX IE01_RV_MOV
ON [dbo].[RV_MOV] ([DATAMOV],[COMPRAVENDA],[VALOR],[DT_PREVLIQ])
INCLUDE ([CODCLI],[CODPAP])
GO

USE [YMFSAC_CBLC]
GO
CREATE NONCLUSTERED INDEX IE01_SAC_RF_POS
ON [dbo].[SAC_RF_POS] ([DT],[VL_LIQ_POS])
INCLUDE ([RFOP_CD])
GO

USE [YMFSAC_CBLC]
GO
CREATE NONCLUSTERED INDEX IE01_SAC_CL_PATR
ON [dbo].[SAC_CL_PATR] ([DT],[VL_PATRLIQTOT])
INCLUDE ([CLCLI_CD])
GO