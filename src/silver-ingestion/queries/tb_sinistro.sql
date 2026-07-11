SELECT
    id                  AS sinistro_id,
    apolice_id          AS apolice_id,
    data_hora_abertura  AS data_hora_abertura,
    tipo_sinistro       AS tipo_sinistro,
    valor_estimado      AS valor_estimado,
    latitude            AS latitude,
    longitude           AS longitude,
    endereco_ocorrencia AS endereco_ocorrencia,
    canal_abertura      AS canal_abertura,
    status              AS status,
    descricao_texto     AS descricao_texto,
    dt_insercao         AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_sinistro