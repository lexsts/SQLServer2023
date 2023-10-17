create table cetip.tmp_commodity_opcao_aux AS
    SELECT
        i.num_indice_valorizacao,
        i.cod_indicador_financeiro,
        i.cod_indicador_financeiro_base,
        i.val_fator_conversao,
        fa.nom_fonte_apuracao             AS bolsa_referencia,
        fa.num_id_fonte_apuracao,
        ca.nom_criterio_apuracao          AS tipo,
        ca.cod_criterio_apuracao,
        icomm.nom_indicador_financeiro    AS commodity,
        imoeda.nom_indicador_financeiro   AS moeda,
        um.nom_unidade_medida             AS unidade_negociacao,
        um.num_unidade_medida,
        i.num_mes_base                    AS mes_venc,
        i.num_ano_base                    AS ano_venc,
        i.dat_limite_venc                 AS data_limite,
        i.nom_code_ric                    AS ric,
        fc.nom_fonte_coleta               AS fonte_informacao,
        fc.num_id_fonte_coleta,
        timoeda.nom_tipo_indicador        AS nome_indicador_moeda,
        ticomm.nom_tipo_indicador         AS nome_indicador_commodity,
        i.dat_exclusao
    FROM
        cetip.indice_valorizacao i 
		join cetip.indicador_financeiro   icomm on i.cod_indicador_financeiro = icomm.cod_indicador_financeiro
        join cetip.indicador_financeiro   imoeda on i.cod_indicador_financeiro_base = imoeda.cod_indicador_financeiro
        join cetip.tipo_indicador         ticomm on icomm.num_id_tipo_indicador = ticomm.num_id_tipo_indicador
        join cetip.tipo_indicador         timoeda on imoeda.num_id_tipo_indicador = timoeda.num_id_tipo_indicador
        join cetip.fonte_apuracao         fa on fa.num_id_fonte_apuracao = i.num_id_fonte_apuracao
        join cetip.criterio_apuracao      ca on ca.cod_criterio_apuracao = i.cod_criterio_apuracao
        join cetip.unidade_medida         um on um.num_unidade_medida = i.num_unidade_medida
        join cetip.fonte_coleta           fc on fc.num_id_fonte_coleta = i.num_id_fonte_coleta
    WHERE
        timoeda.num_id_tipo_indicador = 2
        AND ticomm.num_id_tipo_indicador = 4
        AND i.nom_limite_cotacao IS NULL
        AND i.dat_exclusao IS NULL

create index CETIP.IDX01_tmp_commodity_opcao_aux on cetip.tmp_commodity_opcao_aux(num_indice_valorizacao);		

create table cetip.tmp_ins_fin AS
SELECT
            *
        FROM
            cetip.instrumento_financeiro fi
        WHERE
            fi.dat_exclusao IS NULL
            AND fi.num_tipo_if = 22
        UNION ALL
        SELECT
            *
        FROM
            cetip.instrumento_financeiro fi2
        WHERE
            fi2.dat_exclusao >= '04/02/22'
            AND fi2.num_tipo_if = 22
            AND fi2.num_if = (
                SELECT
                    MAX(fi3.num_if)
                FROM
                    cetip.instrumento_financeiro fi3
                WHERE
                    fi3.cod_if = fi2.cod_if
                    AND fi3.num_tipo_if = 22
                    AND fi3.dat_exclusao >= '04/02/22'
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    cetip.instrumento_financeiro fi3
                WHERE
                    fi3.cod_if = fi2.cod_if
                    AND fi3.num_tipo_if = 22
                    AND fi3.dat_exclusao IS NULL
            )
create index CETIP.IDX01_tmp_ins_fin on cetip.tmp_ins_fin(NUM_IF);   
			
create table cetip.tmp_contrato_cedido AS
SELECT
                    ifcedido.cod_if cod_if_cedido,ifcedido.num_if
                FROM
                    cetip.instrumento_financeiro ifcedido
					join cetip.tmp_ins_fin ins_fin on ifcedido.num_if=ins_fin.num_if
                WHERE
                    ifcedido.num_tipo_if = 22
                    AND ifcedido.num_sistema = 55                    
                    AND ifcedido.cod_if <> ifcedido.cod_antigo_if
                    AND length(ifcedido.cod_if) = length(ifcedido.cod_antigo_if)
                    --AND ROWNUM = 1			
create index CETIP.IDX01_tmp_contrato_cedido on cetip.tmp_contrato_cedido(NUM_IF);   
					
		

