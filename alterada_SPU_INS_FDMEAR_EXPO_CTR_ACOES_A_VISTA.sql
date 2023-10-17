USE [DM_RISCO]
GO

/****** Object:  StoredProcedure [dbo].[SPU_INS_FDMEAR_EXPO_CTR_ACOES_A_VISTA]    Script Date: 06/07/2023 23:11:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--/************************************************************************************************  
-- Objetivo : Realiza insert da tabela FDMEAR_EXPOSICAO_CONTRATO.
-- ------------------------------------------------------------------------------   
-- Autor   : Patrícia Pontes (TDW)
-- Criação : 29/07/2016
-- ------------------------------------------------------------------------------   
-- Alteração 01 : 27/10/2016
-- Responsável: Cynthia Santos (TDW)
-- Motivo     : JIRA 429 (Inclusão de Debentures)
-- ------------------------------------------------------------------------------   
-- Alteração 02 : 07/10/2016  
-- Responsável: Bruno Ferreira
-- Motivo     : DIGRPT-449
-- ------------------------------------------------------------------------------   
-- Alteração 03 : 07/02/2017
-- Responsável: Cynthia Santos (TDW)
-- Motivo     : DIGRPT-554
-- ------------------------------------------------------------------------------   
-- Alteração 04 : 20/03/2017
-- Responsável: Cynthia Santos (TDW)
-- Motivo     : DIGRPT-587
-- ------------------------------------------------------------------------------   
-- Alteração 05 : 08/02/2019  
-- Responsável: Diego Américo Alves	
-- Motivo     : DIGRPT-664  
-- ------------------------------------------------------------------------------   
-- Alteração 06 : 26/09/2022
-- Responsável: mbufon
-- Motivo     : DIGRPT-880  
--************************************************************************************************/  
-- EXEC [dbo].SPU_INS_FDMEAR_EXPO_CTR_ACOES_A_VISTA '2016-08-31', -1

CREATE PROCEDURE [dbo].[SPU_INS_FDMEAR_EXPO_CTR_ACOES_A_VISTA]
(
   @dt_base_processamento datetime = null
   ,@p_cod_log_execucao	int = NULL
)
AS
BEGIN

DECLARE 
		-- Variaveis para log
		@p_nome_componente				varchar(100),
		@p_desc_comando					varchar(max),
		@p_data_inicio					datetime,
		@p_data_fim						datetime,
		@p_qte_linha_afetada			int,	
		-- Variaveis de controle
		@data_carga						smalldatetime

	-- Inicializa variaveis
	SET @p_nome_componente 	= '[DBO].[SPU_INS_FDMEAR_EXPO_CTR_ACOES_A_VISTA]'
	SET @p_data_inicio = GETDATE();  


DECLARE @VL_INDICADOR DECIMAL (19, 7) = 1.0,
        @VL_CONS_CEM_MIL DECIMAL (7, 1) = 100000.0,
		@VL_CONS_252 DECIMAL (4,1) = 252.0,
		@VL_CONS_360 DECIMAL (4,1) = 360.0,
		@VL_CONS_100 DECIMAL (4,1) = 100.0		

---------------- Tabelas Temporárias ----------------
--INDICADOR_ECONOMICO_CTR_AUX
IF OBJECT_ID('tempdb..##INDICADOR_ECONOMICO_CTR_AUX') IS NOT NULL
BEGIN
   DROP TABLE ##INDICADOR_ECONOMICO_CTR_AUX
END

CREATE TABLE ##INDICADOR_ECONOMICO_CTR_AUX
(
	cod_moeda VARCHAR(3),
	val_ind_economico_dolar_ptax decimal(28,20)
)
 
--VDMEAR_POSICAO_MERCADO_A_VISTA_AUX
IF OBJECT_ID('tempdb..##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX') IS NOT NULL
BEGIN
   DROP TABLE ##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX
END

CREATE TABLE ##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX
(
	cod_instrumento VARCHAR(500)
)

