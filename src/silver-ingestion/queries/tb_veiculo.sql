SELECT
    id                  AS veiculo_id,
    apolice_id          AS apolice_id,
    marca               AS marca,
    modelo              AS modelo,
    ano                 AS ano,
    valor_fipe          AS valor_fipe,
    uso                 AS uso,
    km_rodado_estimado  AS km_rodado_estimado,
    dt_insercao         AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_veiculo