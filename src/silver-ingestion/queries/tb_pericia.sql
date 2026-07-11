SELECT
    id              AS pericia_id,
    sinistro_id     AS sinistro_id,
    perito_id       AS perito_id,
    data_agendada   AS data_agendada,
    laudo_resumo    AS laudo_resumo,
    resultado       AS resultado,
    dt_insercao     AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_pericia