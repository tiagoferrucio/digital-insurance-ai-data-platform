SELECT
    NVL(id, -1)                                          AS sinistro_id,
    NVL(apolice_id, -1)                                  AS apolice_id,
    NVL(data_hora_abertura, TIMESTAMP '1900-01-01 00:00:00') AS data_hora_abertura,
    UPPER(NVL(tipo_sinistro, 'NÃO INFORMADO'))           AS tipo_sinistro,
    NVL(valor_estimado, 0.00)                            AS valor_estimado,
    NVL(latitude, 0.00)                                  AS latitude,
    NVL(longitude, 0.00)                                 AS longitude,
    UPPER(NVL(endereco_ocorrencia, 'NÃO INFORMADO'))     AS endereco_ocorrencia,
    UPPER(NVL(canal_abertura, 'NÃO INFORMADO'))          AS canal_abertura,
    UPPER(NVL(status, 'NÃO INFORMADO'))                  AS status,
    UPPER(NVL(descricao_texto, 'NÃO INFORMADO'))         AS descricao_texto,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_sinistro