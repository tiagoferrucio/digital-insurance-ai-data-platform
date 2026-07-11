SELECT
    id                  AS apolice_id,
    cliente_id          AS cliente_id,
    tipo_seguro         AS tipo_seguro,
    data_inicio         AS data_inicio,
    data_fim            AS data_fim,
    valor_premio        AS valor_premio,
    valor_cobertura     AS valor_cobertura,
    status              AS status,
    score_risco_atual   AS score_risco_atual,
    dt_insercao         AS dt_insercao_db
from lab_catalog_bronze.digital_insurance.tb_apolice