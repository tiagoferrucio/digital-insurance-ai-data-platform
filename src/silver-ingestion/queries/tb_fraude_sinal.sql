SELECT
    id              AS fraude_sinal_id,
    sinistro_id     AS sinistro_id,
    sinal_tipo      AS sinal_tipo,
    score_fraude    AS score_fraude,
    dt_insercao     AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_fraude_sinal