SELECT
    SYSDATE                                     dat_arquivo,
    DECODE(vm_con_swap.fluxo_constante, 'S', 'FLUXO CONSTANTE', 'N', 'FLUXO NAO CONSTANTE', 'PAGAMENTO_FINAL') cod_tipo_fluxo_caixa,
    vm_con_swap.data_emissao                    data_emissao,
    vm_con_swap.instrumento_financeiro          cod_instrumento_financeiro,
    CASE
        WHEN ins_fin.num_id_sistema_origem = 1 THEN
            'BVMF_' || ins_fin.cod_if_sistema_origem
        ELSE
            (
                SELECT
                    ifcedido.cod_if cod_if_cedido
                FROM
                    cetip.instrumento_financeiro ifcedido
                WHERE ifcedido.num_if = ins_fin.num_if                    
                AND ROWNUM = 1
            )
    END cod_contrato_cedido,
    vm_con_swap.conta_parte                     cod_conta_parte,
	(
        SELECT
            pj.cod_nacional_pj
        FROM
            cetip.pessoa_juridica      pj,
            cetip.conta_participante   cp
        WHERE
            pj.num_id_entidade = cp.num_id_entidade
            AND cp.num_conta_participante = vm_con_swap.num_conta_parte
    ) cod_cnpj_participante_parte,
    vm_con_swap.cpf_cnpj_parte                  cod_cpf_cnpj_parte,
    vm_con_swap.conta_contraparte               cod_conta_contraparte,
    (
        SELECT
            pj.cod_nacional_pj
        FROM
            cetip.pessoa_juridica      pj,
            cetip.conta_participante   cp
        WHERE
            pj.num_id_entidade = cp.num_id_entidade
            AND cp.num_conta_participante = vm_con_swap.num_conta_contraparte
    ) cod_cnpj_participante_contra,
    vm_con_swap.cpf_cnpj_contraparte            cod_cpf_cnpj_contraparte,
    vm_con_swap.data_inicio_vigencia            data_inicio_vigencia,
    vm_con_swap.data_vencimento                 data_vencimento,
    '1' qte_inteira_positiva,
    vm_con_swap.valor_base_atual                val_base_atual,
    vm_con_swap.valor_base                      val_base_original,
    vm_con_swap.data_registro                   data_registro,
    vm_con_swap.percentual_termo_parte          val_percentual_curva_termo,
    vm_con_swap.pu_atual_termo                  val_preco_unitario_atual_termo,
    vm_con_swap.tipo_classe_termo_contraparte   cod_classe_indice_valor,
    vm_con_swap.denominacao_termo_parte         desc_denominacao_termo_parte,
    vm_con_swap.period_jur_dm_parte             cod_periodo_juro_parte,
    vm_con_swap.periodo_evento_parte            cod_periodo_evento_parte,
    vm_con_swap.data_inicio_juros_parte         data_inicio_juro_parte,
    vm_con_swap.tempo_period_amort_parte        cod_periodo_amortizacao_parte,
    vm_con_swap.period_amort_dm_parte           cod_tempo_pago_diferencial,
    vm_con_swap.data_inicio_amort_parte         data_inicio_amortizacao_parte,
    vm_con_swap.amort_sobre_valor_parte         cod_amortizacao_sobre_contrato,
    vm_con_swap.percentual_curva_parte          val_percentual_curva_parte,
    vm_con_swap.num_ind_val_curva_parte         cod_curva_parte,
    (
        SELECT
            nom_indice_valorizacao
        FROM
            cetip.indice_valorizacao iv
        WHERE
            iv.num_indice_valorizacao = vm_con_swap.num_ind_val_curva_parte
    ) nome_curva_parte,
    replace(vm_con_swap.denominacao_parte, ';', ',') desc_denominacao_curva_parte,
    vm_con_swap.taxa_juros_parte                val_taxa_juro_parte,
    vm_con_swap.valor_curva_atual_parte         val_base_parte,
    vm_con_swap.percentual_curva_contraparte    perc_curva_contraparte,
    nvl(
        CASE
            WHEN vm_con_swap.num_id_categoria_parte = 0 THEN
                (
                    SELECT DISTINCT
                        CASE
                            WHEN b.num_id_qualificacao = 73 THEN
                                (
                                    SELECT
                                        DECODE(num_id_classif_tp_classe_cvm, 17, 11, 18, 18, 19, 9, 20, 15, 21, 19, 23, 17) num_id_classif_tp_classe_cvm
                                    FROM
                                        cetip.estrategia   b, cetip.contrato     c
                                    WHERE
                                        b.num_id_estrategia = c.num_id_estrategia
                                        AND vm_con_swap.num_if = c.num_if
                                )
                            ELSE
                                DECODE(a.num_id_classificacao_tp_classe, 1, 9, 2, 1, 3, 4, 4, 3, 5, 5, 6, 8, 9, 12, 11, 9, 13, 14
                                , 15, 11, 16, 6, 26, 10, 27, 7, 28, 2, 29, 15)
                        END a
                    FROM
                        cetip.classificacao_tp_classe       a, cetip.rel_classificacao_tp_classe   b
                    WHERE
                        b.num_id_classif_tp_classe_n1 = a.num_id_classificacao_tp_classe
                        AND vm_con_swap.tipo_classe_parte = b.num_id_qualificacao
                )
            ELSE
                DECODE(vm_con_swap.num_id_categoria_parte, 4, 5, 23, 7, 5, 15, 1, 11, 8, 10, 2, 9)
        END, - 1) fat_risco_parte,
    vm_con_swap.num_ind_val_curva_contraparte   cod_curva_contraparte,
    (
        SELECT
            nom_indice_valorizacao
        FROM
            cetip.indice_valorizacao iv
        WHERE
            iv.num_indice_valorizacao = vm_con_swap.num_ind_val_curva_contraparte
    ) nome_curva_contraparte,
    replace(vm_con_swap.denominacao_contraparte, ';', ',') desc_denominacao_contraparte,
    vm_con_swap.taxa_juros_contraparte          val_taxa_juro_contraparte,
    vm_con_swap.valor_curva_atual_contraparte   val_base_contraparte,
    vm_con_swap.pu_inicial_parte                val_preco_unitario_parte,
    nvl(
        CASE
            WHEN vm_con_swap.num_id_categoria_contraparte = 0 THEN
                (
                    SELECT DISTINCT
                        CASE
                            WHEN b.num_id_qualificacao = 73 THEN
                                (
                                    SELECT
                                        DECODE(num_id_classif_tp_classe_cvm, 17, 11, 18, 18, 19, 9, 20, 15, 21, 19, 23, 17) num_id_classif_tp_classe_cvm
                                    FROM
                                        cetip.estrategia   b, cetip.contrato     c
                                    WHERE
                                        b.num_id_estrategia = c.num_id_estrategia
                                        AND vm_con_swap.num_if = c.num_if
                                )
                            ELSE
                                DECODE(a.num_id_classificacao_tp_classe, 1, 9, 2, 1, 3, 4, 4, 3, 5, 5, 6, 8, 9, 12, 11, 9, 13, 14
                                , 15, 11, 16, 6, 26, 10, 27, 7, 28, 2, 29, 15)
                        END a
                    FROM
                        cetip.classificacao_tp_classe       a, cetip.rel_classificacao_tp_classe   b
                    WHERE
                        b.num_id_classif_tp_classe_n1 = a.num_id_classificacao_tp_classe
                        AND vm_con_swap.tipo_classe_contraparte = b.num_id_qualificacao
                )
            ELSE
                DECODE(vm_con_swap.num_id_categoria_contraparte, 4, 5, 23, 7, 5, 15, 1, 11, 8, 10, 2, 9)
        END, - 1) fat_risco_contraparte,
    vm_con_swap.tipo_classe_parte               cod_tipo_classe_parte,
    vm_con_swap.nome_tipo_classe_parte          nome_tipo_classe_parte,
    vm_con_swap.pu_inicial_contraparte          val_preco_unitario_contra,
    vm_con_swap.tipo_classe_contraparte         cod_tipo_classe_contraparte,
    vm_con_swap.nome_tipo_classe_contraparte    nome_tipo_classe_contraparte,
    vm_con_swap.cupom_limpo_parte               val_cupom_limpo_parte,
    vm_con_swap.tipo_unidade_tempo_parte        cod_tipo_unidade_tempo_parte,
    CASE
        WHEN parametro_parte IN (
            'LIBOR',
            'TJMI'
        ) THEN
            DECODE(variacao_cambial_parte, 4, 'DI', 2, 'SELIC', 72, 'DOLAR', 568, 'EURO', 563, 'IENE', 565, 'LIBRA', 1, 'OUTROS',
            5, 'OURO', 21, 'TR', 24, 'TJLP', 25, 'TBF', 4854, 'DOLAR 11:30', 7239, 'SELIC C/J', ' ')
        ELSE
            ' '
    END cod_varia_cambial_parte,
    vm_con_swap.tipo_libor_per_parte            cod_tipo_libor_parte,
    vm_con_swap.data_referencia_parte           cod_referencia_libor_parte,
    vm_con_swap.outros_cotacao_parte            val_outros_cambio_parte,
    vm_con_swap.aliquota_ir_parte               val_aliquota_ir_libor_parte,
    vm_con_swap.limite_inf_libor_parte          val_inferior_libor_parte,
    vm_con_swap.limite_sup_libor_parte          val_superior_libor_parte,
    CASE
        WHEN parametro_contraparte IN (
            'LIBOR',
            'TJMI'
        ) THEN
            DECODE(variacao_cambial_contraparte, 4, 'DI', 2, 'SELIC', 72, 'DOLAR', 568, 'EURO', 563, 'IENE', 565, 'LIBRA', 1, 'OUTROS'
            , 5, 'OURO', 21, 'TR', 24, 'TJLP', 25, 'TBF', 4854, 'DOLAR 11:30', 7239, 'SELIC C/J', ' ')
        ELSE
            ' '
    END cod_varia_cambial_libor_contra,
    vm_con_swap.tipo_libor_per_contraparte      cod_tipo_libor_contraparte,
    vm_con_swap.data_referencia_contraparte     cod_referencia_libor_contra,
    vm_con_swap.outros_cotacao_contraparte      val_outros_cambio_contraparte,
    vm_con_swap.aliquota_ir_contraparte         val_aliquota_ir_contraparte,
    vm_con_swap.limite_inf_libor_contraparte    val_inferior_libor_contraparte,
    vm_con_swap.limite_sup_libor_contraparte    val_superior_libor_contraparte,
    vm_con_swap.taxa_juros_tjmi_parte           val_taxa_juro_tjmi_parte,
    vm_con_swap.troca_fluxo_tjmi_parte          cod_troca_fluxo_tjmi_parte,
    CASE
        WHEN parametro_parte IN (
            'LIBOR',
            'TJMI'
        ) THEN
            DECODE(var_cambial_tjmi_parte, 4, 'DI', 2, 'SELIC', 72, 'DOLAR', 568, 'EURO', 563, 'IENE', 565, 'LIBRA', 1, 'OUTROS',
            5, 'OURO', 21, 'TR', 24, 'TJLP', 25, 'TBF', 4854, 'DOLAR 11:30', 7239, 'SELIC C/J', ' ')
        ELSE
            ' '
    END cod_varia_cambial_tjmi_parte,
    vm_con_swap.cotacao_tjmi_parte              val_cotacao_tjmi_parte,
    vm_con_swap.aliquota_ir_tjmi_parte          val_aliquota_ir_tjmi_parte,
    vm_con_swap.limite_inf_tjmi_parte           val_limite_inferior_tjmi_parte,
    vm_con_swap.limite_sup_tjmi_parte           val_limite_superior_tjmi_parte,
    vm_con_swap.taxa_juros_tjmi_contraparte     val_taxa_juro_tjmi_contraparte,
    vm_con_swap.troca_fluxo_tjmi_contraparte    cod_troca_fluxo_tjmi_contra,
    CASE
        WHEN parametro_contraparte IN (
            'LIBOR',
            'TJMI'
        ) THEN
            DECODE(var_cambial_tjmi_contraparte, 4, 'DI', 2, 'SELIC', 72, 'DOLAR', 568, 'EURO', 563, 'IENE', 565, 'LIBRA', 1, 'OUTROS'
            , 5, 'OURO', 21, 'TR', 24, 'TJLP', 25, 'TBF', 4854, 'DOLAR 11:30', 7239, 'SELIC C/J', ' ')
        ELSE
            ' '
    END cod_varia_cambial_tjmi_contra,
    vm_con_swap.cotacao_tjmi_contraparte        val_cotacao_tjmi_contraparte,
    vm_con_swap.aliquota_ir_tjmi_contraparte    val_aliquota_ir_tjmi_contra,
    vm_con_swap.limite_inf_tjmi_contraparte     val_inferior_tjmi_contraparte,
    vm_con_swap.limite_sup_tjmi_contraparte     val_superior_tjmi_contraparte,
    DECODE(vm_con_swap.cod_tipo_contrato, '0', 'SEM FUNCIONALIDADE', vm_con_swap.tipo_contrato) cod_funcionalidade_contrato,
    vm_con_swap.valor_antecipacao_acumulada     val_antecipacao_acumulada,
    nvl(vm_con_swap.curva_trigin_parte, vm_con_swap.curva_trigin_contraparte) cod_curva_trigger_in,
    nvl(vm_con_swap.valor_trigin_parte, vm_con_swap.valor_trigin_contraparte) val_trigger_in,
    nvl(vm_con_swap.variacao_trigin_parte, vm_con_swap.variacao_trigin_contraparte) cod_verificacao_trigger_in,
    nvl(vm_con_swap.data_trigin_parte, vm_con_swap.data_trigin_contraparte) data_disparo_trigger_in,
    nvl(vm_con_swap.curva_trigout_parte, vm_con_swap.curva_trigout_contraparte) cod_curva_trigger_out,
    nvl(vm_con_swap.valor_trigout_parte, vm_con_swap.valor_trigout_contraparte) val_trigger_out,
    nvl(vm_con_swap.variacao_trigout_parte, vm_con_swap.variacao_trigout_contraparte) cod_verificacao_trigger_out,
    nvl(vm_con_swap.data_trigout_parte, vm_con_swap.data_trigout_contraparte) data_disparo_trigger_out,
    nvl(vm_con_swap.valor_premio1_parte, vm_con_swap.valor_premio1_contraparte) val_premio_1,
    nvl(vm_con_swap.data_premio1_parte, vm_con_swap.data_premio1_contraparte) data_premio_1,
    nvl(vm_con_swap.valor_premio2_parte, vm_con_swap.valor_premio2_contraparte) val_premio_2,
    nvl(vm_con_swap.data_premio2_parte, vm_con_swap.data_premio2_contraparte) data_premio_2,
    nvl(vm_con_swap.valor_rebate_parte, vm_con_swap.valor_rebate_contraparte) val_rebate,
    nvl(vm_con_swap.tipo_rebate_parte, vm_con_swap.tipo_rebate_contraparte) cod_tipo_rebate,
    nvl(vm_con_swap.qtd_dias_rebate_parte, vm_con_swap.qtd_dias_rebate_contraparte) qte_dia_util_rebate,
    vm_con_swap.comissao_parte                  val_percentual_comissao_parte,
    vm_con_swap.comissao_contraparte            perc_comissao_contraparte,
    nvl(vm_con_swap.curva_terc_curva_parte, vm_con_swap.curva_terc_curva_contraparte) cod_curva_terceira_parte,
    nvl(vm_con_swap.cupom_terc_curva_parte, vm_con_swap.cupom_terc_curva_contraparte) val_cupom_terceira_curva_parte,
    nvl(vm_con_swap.perc_terc_curva_parte, vm_con_swap.perc_terc_curva_contraparte) perc_terceira_curva_parte,
    CASE
        WHEN nvl(vm_con_swap.juros_terc_curva_parte, vm_con_swap.juros_terc_curva_contraparte) < 0 THEN
            '-'
        WHEN nvl(vm_con_swap.juros_terc_curva_parte, vm_con_swap.juros_terc_curva_contraparte) >= 0 THEN
            '+'
    END cod_sinal_terceira_curva_parte,
    nvl(vm_con_swap.juros_terc_curva_parte, vm_con_swap.juros_terc_curva_contraparte) val_juro_terceira_curva_parte,
    nvl(vm_con_swap.lim_inf_terc_curva_parte, vm_con_swap.lim_inf_terc_curva_contraparte) cod_inferior_terceira_parte,
    (
        SELECT
            nvl(nvl(pltc.val_limite, vm_con_swap.cupom_terc_curva_parte), vm_con_swap.cupom_terc_curva_contraparte)
        FROM
            cetip.condicao_if        cifpltc2,
            cetip.parametro_limite   pltc
        WHERE
            cifpltc2.num_condicao_if = pltc.num_condicao_if
            AND cifpltc2.cod_tipo_condicao_if = 17
            AND pltc.ind_terc_curva = 'S'
            AND cifpltc2.num_id_parametro_ponta IN (
                vm_con_swap.parametro_ponta_parte,
                vm_con_swap.parametro_ponta_contraparte
            )
    ) val_limite_terceira_curva,
    vm_con_swap.cesta_garant_parte              cod_cesta_garantia_parte,
    vm_con_swap.cesta_garant_contraparte        cod_cesta_garantia_contraparte,
    vm_con_swap.contrato_global                 ind_adesao_contrato_global,
    ( nvl(vm_con_swap.valor_base_atual, 0) - nvl(vm_con_swap.valor_total_amortizado, 0) - nvl(vm_con_swap.valor_antecipacao_acumulada
    , 0) ) val_base_remanescente,
    vm_con_swap.ind_mantem_premio               ind_manter_premio,
    vm_con_swap.ind_reset                       ind_reset,
    vm_con_swap.observacao                      desc_observacao_adcional,
    vm_con_swap.tipo_classe_termo_parte         cod_classe_vcp_termo_parte,
    vm_con_swap.tempo_period_juros_parte        cod_periodo_pago_diferencial,
    vm_con_swap.data_tr_parte                   data_tr_parte,
    DECODE(vm_con_swap.sinal_juros_parte, 'S', '+', '-') cod_sinal_taxa_parte,
    vm_con_swap.limite_inferior_parte           val_limite_inferior_parte,
    vm_con_swap.limite_superior_parte           val_limite_superior_parte,
    vm_con_swap.data_tr_contraparte             data_tr_contraparte,
    DECODE(vm_con_swap.sinal_juros_contraparte, 'S', '+', '-') cod_sinal_taxa_contraparte,
    vm_con_swap.limite_inferior_contraparte     val_inferior_contraparte,
    vm_con_swap.limite_superior_contraparte     val_superior_contraparte,
    DECODE(vm_con_swap.curva_terc_curva_parte, NULL, DECODE(vm_con_swap.curva_terc_curva_contraparte, NULL, NULL, 1), 0) cod_participante_terceira
    ,
    vm_con_swap.cupom_limpo_contraparte         val_cupom_limpo_contraparte,
    DECODE(vm_con_swap.periodo_evento_contraparte, 'D-1', 1, 'D-2', 2, 'D-3', 3) cod_periodo_evento_contraparte,
    DECODE(vm_con_swap.tipo_libor_moeda_parte, 72, 15, 568, 33, 563, 35, 565, 36) cod_tipo_libor_moeda_parte,
    DECODE(vm_con_swap.tipo_libor_moeda_contraparte, 72, 15, 568, 33, 563, 35, 565, 36) cod_tipo_libor_moeda_contra,
    DECODE(vm_con_swap.valor_premio1_parte, NULL, DECODE(vm_con_swap.valor_premio1_contraparte, NULL, NULL, 1), 0) cod_titular_premio
    ,
    vm_con_swap.cod_estrategia                  cod_estrategia,
    estrategia.nom_estrategia                   nome_estrategia,
    vm_con_swap.data_ultima_antecipacao         data_ultima_antecipacao,
    CASE
        WHEN EXISTS (
            SELECT
                1
            FROM
                cetip.posicao_derivativo pos_deriv
            WHERE
                pos_deriv.cod_if = vm_con_swap.instrumento_financeiro
                AND pos_deriv.dat_exclusao IS NULL
        ) THEN
            'S'
        ELSE
            'N'
    END ind_exposicao_cambial,
    CASE
        WHEN EXISTS (
            SELECT
                1
            FROM
                cetip.pagamento_periodico pag_period
            WHERE
                pag_period.num_if = vm_con_swap.num_if
                AND pag_period.dat_exclusao IS NULL
        ) THEN
            'S'
        ELSE
            'N'
    END ind_redutor_risco_credito,
    cetip.get_cod_indice_valorizacao(vm_con_swap.indice_termo_parte) cod_indice_termo_parte,
    CASE
        WHEN vm_con_swap.num_id_categoria_parte = 0
             OR vm_con_swap.num_id_categoria_contraparte = 0 THEN
            nvl(mtm_parte.dat_marcacao_mercado, mtm_contra.dat_marcacao_mercado)
        ELSE
            mtm_parte.dat_marcacao_mercado
    END data_mtm_parte,
    (
        SELECT
            mtm.val_marcacao_mercado
        FROM
            cetip.marcacao_mercado mtm
        WHERE
            mtm.num_id_parametro_ponta = vm_con_swap.parametro_ponta_parte
            AND mtm.num_id_marcacao_mercado = (
                SELECT
                    MAX(mm.num_id_marcacao_mercado)
                FROM
                    cetip.marcacao_mercado mm
                WHERE
                    mm.num_id_parametro_ponta = vm_con_swap.parametro_ponta_parte
                    AND mm.dat_exclusao IS NULL
                    AND mm.dat_marcacao_mercado IS NOT NULL
            )
    ) val_mtm_parte,
    CASE
        WHEN vm_con_swap.num_id_categoria_parte = 0
             OR vm_con_swap.num_id_categoria_contraparte = 0 THEN
            nvl(mtm_contra.dat_marcacao_mercado, mtm_parte.dat_marcacao_mercado)
        ELSE
            mtm_contra.dat_marcacao_mercado
    END data_mtm_contraparte,
    (
        SELECT
            mtm.val_marcacao_mercado
        FROM
            cetip.marcacao_mercado mtm
        WHERE
            mtm.num_id_parametro_ponta = vm_con_swap.parametro_ponta_contraparte
            AND mtm.num_id_marcacao_mercado = (
                SELECT
                    MAX(mm.num_id_marcacao_mercado)
                FROM
                    cetip.marcacao_mercado mm
                WHERE
                    mm.num_id_parametro_ponta = vm_con_swap.parametro_ponta_contraparte
                    AND mm.dat_exclusao IS NULL
                    AND mm.dat_marcacao_mercado IS NOT NULL
            )
    ) val_mtm_contraparte,
    (
        SELECT
            MIN(mm2.val_exposicao_min)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_parte
            AND mm2.dat_exclusao IS NULL
    ) val_minimo_nocional_parte,
    (
        SELECT
            MIN(mm2.val_exposicao_max)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_parte
            AND mm2.dat_exclusao IS NULL
    ) val_maximo_nocional_parte,
    (
        SELECT
            MAX(mm2.dat_exposicao)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_parte
            AND mm2.dat_exclusao IS NULL
    ) data_nocional_parte,
    (
        SELECT
            MIN(mm2.val_exposicao_min)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_contraparte
            AND mm2.dat_exclusao IS NULL
    ) val_minimo_nocional_contra,
    (
        SELECT
            MIN(mm2.val_exposicao_max)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_contraparte
            AND mm2.dat_exclusao IS NULL
    ) val_maximo_nocional_contra,
    (
        SELECT
            MAX(mm2.dat_exposicao)
        FROM
            cetip.marcacao_mercado mm2
        WHERE
            mm2.num_if = vm_con_swap.num_if
            AND mm2.num_id_parametro_ponta = vm_con_swap.parametro_ponta_contraparte
            AND mm2.dat_exclusao IS NULL
    ) data_nocional_contraparte,
    0 cod_mtm_cetip_parte,
    0 cod_mtm_cetip_contraparte,
    vm_con_swap.cod_situacao_contrato           cod_situacao_contrato,
    vm_con_swap.cod_situacao_if                 cod_situacao_instrumento,
    (
        SELECT
            pos_deriv.val_notional_ajustado_mbc
        FROM
            cetip.posicao_derivativo     pos_deriv,
            cetip.controle_operacional   cont_oper
        WHERE
            pos_deriv.cod_if = vm_con_swap.instrumento_financeiro
            AND pos_deriv.dat_referencia = cont_oper.dat_ctl_oper
            AND pos_deriv.dat_exclusao IS NULL
            AND cont_oper.num_ordem = 0
            AND cont_oper.num_sistema IS NULL
    ) val_delta,
    CASE
        WHEN vm_con_swap.conta_acelerador IS NOT NULL THEN
            DECODE((
                SELECT
                    aif.num_conta_contraparte
                FROM
                    cetip.aceleracao_if aif
                WHERE
                    aif.num_if = ins_fin.num_if
                    AND aif.dat_exclusao IS NULL
            ), NULL, vm_con_swap.conta_acelerador, 'AMBOS')
        ELSE
            NULL
    END cod_conta_acelerador,
    vm_con_swap.nome_acelerador                 nome_acelerador,
    (
        SELECT
            DECODE(cpac.cod_conta_participante, '99999.00-5', 1, DECODE(ac.num_conta_contraparte, NULL, 2, 3))
        FROM
            cetip.agente_calculo       ac,
            cetip.conta_participante   cpac
        WHERE
            ac.num_conta_participante = cpac.num_conta_participante
            AND ac.num_if = vm_con_swap.num_if
            AND ac.dat_exclusao IS NULL
    ) cod_tipo_agente_calculo,
    vm_con_swap.conta_agente_calculo            cod_conta_agente_calculo,
    ins_fin.ind_paga_so_juros                   ind_amortizar_sem_diferencial,
    vm_con_swap.codigo_identificador            cod_identificador,
    (
        SELECT
            DECODE(cetip.f_has_commodity(atu_pos_parte.num_indice_valorizacao), 1, commodity_parte.ric, NULL)
        FROM
            cetip.tmp_commodity_opcao_aux commodity_parte
        WHERE
            atu_pos_parte.num_indice_valorizacao = commodity_parte.num_indice_valorizacao (+)
    ) cod_commodity_parte,
    vm_con_swap.media_asiatiaca_parte           cod_media_asiatica_parte,
    DECODE(cetip.f_has_commodity(atu_pos_parte.num_indice_valorizacao), 1, cetip.f_periodo_evento(atu_pos_parte.cod_deslocamento_indice
    ), NULL) cod_periodo_ajuste_parte,
    (
        SELECT
            DECODE(commodity_parte.ric, NULL, ' ', par_ponta_parte.val_pu_inicial, NULL)
        FROM
            cetip.tmp_commodity_opcao_aux commodity_parte
        WHERE
            atu_pos_parte.num_indice_valorizacao = commodity_parte.num_indice_valorizacao (+)
    ) val_cotacao_inicial_parte,
    (
        SELECT
            DECODE(cetip.f_has_commodity(atu_pos_contraparte.num_indice_valorizacao), 1, commodity_contraparte.ric, NULL)
        FROM
            cetip.tmp_commodity_opcao_aux commodity_contraparte
        WHERE
            atu_pos_contraparte.num_indice_valorizacao = commodity_contraparte.num_indice_valorizacao (+)
    ) cod_commodity_contraparte,
    vm_con_swap.media_asiatiaca_contraparte     cod_media_asiatica_contra,
    DECODE(cetip.f_has_commodity(atu_pos_contraparte.num_indice_valorizacao), 1, cetip.f_periodo_evento(atu_pos_contraparte.cod_deslocamento_indice
    ), NULL) cod_periodo_ajuste_contraparte,
    (
        SELECT
            DECODE(commodity_contraparte.ric, NULL, ' ', par_ponta_contraparte.val_pu_inicial, NULL)
        FROM
            cetip.tmp_commodity_opcao_aux commodity_contraparte
        WHERE
            atu_pos_contraparte.num_indice_valorizacao = commodity_contraparte.num_indice_valorizacao (+)
    ) val_cotacao_inicial_contra,
    CASE
        WHEN vm_con_swap.curva_trigin_parte IS NOT NULL THEN
            'PARTE'
        WHEN vm_con_swap.curva_trigin_contraparte IS NOT NULL THEN
            'CONTRAPARTE'
        ELSE
            NULL
    END nome_ponta_trigger_in,
    CASE
        WHEN vm_con_swap.curva_trigout_parte IS NOT NULL THEN
            'PARTE'
        WHEN vm_con_swap.curva_trigout_contraparte IS NOT NULL THEN
            'CONTRAPARTE'
        ELSE
            NULL
    END nome_ponta_trigger_out
