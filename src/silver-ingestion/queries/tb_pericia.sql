SELECT
    NVL(id, -1)                                          AS pericia_id,
    NVL(sinistro_id, -1)                                 AS sinistro_id,
    NVL(perito_id, -1)                                   AS perito_id,
    NVL(data_agendada, DATE '1900-01-01')                AS data_agendada,
    UPPER(NVL(laudo_resumo, 'NÃO INFORMADO'))            AS laudo_resumo,
    UPPER(NVL(resultado, 'NÃO INFORMADO'))               AS resultado,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_pericia