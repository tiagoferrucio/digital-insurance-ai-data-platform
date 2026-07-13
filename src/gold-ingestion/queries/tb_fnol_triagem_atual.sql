SELECT z.sinistro_id,
       z.apolice_id,
       z.data_hora_abertura,
       z.tipo_sinistro,
       z.canal_abertura,
       z.status_sinistro,
       z.valor_estimado,
       z.valor_cobertura,
       z.indice_dano,
       z.latitude,
       z.longitude,
       z.status_apolice,
       z.apolice_vigente,
       z.score_risco_atual,
       z.score_fraude,
       z.score_triagem,
       CASE WHEN z.score_triagem >= 0.80 THEN 'CRITICA' WHEN z.score_triagem >= 0.60 THEN 'ALTA' WHEN z.score_triagem >= 0.35 THEN 'MEDIA' ELSE 'BAIXA' END AS prioridade,
       CASE WHEN z.apolice_vigente = FALSE THEN 'REVISAO_COBERTURA' WHEN z.score_fraude >= 0.80 THEN 'REVISAO_FRAUDE' WHEN z.score_triagem >= 0.60 THEN 'ANALISE_HUMANA' ELSE 'FAST_TRACK' END AS rota_recomendada,
       CURRENT_TIMESTAMP() AS dt_atualizacao
FROM
  (SELECT y.*,
          LEAST(1.0, y.indice_dano * 0.60 + LEAST(GREATEST(COALESCE(y.score_risco_atual, 0.0), 0.0), 1.0) * 0.20 + LEAST(GREATEST(COALESCE(y.score_fraude, 0.0), 0.0), 1.0) * 0.20) AS score_triagem
   FROM
     (SELECT x.*,
             CASE WHEN x.status_apolice = 'ATIVA'
                      AND CAST(x.data_hora_abertura AS DATE) BETWEEN x.data_inicio AND x.data_fim THEN TRUE ELSE FALSE END AS apolice_vigente,
             CASE WHEN COALESCE(x.valor_cobertura, 0.0) > 0.0 THEN LEAST(COALESCE(x.valor_estimado, 0.0) / x.valor_cobertura, 1.0) ELSE 0.0 END AS indice_dano
      FROM
        (SELECT CAST(s.sinistro_id AS BIGINT) AS sinistro_id,
                CAST(s.apolice_id AS BIGINT) AS apolice_id,
                CAST(s.data_hora_abertura AS TIMESTAMP) AS data_hora_abertura,
                CAST(s.tipo_sinistro AS STRING) AS tipo_sinistro,
                CAST(s.canal_abertura AS STRING) AS canal_abertura,
                CAST(s.status AS STRING) AS status_sinistro,
                CAST(s.valor_estimado AS DOUBLE) AS valor_estimado,
                CAST(s.latitude AS DOUBLE) AS latitude,
                CAST(s.longitude AS DOUBLE) AS longitude,
                CAST(a.status AS STRING) AS status_apolice,
                CAST(a.data_inicio AS DATE) AS data_inicio,
                CAST(a.data_fim AS DATE) AS data_fim,
                CAST(a.valor_cobertura AS DOUBLE) AS valor_cobertura,
                CAST(a.score_risco_atual AS DOUBLE) AS score_risco_atual,
                COALESCE(f.score_fraude, 0.0) AS score_fraude
         FROM lab_catalog_silver.digital_insurance.tb_sinistro s
         LEFT JOIN lab_catalog_silver.digital_insurance.tb_apolice a ON CAST(s.apolice_id AS BIGINT) = CAST(a.apolice_id AS BIGINT)
         LEFT JOIN
           (SELECT CAST(sinistro_id AS BIGINT) AS sinistro_id,
                   MAX(CAST(score_fraude AS DOUBLE)) AS score_fraude
            FROM lab_catalog_silver.digital_insurance.tb_fraude_sinal
            WHERE CAST(sinistro_id AS BIGINT) > 0
            GROUP BY CAST(sinistro_id AS BIGINT)) f ON CAST(s.sinistro_id AS BIGINT) = f.sinistro_id
         WHERE CAST(s.sinistro_id AS BIGINT) > 0) x) y) z;