SELECT
    NVL(id, -1)                                          AS apolice_id,
    NVL(cliente_id, -1)                                  AS cliente_id,
    UPPER(NVL(tipo_seguro, 'NÃO INFORMADO'))             AS tipo_seguro,
    NVL(data_inicio, DATE '1900-01-01')                  AS data_inicio,
    NVL(data_fim, DATE '1900-01-01')                     AS data_fim,
    NVL(valor_premio, 0.00)                              AS valor_premio,
    NVL(valor_cobertura, 0.00)                           AS valor_cobertura,
    UPPER(NVL(status, 'NÃO INFORMADO'))                  AS status,
    NVL(score_risco_atual, 0.00)                         AS score_risco_atual,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
from lab_catalog_bronze.digital_insurance.tb_apolice