--TDWGPS_PRECO_AJUSTE_AUX
IF OBJECT_ID('tempdb..##TDWGPS_PRECO_AJUSTE_CTR_AUX') IS NOT NULL
BEGIN
   DROP TABLE ##TDWGPS_PRECO_AJUSTE_CTR_AUX
END

CREATE TABLE ##TDWGPS_PRECO_AJUSTE_CTR_AUX
(
	data_referencia_preco_ajuste date,
	cod_instrumento varchar(500),
	cod_origem_identificacao_instrumento varchar(10),
	cod_bolsa_valor varchar(100),
	cod_situacao_preco_ajuste char(1),
	cod_lote_calculo_preco_ajuste varchar(8),
	dthr_calculo_preco_ajuste datetime2(7),
	ind_valor_arbitrado smallint,
	val_taxa_preco_ajuste decimal(28, 20),
	val_preco_ajuste decimal(38, 20),
	val_dolar_ponto_basico decimal(38, 20)
)

---------------- Fim - Tabelas Temporárias ----------------

--------------------  DIGRPT-664 --------------------

INSERT INTO ##INDICADOR_ECONOMICO_CTR_AUX
SELECT 
	cod_mercadoria, 
	val_indicador_economico
  FROM [dm].[FNC_SEL_INDICADOR_ECONOMICO] 
	   (@dt_base_processamento,
		'Codigo Instrumento - PTAX',
		'Codigo Origem Identificacao Instrumento - PTAX',
		'Codigo Bolsa Valor - PTAX',
		'Codigo Dias de Liquidacao - PTAX',
		'USD'
		)

-- Número de linhas afetadas
SET @p_qte_linha_afetada = @@ROWCOUNT
-- Estatistica de processamento
If not @p_cod_log_execucao is null
	begin
		SET @p_data_fim			 = GETDATE()
		SET @p_desc_comando      = @p_nome_componente + ' 01/01 - ##INDICADOR_ECONOMICO_CTR_AUX - Busca PTAX ' + CONVERT(varchar,@dt_base_processamento,112)

		exec aud.SPU_INS_ESTATISTICA @p_cod_log_execucao, @p_desc_comando, 
										@p_qte_linha_afetada, @p_data_inicio, @p_data_fim
	end
	
--------------------  DIGRPT-880 --------------------
--##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX
INSERT INTO ##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX
	SELECT
		DISTINCT DM.VDMEAR_POSICAO_MERCADO_A_VISTA.cod_instrumento
	FROM
		DM.VDMEAR_POSICAO_MERCADO_A_VISTA
	WHERE 
		DM.VDMEAR_POSICAO_MERCADO_A_VISTA.DATA_REFERENCIA = @dt_base_processamento
	AND 
		DM.VDMEAR_POSICAO_MERCADO_A_VISTA.COD_MODALIDADE_NEGOCIACAO in (20, 21) --DIGRPT-888

-- Número de linhas afetadas
SET @p_qte_linha_afetada = @@ROWCOUNT
-- Estatistica de processamento
If not @p_cod_log_execucao is null
	begin
		SET @p_data_fim			 = GETDATE()
		SET @p_desc_comando      = @p_nome_componente + ' 01/03 - ##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX - Busca Distinct(cod_instrumento) ' + CONVERT(varchar,@dt_base_processamento,112)

		exec aud.SPU_INS_ESTATISTICA @p_cod_log_execucao, @p_desc_comando, 
										@p_qte_linha_afetada, @p_data_inicio, @p_data_fim
	end

