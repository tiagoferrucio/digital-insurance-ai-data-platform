SELECT
    id                          AS cliente_id,
    nome                        AS nome,
    cpf                         AS cpf,
    data_nascimento             AS data_nascimento,
    cidade                      AS cidade,
    uf                          AS uf,
    tempo_relacionamento_meses  AS tempo_relacionamento_meses,
    canal_aquisicao             AS canal_aquisicao,
    dt_insercao                 AS dt_insercao
from lab_catalog_bronze.digital_insurance.tb_cliente