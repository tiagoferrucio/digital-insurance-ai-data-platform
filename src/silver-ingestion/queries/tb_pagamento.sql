SELECT
    id              AS pagamento_id,
    sinistro_id     AS sinistro_id,
    valor_pago      AS valor_pago,
    data_pagamento  AS data_pagamento,
    forma_pagamento AS forma_pagamento,
    dt_insercao     AS dt_insercao
FROM lab_catalog_bronze.digital_insurance.tb_pagamento