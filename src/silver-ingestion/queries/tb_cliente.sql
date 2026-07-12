SELECT
    NVL(id, -1)                                          AS cliente_id,
    UPPER(NVL(nome, 'NÃO INFORMADO'))                    AS nome,
    UPPER(NVL(cpf, 'NÃO INFORMADO'))                     AS cpf,
    NVL(data_nascimento, DATE '1900-01-01')              AS data_nascimento,
    UPPER(NVL(cidade, 'NÃO INFORMADO'))                  AS cidade,
    UPPER(NVL(uf, 'NÃO INFORMADO'))                      AS uf,
    NVL(tempo_relacionamento_meses, -1)                  AS tempo_relacionamento_meses,
    UPPER(NVL(canal_aquisicao, 'NÃO INFORMADO'))         AS canal_aquisicao,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
from lab_catalog_bronze.digital_insurance.tb_cliente