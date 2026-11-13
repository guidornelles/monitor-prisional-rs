# Conferência da versão candidata RS — 13 de novembro de 2026

A [execução de referência](../../../scripts/rs/README.md) regenerou as tabelas em uma pasta isolada, usando a Base Única SISDEPEN 2025/2, o catálogo de versões da SSP-RS, o snapshot Sinesp VDE de 03/10/2026 e a tabulação de tuberculose de maio de 2026. Esta pasta guarda controles públicos agregados e hashes de saídas locais. Os CSVs de conexão e os anexos internos ficam com a equipe.

| Controle | Resultado |
| --- | --- |
| [Reconciliação criminal](criminal_reconciliacao.csv) | 1.988 chaves únicas (497 municípios × 4 anos). Após a revisão de 2022, a diferença do total reconstruído de furto frente ao agregado oficial é de +0,15% nesse ano. Os campos “outros” têm um universo mais restrito. |
| [Mandados anuais](mandados_sinesp_cobertura_anual.csv) e [mensais](mandados_sinesp_reconciliacao_mensal.csv) | 48 meses estaduais conferidos com a SSP-RS. Em 2025, 319 municípios têm doze meses, três têm cobertura parcial e 175 não têm valor. |
| [Cobertura prisional](prisional_cobertura.csv), [estoque e celas-seguro](prisional_estoque_celas_seguro.csv) e [mortalidade](prisional_mortalidade_cobertura.csv) | 927 registros únicos de estabelecimento e ano. As 409 respostas históricas de 2017 a 2020 foram recuperadas. Óbitos de 2017 a 2022 têm cobertura parcial. |
| [Saúde](saude_cobertura.csv) | Tuberculose em 2025: 7.846 casos em 497 municípios, incluindo 171 zeros explícitos. As outras cinco séries de 2025 ficam vazias. |
| [Panoramas](manifesto_panoramas.json) | Seis censos; PIB 2010–2023 em mil reais correntes; distorção idade-série de 2025, ensino fundamental. O manifesto registra URLs, hashes e controles de cobertura. |

O [manifesto de saídas](manifesto_execucao.json) permite comparar arquivos regenerados. Ele registra a execução local, separadamente das conexões efetivas do [Data Studio](../../../docs/looker_studio_guia.md). O [relatório SP–RS](../../../docs/auditoria_metodologica_sp_rs.md) explica por que a validação interna não garante comparabilidade entre estados.

## Mapa prisional

O [cruzamento por ID](drpp_vinculo_unidades_2024.csv) contém as 104 unidades de cela física de 2024. Os vínculos são os do [diretório público da Polícia Penal](https://www.policiapenal.rs.gov.br/presidios-e-delegacias-penitenciarias), consultado em 13/11/2026, com 103 confirmações e um vínculo não confirmado. Use o [campo calculado por ID](drpp_vinculo_looker.txt) para tabelas, filtros e conferência. Mantenha o ID como texto no Data Studio.

Para colorir os pontos por endereço, atribua uma categoria comum a localizações compartilhadas por vínculos diferentes. Em Charqueadas, os IDs 1132, 1167, 1190 e 1144 compartilham um endereço no SISDEPEN. O vínculo por unidade permanece na tabela. Antes de separar os pontos, obtenha coordenadas oficiais. Esse cruzamento identifica o vínculo administrativo de unidades e não delimita os municípios ou a área de cada DRPP.