--##TDWGPS_PRECO_AJUSTE_CTR_AUX - Todos os instrumentos BVMF
INSERT INTO ##TDWGPS_PRECO_AJUSTE_CTR_AUX
           ([data_referencia_preco_ajuste]
           ,[cod_instrumento]
           ,[cod_origem_identificacao_instrumento]
           ,[cod_bolsa_valor]
           ,[cod_situacao_preco_ajuste]
           ,[cod_lote_calculo_preco_ajuste]
           ,[dthr_calculo_preco_ajuste]
           ,[ind_valor_arbitrado]
           ,[val_taxa_preco_ajuste]
           ,[val_preco_ajuste])
	SELECT 
		[data_referencia_preco_ajuste]
		,[cod_instrumento]
		,[cod_origem_identificacao_instrumento]
		,[cod_bolsa_valor]
		,[cod_situacao_preco_ajuste]
		,[cod_lote_calculo_preco_ajuste]
		,[dthr_calculo_preco_ajuste]
		,[ind_valor_arbitrado]
		,[val_taxa_preco_ajuste]
		,[val_preco_ajuste]
	FROM
		DM.VDMEAR_PRECO_AJUSTE
	WHERE DM.VDMEAR_PRECO_AJUSTE.data_referencia_preco_ajuste = @dt_base_processamento
	
-- Número de linhas afetadas
SET @p_qte_linha_afetada = @@ROWCOUNT
-- Estatistica de processamento
If not @p_cod_log_execucao is null
	begin
		SET @p_data_fim			 = GETDATE()
		SET @p_desc_comando      = @p_nome_componente + ' 02/03 - ##TDWGPS_PRECO_AJUSTE_CTR_AUX - Todos os instrumentos BVMF ' + CONVERT(varchar,@dt_base_processamento,112)

		exec aud.SPU_INS_ESTATISTICA @p_cod_log_execucao, @p_desc_comando, 
										@p_qte_linha_afetada, @p_data_inicio, @p_data_fim
	end
	
--##TDWGPS_PRECO_AJUSTE_CTR_AUX - Somente instrumentos do mercado vista
INSERT INTO ##TDWGPS_PRECO_AJUSTE_CTR_AUX
           ([data_referencia_preco_ajuste]
           ,[cod_instrumento]
           ,[cod_origem_identificacao_instrumento]
           ,[cod_bolsa_valor]
           ,[cod_situacao_preco_ajuste]
           ,[cod_lote_calculo_preco_ajuste]
           ,[dthr_calculo_preco_ajuste]
           ,[ind_valor_arbitrado]
           ,[val_taxa_preco_ajuste]
           ,[val_preco_ajuste])
	SELECT 
		[data_referencia_preco_ajuste]
		,TB_GPSPA.[cod_instrumento]
		,[cod_origem_identificacao_instrumento]
		,'SLTO' AS [cod_bolsa_valor]
		,[cod_situacao_preco_ajuste]
		,[cod_lote_calculo_preco_ajuste]
		,[dthr_calculo_preco_ajuste]
		,[ind_valor_arbitrado]
		,[val_taxa_preco_ajuste]
		,[val_preco_ajuste]
	FROM
		dm.VDMEAR_PRECO_AJUSTE AS TB_GPSPA
	INNER JOIN
		##VDMEAR_POSICAO_MERCADO_A_VISTA_CTR_AUX AS TB_POSVISTA
	ON
		TB_GPSPA.[cod_instrumento] = TB_POSVISTA.cod_instrumento
	WHERE TB_GPSPA.data_referencia_preco_ajuste = @dt_base_processamento

-- Número de linhas afetadas
SET @p_qte_linha_afetada = @@ROWCOUNT
-- Estatistica de processamento
If not @p_cod_log_execucao is null
	begin
		SET @p_data_fim			 = GETDATE()
		SET @p_desc_comando      = @p_nome_componente + ' 03/03 - ##TDWGPS_PRECO_AJUSTE_CTR_AUX - SLTO Instrumentos vista ' + CONVERT(varchar,@dt_base_processamento,112)

		exec aud.SPU_INS_ESTATISTICA @p_cod_log_execucao, @p_desc_comando, 
										@p_qte_linha_afetada, @p_data_inicio, @p_data_fim
	end

