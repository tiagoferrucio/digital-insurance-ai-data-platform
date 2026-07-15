--------------------------------------------------------------------------------
-- ALERTA DE SINAL DE FRAUDE EM NEAR REAL TIME
--------------------------------------------------------------------------------
-- Grão da OBT: 1 linha por sinistro (fraude achatada), enriquecida com
--              cliente/apólice e — crítico — flag de PAGAMENTO JÁ EMITIDO.
-- Janela     : últimos 30 min de captura CDC (dt_insercao do sinal de fraude).
--------------------------------------------------------------------------------

WITH fs AS (
        SELECT
            sinistro_id,
            MAX(score_fraude)                                    AS max_score_fraude,
            COUNT(*)                                             AS qtd_sinais,
            concat_ws(' | ',
                sort_array(collect_list(sinal_tipo), false))     AS sinais_detectados,
            MAX(to_timestamp(dt_insercao, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]')) AS dt_sinal_cdc
        FROM lab_catalog_silver.digital_insurance.tb_fraude_sinal
        WHERE to_timestamp(dt_insercao, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]')
              >= current_timestamp() - INTERVAL '30' MINUTE
        GROUP BY sinistro_id
        HAVING MAX(score_fraude) >= 70
)
SELECT
    fs.sinistro_id,
    fs.max_score_fraude,
    fs.qtd_sinais,
    fs.sinais_detectados,
    fs.dt_sinal_cdc,
    ROUND((unix_timestamp(current_timestamp()) - unix_timestamp(fs.dt_sinal_cdc)) / 60.0, 1) AS minutos_desde_sinal,
    s.tipo_sinistro,
    s.status                                                     AS status_sinistro,
    s.valor_estimado,
    to_timestamp(s.data_hora_abertura, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]') AS data_hora_abertura,
    a.apolice_id,
    a.valor_cobertura,
    ROUND(s.valor_estimado / NULLIF(a.valor_cobertura, 0), 3)    AS pct_da_cobertura,
    c.cliente_id,
    c.nome                                                       AS cliente_nome,
    c.uf,
    CASE WHEN p.sinistro_id IS NOT NULL THEN 'SIM' ELSE 'NAO' END AS pagamento_ja_emitido,
    p.valor_pago,
    -- severidade para ordenar o painel
    CASE
        WHEN p.sinistro_id IS NOT NULL     THEN 'CRITICO_PAGO'
        WHEN fs.max_score_fraude >= 85     THEN 'CRITICO'
        WHEN fs.max_score_fraude >= 70     THEN 'ALTO'
        ELSE 'MEDIO'
    END                                                          AS severidade,
    current_timestamp()                                          AS dt_processamento_obt
FROM fs
JOIN      lab_catalog_silver.digital_insurance.tb_sinistro  s ON s.sinistro_id = fs.sinistro_id
JOIN      lab_catalog_silver.digital_insurance.tb_apolice   a ON a.apolice_id  = s.apolice_id
JOIN      lab_catalog_silver.digital_insurance.tb_cliente   c ON c.cliente_id  = a.cliente_id
LEFT JOIN lab_catalog_silver.digital_insurance.tb_pagamento p ON p.sinistro_id = s.sinistro_id
ORDER BY
    CASE WHEN p.sinistro_id IS NOT NULL THEN 0 ELSE 1 END,
    fs.max_score_fraude DESC,
    fs.dt_sinal_cdc DESC;