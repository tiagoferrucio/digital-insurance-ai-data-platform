SELECT
    NVL(id, -1)                                          AS fraude_sinal_id,
    NVL(sinistro_id, -1)                                 AS sinistro_id,
    UPPER(NVL(sinal_tipo, 'NÃO INFORMADO'))              AS sinal_tipo,
    NVL(score_fraude, 0.00)                              AS score_fraude,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_fraude_sinal