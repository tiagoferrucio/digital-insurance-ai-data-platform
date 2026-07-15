--------------------------------------------------------------------------------
-- FNOL - Triagem de Sinistros com AI Agents (OCI AI Data Platform)
-- Schema + massa de dados sintéticos
-- Compatível com Oracle 26ai
-- Todas as tabelas possuem DT_INSERCAO (timestamp de criação do registro),
-- facilitando a identificação de novos registros pelo CDC / GoldenGate.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0. LIMPEZA (opcional, útil para reprocessar o lab)
--------------------------------------------------------------------------------
BEGIN
   FOR t IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('TB_FRAUDE_SINAL','TB_PAGAMENTO','TB_PERICIA',
                                   'TB_SINISTRO_HISTORICO','TB_SINISTRO',
                                   'TB_VEICULO','TB_APOLICE','TB_CLIENTE'))
   LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
   END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 1. TB_CLIENTE
--------------------------------------------------------------------------------
CREATE TABLE tb_cliente (
    id                          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome                        VARCHAR2(120),
    cpf                         VARCHAR2(14),
    data_nascimento             DATE,
    cidade                      VARCHAR2(60),
    uf                          VARCHAR2(2),
    tempo_relacionamento_meses  NUMBER,
    canal_aquisicao             VARCHAR2(30),
    dt_insercao                 TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 2. TB_APOLICE
--------------------------------------------------------------------------------
CREATE TABLE tb_apolice (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id          NUMBER REFERENCES tb_cliente(id),
    tipo_seguro         VARCHAR2(20),   -- AUTO, RESIDENCIAL, VIDA
    data_inicio         DATE,
    data_fim            DATE,
    valor_premio        NUMBER(10,2),
    valor_cobertura     NUMBER(12,2),
    status              VARCHAR2(20),   -- ATIVA, CANCELADA, EXPIRADA
    score_risco_atual   NUMBER(4,1),    -- 0 a 100
    dt_insercao         TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 3. TB_VEICULO (apenas para apólices tipo AUTO)
--------------------------------------------------------------------------------
CREATE TABLE tb_veiculo (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    apolice_id          NUMBER REFERENCES tb_apolice(id),
    marca               VARCHAR2(40),
    modelo              VARCHAR2(40),
    ano                 NUMBER(4),
    valor_fipe          NUMBER(10,2),
    uso                 VARCHAR2(20),   -- PARTICULAR, APP
    km_rodado_estimado  NUMBER,
    dt_insercao         TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 4. TB_SINISTRO  <-- tabela "quente", alvo do CDC / GoldenGate
--------------------------------------------------------------------------------
CREATE TABLE tb_sinistro (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    apolice_id          NUMBER REFERENCES tb_apolice(id),
    data_hora_abertura  TIMESTAMP,
    tipo_sinistro       VARCHAR2(30),   -- COLISAO, ROUBO, INCENDIO, DANO_TERCEIRO, ALAGAMENTO
    valor_estimado      NUMBER(12,2),
    latitude            NUMBER(9,6),
    longitude           NUMBER(9,6),
    endereco_ocorrencia VARCHAR2(200),
    canal_abertura      VARCHAR2(20),   -- APP, CALL_CENTER, WEB
    status              VARCHAR2(20),   -- ABERTO, EM_ANALISE, APROVADO, NEGADO, PERICIA
    descricao_texto     VARCHAR2(500),
    dt_insercao         TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 5. TB_SINISTRO_HISTORICO -- pré-agregada, evita agregação pesada em tempo real
--------------------------------------------------------------------------------
CREATE TABLE tb_sinistro_historico (
    apolice_id                  NUMBER PRIMARY KEY REFERENCES tb_apolice(id),
    qtd_sinistros_ultimos_12m   NUMBER,
    qtd_sinistros_negados       NUMBER,
    valor_total_pago_historico  NUMBER(12,2),
    data_ultima_atualizacao     TIMESTAMP DEFAULT SYSTIMESTAMP,
    dt_insercao                 TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 6. TB_PERICIA
--------------------------------------------------------------------------------
CREATE TABLE tb_pericia (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sinistro_id     NUMBER REFERENCES tb_sinistro(id),
    perito_id       NUMBER,
    data_agendada   DATE,
    laudo_resumo    VARCHAR2(300),
    resultado       VARCHAR2(20),   -- PROCEDENTE, IMPROCEDENTE, INCONCLUSIVO
    dt_insercao     TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 7. TB_PAGAMENTO
--------------------------------------------------------------------------------
CREATE TABLE tb_pagamento (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sinistro_id     NUMBER REFERENCES tb_sinistro(id),
    valor_pago      NUMBER(12,2),
    data_pagamento  DATE,
    forma_pagamento VARCHAR2(20),   -- PIX, TED, CHEQUE
    dt_insercao     TIMESTAMP DEFAULT SYSTIMESTAMP
);

--------------------------------------------------------------------------------
-- 8. TB_FRAUDE_SINAL
--------------------------------------------------------------------------------
CREATE TABLE tb_fraude_sinal (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sinistro_id     NUMBER REFERENCES tb_sinistro(id),
    sinal_tipo      VARCHAR2(200),
    score_fraude    NUMBER(5,2),   -- 0 a 100
    dt_insercao     TIMESTAMP DEFAULT SYSTIMESTAMP
);

COMMIT;

--------------------------------------------------------------------------------
-- GERAÇÃO DE DADOS SINTÉTICOS
-- Volumes: ~12.000 clientes / ~15.000 apólices / ~45.000 sinistros
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. TB_CLIENTE (12.000 registros)
--------------------------------------------------------------------------------
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(30);
    v_nomes    t_str_arr := t_str_arr('Ana','Bruno','Carla','Diego','Elaine','Felipe',
                                       'Gabriela','Hugo','Isabela','João','Karina','Lucas',
                                       'Marina','Nelson','Olivia','Paulo','Renata','Sergio',
                                       'Tatiana','Vitor');
    v_sobrenomes t_str_arr := t_str_arr('Silva','Souza','Oliveira','Santos','Pereira',
                                         'Costa','Rodrigues','Almeida','Nascimento','Lima',
                                         'Araujo','Ribeiro','Carvalho','Gomes','Martins');
    v_cidades  t_str_arr := t_str_arr('Sao Paulo','Campinas','Rio de Janeiro','Belo Horizonte',
                                       'Curitiba','Porto Alegre','Salvador','Recife','Fortaleza',
                                       'Brasilia');
    v_ufs      t_str_arr := t_str_arr('SP','SP','RJ','MG','PR','RS','BA','PE','CE','DF');
    v_canais   t_str_arr := t_str_arr('CORRETOR','APP','WEBSITE','CALL_CENTER');
    v_idx      NUMBER;
    v_total    CONSTANT NUMBER := 12000;
BEGIN
    FOR i IN 1..v_total LOOP
        v_idx := TRUNC(DBMS_RANDOM.VALUE(1, 10.999));
        INSERT INTO tb_cliente (nome, cpf, data_nascimento, cidade, uf,
                                 tempo_relacionamento_meses, canal_aquisicao)
        VALUES (
            v_nomes(TRUNC(DBMS_RANDOM.VALUE(1,20.999))) || ' ' ||
                v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1,15.999))),
            LPAD(TRUNC(DBMS_RANDOM.VALUE(10000000000,99999999999)),11,'0'),
            SYSDATE - TRUNC(DBMS_RANDOM.VALUE(18*365, 75*365)),
            v_cidades(v_idx),
            v_ufs(v_idx),
            TRUNC(DBMS_RANDOM.VALUE(1,180)),
            v_canais(TRUNC(DBMS_RANDOM.VALUE(1,4.999)))
        );
        IF MOD(i, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 2. TB_APOLICE (~15.000 registros, um cliente pode ter mais de uma)
--------------------------------------------------------------------------------
DECLARE
    v_max_cliente NUMBER;
    v_tipo        VARCHAR2(20);
    v_inicio      DATE;
    v_premio      NUMBER;
    v_cobertura   NUMBER;
    v_total       CONSTANT NUMBER := 15000;
BEGIN
    SELECT MAX(id) INTO v_max_cliente FROM tb_cliente;

    FOR i IN 1..v_total LOOP
        v_tipo := CASE TRUNC(DBMS_RANDOM.VALUE(1,4))
                     WHEN 1 THEN 'AUTO'
                     WHEN 2 THEN 'RESIDENCIAL'
                     ELSE 'VIDA'
                  END;
        v_inicio := SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 730));

        v_cobertura := CASE v_tipo
                          WHEN 'AUTO' THEN DBMS_RANDOM.VALUE(30000,150000)
                          WHEN 'RESIDENCIAL' THEN DBMS_RANDOM.VALUE(80000,500000)
                          ELSE DBMS_RANDOM.VALUE(50000,300000)
                       END;
        v_premio := v_cobertura * DBMS_RANDOM.VALUE(0.02,0.06) / 12;

        INSERT INTO tb_apolice (cliente_id, tipo_seguro, data_inicio, data_fim,
                                 valor_premio, valor_cobertura, status, score_risco_atual)
        VALUES (
            TRUNC(DBMS_RANDOM.VALUE(1, v_max_cliente + 0.999)),
            v_tipo,
            v_inicio,
            v_inicio + 365,
            ROUND(v_premio,2),
            ROUND(v_cobertura,2),
            CASE WHEN v_inicio + 365 < SYSDATE THEN 'EXPIRADA' ELSE 'ATIVA' END,
            ROUND(DBMS_RANDOM.VALUE(10,90),1)
        );
        IF MOD(i, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 3. TB_VEICULO (um para cada apólice do tipo AUTO)
--------------------------------------------------------------------------------
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(30);
    v_marcas  t_str_arr := t_str_arr('Fiat','Volkswagen','Chevrolet','Toyota','Hyundai',
                                      'Honda','Jeep','Renault','Ford');
    v_modelos t_str_arr := t_str_arr('Argo','Onix','Corolla','HB20','Civic','Compass',
                                      'Kwid','Ka','Polo','Cronos');
    v_contador NUMBER := 0;
BEGIN
    FOR ap IN (SELECT id FROM tb_apolice WHERE tipo_seguro = 'AUTO') LOOP
        INSERT INTO tb_veiculo (apolice_id, marca, modelo, ano, valor_fipe, uso, km_rodado_estimado)
        VALUES (
            ap.id,
            v_marcas(TRUNC(DBMS_RANDOM.VALUE(1,9.999))),
            v_modelos(TRUNC(DBMS_RANDOM.VALUE(1,10.999))),
            TRUNC(DBMS_RANDOM.VALUE(2012,2026)),
            ROUND(DBMS_RANDOM.VALUE(35000,180000),2),
            CASE WHEN DBMS_RANDOM.VALUE(0,1) < 0.15 THEN 'APP' ELSE 'PARTICULAR' END,
            TRUNC(DBMS_RANDOM.VALUE(5000,150000))
        );
        v_contador := v_contador + 1;
        IF MOD(v_contador, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 4. TB_SINISTRO (~45.000 registros) -- tabela de maior volume, foco do CDC
-- ~3% seguindo padrao classico de fraude:
--   sinistro aberto poucos dias apos inicio da apolice E valor proximo do limite
--------------------------------------------------------------------------------
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(30);
    v_tipos    t_str_arr := t_str_arr('COLISAO','ROUBO','INCENDIO','DANO_TERCEIRO','ALAGAMENTO');
    v_canais   t_str_arr := t_str_arr('APP','CALL_CENTER','WEB');
    v_apolice  tb_apolice%ROWTYPE;
    v_max_ap   NUMBER;
    v_fraude   BOOLEAN;
    v_dt_abertura TIMESTAMP;
    v_valor    NUMBER;
    v_total    CONSTANT NUMBER := 45000;
BEGIN
    SELECT MAX(id) INTO v_max_ap FROM tb_apolice;

    FOR i IN 1..v_total LOOP
        SELECT * INTO v_apolice FROM tb_apolice
        WHERE id = TRUNC(DBMS_RANDOM.VALUE(1, v_max_ap + 0.999));

        -- ~3% dos sinistros seguem o padrao classico de fraude
        v_fraude := DBMS_RANDOM.VALUE(0,1) < 0.03;

        IF v_fraude THEN
            v_dt_abertura := CAST(v_apolice.data_inicio AS TIMESTAMP)
                              + NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1,10)), 'DAY');
            v_valor := v_apolice.valor_cobertura * DBMS_RANDOM.VALUE(0.85,0.99);
        ELSE
            v_dt_abertura := CAST(v_apolice.data_inicio AS TIMESTAMP)
                              + NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(15,360)), 'DAY');
            v_valor := v_apolice.valor_cobertura * DBMS_RANDOM.VALUE(0.02,0.45);
        END IF;

        -- nao deixa passar da data_fim da apolice
        IF v_dt_abertura > CAST(v_apolice.data_fim AS TIMESTAMP) THEN
            v_dt_abertura := CAST(v_apolice.data_fim AS TIMESTAMP) - INTERVAL '5' DAY;
        END IF;

        INSERT INTO tb_sinistro (apolice_id, data_hora_abertura, tipo_sinistro,
                                  valor_estimado, latitude, longitude, endereco_ocorrencia,
                                  canal_abertura, status, descricao_texto)
        VALUES (
            v_apolice.id,
            v_dt_abertura,
            v_tipos(TRUNC(DBMS_RANDOM.VALUE(1,5.999))),
            ROUND(v_valor,2),
            ROUND(DBMS_RANDOM.VALUE(-33.0,-3.0),6),   -- faixa aproximada de latitude no Brasil
            ROUND(DBMS_RANDOM.VALUE(-73.0,-35.0),6),  -- faixa aproximada de longitude no Brasil
            'Endereco sintetico ' || i,
            v_canais(TRUNC(DBMS_RANDOM.VALUE(1,3.999))),
            CASE
                WHEN v_fraude THEN 'PERICIA'
                ELSE (CASE TRUNC(DBMS_RANDOM.VALUE(1,5))
                        WHEN 1 THEN 'ABERTO'
                        WHEN 2 THEN 'EM_ANALISE'
                        WHEN 3 THEN 'APROVADO'
                        WHEN 4 THEN 'NEGADO'
                        ELSE 'APROVADO'
                      END)
            END,
            'Relato sintetico do sinistro numero ' || i
        );

        IF MOD(i, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 5. TB_SINISTRO_HISTORICO (agregado a partir da tabela TB_SINISTRO)
--------------------------------------------------------------------------------
INSERT INTO tb_sinistro_historico (apolice_id, qtd_sinistros_ultimos_12m,
                                    qtd_sinistros_negados, valor_total_pago_historico)
SELECT
    apolice_id,
    COUNT(*),
    SUM(CASE WHEN status = 'NEGADO' THEN 1 ELSE 0 END),
    SUM(CASE WHEN status = 'APROVADO' THEN valor_estimado ELSE 0 END)
FROM tb_sinistro
GROUP BY apolice_id;

COMMIT;

--------------------------------------------------------------------------------
-- 6. TB_PERICIA (para sinistros com status PERICIA ou NEGADO)
--------------------------------------------------------------------------------
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(20);
    v_resultados t_str_arr := t_str_arr('PROCEDENTE','IMPROCEDENTE','INCONCLUSIVO');
    v_contador NUMBER := 0;
BEGIN
    FOR s IN (SELECT id, data_hora_abertura FROM tb_sinistro
              WHERE status IN ('PERICIA','NEGADO')) LOOP
        INSERT INTO tb_pericia (sinistro_id, perito_id, data_agendada, laudo_resumo, resultado)
        VALUES (
            s.id,
            TRUNC(DBMS_RANDOM.VALUE(1,50.999)),
            CAST(s.data_hora_abertura AS DATE) + TRUNC(DBMS_RANDOM.VALUE(2,15)),
            'Laudo tecnico sintetico referente ao sinistro ' || s.id,
            v_resultados(TRUNC(DBMS_RANDOM.VALUE(1,3.999)))
        );
        v_contador := v_contador + 1;
        IF MOD(v_contador, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 7. TB_PAGAMENTO (para sinistros aprovados)
--------------------------------------------------------------------------------
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(20);
    v_formas t_str_arr := t_str_arr('PIX','TED','CHEQUE');
    v_contador NUMBER := 0;
BEGIN
    FOR s IN (SELECT id, data_hora_abertura, valor_estimado FROM tb_sinistro
              WHERE status = 'APROVADO') LOOP
        INSERT INTO tb_pagamento (sinistro_id, valor_pago, data_pagamento, forma_pagamento)
        VALUES (
            s.id,
            ROUND(s.valor_estimado * DBMS_RANDOM.VALUE(0.9,1.0),2),
            CAST(s.data_hora_abertura AS DATE) + TRUNC(DBMS_RANDOM.VALUE(5,30)),
            v_formas(TRUNC(DBMS_RANDOM.VALUE(1,3.999)))
        );
        v_contador := v_contador + 1;
        IF MOD(v_contador, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 8. TB_FRAUDE_SINAL
-- Gera sinais para os sinistros com padrao classico de fraude
-- (poucos dias apos inicio da apolice + valor perto do limite de cobertura)
--------------------------------------------------------------------------------
DECLARE
    v_dias_apolice  NUMBER;
    v_pct_cobertura NUMBER;
    v_contador      NUMBER := 0;
BEGIN
    FOR s IN (
        SELECT si.id AS sinistro_id, si.valor_estimado, si.data_hora_abertura,
               ap.data_inicio, ap.valor_cobertura
        FROM tb_sinistro si
        JOIN tb_apolice ap ON ap.id = si.apolice_id
    ) LOOP
        v_dias_apolice := CAST(s.data_hora_abertura AS DATE) - s.data_inicio;
        v_pct_cobertura := s.valor_estimado / s.valor_cobertura;

        IF v_dias_apolice <= 10 THEN
            INSERT INTO tb_fraude_sinal (sinistro_id, sinal_tipo, score_fraude)
            VALUES (s.sinistro_id,
                    'Sinistro aberto ' || v_dias_apolice || ' dias apos inicio da apolice',
                    ROUND(DBMS_RANDOM.VALUE(60,95),2));
        END IF;

        IF v_pct_cobertura >= 0.85 THEN
            INSERT INTO tb_fraude_sinal (sinistro_id, sinal_tipo, score_fraude)
            VALUES (s.sinistro_id,
                    'Valor estimado proximo do limite de cobertura da apolice',
                    ROUND(DBMS_RANDOM.VALUE(50,90),2));
        END IF;

        v_contador := v_contador + 1;
        IF MOD(v_contador, 2000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------------------
-- CHECAGEM RAPIDA DE VOLUMES
--------------------------------------------------------------------------------
SELECT 'TB_CLIENTE' tabela, COUNT(*) qtd FROM tb_cliente
UNION ALL SELECT 'TB_APOLICE', COUNT(*) FROM tb_apolice
UNION ALL SELECT 'TB_VEICULO', COUNT(*) FROM tb_veiculo
UNION ALL SELECT 'TB_SINISTRO', COUNT(*) FROM tb_sinistro
UNION ALL SELECT 'TB_SINISTRO_HISTORICO', COUNT(*) FROM tb_sinistro_historico
UNION ALL SELECT 'TB_PERICIA', COUNT(*) FROM tb_pericia
UNION ALL SELECT 'TB_PAGAMENTO', COUNT(*) FROM tb_pagamento
UNION ALL SELECT 'TB_FRAUDE_SINAL', COUNT(*) FROM tb_fraude_sinal;

--> Create trigger to update dt_insercao
CREATE OR REPLACE TRIGGER trg_tb_cliente_bu
BEFORE UPDATE ON tb_cliente
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_apolice_bu
BEFORE UPDATE ON tb_apolice
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_veiculo_bu
BEFORE UPDATE ON tb_veiculo
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_sinistro_bu
BEFORE UPDATE ON tb_sinistro
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_sinistro_historico_bu
BEFORE UPDATE ON tb_sinistro_historico
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_pericia_bu
BEFORE UPDATE ON tb_pericia
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_pagamento_bu
BEFORE UPDATE ON tb_pagamento
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_tb_fraude_sinal_bu
BEFORE UPDATE ON tb_fraude_sinal
FOR EACH ROW
BEGIN
  :NEW.dt_insercao := SYSTIMESTAMP;
END;
/