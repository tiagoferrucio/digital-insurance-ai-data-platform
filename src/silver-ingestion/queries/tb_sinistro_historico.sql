SELECT
 	NVL(apolice_id, -1)                                  AS apolice_id,
    NVL(qtd_sinistros_ultimos_12m, -1)                   AS qtd_sinistros_ultimos_12m,
    NVL(qtd_sinistros_negados, -1)                       AS qtd_sinistros_negados,
    NVL(valor_total_pago_historico, 0.00)                AS valor_total_pago_historico,
    NVL(data_ultima_atualizacao, TIMESTAMP '1900-01-01 00:00:00') AS data_ultima_atualizacao,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_sinistro_historico