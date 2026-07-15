--------------------------------------------------------------------------------
-- FILA VIVA DE SINISTROS (status ABERTO / EM_ANALISE)
--------------------------------------------------------------------------------
-- Grão da OBT: 1 linha por (tipo_sinistro x status x faixa_espera).
-- Métricas de operação: volume, valor exposto, idade do mais antigo (SLA) e
--                       quanto entrou na última janela de CDC (fila crescendo?).
--------------------------------------------------------------------------------
WITH base_sinistro AS
  (SELECT tipo_sinistro,
          status,
          valor_estimado,
          to_timestamp(data_hora_abertura, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]') AS data_hora_abertura,
          to_timestamp(dt_insercao, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]') AS dt_insercao
   FROM lab_catalog_silver.digital_insurance.tb_sinistro
   WHERE status IN ('ABERTO','EM_ANALISE'))
SELECT tipo_sinistro,
       status, -- tempo de espera desde a abertura (idade da fila)
 CASE
     WHEN data_hora_abertura >= current_timestamp() - INTERVAL '1' HOUR THEN '0-1h'
     WHEN data_hora_abertura >= current_timestamp() - INTERVAL '4' HOUR THEN '1-4h'
     WHEN data_hora_abertura >= current_timestamp() - INTERVAL '24' HOUR THEN '4-24h'
     ELSE '24h+'
 END AS faixa_espera,
 COUNT(*) AS qtd_sinistros,
 CONCAT('R$ ', TRANSLATE(FORMAT_NUMBER(SUM(valor_estimado), 2), ',.', '.,')) AS valor_exposto_total,
 CONCAT('R$ ', TRANSLATE(FORMAT_NUMBER(AVG(valor_estimado), 2), ',.', '.,')) AS valor_medio, 
    -- SLA: há quantas horas o sinistro mais antigo da fila está parado
 ROUND((unix_timestamp(current_timestamp()) - unix_timestamp(MIN(data_hora_abertura))) / 3600.0 , 1) AS horas_espera_mais_antigo, 
    -- pressão de entrada: quantos caíram na fila na última janela de CDC (15 min)
 SUM(CASE
         WHEN dt_insercao >= current_timestamp() - INTERVAL '15' MINUTE THEN 1
         ELSE 0
     END) AS entradas_ultimos_15min,
 MAX(dt_insercao) AS ultima_atualizacao_cdc,
 current_timestamp() AS dt_processamento_obt
FROM base_sinistro
GROUP BY tipo_sinistro,
         status,
         CASE
             WHEN data_hora_abertura >= current_timestamp() - INTERVAL '1' HOUR THEN '0-1h'
             WHEN data_hora_abertura >= current_timestamp() - INTERVAL '4' HOUR THEN '1-4h'
             WHEN data_hora_abertura >= current_timestamp() - INTERVAL '24' HOUR THEN '4-24h'
             ELSE '24h+'
         END
ORDER BY qtd_sinistros DESC,
         valor_exposto_total DESC;