FROM
    cetip.v_dw_contratos_swap vm_con_swap,
    cetip.estrategia estrategia,
    cetip.tmp_ins_fin ins_fin, --CRIADA TABELA TEMPORARIA
    cetip.condicao_if cond_if_parte,
    cetip.atualizacao_pos atu_pos_parte,
    cetip.parametro_ponta par_ponta_parte,
    cetip.condicao_if cond_if_contraparte,
    cetip.atualizacao_pos atu_pos_contraparte,
    cetip.parametro_ponta par_ponta_contraparte,
    (
        SELECT
            mm.num_if,
            mm.dat_marcacao_mercado,
            mm.num_id_parametro_ponta,
            mm.val_marcacao_mercado
        FROM
            cetip.marcacao_mercado mm,
            (
                SELECT
                    num_if,
                    MAX(mm.dat_marcacao_mercado) dat_marcacao_mercado,
                    MAX(mm.num_id_marcacao_mercado) num_id_marcacao_mercado
                FROM
                    cetip.marcacao_mercado mm
                WHERE
                    mm.dat_exclusao IS NULL
                    AND dat_marcacao_mercado IS NOT NULL
                    AND num_id_parametro_ponta IS NOT NULL
                GROUP BY
                    num_if
            ) mm2
        WHERE
            mm.num_if = mm2.num_if
            AND mm.num_id_marcacao_mercado = mm2.num_id_marcacao_mercado
            AND mm.dat_exclusao IS NULL
            AND mm.dat_marcacao_mercado IS NOT NULL
            AND mm.num_id_parametro_ponta IS NOT NULL
    ) mtm_parte,
    (
        SELECT
            mm.num_if,
            mm.dat_marcacao_mercado,
            mm.num_id_parametro_ponta,
            mm.val_marcacao_mercado
        FROM
            cetip.marcacao_mercado mm,
            (
                SELECT
                    num_if,
                    MAX(mm.dat_marcacao_mercado) dat_marcacao_mercado,
                    MAX(mm.num_id_marcacao_mercado) num_id_marcacao_mercado
                FROM
                    cetip.marcacao_mercado mm
                WHERE
                    mm.dat_exclusao IS NULL
                    AND dat_marcacao_mercado IS NOT NULL
                    AND num_id_parametro_ponta IS NOT NULL
                GROUP BY
                    num_if
            ) mm2
        WHERE
            mm.num_if = mm2.num_if
            AND mm.num_id_marcacao_mercado = mm2.num_id_marcacao_mercado
            AND mm.dat_exclusao IS NULL
            AND mm.dat_marcacao_mercado IS NOT NULL
            AND mm.num_id_parametro_ponta IS NOT NULL
    ) mtm_contra
