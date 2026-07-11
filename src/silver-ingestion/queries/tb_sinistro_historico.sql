SELECT
    apolice_id                  AS apolice_id,
    qtd_sinistros_ultimos_12m   AS qtd_sinistros_ultimos_12m,
    qtd_sinistros_negados       AS qtd_sinistros_negados,
    valor_total_pago_historico  AS valor_total_pago_historico,
    data_ultima_atualizacao     AS data_ultima_atualizacao,
    dt_insercao                 AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_sinistro_historico