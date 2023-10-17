declare   @dt_base_processamento datetime = null
		,@p_cod_log_execucao	int = NULL,

		@p_nome_componente				varchar(100),
		@p_desc_comando					varchar(max),
		@p_data_inicio					datetime,
		@p_data_fim						datetime,
		@p_qte_linha_afetada			int,	
		-- Variaveis de controle
		@data_carga						smalldatetime,
		@ErrorMessage NVARCHAR(4000), 
		@ErrorNumber INT, 
		@ErrorSeverity INT, 
		@ErrorState INT, 
		@ErrorLine INT
		
set @dt_base_processamento='20220315'
set @p_data_inicio='20220315'
set @p_data_fim='20220315'
		
/*  INÍCIO TRECHO PARA TESTES 

	,@dt_base_processamento datetime = null
	,@p_cod_log_execucao	int = NULL
	set @DT_BASE_PROCESSAMENTO = '2016-01-28'
	SET @P_COD_LOG_EXECUCAO = 6900101
	
--	FIM TRECHO PARA TESTES */

		-- Inicializa variaveis
		SET @p_nome_componente 	= 'SPU_INS_TDWCONTA'
		SET @p_data_inicio = GETDATE();  

		/*

		CREATE TABLE dw.#ADWCONTA (
					data_importacao_registro							datetime,
					num_sequencial_conta								int,
					num_identificacao_conta								varchar(15),
					num_sequencial_entidade_participante				int,
					num_sequencial_entidade_investidor					int,
					--num_sequencial_participante							int,
					cod_operacional_participante						varchar(6),
					--sigl_categoria										varchar(4),
					--cod_categoria										smallint,
					--nome_categoria										varchar(60),
					--num_sequencial_situacao_participante				smallint,
					cod_tipo_pessoa										char(2),
					num_documento_identificacao							varchar(23),
					num_documento_identificacao_formatado				varchar(30),
					num_documento_identificacao_cvm						varchar(23),
					nome_completo_razao_social							varchar(150),
					num_sequencial_tipo_conta							smallint,
					nome_tipo_conta										varchar(60),
					num_sequencial_situacao								smallint,
					nome_situacao										varchar(35),
					data_situacao_atual									date,
					dthr_inclusao										datetime2(7),
					dthr_alteracao										datetime2(7),
					cod_motivo_situacao									smallint,
					nome_motivo_situacao								varchar(40),
					ind_conta_propria_participante_negociacao			char(1),
					ind_pessoa_vinculado								char(1),
					num_sequencial_titular_conta_endereco				int,
					cod_atividade_economica_primaria					varchar(20),
					cod_ocupacao										varchar(10),
					num_sequencial_conta_master							int,
					num_sequencial_situacao_vinculo_master				smallint,
					num_identificacao_conta_master						varchar(15),
					num_sequencial_entidade_participante_master			int,
					num_sequencial_entidade_investidor_master			int,
					cod_operacional_participante_master					varchar(6),
					num_documento_identificacao_master					varchar(23),
					num_documento_identificacao_formatado_master		varchar(30),
					nome_completo_razao_social_master					varchar(150),
					cod_tipo_pessoa_master								char(2),
					cod_atividade_economica_primaria_master				varchar(20),
					cod_ocupacao_master									varchar(10),
					num_sequencial_situacao_master						smallint,
					num_sequencial_conta_proximo_nivel					int,
					num_identificacao_conta_proximo_nivel				varchar(15),
					num_sequencial_entidade_participante_proximo_nivel	int,
					num_sequencial_entidade_investidor_proximo_nivel	int,
					cod_operacional_participante_proximo_nivel			varchar(6),
					num_documento_identificacao_proximo_nivel			varchar(23),
					num_documento_identificacao_formatado_proximo_nivel varchar(30),
					num_documento_identificacao_cvm_proximo_nivel		varchar(23),
					nome_completo_razao_social_proximo_nivel			varchar(150),
					cod_tipo_pessoa_proximo_nivel						char(2),
					cod_atividade_economica_primaria_proximo_nivel		varchar(20),
					cod_ocupacao_proximo_nivel							varchar(10),
					num_sequencial_situacao_proximo_nivel				smallint,
					num_sequencial_situacao_vinculo_proximo_nivel		smallint,
					num_sequencial_conta_final							int,
					num_identificacao_conta_final						varchar(15),
					num_sequencial_entidade_participante_final			int,
					num_sequencial_entidade_investidor_final			int,
					cod_operacional_participante_final					varchar(6),
					num_documento_identificacao_final					varchar(23),
					num_documento_identificacao_formatado_final			varchar(30),
					num_documento_identificacao_cvm_final				varchar(23),
					nome_completo_razao_social_final					varchar(150),
					cod_tipo_pessoa_final								char(2),
					cod_atividade_economica_primaria_final				varchar(20),
					cod_ocupacao_final									varchar(10),
					num_sequencial_situacao_final						smallint,
					num_sequencial_situacao_vinculo_final				smallint,
					ind_conta_final										tinyint, 
					ind_cadastro_simplificado							char(1),
					num_sequencial_titular_conta_telefone				int,
					num_sequencial_titular_conta_email					int,
					num_documento_nif									VARCHAR(25),
					num_documento_nif_proximo_nivel						VARCHAR(25),
					num_documento_nif_final								VARCHAR(25),
                    num_sequencial_tipo_entidade_investidor             SMALLINT,
                    num_sequencial_tipo_entidade_investidor_proximo_nivel SMALLINT,
                    num_sequencial_tipo_entidade_investidor_final SMALLINT
				)



		SET @p_data_inicio		= GETDATE();
		
		
		
		
			SET @p_data_inicio = GETDATE();

			/* Tabela Temporária criada devido à existência de Documentos NIF não numéricos abendando no convert */
			
			CREATE TABLE dw.#tmpdocumento 
			(
			 num_sequencial_entidade INT , 
			 cod_tipo_documento	varchar(6),
			 data_calendario date,
			 cod_documento	varchar (23),
			 ind_principal char(1),
			 cod_doc99_char varchar(23)
			)
			
			/*Carregar todos documentos X tipo documentos X Entidades afim de aplicar as regras de controle de duplicidade que seguirão abaixo */
			
			INSERT INTO  dw.#tmpdocumento 
			(
			 num_sequencial_entidade , 
			 cod_tipo_documento	,
			 data_calendario ,
			 cod_documento	,
			 ind_principal ,
			 cod_doc99_char
			)
			select doc.num_sequencial_entidade, doc.cod_tipo_documento, caled.data_calendario, 
			       case when isnumeric(doc.cod_documento) = 1
						then cast(cast(doc.cod_documento as numeric(23)) as varchar(23)) 
						else doc.cod_documento end cod_documento,
				   doc.ind_principal  , 
			       case 
					WHEN doc.cod_tipo_documento = '11' THEN
						CASE WHEN isnumeric(doc.cod_documento) = 1 
								then cast(cast('990000000' + substring(doc.cod_documento,12,6) as numeric(23)) as varchar(23)) 
								else '990000000' + substring(doc.cod_documento,12,6) end 
					ELSE NULL END as cod_doc99_char 

			from hst.TDWCLS_CALENDARIO caled (NOLOCK)
			join hst.TDWICDX_DOCUMENTO doc  (NOLOCK)
				on  exists (select 1 from hst.TDWICDX_TITULAR_CONTA TitularConta (NOLOCK)
							where doc.num_sequencial_entidade = TitularConta.cod_titular_conta 
							and  caled.data_calendario >= TitularConta.data_inicio_vigencia_historico 
							AND (caled.data_calendario < TitularConta.data_fim_vigencia_historico or TitularConta.data_fim_vigencia_historico is null)
							)
				and  caled.data_calendario >= doc.data_inicio_vigencia_historico
				AND (caled.data_calendario <  doc.data_fim_vigencia_historico OR doc.data_fim_vigencia_historico IS NULL)
				and doc.cod_tipo_documento in ('1','2','11','17','18','19','20')
			where caled.data_calendario = @dt_base_processamento
			OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION'))--50SEGUNDOS
			
			/* Insert incluido devido à existência de Documentos NIF não numéricos abendando no convert */
			INSERT INTO  dw.#tmpdocumento 
			(
			 num_sequencial_entidade , 
			 cod_tipo_documento	,
			 data_calendario ,
			 cod_documento	,
			 ind_principal , 
			 cod_doc99_char
			)
			select doc.num_sequencial_entidade, 
				   doc.cod_tipo_documento, 
				   caled.data_calendario, 
			       doc.cod_documento,
				   doc.ind_principal ,
				   null

			from hst.TDWCLS_CALENDARIO caled (NOLOCK)
			join hst.TDWICDX_DOCUMENTO doc  (NOLOCK)
				on  exists (select 1 from hst.TDWICDX_TITULAR_CONTA TitularConta (NOLOCK)
							where doc.num_sequencial_entidade = TitularConta.cod_titular_conta 
							and  caled.data_calendario >= TitularConta.data_inicio_vigencia_historico 
							AND (caled.data_calendario < TitularConta.data_fim_vigencia_historico or TitularConta.data_fim_vigencia_historico is null)
							)
				and  caled.data_calendario >= doc.data_inicio_vigencia_historico
				AND (caled.data_calendario <  doc.data_fim_vigencia_historico OR doc.data_fim_vigencia_historico IS NULL)
				and doc.cod_tipo_documento in ('45')
			where caled.data_calendario = @dt_base_processamento
			OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --5segundos
			
				
		SET @p_data_inicio = GETDATE();
		/*Carregar todos documentos X tipo documentos X Entidades que tenham um documento configurado como principal */
		;with cte_doc_cvm as   /*Excessão: Caso exista documentos X entidades duplicados do tipo CPF e CNPJ (1,2), mas para a Entidade exista documento CVM. Então não considerar como duplicado o tipo CPF e CNPJ. Neste caso não deverá ser preenchido os campos correpondentes a estes tipos de documento*/
		(select a.num_sequencial_entidade, a.cod_tipo_documento,COUNT(*) as contcpfcnpj
			from dw.#tmpdocumento a
			where a.cod_tipo_documento in ('1','2')
			and exists (select 1 from dw.#tmpdocumento b where a.num_sequencial_entidade = b.num_sequencial_entidade and b.cod_tipo_documento ='11')
			group by a.num_sequencial_entidade, a.cod_tipo_documento
			having COUNT(*) > 1
		)
		select a.num_sequencial_entidade, a.cod_tipo_documento, a.cod_documento, a.cod_doc99_char
		into dw.#tmpdocumento_final 
		from dw.#tmpdocumento a
		left join cte_doc_cvm cvm on a.num_sequencial_entidade = cvm.num_sequencial_entidade and a.cod_tipo_documento = cvm.cod_tipo_documento 
		where exists (select 1 from dw.#tmpdocumento b where a.num_sequencial_entidade = b.num_sequencial_entidade and a.cod_tipo_documento = b.cod_tipo_documento and b.ind_principal = 'S')
		and   cvm.num_sequencial_entidade is null 
		group by a.num_sequencial_entidade, a.cod_tipo_documento, a.cod_documento , a.cod_doc99_char
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --28segundos
			
		SET @p_data_inicio = GETDATE();
		/*Carregar todos documentos X tipo documentos X Entidades que não tenham nenhum documento configurado como principal */
		;with cte_doc_cvm as /*Excessão: Caso exista documentos X entidades duplicados do tipo CPF e CNPJ (1,2), mas para a Entidade exista documento CVM. Então não considerar como duplicado o tipo CPF e CNPJ. Neste caso não deverá ser preenchido os campos correpondentes a estes tipos de documento*/
		(select a.num_sequencial_entidade, a.cod_tipo_documento,COUNT(*) as contcpfcnpj
			from dw.#tmpdocumento a
			where a.cod_tipo_documento in ('1','2')
			and exists (select 1 from dw.#tmpdocumento b where a.num_sequencial_entidade = b.num_sequencial_entidade and b.cod_tipo_documento ='11')
			group by a.num_sequencial_entidade, a.cod_tipo_documento
			having COUNT(*) > 1
		)
		insert dw.#tmpdocumento_final 
		select a.num_sequencial_entidade, a.cod_tipo_documento, a.cod_documento , a.cod_doc99_char
		from dw.#tmpdocumento a
		left join cte_doc_cvm cvm on a.num_sequencial_entidade = cvm.num_sequencial_entidade and a.cod_tipo_documento = cvm.cod_tipo_documento 
		where not exists (select 1 from dw.#tmpdocumento b where a.num_sequencial_entidade = b.num_sequencial_entidade and a.cod_tipo_documento = b.cod_tipo_documento and b.ind_principal = 'S')
		and   cvm.num_sequencial_entidade is null 
		group by a.num_sequencial_entidade, a.cod_tipo_documento, a.cod_documento , a.cod_doc99_char
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --8segundos
			
		
				
		SET @p_data_inicio = GETDATE();
				

		SET @p_data_inicio = GETDATE();
				
		CREATE CLUSTERED INDEX IX_TMPDOC ON dw.#tmpdocumento_final (num_sequencial_entidade,cod_tipo_documento)

		SET @p_data_inicio = GETDATE();
		select distinct 
		 par.num_sequencial_participante
		, par.num_sequencial_situacao
		, par.cod_operacional_participante
		, cat.sigl_categoria
		, cat.cod_categoria
		, cat.nome_categoria
		into dw.#tmpParCategoria
		from hst.TDWCLS_CALENDARIO caled (nolock) 
		inner join hst.TDWICDX_PARTICIPANTE par (nolock)
					on   caled.data_calendario >= par.data_inicio_vigencia_historico
					and (caled.data_calendario <  par.data_fim_vigencia_historico or par.data_fim_vigencia_historico is null) /*Considera status ativo*/
					and (	
							(		
									( par.data_situacao_atual = (select max(parmax.data_situacao_atual) from hst.TDWICDX_PARTICIPANTE parmax 
																		where parmax.cod_operacional_participante = par.cod_operacional_participante 
																		and   parmax.sigl_categoria = par.sigl_categoria
																		and  caled.data_calendario >= parmax.data_inicio_vigencia_historico
																		and (caled.data_calendario <  parmax.data_fim_vigencia_historico or parmax.data_fim_vigencia_historico is null) 
																		and par.num_sequencial_situacao = parmax.num_sequencial_situacao
																		)  		
											or par.data_situacao_atual is null  /*Esta situação deveria estar corrigida na origem, antes de ir para produção (14/01/2013) */
										)
								and par.num_sequencial_situacao = 6
							)	
							OR /*Considera status diferente de ativo*/
							( ( par.data_situacao_atual = (select max(parmax.data_situacao_atual) from hst.TDWICDX_PARTICIPANTE parmax 
																			where parmax.cod_operacional_participante = par.cod_operacional_participante 
																			and   parmax.sigl_categoria = par.sigl_categoria
																			and  caled.data_calendario >= parmax.data_inicio_vigencia_historico
																			and (caled.data_calendario <  parmax.data_fim_vigencia_historico or parmax.data_fim_vigencia_historico is null)
																			and parmax.num_sequencial_situacao <> 6
																			)  		
												or par.data_situacao_atual is null  /*Esta situação deveria estar corrigida na origem, antes de ir para produção (14/01/2013) */
											)
								and par.num_sequencial_situacao <> 6
								and not exists (select 1 from hst.TDWICDX_PARTICIPANTE par6
									where par6.cod_operacional_participante = par.cod_operacional_participante 
									and   par6.sigl_categoria = par.sigl_categoria
									and  caled.data_calendario >= par6.data_inicio_vigencia_historico
									and (caled.data_calendario <  par6.data_fim_vigencia_historico or par6.data_fim_vigencia_historico is null)
									and par6.num_sequencial_situacao = 6
									)
							)
					)
				inner join hst.TDWICDX_CATEGORIA cat (nolock) 
					on par.sigl_categoria = cat.sigl_categoria
					and  caled.data_calendario >= cat.data_inicio_vigencia_historico
					and (caled.data_calendario <  cat.data_fim_vigencia_historico or cat.data_fim_vigencia_historico is null) 
					and  cat.ind_categoria_permite_criar_conta =  'S'
		where caled.data_calendario = @dt_base_processamento
		
		
		
		SET @p_data_inicio = GETDATE();
		
		CREATE CLUSTERED INDEX IE_tmpParCategoria ON dw.#tmpParCategoria (num_sequencial_participante)

		SET @p_data_inicio = GETDATE();
		
		select convert(smalldatetime,caled.data_calendario) as data_calendario
			 , conta.num_sequencial_conta
			 , conta.cod_participante_negociacao
			 , conta.num_identificacao_conta 
			 , conta.cod_operacional_participante
			 , conta.num_sequencial_tipo_conta
			 , conta.num_sequencial_titular_conta_email
			 , conta.num_sequencial_titular_conta_endereco 
			 , conta.num_sequencial_titular_conta_telefone
			 , conta.cod_titular_conta
			 , conta.num_sequencial_situacao
			 , conta.cod_motivo_situacao
			 , conta.ind_cadastro_simplificado
			 , conta.ind_conta_propria_participante_negociacao 
			 , conta.data_situacao_atual 
			 , conta.dthr_inclusao 
			 , conta.dthr_alteracao  
			 , conta.data_inicio_vigencia_historico
			 , conta.data_fim_vigencia_historico   
		INTO dw.#tmp_TDWICDX_CONTA
		from hst.TDWCLS_CALENDARIO caled (nolock) 
	   inner join hst.TDWICDX_CONTA conta (nolock)
		  on convert(smalldatetime,caled.data_calendario) >= conta.data_inicio_vigencia_historico
		 and (convert(smalldatetime,caled.data_calendario) < conta.data_fim_vigencia_historico or conta.data_fim_vigencia_historico is null)
	   WHERE caled.data_calendario = @dt_base_processamento
         and conta.num_sequencial_tipo_conta not in (13,14,15,16) /*Exclui contas do tipo SELIC: 13 - SELIC CUSTODIA, 14 - SELIC ESPECIAL CAMARA, 15 - SELIC ESPECIAL CAMARA, 16 - SELIC OUTROS*/
		 OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --150segundos
		 

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_CONTA_01 ON dw.#tmp_TDWICDX_CONTA (data_calendario, num_sequencial_conta)
		CREATE INDEX IE_tmp_TDWICDX_CONTA_02 ON dw.#tmp_TDWICDX_CONTA (data_calendario, cod_titular_conta)

		SET @p_data_inicio = GETDATE();
		
		 SELECT convert(smalldatetime,caled.data_calendario) data_calendario
			  , ent.num_sequencial_entidade
			  , ent.num_sequencial_tipo_entidade
  			  , ent.cod_tipo_pessoa
		 INTO dw.#tmp_TDWICDX_ENTIDADE
		 FROM hst.TDWCLS_CALENDARIO caled
		INNER JOIN  hst.TDWICDX_ENTIDADE as ent (nolock) 
		   on convert(smalldatetime,caled.data_calendario) >= ent.data_inicio_vigencia_historico
		  and (convert(smalldatetime,caled.data_calendario) < ent.data_fim_vigencia_historico or ent.data_fim_vigencia_historico is null)
        WHERE caled.data_calendario = @dt_base_processamento
		--OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --MAIS RAPIDO SEM O HINT
		

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_ENTIDADE_01 ON dw.#tmp_TDWICDX_ENTIDADE (data_calendario, num_sequencial_entidade)
		CREATE INDEX IE_tmp_TDWICDX_ENTIDADE_02 ON dw.#tmp_TDWICDX_ENTIDADE (data_calendario, num_sequencial_tipo_entidade)

		SET @p_data_inicio = GETDATE();
		
		 SELECT convert(smalldatetime,caled.data_calendario) data_calendario
			  , pf.num_sequencial_entidade
			  , pf.nome_completo
			  , pf.cod_ocupacao

		 INTO dw.#tmp_TDWICDX_PESSOA_FISICA
		 FROM hst.TDWCLS_CALENDARIO caled
		INNER JOIN  hst.TDWICDX_PESSOA_FISICA as pf (nolock) 
		   on convert(smalldatetime,caled.data_calendario) >= pf.data_inicio_vigencia_historico
		  and (convert(smalldatetime,caled.data_calendario) < pf.data_fim_vigencia_historico or pf.data_fim_vigencia_historico is null)
        WHERE caled.data_calendario = @dt_base_processamento
		--50 SEGUNDOS

		

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_PESSOA_FISICA_01 ON dw.#tmp_TDWICDX_PESSOA_FISICA (data_calendario, num_sequencial_entidade)

		
		SET @p_data_inicio = GETDATE();

		 SELECT convert(smalldatetime,caled.data_calendario) data_calendario
			  , pj.num_sequencial_entidade
			  , pj.nome_razao_social
			  , pj.cod_atividade_economica_primaria

		 INTO dw.#tmp_TDWICDX_PESSOA_JURIDICA
		 FROM hst.TDWCLS_CALENDARIO caled
		INNER JOIN  hst.TDWICDX_PESSOA_JURIDICA as pj (nolock) 
		   on convert(smalldatetime,caled.data_calendario) >= pj.data_inicio_vigencia_historico
		  and (convert(smalldatetime,caled.data_calendario) < pj.data_fim_vigencia_historico or pj.data_fim_vigencia_historico is null)
        WHERE caled.data_calendario = @dt_base_processamento
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --1 SEGUNDO
		

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_PESSOA_JURIDICA_01 ON dw.#tmp_TDWICDX_PESSOA_JURIDICA (data_calendario, num_sequencial_entidade)
		
		SET @p_data_inicio = GETDATE();

		 SELECT convert(smalldatetime,caled.data_calendario) data_calendario
		      , tit.cod_titular_conta
			  , tit.cod_participante_negociacao
			  , tit.cod_tipo_pessoa
			  , tit.ind_pessoa_vinculado
		 INTO dw.#tmp_TDWICDX_TITULAR_CONTA
		 FROM hst.TDWCLS_CALENDARIO caled
		INNER JOIN  hst.TDWICDX_TITULAR_CONTA as tit (nolock) 
		   on convert(smalldatetime,caled.data_calendario) >= tit.data_inicio_vigencia_historico
		  and (convert(smalldatetime,caled.data_calendario) < tit.data_fim_vigencia_historico or tit.data_fim_vigencia_historico is null)
        WHERE caled.data_calendario = @dt_base_processamento
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --75 SEGUNDOS

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_TITULAR_CONTA_01 ON dw.#tmp_TDWICDX_TITULAR_CONTA (data_calendario, cod_titular_conta, cod_participante_negociacao)
		
		SET @p_data_inicio = GETDATE();	

		 SELECT convert(smalldatetime,caled.data_calendario) data_calendario
		      , tit_conta_pf.cod_titular_conta
			  , tit_conta_pf.cod_participante_negociacao
			  , tit_conta_pf.cod_ocupacao

		 INTO dw.#tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA
		 FROM hst.TDWCLS_CALENDARIO caled
		INNER JOIN  hst.TDWICDX_TITULAR_CONTA_PESSOA_FISICA as tit_conta_pf (nolock) 
		   on convert(smalldatetime,caled.data_calendario) >= tit_conta_pf.data_inicio_vigencia_historico
		  and (convert(smalldatetime,caled.data_calendario) < tit_conta_pf.data_fim_vigencia_historico or tit_conta_pf.data_fim_vigencia_historico is null)
        WHERE caled.data_calendario = @dt_base_processamento
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --75SEGUNDOS

		CREATE CLUSTERED INDEX IE_tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA_01 ON dw.#tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA (data_calendario, cod_titular_conta, cod_participante_negociacao)
		
		SET @p_data_inicio = GETDATE();		
		--;with cte_conta_master as
		select conta.num_sequencial_conta, conta.data_inicio_vigencia_historico, conta.data_fim_vigencia_historico   
			, contamaster.num_sequencial_conta as num_sequencial_conta_master
			, contamaster.num_identificacao_conta as num_identificacao_conta_master
			, contamaster.cod_participante_negociacao as num_sequencial_entidade_participante_master
			, contamaster.cod_titular_conta as num_sequencial_entidade_investidor_master
			, contamaster.cod_operacional_participante as cod_operacional_participante_master
			, /* INÍCIO Regra antiga "por eliminação" - desativada 
					case when entdocnresbovmaster.cod_documento is not null then entdocnresbovmaster.cod_documento 
					when entdocnresbovmaster18.cod_documento is not null then entdocnresbovmaster18.cod_documento
					when entdocnresbmfmaster19.cod_documento is not null then entdocnresbmfmaster19.cod_documento
					when entdocnresbmfmaster20.cod_documento is not null then entdocnresbmfmaster20.cod_documento
					when entdoccvmmaster.cod_documento is not null then '990000000' + substring(entdoccvmmaster.cod_documento,12,6)  
					else case when entmaster.cod_tipo_pessoa = 'PF' then entdocpfmaster.cod_documento when entmaster.cod_tipo_pessoa = 'PJ' then entdocpjmaster.cod_documento else null end 
				end 
				FIM Regra antiga "por eliminação" - desativada */
			  case when entmaster.num_sequencial_tipo_entidade = 1 then entdocpfmaster.cod_documento 
					when entmaster.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbovmaster18.cod_documento,'') = '' 
																		then entdocnresbmfmaster19.cod_documento
																		ELSE entdocnresbovmaster18.cod_documento
																END
					when entmaster.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbovmaster.cod_documento,'') = '' 
																		then entdoccvmmaster.cod_doc99_char
																		else entdocnresbovmaster.cod_documento 
																END 
					
					when entmaster.num_sequencial_tipo_entidade = 4 then entdocpjmaster.cod_documento 
					when entmaster.num_sequencial_tipo_entidade = 5 then
																CASE when ISNULL(entdocnresbovmaster18.cod_documento,'') = '' 
																		then entdocnresbmfmaster20.cod_documento
																		else entdocnresbovmaster18.cod_documento
																END
					when entmaster.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbovmaster.cod_documento,'') = '' 
																		then entdoccvmmaster.cod_doc99_char
																		else entdocnresbovmaster.cod_documento 
																END 
					else null					
				end as num_documento_identificacao_master
			, /* INÍCIO Regra antiga "por eliminação" - desativada 
				case when entdocnresbovmaster.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster.cod_tipo_documento,entdocnresbovmaster.cod_documento) 
					when entdocnresbovmaster18.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster18.cod_tipo_documento,entdocnresbovmaster18.cod_documento)
					when entdocnresbmfmaster19.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfmaster19.cod_tipo_documento,entdocnresbmfmaster19.cod_documento)
					when entdocnresbmfmaster20.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfmaster20.cod_tipo_documento,entdocnresbmfmaster20.cod_documento)
					when entdoccvmmaster.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdoccvmmaster.cod_tipo_documento,'990000000' + substring(entdoccvmmaster.cod_documento,12,6))   
					else case when entmaster.cod_tipo_pessoa = 'PF' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpfmaster.cod_tipo_documento,entdocpfmaster.cod_documento) 
								when entmaster.cod_tipo_pessoa = 'PJ' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpjmaster.cod_tipo_documento,entdocpjmaster.cod_documento) 
								else null end 
					end 
				FIM Regra antiga "por eliminação" - desativada */
				case when entmaster.num_sequencial_tipo_entidade = 1 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpfmaster.cod_tipo_documento,entdocpfmaster.cod_documento)
					when entmaster.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbovmaster18.cod_documento,'') = '' 
																		THEN dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfmaster19.cod_tipo_documento,entdocnresbmfmaster19.cod_documento)
																		ELSE dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster18.cod_tipo_documento,entdocnresbovmaster18.cod_documento)		
																	END
					when entmaster.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbovmaster.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvmmaster.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster.cod_tipo_documento,entdocnresbovmaster.cod_documento)
																END 
					when entmaster.num_sequencial_tipo_entidade = 4 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpjmaster.cod_tipo_documento,entdocpjmaster.cod_documento)
					when entmaster.num_sequencial_tipo_entidade = 5 then 
																CASE when ISNULL(entdocnresbovmaster18.cod_documento,'') = '' 
																		THEN dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfmaster20.cod_tipo_documento,entdocnresbmfmaster20.cod_documento)
																		ELSE dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster18.cod_tipo_documento,entdocnresbovmaster18.cod_documento) 
																END
					when entmaster.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbovmaster.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvmmaster.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovmaster.cod_tipo_documento,entdocnresbovmaster.cod_documento)
																END 
					else null					
				end	as num_documento_identificacao_formatado_master
			, case when entmaster.cod_tipo_pessoa = 'PF' then pfmaster.nome_completo when entmaster.cod_tipo_pessoa = 'PJ' then pjmaster.nome_razao_social else null end as nome_completo_razao_social_master
			, titcontamaster.cod_tipo_pessoa as cod_tipo_pessoa_master
			, pjmaster.cod_atividade_economica_primaria as cod_atividade_economica_primaria_master
			, ISNULL(titcontaPFmaster.cod_ocupacao, pfmaster.cod_ocupacao) as cod_ocupacao_master
			, contamaster.num_sequencial_situacao  as num_sequencial_situacao_master
			, vincmaster.num_sequencial_situacao as num_sequencial_situacao_vinculo_master 

			into dw.#conta_master

			from dw.#tmp_TDWICDX_CONTA conta (nolock)
			inner join hst.TDWICDX_CONTA_VINCULADA contavincmaster (nolock)
				on conta.num_sequencial_conta = contavincmaster.num_sequencial_conta 
				and contavincmaster.ind_parte_vinculo = 'C'
				and  conta.data_calendario >= contavincmaster.data_inicio_vigencia_historico
				and (conta.data_calendario <  contavincmaster.data_fim_vigencia_historico or contavincmaster.data_fim_vigencia_historico is null)		
			inner join hst.TDWICDX_VINCULO vincmaster (nolock)
				on contavincmaster.num_sequencial_vinculo = vincmaster.num_sequencial_vinculo 
				and  conta.data_calendario >= vincmaster.data_inicio_vigencia_historico
				and (conta.data_calendario <  vincmaster.data_fim_vigencia_historico or vincmaster.data_fim_vigencia_historico is null)	
				and vincmaster.num_sequencial_situacao in(6,9) /*Situação = ATIVO*/ 	
			inner join hst.TDWICDX_TIPO_VINCULO tvincmaster (nolock)
				on vincmaster.num_sequencial_tipo_vinculo = tvincmaster.num_sequencial_tipo_vinculo
				and tvincmaster.nome_tipo_vinculo ='CONTA MÁSTER'
				and  conta.data_calendario >= tvincmaster.data_inicio_vigencia_historico
				and (conta.data_calendario <  tvincmaster.data_fim_vigencia_historico or tvincmaster.data_fim_vigencia_historico is null)
			inner join hst.TDWICDX_CONTA_VINCULADA contavincmaster2 (nolock)
				on vincmaster.num_sequencial_vinculo = contavincmaster2.num_sequencial_vinculo
				and contavincmaster2.ind_parte_vinculo = 'P'
				and  conta.data_calendario >= contavincmaster2.data_inicio_vigencia_historico
				and (conta.data_calendario <  contavincmaster2.data_fim_vigencia_historico or contavincmaster2.data_fim_vigencia_historico is null)	
			inner join dw.#tmp_TDWICDX_CONTA contamaster (nolock)
				on contavincmaster2.num_sequencial_conta = contamaster.num_sequencial_conta  
				and  conta.data_calendario = contamaster.data_calendario
				
			left join dw.#tmp_TDWICDX_TITULAR_CONTA titcontamaster (nolock)
				on contamaster.cod_titular_conta = titcontamaster.cod_titular_conta 
				and contamaster.cod_participante_negociacao = titcontamaster.cod_participante_negociacao 	
				and conta.data_calendario = titcontamaster.data_calendario

			left join dw.#tmp_TDWICDX_ENTIDADE entmaster (nolock) 
				on contamaster.cod_titular_conta  = entmaster.num_sequencial_entidade 
				and conta.data_calendario = entmaster.data_calendario
			left join hst.TDWICDX_TIPO_ENTIDADE tentmaster (nolock) 
				on entmaster.num_sequencial_tipo_entidade = tentmaster.num_sequencial_tipo_entidade 
				and  conta.data_calendario >= tentmaster.data_inicio_vigencia_historico
				and (conta.data_calendario <  tentmaster.data_fim_vigencia_historico or tentmaster.data_fim_vigencia_historico is null)	
			left join dw.#tmp_TDWICDX_PESSOA_FISICA pfmaster (nolock) 
				on entmaster.num_sequencial_entidade = pfmaster.num_sequencial_entidade
				and  conta.data_calendario = pfmaster.data_calendario
			left join dw.#tmp_TDWICDX_PESSOA_JURIDICA pjmaster (nolock) 
				on entmaster.num_sequencial_entidade = pjmaster.num_sequencial_entidade
				and  conta.data_calendario = pjmaster.data_calendario
			left join dw.#tmpdocumento_final entdocpfmaster (nolock) 
				on entmaster.num_sequencial_entidade = entdocpfmaster.num_sequencial_entidade and entdocpfmaster.cod_tipo_documento = '2'
			left join dw.#tmpdocumento_final entdocpjmaster (nolock) 
				on entmaster.num_sequencial_entidade = entdocpjmaster.num_sequencial_entidade and entdocpjmaster.cod_tipo_documento = '1'  
			left join dw.#tmpdocumento_final entdocnresbovmaster (nolock) 
				on entmaster.num_sequencial_entidade = entdocnresbovmaster.num_sequencial_entidade and entdocnresbovmaster.cod_tipo_documento = '17'  
			left join dw.#tmpdocumento_final entdocnresbovmaster18 (nolock) 
				on entmaster.num_sequencial_entidade = entdocnresbovmaster18.num_sequencial_entidade and entdocnresbovmaster18.cod_tipo_documento = '18'
			left join dw.#tmpdocumento_final entdocnresbmfmaster19 (nolock) 
				on entmaster.num_sequencial_entidade = entdocnresbmfmaster19.num_sequencial_entidade and entdocnresbmfmaster19.cod_tipo_documento = '19'
			left join dw.#tmpdocumento_final entdocnresbmfmaster20 (nolock) 
				on entmaster.num_sequencial_entidade = entdocnresbmfmaster20.num_sequencial_entidade and entdocnresbmfmaster20.cod_tipo_documento = '20'				
			left join dw.#tmpdocumento_final entdoccvmmaster (nolock) 
				on entmaster.num_sequencial_entidade = entdoccvmmaster.num_sequencial_entidade and entdoccvmmaster.cod_tipo_documento = '11'  
			left join dw.#tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA titcontaPFmaster (nolock)
				on titcontamaster.cod_titular_conta = titcontaPFmaster.cod_titular_conta
				and titcontamaster.cod_participante_negociacao = titcontaPFmaster.cod_participante_negociacao
				and  conta.data_calendario = titcontaPFmaster.data_calendario
			where conta.data_calendario = @dt_base_processamento
			OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --36SEGUNDOS
			

		SET @p_data_inicio = GETDATE();

		create clustered index IE_conta_master on dw.#conta_master (num_sequencial_conta, data_inicio_vigencia_historico)
		
		SET @p_data_inicio = GETDATE();	

		--), cte_conta_proximo_nivel as
		--(

		select conta.num_sequencial_conta, conta.data_inicio_vigencia_historico, conta.data_fim_vigencia_historico   
			, contaprox.num_sequencial_conta as num_sequencial_conta_proximo_nivel
			, contaprox.num_identificacao_conta as num_identificacao_conta_proximo_nivel
			, contaprox.cod_participante_negociacao as num_sequencial_entidade_participante_proximo_nivel
			, contaprox.cod_titular_conta as num_sequencial_entidade_investidor_proximo_nivel
			, contaprox.cod_operacional_participante as cod_operacional_participante_proximo_nivel
			, /* INÍCIO Regra antiga "por eliminação" - desativada 
			case when entdocnresbovprox.cod_documento is not null then entdocnresbovprox.cod_documento 
					when entdocnresbovprox18.cod_documento is not null then entdocnresbovprox18.cod_documento 
					when entdocnresbmfprox19.cod_documento is not null then entdocnresbmfprox19.cod_documento
					when entdocnresbmfprox20.cod_documento is not null then entdocnresbmfprox20.cod_documento
					when entdoccvmprox.cod_documento is not null then '990000000' + substring(entdoccvmprox.cod_documento,12,6)  
					else case when entprox.cod_tipo_pessoa = 'PF' then entdocpfprox.cod_documento when entprox.cod_tipo_pessoa = 'PJ' then entdocpjprox.cod_documento else null end 
				end as num_documento_identificacao_proximo_nivel
				FIM Regra antiga "por eliminação" - desativada */
			case when entprox.num_sequencial_tipo_entidade = 1 then entdocpfprox.cod_documento 
					when entprox.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbovprox18.cod_documento,'') = '' 
																		then entdocnresbmfprox19.cod_documento
																		ELSE entdocnresbovprox18.cod_documento
																END
					when entprox.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbovprox.cod_documento,'') = '' 
																		then entdoccvmprox.cod_doc99_char
																		else entdocnresbovprox.cod_documento 
																END 
					
					when entprox.num_sequencial_tipo_entidade = 4 then entdocpjprox.cod_documento 
					when entprox.num_sequencial_tipo_entidade = 5 then
																CASE when ISNULL(entdocnresbovprox18.cod_documento,'') = '' 
																		then entdocnresbmfprox20.cod_documento
																		else entdocnresbovprox18.cod_documento
																END
					when entprox.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbovprox.cod_documento,'') = '' 
																		then entdoccvmprox.cod_doc99_char
																		else entdocnresbovprox.cod_documento 
																END 
					else null					
				end as num_documento_identificacao_proximo_nivel
			, /* INÍCIO Regra antiga "por eliminação" - desativada 
				case when entdocnresbovprox.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox.cod_tipo_documento,entdocnresbovprox.cod_documento) 
					when entdocnresbovprox18.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox18.cod_tipo_documento,entdocnresbovprox18.cod_documento)
					when entdocnresbmfprox19.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox19.cod_tipo_documento,entdocnresbmfprox19.cod_documento)
					when entdocnresbmfprox20.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox20.cod_tipo_documento,entdocnresbmfprox20.cod_documento)
					when entdoccvmprox.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdoccvmprox.cod_tipo_documento,'990000000' + substring(entdoccvmprox.cod_documento,12,6))   
					else case when entprox.cod_tipo_pessoa = 'PF' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpfprox.cod_tipo_documento,entdocpfprox.cod_documento) 
								when entprox.cod_tipo_pessoa = 'PJ' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpjprox.cod_tipo_documento,entdocpjprox.cod_documento) 
								else null end 
					end 
					
				FIM Regra antiga "por eliminação" - desativada */
				case when entprox.num_sequencial_tipo_entidade = 1 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpfprox.cod_tipo_documento,entdocpfprox.cod_documento)
					when entprox.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbovprox18.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox19.cod_tipo_documento,entdocnresbmfprox19.cod_documento)
																		ELSE dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox18.cod_tipo_documento,entdocnresbovprox18.cod_documento)
																END
					when entprox.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbovprox.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvmprox.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox.cod_tipo_documento,entdocnresbovprox.cod_documento )
																END 
					
					when entprox.num_sequencial_tipo_entidade = 4 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpjprox.cod_tipo_documento,entdocpjprox.cod_documento)
					when entprox.num_sequencial_tipo_entidade = 5 then
																CASE when ISNULL(entdocnresbovprox18.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox20.cod_tipo_documento,entdocnresbmfprox20.cod_documento)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox18.cod_tipo_documento,entdocnresbovprox18.cod_documento)
																END
					when entprox.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbovprox.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvmprox.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox.cod_tipo_documento,entdocnresbovprox.cod_documento)
																END 
					else null					
				end as num_documento_identificacao_formatado_proximo_nivel
			, entdoccvmprox.cod_documento as num_documento_identificacao_cvm_proximo_nivel					
			, case when entprox.cod_tipo_pessoa = 'PF' then pfprox.nome_completo when entprox.cod_tipo_pessoa = 'PJ' then pjprox.nome_razao_social else null end as nome_completo_razao_social_proximo_nivel
			, titcontaprox.cod_tipo_pessoa as cod_tipo_pessoa_proximo_nivel
			, pjprox.cod_atividade_economica_primaria as cod_atividade_economica_primaria_proximo_nivel
			, ISNULL(titcontaPFprox.cod_ocupacao, pfprox.cod_ocupacao) as cod_ocupacao_proximo_nivel
			, contaprox.num_sequencial_situacao as num_sequencial_situacao_proximo_nivel 
			, vincprox.num_sequencial_situacao as num_sequencial_situacao_vinculo_proximo_nivel 
			, entdocnresbmfprox45.cod_documento as num_documento_nif_proximo_nivel
            , entprox.num_sequencial_tipo_entidade as num_sequencial_tipo_entidade_investidor_proximo_nivel

			into dw.#conta_proximo_nivel
			
			from dw.#tmp_TDWICDX_CONTA conta (nolock)
			inner join hst.TDWICDX_CONTA_VINCULADA contavincprox (nolock)
				on conta.num_sequencial_conta = contavincprox.num_sequencial_conta 
				and contavincprox.ind_parte_vinculo = 'P'
				and  conta.data_calendario >= contavincprox.data_inicio_vigencia_historico
				and (conta.data_calendario < contavincprox.data_fim_vigencia_historico or contavincprox.data_fim_vigencia_historico is null)		
			inner join hst.TDWICDX_VINCULO vincprox (nolock)
				on contavincprox.num_sequencial_vinculo = vincprox.num_sequencial_vinculo 
				and  conta.data_calendario >= vincprox.data_inicio_vigencia_historico 
				and (conta.data_calendario <  vincprox.data_fim_vigencia_historico or vincprox.data_fim_vigencia_historico is null)	
				and vincprox.num_sequencial_situacao in (6,9) /*Situação = ATIVO*/ 
			inner join hst.TDWICDX_TIPO_VINCULO tvincprox (nolock)
				on vincprox.num_sequencial_tipo_vinculo = tvincprox.num_sequencial_tipo_vinculo
				and tvincprox.nome_tipo_vinculo ='POR CONTA E ORDEM'
				and  conta.data_calendario >= tvincprox.data_inicio_vigencia_historico
				and (conta.data_calendario <  tvincprox.data_fim_vigencia_historico or tvincprox.data_fim_vigencia_historico is null)		
			inner join hst.TDWICDX_CONTA_VINCULADA contavincprox2 (nolock)
				on vincprox.num_sequencial_vinculo = contavincprox2.num_sequencial_vinculo
				and contavincprox2.ind_parte_vinculo = 'C'
				and  conta.data_calendario >= contavincprox2.data_inicio_vigencia_historico
				and (conta.data_calendario <  contavincprox2.data_fim_vigencia_historico or contavincprox2.data_fim_vigencia_historico is null)	
			inner join dw.#tmp_TDWICDX_CONTA contaprox (nolock)
				on contavincprox2.num_sequencial_conta = contaprox.num_sequencial_conta  
				and  conta.data_calendario = contaprox.data_calendario
				
			left join dw.#tmp_TDWICDX_TITULAR_CONTA titcontaprox (nolock)
				on contaprox.cod_titular_conta = titcontaprox.cod_titular_conta 
				and contaprox.cod_participante_negociacao = titcontaprox.cod_participante_negociacao 	
				and conta.data_calendario = titcontaprox.data_calendario

			left join dw.#tmp_TDWICDX_ENTIDADE entprox (nolock) 
				on contaprox.cod_titular_conta  = entprox.num_sequencial_entidade 
				and  conta.data_calendario = entprox.data_calendario

			left join hst.TDWICDX_TIPO_ENTIDADE tentprox (nolock) 
				on entprox.num_sequencial_tipo_entidade = tentprox.num_sequencial_tipo_entidade 
				and  conta.data_calendario >= tentprox.data_inicio_vigencia_historico
				and (conta.data_calendario <  tentprox.data_fim_vigencia_historico or tentprox.data_fim_vigencia_historico is null)	

			left join dw.#tmp_TDWICDX_PESSOA_FISICA pfprox (nolock) 
				on entprox.num_sequencial_entidade = pfprox.num_sequencial_entidade
				and  conta.data_calendario = pfprox.data_calendario

			left join dw.#tmp_TDWICDX_PESSOA_JURIDICA pjprox (nolock) 
				on entprox.num_sequencial_entidade = pjprox.num_sequencial_entidade
				and  conta.data_calendario = pjprox.data_calendario

			left join dw.#tmpdocumento_final entdocpfprox (nolock) 
				on entprox.num_sequencial_entidade = entdocpfprox.num_sequencial_entidade and entdocpfprox.cod_tipo_documento = '2' 
			left join dw.#tmpdocumento_final entdocpjprox (nolock) 
				on entprox.num_sequencial_entidade = entdocpjprox.num_sequencial_entidade and entdocpjprox.cod_tipo_documento = '1'  
			left join dw.#tmpdocumento_final entdocnresbovprox (nolock) 
				on entprox.num_sequencial_entidade = entdocnresbovprox.num_sequencial_entidade and entdocnresbovprox.cod_tipo_documento = '17'  
			left join dw.#tmpdocumento_final entdocnresbovprox18 (nolock) 
				on entprox.num_sequencial_entidade = entdocnresbovprox18.num_sequencial_entidade and entdocnresbovprox18.cod_tipo_documento = '18'
			left join dw.#tmpdocumento_final entdocnresbmfprox19 (nolock) 
				on entprox.num_sequencial_entidade = entdocnresbmfprox19.num_sequencial_entidade and entdocnresbmfprox19.cod_tipo_documento = '19'
			left join dw.#tmpdocumento_final entdocnresbmfprox20 (nolock) 
				on entprox.num_sequencial_entidade = entdocnresbmfprox20.num_sequencial_entidade and entdocnresbmfprox20.cod_tipo_documento = '20'
			left join dw.#tmpdocumento_final entdocnresbmfprox45 (nolock) 
				on entprox.num_sequencial_entidade = entdocnresbmfprox45.num_sequencial_entidade and entdocnresbmfprox45.cod_tipo_documento = '45'
			left join dw.#tmpdocumento_final entdoccvmprox (nolock) 
				on entprox.num_sequencial_entidade = entdoccvmprox.num_sequencial_entidade and entdoccvmprox.cod_tipo_documento = '11'  
			left join dw.#tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA titcontaPFprox (nolock)
				on titcontaprox.cod_titular_conta = titcontaPFprox.cod_titular_conta
				and titcontaprox.cod_participante_negociacao = titcontaPFprox.cod_participante_negociacao
				and  conta.data_calendario = titcontaPFprox.data_calendario
			where conta.data_calendario = @dt_base_processamento
			OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --283segundos
		--)
		


		SET @p_data_inicio = GETDATE();

		create clustered index IE_conta_proximo_nivel on dw.#conta_proximo_nivel (num_sequencial_conta, data_inicio_vigencia_historico)
		
		*/
		
		
		insert into dw.#ADWCONTA --dw.ADWCONTA
		(
			 data_importacao_registro,num_sequencial_conta,num_identificacao_conta,num_sequencial_entidade_participante,num_sequencial_entidade_investidor
			 --,num_sequencial_participante,num_sequencial_situacao_participante
			,cod_operacional_participante
			 --,sigl_categoria,cod_categoria,nome_categoria
			,cod_tipo_pessoa,num_documento_identificacao
			,num_documento_identificacao_formatado,num_documento_identificacao_cvm,nome_completo_razao_social,num_sequencial_tipo_conta,nome_tipo_conta,num_sequencial_situacao,nome_situacao
			,data_situacao_atual,dthr_inclusao,dthr_alteracao,cod_motivo_situacao,nome_motivo_situacao,ind_conta_propria_participante_negociacao,ind_pessoa_vinculado
			,num_sequencial_titular_conta_endereco,cod_atividade_economica_primaria,cod_ocupacao,num_sequencial_conta_master,num_identificacao_conta_master,num_sequencial_entidade_participante_master
			,num_sequencial_entidade_investidor_master,cod_operacional_participante_master,num_documento_identificacao_master,num_documento_identificacao_formatado_master
			,nome_completo_razao_social_master,cod_tipo_pessoa_master,cod_atividade_economica_primaria_master,cod_ocupacao_master,num_sequencial_situacao_master, num_sequencial_situacao_vinculo_master 
			,num_sequencial_conta_proximo_nivel,num_identificacao_conta_proximo_nivel,num_sequencial_entidade_participante_proximo_nivel
			,num_sequencial_entidade_investidor_proximo_nivel,cod_operacional_participante_proximo_nivel,num_documento_identificacao_proximo_nivel
			,num_documento_identificacao_formatado_proximo_nivel,num_documento_identificacao_cvm_proximo_nivel,nome_completo_razao_social_proximo_nivel,cod_tipo_pessoa_proximo_nivel
			,cod_atividade_economica_primaria_proximo_nivel,cod_ocupacao_proximo_nivel,num_sequencial_situacao_proximo_nivel,num_sequencial_situacao_vinculo_proximo_nivel 
			,num_sequencial_conta_final,num_identificacao_conta_final,num_sequencial_entidade_participante_final
			,num_sequencial_entidade_investidor_final,cod_operacional_participante_final,num_documento_identificacao_final,num_documento_identificacao_formatado_final,num_documento_identificacao_cvm_final
			,nome_completo_razao_social_final,cod_tipo_pessoa_final,cod_atividade_economica_primaria_final,cod_ocupacao_final,num_sequencial_situacao_final
			,num_sequencial_situacao_vinculo_final,ind_conta_final
			,ind_cadastro_simplificado
			,num_sequencial_titular_conta_telefone
			,num_sequencial_titular_conta_email
			,num_documento_nif
			,num_documento_nif_proximo_nivel
			,num_documento_nif_final
            ,num_sequencial_tipo_entidade_investidor
            ,num_sequencial_tipo_entidade_investidor_proximo_nivel
            ,num_sequencial_tipo_entidade_investidor_final
		)
		select @dt_base_processamento as data_importacao_registro
		, conta.num_sequencial_conta 
		, conta.num_identificacao_conta 
		, conta.cod_participante_negociacao as num_sequencial_entidade_participante
		, conta.cod_titular_conta as num_sequencial_entidade_investidor
		--, par.num_sequencial_participante
		--, par.num_sequencial_situacao as num_sequencial_situacao_participante
		, conta.cod_operacional_participante as cod_operacional_participante 
		--, par.sigl_categoria as sigl_categoria  
		--, par.cod_categoria as cod_categoria  
		--, par.nome_categoria as nome_categoria  
		, titconta.cod_tipo_pessoa
		,/* INÍCIO Regra antiga "por eliminação" - desativada 
			case when entdocnresbov.cod_documento is not null then entdocnresbov.cod_documento 
				when entdocnresbov18.cod_documento is not null then entdocnresbov18.cod_documento
				when entdocnresbmf19.cod_documento is not null then entdocnresbmf19.cod_documento
				when entdocnresbmf20.cod_documento is not null then entdocnresbmf20.cod_documento
				when entdoccvm.cod_documento is not null then '990000000' + substring(entdoccvm.cod_documento,12,6)  
				else case when ent.cod_tipo_pessoa = 'PF' then entdocpf.cod_documento when ent.cod_tipo_pessoa = 'PJ' then entdocpj.cod_documento else null end 
			end
			FIM Regra antiga "por eliminação" - desativada */ 
			case when ent.num_sequencial_tipo_entidade = 1 then entdocpf.cod_documento 
					when ent.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbov18.cod_documento,'') = '' 
																		then entdocnresbmf19.cod_documento
																		ELSE entdocnresbov18.cod_documento
																END
					when ent.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbov.cod_documento,'') = '' 
																		then entdoccvm.cod_doc99_char
																		else entdocnresbov.cod_documento 
																END 
					
					when ent.num_sequencial_tipo_entidade = 4 then entdocpj.cod_documento 
					when ent.num_sequencial_tipo_entidade = 5 then
																CASE when ISNULL(entdocnresbov18.cod_documento,'') = '' 
																		then entdocnresbmf20.cod_documento
																		else entdocnresbov18.cod_documento
																END
					when ent.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbov.cod_documento,'') = '' 
																		then entdoccvm.cod_doc99_char
																		else entdocnresbov.cod_documento 
																END 
					else null					
				end as num_documento_identificacao  
		,/* INÍCIO Regra antiga "por eliminação" - desativada 
			case when entdocnresbov.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov.cod_tipo_documento,entdocnresbov.cod_documento) 
				when entdocnresbov18.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov18.cod_tipo_documento,entdocnresbov18.cod_documento)
				when entdocnresbmf19.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmf19.cod_tipo_documento,entdocnresbmf19.cod_documento)
				when entdocnresbmf20.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmf20.cod_tipo_documento,entdocnresbmf20.cod_documento)
				when entdoccvm.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdoccvm.cod_tipo_documento,'990000000' + substring(entdoccvm.cod_documento,12,6))   
				else case when ent.cod_tipo_pessoa = 'PF' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpf.cod_tipo_documento,entdocpf.cod_documento) 
							when ent.cod_tipo_pessoa = 'PJ' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpj.cod_tipo_documento,entdocpj.cod_documento) 
							else null end 
				end 
			FIM Regra antiga "por eliminação" - desativada */ 
			case when ent.num_sequencial_tipo_entidade = 1 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpf.cod_tipo_documento,entdocpf.cod_documento)
					when ent.num_sequencial_tipo_entidade = 2 then 
																CASE when ISNULL(entdocnresbov18.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmf19.cod_tipo_documento,entdocnresbmf19.cod_documento)
																		ELSE dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov18.cod_tipo_documento,entdocnresbov18.cod_documento)
																END
					when ent.num_sequencial_tipo_entidade = 3 then 
																CASE when ISNULL(entdocnresbov.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvm.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov.cod_tipo_documento,entdocnresbov.cod_documento)
																END 
					
					when ent.num_sequencial_tipo_entidade = 4 then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpj.cod_tipo_documento,entdocpj.cod_documento)
					when ent.num_sequencial_tipo_entidade = 5 then
																CASE when ISNULL(entdocnresbov18.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmf20.cod_tipo_documento,entdocnresbmf20.cod_documento)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov18.cod_tipo_documento,entdocnresbov18.cod_documento)
																END
					when ent.num_sequencial_tipo_entidade = 6 then 
																CASE when ISNULL(entdocnresbov.cod_documento,'') = '' 
																		then dw.FDW_MASCARA_TIPO_DOCUMENTO(17,entdoccvm.cod_doc99_char)
																		else dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbov.cod_tipo_documento,entdocnresbov.cod_documento)
																END 
					else null					
				end as num_documento_identificacao_formatado
		, entdoccvm.cod_documento as num_documento_identificacao_cvm				
		, case when ent.cod_tipo_pessoa = 'PF' then pf.nome_completo when ent.cod_tipo_pessoa = 'PJ' then pj.nome_razao_social else null end as nome_completo_razao_social
		, conta.num_sequencial_tipo_conta 
		, tconta.nome_tipo_conta
		, conta.num_sequencial_situacao
		, sit.nome_situacao
		, conta.data_situacao_atual 
		, conta.dthr_inclusao 
		, conta.dthr_alteracao  
		, conta.cod_motivo_situacao 
		, motsit.nome_motivo_situacao  
		, conta.ind_conta_propria_participante_negociacao 
		, titconta.ind_pessoa_vinculado  
		, conta.num_sequencial_titular_conta_endereco 
		, pj.cod_atividade_economica_primaria as cod_atividade_economica_primaria
		, ISNULL(titcontaPF.cod_ocupacao, pf.cod_ocupacao) as cod_ocupacao 
		, contamaster.num_sequencial_conta_master
		, contamaster.num_identificacao_conta_master
		, contamaster.num_sequencial_entidade_participante_master
		, contamaster.num_sequencial_entidade_investidor_master
		, contamaster.cod_operacional_participante_master
		, contamaster.num_documento_identificacao_master
		, contamaster.num_documento_identificacao_formatado_master
		, contamaster.nome_completo_razao_social_master
		, contamaster.cod_tipo_pessoa_master
		, contamaster.cod_atividade_economica_primaria_master
		, contamaster.cod_ocupacao_master 
		, contamaster.num_sequencial_situacao_master
		, contamaster.num_sequencial_situacao_vinculo_master 
		, contaprox.num_sequencial_conta_proximo_nivel
		, contaprox.num_identificacao_conta_proximo_nivel
		, contaprox.num_sequencial_entidade_participante_proximo_nivel
		, contaprox.num_sequencial_entidade_investidor_proximo_nivel
		, contaprox.cod_operacional_participante_proximo_nivel
		, contaprox.num_documento_identificacao_proximo_nivel
		, contaprox.num_documento_identificacao_formatado_proximo_nivel
		, contaprox.num_documento_identificacao_cvm_proximo_nivel
		, contaprox.nome_completo_razao_social_proximo_nivel
		, contaprox.cod_tipo_pessoa_proximo_nivel
		, contaprox.cod_atividade_economica_primaria_proximo_nivel
		, contaprox.cod_ocupacao_proximo_nivel  
		, contaprox.num_sequencial_situacao_proximo_nivel
		, contaprox.num_sequencial_situacao_vinculo_proximo_nivel 
		, contaprox.num_sequencial_conta_proximo_nivel as num_sequencial_conta_final
		, contaprox.num_identificacao_conta_proximo_nivel as num_identificacao_conta_final
		, contaprox.num_sequencial_entidade_participante_proximo_nivel as num_sequencial_entidade_participante_final
		, contaprox.num_sequencial_entidade_investidor_proximo_nivel as num_sequencial_entidade_investidor_final
		, contaprox.cod_operacional_participante_proximo_nivel as cod_operacional_participante_final
		, contaprox.num_documento_identificacao_proximo_nivel as num_documento_identificacao_final
		, contaprox.num_documento_identificacao_formatado_proximo_nivel as num_documento_identificacao_formatado_final
		, contaprox.num_documento_identificacao_cvm_proximo_nivel as num_documento_identificacao_cvm_final		
		, contaprox.nome_completo_razao_social_proximo_nivel as nome_completo_razao_social_final
		, contaprox.cod_tipo_pessoa_proximo_nivel as cod_tipo_pessoa_final
		, contaprox.cod_atividade_economica_primaria_proximo_nivel as cod_atividade_economica_primaria_final
		, contaprox.cod_ocupacao_proximo_nivel as cod_ocupacao_final
		, contaprox.num_sequencial_situacao_proximo_nivel as num_sequencial_situacao_final
		, contaprox.num_sequencial_situacao_vinculo_proximo_nivel as num_sequencial_situacao_vinculo_final
		, CASE WHEN (contaprox.num_sequencial_conta_proximo_nivel is not null) THEN  0 
			   WHEN (contaprox.num_sequencial_conta_proximo_nivel <>  conta.num_sequencial_conta) THEN  0 
			   /* Regra adicionada p/ tratar vinculos que apontam para a própria conta */
			   ELSE 1 END as ind_conta_final
		, conta.ind_cadastro_simplificado as ind_cadastro_simplificado 
		, conta.num_sequencial_titular_conta_telefone
		, conta.num_sequencial_titular_conta_email
		, entdocnresbmf45.cod_documento AS num_documento_nif
		, contaprox.num_documento_nif_proximo_nivel AS num_documento_nif_proximo_nivel
		, contaprox.num_documento_nif_proximo_nivel AS num_documento_nif_final
        , ent.num_sequencial_tipo_entidade as num_sequencial_tipo_entidade_investidor
        , contaprox.num_sequencial_tipo_entidade_investidor_proximo_nivel as num_sequencial_tipo_entidade_investidor_proximo_nivel
        , contaprox.num_sequencial_tipo_entidade_investidor_proximo_nivel as num_sequencial_tipo_entidade_investidor_final
		from dw.#tmp_TDWICDX_CONTA conta (nolock)
		left join hst.TDWICDX_TIPO_CONTA tconta (nolock)
			on conta.num_sequencial_tipo_conta = tconta.num_sequencial_tipo_conta 
			and  conta.data_calendario >= tconta.data_inicio_vigencia_historico
			and (conta.data_calendario <  tconta.data_fim_vigencia_historico or tconta.data_fim_vigencia_historico is null) 
		--left join dw.#tmpParCategoria par (nolock)
		--	on Conta.cod_operacional_participante = par.cod_operacional_participante 
		left join dw.#tmp_TDWICDX_TITULAR_CONTA titconta (nolock)
			on conta.cod_titular_conta = titconta.cod_titular_conta 
			and conta.cod_participante_negociacao = titconta.cod_participante_negociacao 	
			and conta.data_calendario = titconta.data_calendario

		left join hst.TDWICDX_SITUACAO sit (nolock)
			on conta.num_sequencial_situacao = sit.num_sequencial_situacao 
			and  conta.data_calendario >= sit.data_inicio_vigencia_historico
			and (conta.data_calendario <  sit.data_fim_vigencia_historico or sit.data_fim_vigencia_historico is null)
		left join hst.TDWICDX_MOTIVO_SITUACAO motsit (nolock)
			on conta.cod_motivo_situacao = motsit.cod_motivo_situacao  
			and  conta.data_calendario >= motsit.data_inicio_vigencia_historico
			and (conta.data_calendario <  motsit.data_fim_vigencia_historico or motsit.data_fim_vigencia_historico is null)	
		left join dw.#tmp_TDWICDX_ENTIDADE ent (nolock) 
			on conta.cod_titular_conta = ent.num_sequencial_entidade 
			and  conta.data_calendario = ent.data_calendario

		left join hst.TDWICDX_TIPO_ENTIDADE tent (nolock) 
			on ent.num_sequencial_tipo_entidade = tent.num_sequencial_tipo_entidade 
			and  conta.data_calendario >= tent.data_inicio_vigencia_historico 
			and (conta.data_calendario <  tent.data_fim_vigencia_historico or tent.data_fim_vigencia_historico is null)	

		left join dw.#tmp_TDWICDX_PESSOA_FISICA pf (nolock) 
			on ent.num_sequencial_entidade = pf.num_sequencial_entidade
			and  conta.data_calendario = pf.data_calendario

		left join dw.#tmp_TDWICDX_PESSOA_JURIDICA pj (nolock) 
			on ent.num_sequencial_entidade = pj.num_sequencial_entidade
			and  conta.data_calendario = pj.data_calendario  

		left join dw.#tmpdocumento_final entdocpf (nolock) 
			on ent.num_sequencial_entidade = entdocpf.num_sequencial_entidade and entdocpf.cod_tipo_documento = '2' 
		left join dw.#tmpdocumento_final entdocpj (nolock) 
			on ent.num_sequencial_entidade = entdocpj.num_sequencial_entidade and entdocpj.cod_tipo_documento = '1'  
		left join dw.#tmpdocumento_final entdocnresbov (nolock) 
			on ent.num_sequencial_entidade = entdocnresbov.num_sequencial_entidade and entdocnresbov.cod_tipo_documento = '17'
		left join dw.#tmpdocumento_final entdocnresbov18 (nolock) 
			on ent.num_sequencial_entidade = entdocnresbov18.num_sequencial_entidade and entdocnresbov18.cod_tipo_documento = '18'
		left join dw.#tmpdocumento_final entdocnresbmf19 (nolock) 
			on ent.num_sequencial_entidade = entdocnresbmf19.num_sequencial_entidade and entdocnresbmf19.cod_tipo_documento = '19'
		left join dw.#tmpdocumento_final entdocnresbmf20 (nolock) 
			on ent.num_sequencial_entidade = entdocnresbmf20.num_sequencial_entidade and entdocnresbmf20.cod_tipo_documento = '20'
		left join dw.#tmpdocumento_final entdocnresbmf45 (nolock) 
			on ent.num_sequencial_entidade = entdocnresbmf45.num_sequencial_entidade and entdocnresbmf45.cod_tipo_documento = '45'
		left join dw.#tmpdocumento_final entdoccvm (nolock) 
			on ent.num_sequencial_entidade = entdoccvm.num_sequencial_entidade and entdoccvm.cod_tipo_documento = '11'  
		left join dw.#conta_master contamaster (nolock)
			on conta.num_sequencial_conta = contamaster.num_sequencial_conta  	
			and  conta.data_calendario >= contamaster.data_inicio_vigencia_historico 
			and (conta.data_calendario <  contamaster.data_fim_vigencia_historico or contamaster.data_fim_vigencia_historico is null)	
		left join dw.#conta_proximo_nivel contaprox (nolock)
			on conta.num_sequencial_conta = contaprox.num_sequencial_conta  	
			and  conta.data_calendario >= contaprox.data_inicio_vigencia_historico
			and (conta.data_calendario <  contaprox.data_fim_vigencia_historico or contaprox.data_fim_vigencia_historico is null)	
		left join dw.#tmp_TDWICDX_TITULAR_CONTA_PESSOA_FISICA titcontaPF (nolock)
			on titconta.cod_titular_conta = titcontaPF.cod_titular_conta
			and titconta.cod_participante_negociacao = titcontaPF.cod_participante_negociacao
			and  conta.data_calendario = titcontaPF.data_calendario		
		where conta.data_calendario = @dt_base_processamento
		OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION')) --


		
		CREATE CLUSTERED INDEX IE_ADWCONTA ON DW.#ADWCONTA (num_sequencial_conta) 
		CREATE INDEX IE_ADWCONTA2 ON DW.#ADWCONTA (cod_operacional_participante) 

			
		----------------------------------------------------------------------------------------------
		/* Gera Temporária com o Proximo Nível de cada conta, para buscar a conta final recursivamente*/	
		SET @p_data_inicio = GETDATE();		
		
		select conta.num_sequencial_conta, conta.data_inicio_vigencia_historico, conta.data_fim_vigencia_historico   
		, contaprox.num_sequencial_conta as num_sequencial_conta_proximo_nivel
		, contaprox.num_identificacao_conta as num_identificacao_conta_proximo_nivel
		, contaprox.cod_participante_negociacao as num_sequencial_entidade_participante_proximo_nivel
		, contaprox.cod_titular_conta as num_sequencial_entidade_investidor_proximo_nivel
		, contaprox.cod_operacional_participante as cod_operacional_participante_proximo_nivel
		, case when entdocnresbovprox.cod_documento is not null then entdocnresbovprox.cod_documento 
				when entdocnresbovprox18.cod_documento is not null then entdocnresbovprox18.cod_documento
				when entdocnresbmfprox19.cod_documento is not null then entdocnresbmfprox19.cod_documento
				when entdocnresbmfprox20.cod_documento is not null then entdocnresbmfprox20.cod_documento
				when entdoccvmprox.cod_documento is not null then '990000000' + substring(entdoccvmprox.cod_documento,12,6)  
				else case when entprox.cod_tipo_pessoa = 'PF' then entdocpfprox.cod_documento when entprox.cod_tipo_pessoa = 'PJ' then entdocpjprox.cod_documento else null end 
			end as num_documento_identificacao_proximo_nivel
		, case when entdocnresbovprox.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox.cod_tipo_documento,entdocnresbovprox.cod_documento) 
				when entdocnresbovprox18.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbovprox18.cod_tipo_documento,entdocnresbovprox18.cod_documento)
				when entdocnresbmfprox19.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox19.cod_tipo_documento,entdocnresbmfprox19.cod_documento)
				when entdocnresbmfprox20.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocnresbmfprox20.cod_tipo_documento,entdocnresbmfprox20.cod_documento)		
				when entdoccvmprox.cod_documento is not null then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdoccvmprox.cod_tipo_documento,'990000000' + substring(entdoccvmprox.cod_documento,12,6))   
				else case when entprox.cod_tipo_pessoa = 'PF' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpfprox.cod_tipo_documento,entdocpfprox.cod_documento) 
							when entprox.cod_tipo_pessoa = 'PJ' then dw.FDW_MASCARA_TIPO_DOCUMENTO(entdocpjprox.cod_tipo_documento,entdocpjprox.cod_documento) 
							else null end 
				end as num_documento_identificacao_formatado_proximo_nivel
		, entdoccvmprox.cod_documento as num_documento_identificacao_cvm_proximo_nivel				
		, case when entprox.cod_tipo_pessoa = 'PF' then pfprox.nome_completo when entprox.cod_tipo_pessoa = 'PJ' then pjprox.nome_razao_social else null end as nome_completo_razao_social_proximo_nivel
		, titcontaprox.cod_tipo_pessoa as cod_tipo_pessoa_proximo_nivel
		, pjprox.cod_atividade_economica_primaria as cod_atividade_economica_primaria_proximo_nivel
		, ISNULL(titcontaPFprox.cod_ocupacao,  pfprox.cod_ocupacao) as cod_ocupacao_proximo_nivel 
		, contaprox.num_sequencial_situacao as num_sequencial_situacao_proximo_nivel
		, vincprox.num_sequencial_situacao as num_sequencial_situacao_vinculo_proximo_nivel  
		, tvincprox.nome_tipo_vinculo
		into dw.#tmpcontaprox
		from hst.TDWCLS_CALENDARIO caled (nolock) 
		join hst.TDWICDX_CONTA conta (nolock)
			on   caled.data_calendario >= conta.data_inicio_vigencia_historico
			and (caled.data_calendario <  conta.data_fim_vigencia_historico or conta.data_fim_vigencia_historico is null)
			and conta.num_sequencial_tipo_conta not in (13,14,15,16) /*Exclui contas do tipo SELIC: 13 - SELIC CUSTODIA, 14 - SELIC ESPECIAL CAMARA, 15 - SELIC ESPECIAL CAMARA, 16 - SELIC OUTROS*/
		inner join hst.TDWICDX_CONTA_VINCULADA contavincprox (nolock)
			on conta.num_sequencial_conta = contavincprox.num_sequencial_conta 
			and contavincprox.ind_parte_vinculo = 'P'
			and  caled.data_calendario >= contavincprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  contavincprox.data_fim_vigencia_historico or contavincprox.data_fim_vigencia_historico is null)		
		inner join hst.TDWICDX_VINCULO vincprox (nolock)
			on contavincprox.num_sequencial_vinculo = vincprox.num_sequencial_vinculo 
			and  caled.data_calendario >= vincprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  vincprox.data_fim_vigencia_historico or vincprox.data_fim_vigencia_historico is null)	
			and vincprox.num_sequencial_situacao in (6,9) /*Situação = ATIVO*/
		inner join hst.TDWICDX_TIPO_VINCULO tvincprox (nolock)
			on vincprox.num_sequencial_tipo_vinculo = tvincprox.num_sequencial_tipo_vinculo
			and tvincprox.nome_tipo_vinculo ='POR CONTA E ORDEM'
			and  caled.data_calendario >= tvincprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  tvincprox.data_fim_vigencia_historico or tvincprox.data_fim_vigencia_historico is null)		
		inner join hst.TDWICDX_CONTA_VINCULADA contavincprox2 (nolock)
			on vincprox.num_sequencial_vinculo = contavincprox2.num_sequencial_vinculo
			and contavincprox2.ind_parte_vinculo = 'C'
			and  caled.data_calendario >= contavincprox2.data_inicio_vigencia_historico
			and (caled.data_calendario <  contavincprox2.data_fim_vigencia_historico or contavincprox2.data_fim_vigencia_historico is null)	
		inner join hst.TDWICDX_CONTA contaprox (nolock)
			on contavincprox2.num_sequencial_conta = contaprox.num_sequencial_conta  
			and  caled.data_calendario >= contaprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  contaprox.data_fim_vigencia_historico or contaprox.data_fim_vigencia_historico is null)		
		left join hst.TDWICDX_TITULAR_CONTA titcontaprox (nolock)
			on contaprox.cod_titular_conta = titcontaprox.cod_titular_conta 
			and contaprox.cod_participante_negociacao = titcontaprox.cod_participante_negociacao 	
			and  caled.data_calendario >= titcontaprox.data_inicio_vigencia_historico
			and (caled.data_calendario < titcontaprox.data_fim_vigencia_historico or titcontaprox.data_fim_vigencia_historico is null) 
		left join hst.TDWICDX_TITULAR_CONTA_PESSOA_FISICA titcontaPFprox (nolock)
			on titcontaprox.cod_titular_conta = titcontaPFprox.cod_titular_conta
			and titcontaprox.cod_participante_negociacao = titcontaPFprox.cod_participante_negociacao
			and  caled.data_calendario >= titcontaPFprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  titcontaPFprox.data_fim_vigencia_historico or titcontaPFprox.data_fim_vigencia_historico is null)		
		left join hst.TDWICDX_ENTIDADE entprox (nolock) 
			on contaprox.cod_titular_conta  = entprox.num_sequencial_entidade 
			and  caled.data_calendario >= entprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  entprox.data_fim_vigencia_historico or entprox.data_fim_vigencia_historico is null)
		left join hst.TDWICDX_TIPO_ENTIDADE tentprox (nolock) 
			on entprox.num_sequencial_tipo_entidade = tentprox.num_sequencial_tipo_entidade 
			and  caled.data_calendario >= tentprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  tentprox.data_fim_vigencia_historico or tentprox.data_fim_vigencia_historico is null)	
		left join hst.TDWICDX_PESSOA_FISICA pfprox (nolock) 
			on entprox.num_sequencial_entidade = pfprox.num_sequencial_entidade
			and  caled.data_calendario >= pfprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  pfprox.data_fim_vigencia_historico or pfprox.data_fim_vigencia_historico is null) 
		left join hst.TDWICDX_PESSOA_JURIDICA pjprox (nolock) 
			on entprox.num_sequencial_entidade = pjprox.num_sequencial_entidade
			and  caled.data_calendario >= pjprox.data_inicio_vigencia_historico
			and (caled.data_calendario <  pjprox.data_fim_vigencia_historico or pjprox.data_fim_vigencia_historico is null)  
		left join dw.#tmpdocumento_final entdocpfprox (nolock) 
			on entprox.num_sequencial_entidade = entdocpfprox.num_sequencial_entidade and entdocpfprox.cod_tipo_documento = '2' 
		left join dw.#tmpdocumento_final entdocpjprox (nolock) 
			on entprox.num_sequencial_entidade = entdocpjprox.num_sequencial_entidade and entdocpjprox.cod_tipo_documento = '1'  
		left join dw.#tmpdocumento_final entdocnresbovprox (nolock) 
			on entprox.num_sequencial_entidade = entdocnresbovprox.num_sequencial_entidade and entdocnresbovprox.cod_tipo_documento = '17'
		left join dw.#tmpdocumento_final entdocnresbovprox18 (nolock) 
			on entprox.num_sequencial_entidade = entdocnresbovprox18.num_sequencial_entidade and entdocnresbovprox18.cod_tipo_documento = '18'
		left join dw.#tmpdocumento_final entdocnresbmfprox19 (nolock) 
			on entprox.num_sequencial_entidade = entdocnresbmfprox19.num_sequencial_entidade and entdocnresbmfprox19.cod_tipo_documento = '19'
		left join dw.#tmpdocumento_final entdocnresbmfprox20 (nolock) 
			on entprox.num_sequencial_entidade = entdocnresbmfprox20.num_sequencial_entidade and entdocnresbmfprox20.cod_tipo_documento = '20'			
		left join dw.#tmpdocumento_final entdoccvmprox (nolock) 
			on entprox.num_sequencial_entidade = entdoccvmprox.num_sequencial_entidade and entdoccvmprox.cod_tipo_documento = '11'  
		where caled.data_calendario = @dt_base_processamento

		
		
			
		SET @p_data_inicio = GETDATE();

		create clustered index IE_tmpcontaprox on dw.#tmpcontaprox (num_sequencial_conta)
		create index IE_tmpcontaprox2 on dw.#tmpcontaprox (num_sequencial_conta_proximo_nivel)
		
		
		----------------------------------------------------------------------------------------------	
		/* REaliza o Update da Conta Final com base na temporária gerada acima*/
		SET @p_data_inicio = GETDATE();	
		
		;WITH x_CTE AS (
		 SELECT a.num_sequencial_conta as Pai, 1 as Nivel, a.num_sequencial_conta
		 FROM dw.#tmpcontaprox a 
		 UNION ALL
		 SELECT p.Pai, p.Nivel + 1 as Nivel, e.num_sequencial_conta_proximo_nivel 
		 FROM dw.#tmpcontaprox e
		 INNER JOIN x_CTE p ON p.num_sequencial_conta = e.num_sequencial_conta 
		 )--, cte_conta_fin as

		 SELECT * INTO dw.#RECURSAO_PROX_NIVEL FROM x_CTE

		
		 SET @p_data_inicio = GETDATE();

		 CREATE CLUSTERED INDEX IE_RECURSAO_PROX_NIVEL ON dw.#RECURSAO_PROX_NIVEL (num_sequencial_conta)
		 CREATE INDEX IE_RECURSAO_PROX_NIVEL2 ON dw.#RECURSAO_PROX_NIVEL (Pai)
		
		SET @p_data_inicio = GETDATE();	
		
		 select contafin.Pai, contafin.num_sequencial_conta
			, contaprox.num_sequencial_conta_proximo_nivel
			, contaprox.num_identificacao_conta_proximo_nivel
			, contaprox.num_sequencial_entidade_participante_proximo_nivel
			, contaprox.num_sequencial_entidade_investidor_proximo_nivel
			, contaprox.cod_operacional_participante_proximo_nivel
			, contaprox.num_documento_identificacao_proximo_nivel
			, contaprox.num_documento_identificacao_formatado_proximo_nivel
			, contaprox.num_documento_identificacao_cvm_proximo_nivel
			, contaprox.nome_completo_razao_social_proximo_nivel
			, contaprox.cod_tipo_pessoa_proximo_nivel
			, contaprox.cod_atividade_economica_primaria_proximo_nivel
			, contaprox.cod_ocupacao_proximo_nivel  
			, contaprox.num_sequencial_situacao_proximo_nivel
			, contaprox.num_sequencial_situacao_vinculo_proximo_nivel
			 into dw.#conta_fin
			 from dw.#RECURSAO_PROX_NIVEL contafin
			 inner join dw.#tmpcontaprox contaprox on contafin.num_sequencial_conta = contaprox.num_sequencial_conta_proximo_nivel  
			 where contafin.num_sequencial_conta = (select top 1 xf.num_sequencial_conta 
																		from dw.#RECURSAO_PROX_NIVEL xf 
																		where xf.Pai = contafin.Pai 
																		order by xf.Nivel desc
																		)
		 --) 

		 
		 SET @p_data_inicio = GETDATE();

		
		
			
		 SET @p_data_inicio = GETDATE();


		 create clustered index IE_conta_fin on dw.#conta_fin (Pai)

		 
		
		SET @p_data_inicio = GETDATE();	

		 update dw.#ADWCONTA -- dw.ADWCONTA 
		    set 
		 num_sequencial_conta_final = cte_fin.num_sequencial_conta 
		 ,num_identificacao_conta_final = cte_fin.num_identificacao_conta_proximo_nivel 
		 ,num_sequencial_entidade_participante_final = cte_fin.num_sequencial_entidade_participante_proximo_nivel 
		 ,num_sequencial_entidade_investidor_final = cte_fin.num_sequencial_entidade_investidor_proximo_nivel 
		 ,cod_operacional_participante_final = cte_fin.cod_operacional_participante_proximo_nivel 
		 ,num_documento_identificacao_final = cte_fin.num_documento_identificacao_proximo_nivel 
		 ,num_documento_identificacao_formatado_final = cte_fin.num_documento_identificacao_formatado_proximo_nivel 
		 ,num_documento_identificacao_cvm_final = cte_fin.num_documento_identificacao_cvm_proximo_nivel
		 ,nome_completo_razao_social_final = cte_fin.nome_completo_razao_social_proximo_nivel 
		 ,cod_tipo_pessoa_final = cte_fin.cod_tipo_pessoa_proximo_nivel 
		 ,cod_atividade_economica_primaria_final = cte_fin.cod_atividade_economica_primaria_proximo_nivel 
		 ,cod_ocupacao_final = cte_fin.cod_ocupacao_proximo_nivel  
		 ,num_sequencial_situacao_final = cte_fin.num_sequencial_situacao_proximo_nivel 
		 ,num_sequencial_situacao_vinculo_final = cte_fin.num_sequencial_situacao_vinculo_proximo_nivel  
		 ,ind_conta_final = case when cte_fin.num_sequencial_conta = cte_fin.Pai then 1 else 0 end
		 from dw.#conta_fin cte_fin
		 where dw.#ADWCONTA.num_sequencial_conta = cte_fin.Pai 

		 SET @p_data_inicio = GETDATE();

		

		----------------------------------------------------------------------------------------------	
		/* Realiza o Update da Conta Final com base na temporária gerada acima, para as contas do Proximo Nível que não tem vinculo*/
		SET @p_data_inicio = GETDATE();	
		
		--;with xcte as 
		 SELECT a.num_sequencial_conta as Pai, 1 as Nivel, a.num_sequencial_conta
		 ,a.num_identificacao_conta
		 ,a.num_sequencial_entidade_participante
		 ,a.num_sequencial_entidade_investidor
		 ,a.cod_operacional_participante
		 ,a.num_documento_identificacao 
		 ,a.num_documento_identificacao_formatado
		 ,a.num_documento_identificacao_cvm
		 ,a.nome_completo_razao_social
		 ,a.cod_tipo_pessoa
		 ,a.cod_atividade_economica_primaria
		 ,a.cod_ocupacao 
		 ,a.num_sequencial_situacao
		 INTO dw.#xcte
		 FROM dw.#ADWCONTA a (nolock)
		 left join dw.#tmpcontaprox e on  a.num_sequencial_conta = e.num_sequencial_conta_proximo_nivel
		 where e.num_sequencial_conta is null 
		 --)

		 
		SET @p_data_inicio = GETDATE();	

		 CREATE CLUSTERED INDEX IE_xcte ON dw.#xcte (Pai)
		 
		 
		SET @p_data_inicio = GETDATE();	

		 update dw.#ADWCONTA set 
		 num_sequencial_conta_final = cte_fin.num_sequencial_conta 
		 ,num_identificacao_conta_final = cte_fin.num_identificacao_conta
		 ,num_sequencial_entidade_participante_final = cte_fin.num_sequencial_entidade_participante
		 ,num_sequencial_entidade_investidor_final = cte_fin.num_sequencial_entidade_investidor
		 ,cod_operacional_participante_final = cte_fin.cod_operacional_participante
		 ,num_documento_identificacao_final = cte_fin.num_documento_identificacao
		 ,num_documento_identificacao_formatado_final = cte_fin.num_documento_identificacao_formatado
		 ,num_documento_identificacao_cvm_final = cte_fin.num_documento_identificacao_cvm		 
		 ,nome_completo_razao_social_final = cte_fin.nome_completo_razao_social
		 ,cod_tipo_pessoa_final = cte_fin.cod_tipo_pessoa
		 ,cod_atividade_economica_primaria_final = cte_fin.cod_atividade_economica_primaria
		 ,cod_ocupacao_final = cte_fin.cod_ocupacao  
		 ,num_sequencial_situacao_final = cte_fin.num_sequencial_situacao
		 ,ind_conta_final = case when cte_fin.num_sequencial_conta = cte_fin.Pai then 1 else 0 end
		 from dw.#xcte cte_fin
		 where dw.#ADWCONTA.num_sequencial_conta = cte_fin.Pai 
			and dw.#ADWCONTA.ind_conta_final is null	
		

		SET @p_data_inicio = GETDATE();	

		
		----------------------------------------------------------------------------------------------	
		/* Realiza o Update da Conta Final com base na temporária gerada acima, para as contas que não tem vinculo*/
		SET @p_data_inicio = GETDATE();	
		
		--;with xcte as (
		 SELECT a.num_sequencial_conta as Pai, 1 as Nivel, a.num_sequencial_conta
		 ,a.num_identificacao_conta
		 ,a.num_sequencial_entidade_participante
		 ,a.num_sequencial_entidade_investidor
		 ,a.cod_operacional_participante
		 ,a.num_documento_identificacao 
		 ,a.num_documento_identificacao_formatado
		 ,a.num_documento_identificacao_cvm
		 ,a.nome_completo_razao_social
		 ,a.cod_tipo_pessoa
		 ,a.cod_atividade_economica_primaria
		 ,a.cod_ocupacao 
		 ,a.num_sequencial_situacao		 
		 INTO dw.#xcte2
		 FROM dw.#ADWCONTA a (nolock)
		 left join dw.#tmpcontaprox e on  a.num_sequencial_conta = e.num_sequencial_conta
		 where e.num_sequencial_conta is null 
		 --)
		 
		
		 CREATE CLUSTERED INDEX IE_xcte2 ON dw.#xcte2 (Pai)
		 
		
			
		SET @p_data_inicio = GETDATE();	