WHERE
    vm_con_swap.cod_estrategia = estrategia.cod_estrategia (+)
    AND vm_con_swap.data_vencimento >= '04/02/22'
    AND vm_con_swap.papel_parte = 'P1'
    AND vm_con_swap.num_if = ins_fin.num_if
    AND vm_con_swap.parametro_ponta_parte = cond_if_parte.num_id_parametro_ponta (+)
    AND cond_if_parte.cod_tipo_condicao_if (+) = 4
    AND cond_if_parte.num_condicao_if = atu_pos_parte.num_condicao_if (+)
    AND vm_con_swap.parametro_ponta_parte = par_ponta_parte.num_id_parametro_ponta (+)
    AND vm_con_swap.parametro_ponta_contraparte = cond_if_contraparte.num_id_parametro_ponta (+)
    AND cond_if_contraparte.cod_tipo_condicao_if (+) = 4
    AND cond_if_contraparte.num_condicao_if = atu_pos_contraparte.num_condicao_if (+)
    AND vm_con_swap.parametro_ponta_contraparte = par_ponta_contraparte.num_id_parametro_ponta (+)
    AND mtm_parte.num_if (+) = vm_con_swap.num_if
    AND mtm_parte.num_id_parametro_ponta (+) = vm_con_swap.parametro_ponta_parte
    AND mtm_contra.num_if (+) = vm_con_swap.num_if
    AND mtm_contra.num_id_parametro_ponta (+) = vm_con_swap.parametro_ponta_contraparte