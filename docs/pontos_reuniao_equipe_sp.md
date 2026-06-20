# Pontos para levar à reunião com a equipe do Monitor SP

> Decisões que, se alteradas, precisam ser feitas EM CONJUNTO com SP (afetam a comparabilidade SP↔RS).
> Guilherme levará estes itens ao grupo. Atualizar após a reunião.

## 1. Denominador populacional das taxas por 100 mil
- **Hoje (SP e RS):** população do **Censo 2022 fixa** para todos os anos.
- **Questão:** migrar para **estimativas populacionais anuais do IBGE** (denominador por ano) melhora a precisão temporal, mas diverge se feito só de um lado.
- **Encaminhamento:** decidir em conjunto. Se mudar, mudar nos dois monitores. Implementação no RS já está desenhada (opção parametrizável em `00_config.R`; ver `docs/decisoes_metodologicas.md`).

## 2. Limites temporais dos dados de saúde (DATASUS/TABNET)
- **Achado:** as bases do TABNET têm **cobertura temporal heterogênea e não documentada no Monitor SP**. Ex.: **hepatites virais consolidadas só até 2023** (nota do próprio TABNET: "dados de 2007 a 2023, sujeitos à revisão"); SIM/óbitos e SINAN sem 2025 ainda em jun/2026.
- **Problema:** o Monitor SP **não esclarece esses limites**, o que pode levar a leituras equivocadas (ex.: "queda" de hepatite em 2024 que é só dado provisório).
- **Tratamento no RS:** marcamos anos provisórios como **NA** por indicador (não 0), com corte por último ano consolidado (`cfg$saude_ano_max*`).
- **Encaminhamento:** propor ao grupo (a) documentar os limites temporais por indicador na nota metodológica; (b) padronizar o tratamento de provisórios (NA vs 0) entre SP e RS.

## 3. Reconciliação criminal — furtos 2022 e definição de estupro
- **Furtos 2022:** o microdado aberto do RS sub-registra furtos (~−24% vs oficial); a definir como o Monitor trata anos com microdado incompleto. Pode afetar a leitura comparativa de furtos. (Consulta técnica à SSP-RS em `docs/consultas_ssp_rs.md`.)
- **Estupro:** divergência entre microdado e VCM/agregado (relação ~metade, escopo Lei Maria da Penha). Alinhar com SP qual universo/definição de estupro o Monitor adota (tipo penal, sexo da vítima, fonte), já que SP também depende da definição da SSP local.
- **Encaminhamento:** levar como ponto de método (como o Monitor lida com incompletude e com definições divergentes entre fontes criminais), além da consulta oficial à SSP-RS.

## 4. Erro de cálculo em `tipo_penal_desarmamento` (dado divulgado) — AUDITADO
- A variável `tipo_penal_desarmamento_*` no `Base_Sisdepen.xlsx` divulgado **soma só "Porte (Art.14)"**, omitindo disparo/posse/comércio/tráfico (Arts. 15–18); estes vazam para `tipo_penal_outros` (que fica superestimado).
- **Demonstrado** (não é versão antiga do script): recompondo da Base Única SISDEPEN, em **1.071 estabelecimentos de SP, 1.071 batem com a fórmula bugada (só Art.14) e 0 com a soma correta**; 501 casos com diferença visível, todos confirmando o bug. Detalhe em `docs/auditoria_tipo_penal_sp.md`.
- **Encaminhamento:** reportar à equipe de SP para correção; decidir se o RS corrige (recomendado) e documenta a divergência.

## 5. Achados da revisão das bases do DataStudio (jun/2026)
> Origem: comparação das 5 bases exportadas do DataStudio de SP (`data/raw/bases_data_