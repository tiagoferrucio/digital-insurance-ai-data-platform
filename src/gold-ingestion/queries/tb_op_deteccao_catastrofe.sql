--------------------------------------------------------------------------------
-- DETECÇÃO DE EVENTO EM MASSA / CATÁSTROFE
--------------------------------------------------------------------------------
-- Cluster de sinistros do MESMO tipo_sinistro concentrados numa mesma REGIÃO
-- (geo-grid ~0.25° ≈ 25-28 km) dentro de uma JANELA CURTA (últimos 30 min de
-- CDC). Detecção precoce -> reserva técnica, peritos por região, comunicação
-- proativa aos segurados. Vira ALERTA quando >= 5 sinistros na célula+janela.
--------------------------------------------------------------------------------

WITH base_sinistro AS (
    SELECT
        tipo_sinistro,
        apolice_id,
        valor_estimado,
        latitude,
        longitude,
        to_timestamp(data_hora_abertura, 'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]') AS data_hora_abertura,
        to_timestamp(dt_insercao,        'yyyy-MM-dd HH:mm:ss[.SSSSSSSSS]') AS dt_insercao
    FROM lab_catalog_silver.digital_insurance.tb_sinistro
)
SELECT
    tipo_sinistro,
    qtd_sinistros_no_cluster,
    -- centro geográfico da célula do grid (para plotar no mapa / mobilizar peritos)
    lat_centro_grid,
    long_centro_grid,
    ROUND(lat_medio,  6)                                         AS lat_media_real,
    ROUND(long_medio, 6)                                         AS long_media_real,
    valor_exposto_cluster,
    apolices_distintas,
    primeiro_sinistro_janela,
    ultimo_sinistro_janela,
    -- ritmo de chegada: sinistros por minuto dentro da janela do cluster
    ROUND(
        qtd_sinistros_no_cluster /
        GREATEST(
            (unix_timestamp(ultimo_sinistro_janela)
             - unix_timestamp(primeiro_sinistro_janela)) / 60.0
        , 1.0)
    , 2)                                                         AS sinistros_por_minuto,
    CASE
        WHEN qtd_sinistros_no_cluster >= 20 THEN 'CATASTROFE'
        WHEN qtd_sinistros_no_cluster >= 10 THEN 'EVENTO_GRAVE'
        ELSE 'CLUSTER_EMERGENTE'
    END                                                          AS nivel_alerta,
    current_timestamp()                                          AS dt_processamento_obt
FROM (
        SELECT
            tipo_sinistro,
            -- célula do grid ~0.25° (centro = borda inferior + meia célula)
            FLOOR(latitude  / 0.25) * 0.25 + 0.125               AS lat_centro_grid,
            FLOOR(longitude / 0.25) * 0.25 + 0.125               AS long_centro_grid,
            COUNT(*)                                             AS qtd_sinistros_no_cluster,
            COUNT(DISTINCT apolice_id)                           AS apolices_distintas,
            AVG(latitude)                                        AS lat_medio,
            AVG(longitude)                                       AS long_medio,
            ROUND(SUM(valor_estimado), 2)                        AS valor_exposto_cluster,
            MIN(data_hora_abertura)                              AS primeiro_sinistro_janela,
            MAX(data_hora_abertura)                              AS ultimo_sinistro_janela
        FROM base_sinistro
        -- janela curta de CAPTURA CDC: enxame que chegou nos últimos 30 min
        WHERE dt_insercao >= current_timestamp() - INTERVAL '30' MINUTE
          AND latitude  <> 0        -- descarta coordenada default de NVL na origem
          AND longitude <> 0
        GROUP BY
            tipo_sinistro,
            FLOOR(latitude  / 0.25) * 0.25 + 0.125,
            FLOOR(longitude / 0.25) * 0.25 + 0.125
        -- só é "evento em massa" quando concentra o suficiente na célula+janela
        HAVING COUNT(*) >= 5
     ) clusters
ORDER BY qtd_sinistros_no_cluster DESC, valor_exposto_cluster DESC;