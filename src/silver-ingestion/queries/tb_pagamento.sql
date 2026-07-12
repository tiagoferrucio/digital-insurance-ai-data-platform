SELECT
    NVL(id, -1)                                          AS pagamento_id,
    NVL(sinistro_id, -1)                                 AS sinistro_id,
    NVL(valor_pago, 0.00)                                AS valor_pago,
    NVL(data_pagamento, DATE '1900-01-01')               AS data_pagamento,
    UPPER(NVL(forma_pagamento, 'NÃO INFORMADO'))         AS forma_pagamento,
    NVL(dt_insercao, TIMESTAMP '1900-01-01 00:00:00')    AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_pagamento