--Novo indice - DBA
CREATE NONCLUSTERED INDEX IE01_TMP_TDWGPS_PRECO_AJUSTE
ON [dbo].[##TDWGPS_PRECO_AJUSTE_CTR_AUX] ([data_referencia_preco_ajuste],[cod_instrumento],[cod_origem_identificacao_instrumento],[cod_bolsa_valor],[cod_situacao_preco_ajuste])
INCLUDE ([val_preco_ajuste])

-- PRINT 'Ações a vista'
-------------------- Ações a vista -----------------------
INSERT INTO etl.FDMEAR_EXPOSICAO_CONTRATO
           (data_pregao
           ,num_sk_participante
           ,num_sk_membro_compensacao
           ,num_sk_conta
           ,num_sk_investidor
           ,num_sk_instrumento
           ,cod_bolsa_valor
           ,num_sequencial_instrumento
           ,cod_origem_identificacao_instrumento
		   ,cod_membro_compensacao
		   ,cod_operacional_participante
		   ,num_identificacao_conta
		   ,num_sequencial_entidade_investidor
           ,cod_atividade_economica_primaria
           ,num_documento_cpf_cnpj
           ,nome_completo_razao_social
           ,cod_atividade_economica_anexo
           ,nome_atividade_economica_anexo
           ,cod_atividade_economica_primaria_membro_compensacao
           ,num_documento_cpf_cnpj_membro_compensacao
           ,nome_completo_razao_social_membro_compensacao
           ,cod_atividade_economica_anexo_membro_compensacao
           ,nome_atividade_economica_anexo_membro_compensacao
           ,cod_atividade_economica_primaria_investidor
           ,num_documento_cpf_cnpj_investidor
           ,nome_completo_razao_social_investidor
           ,cod_atividade_economica_anexo_investidor
           ,nome_atividade_economica_anexo_investidor
           ,qte_encerrada
           ,tam_contrato
           ,val_premio_opcao
           ,qte_dia_util_vencimento_contrato
           ,qte_dia_corrido_vencimento_contrato
           ,val_ind_economico_dolar_ptax
           ,val_taxa_dolar_curva_interpolada_pre
           ,val_taxa_dolar_curva_interpolada_cupom
           ,val_valor_nocional_atualizado
           ,val_delta
           ,cod_modalidade_negociacao
           ,cod_segmento
           ,cod_categoria_instrumento
           ,nome_modalidade_negociacao_auxiliar
           ,cod_mercadoria
           ,data_vencimento_contrato
           ,num_serie_instrumento
           ,num_sequencial_instrumento_ativo_objeto
           ,cod_serie
           ,val_mtm_otc
           ,val_preco_negocio_debenture
           ,val_preco_negocio_contrato_btb
           ,val_preco_ajuste
           ,val_maior_strike_box
           ,val_menor_strike_box
           ,val_exposicao_contrato
           ,cod_tipo_opcao
           ,val_exercicio_opcao
           ,val_sinal_box
		   ,cod_natureza_operacao
		   )

SELECT MERC.data_referencia AS data_pregao 
       , ISNULL(PART.num_sk_participante, -2) AS num_sk_participante
       , ISNULL(MC.num_sk_participante, -2) AS num_sk_membro_compensacao
       , ISNULL(CTA.num_sk_conta, -2) AS num_sk_conta
       , ISNULL(INV.num_sk_investidor, -2) AS num_sk_investidor
       , ISNULL(INSTR.num_sk_instrumento, -2) AS num_sk_instrumento
       , MERC.cod_bolsa_valor
       , MERC.cod_instrumento AS num_sequencial_instrumento --INSTR.num_sequencial_instrumento
       , MERC.cod_origem_identificacao_instrumento
	   , MERC.cod_membro_compensacao AS cod_membro_compensacao
	   , MERC.cod_participante AS cod_participante
	   , MERC.num_identificacao_conta AS num_identificacao_conta
	   , ISNULL(INV.num_sequencial_entidade, '-2') AS num_sequencial_entidade_investidor
       , ISNULL(PART.cod_atividade_economica_primaria, '-2') AS cod_atividade_economica_primaria
       , ISNULL(PART.num_documento_cpf_cnpj, '-2') AS num_documento_cpf_cnpj
       , ISNULL(PART.nome_completo_razao_social, 'Sem Informação') AS nome_completo_razao_social
       , ISNULL(PART.cod_atividade_economica_anexo, '-2') AS cod_atividade_economica_anexo
       , ISNULL(PART.nome_atividade_economica_anexo, 'Sem Informação') AS nome_atividade_economica_anexo
       , ISNULL(MC.cod_atividade_economica_primaria, '-2') AS cod_atividade_economica_primaria_mc
       , ISNULL(MC.num_documento_cpf_cnpj, '-2') AS num_documento_cpf_cnpj_mc
       , ISNULL(MC.nome_completo_razao_social, 'Sem Informação') AS nome_completo_razao_social_mc
       , ISNULL(MC.cod_atividade_economica_anexo, '-2') AS cod_atividade_economica_anexo_mc
       , ISNULL(MC.nome_atividade_economica_anexo, 'Sem Informação') AS nome_atividade_economica_anexo_mc
       , ISNULL(INV.cod_atividade_economica_primaria, '-2') AS cod_atividade_economica_primaria_investidor
       , ISNULL(INV.num_documento_cpf_cnpj, '-2') AS num_documento_cpf_cnpj_investidor
       , ISNULL(INV.nome_completo_razao_social, 'Sem Informação') AS nome_completo_razao_social_investidor
       , ISNULL(INV.cod_atividade_economica_anexo, '-2') AS cod_atividade_economica_anexo_investidor
       , ISNULL(INV.nome_atividade_economica_anexo, 'Sem Informação') AS nome_atividade_economica_anexo_investidor 
       , SUM (MERC.qte_compra - MERC.qte_venda) AS qte_encerrada
       , CASE WHEN INSTR.fat_cotacao = 0 THEN NULL 
	     ELSE 1.0 / INSTR.fat_cotacao 
		 END AS tam_contrato
       , NULL AS val_premio_opcao
       , DT_VEN.qte_dia_util - DT_REF.qte_dia_util AS qte_dia_util_vencimento_contrato
       , DT_VEN.qte_dia_corrido - DT_REF.qte_dia_corrido AS qte_dia_corrido_vencimento_contrato
       , INEC.val_ind_economico_dolar_ptax
       , NULL AS val_taxa_dolar_curva_interpolada_pre
       , NULL AS val_taxa_dolar_curva_interpolada_cupom
       , NULL AS val_valor_nocional_atualizado
	   , NULL AS val_delta
       , MERC.cod_modalidade_negociacao
       , INSTR.cod_segmento
       , INSTR.cod_categoria_instrumento
       , 'VISTA' AS nome_modalidade_negociacao_auxiliar
       , CASE WHEN MERC.cod_modalidade_negociacao in (20, 21) THEN LEFT(MERC.cod_negociacao, LEN(MERC.cod_negociacao) - 1) --DIGRPT-888
	          ELSE MERC.cod_negociacao
	     END AS cod_mercadoria
       , MERC.data_liquidacao
       , INSTR.num_serie_instrumento 
       , INSTR.num_sequencial_instrumento_ativo_objeto
       , INSTR.cod_serie
       , NULL AS val_mtm_otc
       , NULL AS val_preco_negocio_debenture
       , NULL AS val_preco_negocio_contrato_btb
       , PRAJ.val_preco_ajuste 
       , NULL AS val_maior_strike_box
       , NULL AS val_menor_strike_box
       , SUM (
	   (MERC.qte_compra - MERC.qte_venda) -- Q
	   * (CASE WHEN INSTR.fat_cotacao = 0 THEN NULL ELSE 1.0 / INSTR.fat_cotacao END) -- Tam
	   * (CASE WHEN MERC.cod_modalidade_negociacao = 5 THEN (MERC.val_total_compra-MERC.val_total_venda)/NULLIF((MERC.qte_compra-MERC.qte_venda),0) ELSE PRAJ.val_preco_ajuste END) -- PA
	    * (CASE WHEN INSTR.cod_moeda = 'USD' THEN INEC.val_ind_economico_dolar_ptax ELSE 1.0 END ) -- TX
	   )AS val_exposicao_contrato
       , NULL AS cod_tipo_opcao
       , NULL AS val_exercicio_opcao
       , NULL AS val_sinal_box
	   , CASE WHEN SUM (MERC.qte_compra - MERC.qte_venda) >= 0 THEN 'C' ELSE 'V' END AS cod_natureza_operacao

  FROM [dm].[VDMEAR_POSICAO_MERCADO_A_VISTA] AS MERC WITH (NOLOCK)

  --LEFT JOIN dm.VDMEAR_PRECO_AJUSTE AS PRAJ WITH (NOLOCK) --DIGRPT-880
  LEFT JOIN ##TDWGPS_PRECO_AJUSTE_CTR_AUX AS PRAJ WITH (NOLOCK)
    ON MERC.cod_instrumento = PRAJ.cod_instrumento
   AND MERC.cod_bolsa_valor = PRAJ.cod_bolsa_valor
   AND MERC.cod_origem_identificacao_instrumento = PRAJ.cod_origem_identificacao_instrumento
   AND MERC.data_referencia = PRAJ.data_referencia_preco_ajuste 
   AND PRAJ.cod_situacao_preco_ajuste = 'F'

  LEFT JOIN DM.DDMEAR_CONTA_CONSOLIDADA AS CTA WITH (NOLOCK) 
    ON MERC.cod_participante = CTA.cod_operacional_participante
   AND MERC.num_identificacao_conta = CTA.num_identificacao_conta
   AND CTA.data_inicio_vigencia <= @dt_base_processamento 
   AND ( CTA.data_fim_vigencia > @dt_base_processamento OR CTA.data_fim_vigencia IS NULL )

  LEFT JOIN DM.DDMEAR_PARTICIPANTE_CONSOLIDADO AS PART WITH (NOLOCK)
    ON PART.cod_operacional_participante = CAST(MERC.cod_participante as varchar(6))
   AND PART.data_inicio_vigencia <= @dt_base_processamento
   AND ( PART.data_fim_vigencia > @dt_base_processamento OR PART.data_fim_vigencia IS NULL )
  
  LEFT JOIN DM.DDMEAR_PARTICIPANTE_CONSOLIDADO AS MC WITH (NOLOCK)
    ON MC.cod_operacional_participante = MERC.cod_membro_compensacao
   AND MC.data_inicio_vigencia <= @dt_base_processamento
   AND ( MC.data_fim_vigencia > @dt_base_processamento OR MC.data_fim_vigencia IS NULL )
  
  LEFT JOIN DM.DDMEAR_INVESTIDOR AS INV WITH (NOLOCK)
    ON INV.num_sk_investidor = CTA.num_sk_investidor
  
  LEFT JOIN DM.DDMEAR_INSTRUMENTO AS INSTR WITH (NOLOCK) 
    ON MERC.cod_instrumento = INSTR.cod_instrumento
   AND MERC.cod_origem_identificacao_instrumento = INSTR.cod_origem_identificacao_instrumento
   AND MERC.cod_bolsa_valor = INSTR.cod_bolsa_valor
   AND INSTR.data_inicio_vigencia <= @dt_base_processamento
   AND ( INSTR.data_fim_vigencia > @dt_base_processamento OR INSTR.data_fim_vigencia IS NULL)

  LEFT JOIN ##INDICADOR_ECONOMICO_CTR_AUX AS INEC WITH (NOLOCK)
    ON INSTR.cod_moeda = INEC.cod_moeda

  LEFT JOIN DM.VDMEAR_CALENDARIO DT_REF WITH (NOLOCK)
    ON DT_REF.data_calendario = MERC.data_referencia

  LEFT JOIN DM.VDMEAR_CALENDARIO DT_VEN WITH (NOLOCK)
    ON DT_VEN.data_calendario = INSTR.data_vencimento_contrato

 WHERE MERC.data_referencia = @dt_base_processamento
   AND MERC.cod_modalidade_negociacao IN (8, 10, 20, 21, 5) --DIGRPT-888

 GROUP BY MERC.data_referencia 
       , ISNULL(PART.num_sk_participante, -2) 
       , ISNULL(MC.num_sk_participante, -2) 
       , ISNULL(CTA.num_sk_conta, -2) 
       , ISNULL(INV.num_sk_investidor, -2) 
       , ISNULL(INSTR.num_sk_instrumento, -2) 
       , MERC.cod_bolsa_valor
       , MERC.cod_instrumento 
       , MERC.cod_origem_identificacao_instrumento
       , ISNULL(PART.cod_atividade_economica_primaria, '-2') 
       , ISNULL(PART.num_documento_cpf_cnpj, '-2') 
       , ISNULL(PART.nome_completo_razao_social, 'Sem Informação') 
       , ISNULL(PART.cod_atividade_economica_anexo, '-2') 
       , ISNULL(PART.nome_atividade_economica_anexo, 'Sem Informação') 
       , ISNULL(MC.cod_atividade_economica_primaria, '-2') 
       , ISNULL(MC.num_documento_cpf_cnpj, '-2') 
       , ISNULL(MC.nome_completo_razao_social, 'Sem Informação') 
       , ISNULL(MC.cod_atividade_economica_anexo, '-2') 
       , ISNULL(MC.nome_atividade_economica_anexo, 'Sem Informação') 
	   , ISNULL(INV.num_sequencial_entidade, '-2')
       , ISNULL(INV.cod_atividade_economica_primaria, '-2') 
       , ISNULL(INV.num_documento_cpf_cnpj, '-2') 
       , ISNULL(INV.nome_completo_razao_social, 'Sem Informação') 
       , ISNULL(INV.cod_atividade_economica_anexo, '-2') 
       , ISNULL(INV.nome_atividade_economica_anexo, 'Sem Informação') 
	   , INEC.val_ind_economico_dolar_ptax
       , INSTR.cod_moeda
	   , MERC.cod_modalidade_negociacao
       , INSTR.cod_segmento
	   , INSTR.fat_cotacao
       , INSTR.cod_categoria_instrumento       
       , CASE WHEN MERC.cod_modalidade_negociacao in (20, 21) THEN LEFT(MERC.cod_negociacao, LEN(MERC.cod_negociacao) - 1) --DIGRPT-888
	          ELSE MERC.cod_negociacao
	     END 
       , MERC.data_liquidacao
       , INSTR.num_serie_instrumento 
       , INSTR.num_sequencial_instrumento_ativo_objeto
       , INSTR.cod_serie       
	   , PRAJ.val_preco_ajuste 
	   , MERC.cod_membro_compensacao 
	   , MERC.cod_participante 
	   , MERC.num_identificacao_conta 
	   , DT_REF.qte_dia_util
	   , DT_VEN.qte_dia_util
	   , DT_REF.qte_dia_corrido
	   , DT_VEN.qte_dia_corrido
	
	HAVING SUM (MERC.qte_compra - MERC.qte_venda) <> 0
	OPTION (LOOP JOIN)


-- Número de linhas afetadas
SET @p_qte_linha_afetada = @@ROWCOUNT
-- Estatistica de processamento
If not @p_cod_log_execucao is null
	begin
		SET @p_data_fim			 = GETDATE()
		SET @p_desc_comando      = @p_nome_componente + ' 01/01 - etl.FDMEAR_EXPOSICAO_CONTRATO - Inclusao de Acoes a Vista ' + CONVERT(varchar,@dt_base_processamento,112)

		exec aud.SPU_INS_ESTATISTICA @p_cod_log_execucao, @p_desc_comando, 
										@p_qte_linha_afetada, @p_data_inicio, @p_data_fim
	end

-------------------- Fim - Ações a vista -----------------------

END
GO

