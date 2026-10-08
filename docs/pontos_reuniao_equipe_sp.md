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
> Origem: comparação das 5 bases exportadas do DataStudio de SP (`data/raw/bases_data_studio/`) com os painéis da PoC. Relatório completo em `docs/revisao_sintese_e_bases_datastudio.md`. Itens marcados [SP] são para alinhar com a equipe de SP; [RS] são decisões internas nossas.

### 5.1 [SP] Camada prisional — formato e derivadas a alinhar (CORRIGIDO)
> ⚠️ **CORREÇÃO (alinha a `revisao_sintese_e_bases_datastudio.md` §2.4, diff coluna a coluna das 530):** uma versão anterior deste item afirmava que a `base_sisdepen` do DataStudio **não continha** regime/pena/tipo penal/filhos. **Isso estava errado** — a inspeção parcial olhou só o início e o fim das 530 colunas.
- A base `base_sisdepen` do DataStudio (530 col) **contém sim** as derivadas: regime (`provisorios_*`/`sentenciado_*`/`internacao_*`/`tratamento_*`), faixas de pena (`pena_*`), pena remanescente (`pena_remanescente_*`), filhos e todo o bloco `tipo_penal_*` — além de continentes, atendimento, cela/gestantes/lactantes e óbitos. Não há hipótese de "estão só no Looker" para essas colunas: estão materializadas na base.
- O que **de fato** precisa alinhar com SP nesta camada não é "qual base", e sim **formato e algumas derivadas** (todos já tratados no `03b`): (a) **óbitos** — renomear `naturais→saude`, `suicidios→suicidio` (item 5.2); (b) **binning de pena** divergente — SP usa `0_2/2_4/4_8/8_15/15_20/20_30/30_mais`, a PoC re-somou para casar 100%; (c) **10 colunas** que faltavam na PoC (continentes, atendimento, gestantes/lactantes) — já geradas; (d) **`tipo_penal`** (item 4) que a PoC corrige de propósito.
- **Encaminhamento:** confirmar com SP apenas o **destino das derivadas "extras"** (regime/pena/tipo penal) e os **rótulos canônicos** — decisão de escopo/nomenclatura, **não** um gate que ameace a replicação. Detalhe em `revisao_sintese_e_bases_datastudio.md` §2.4 e `spec_export_prisional_formato_sp.md`.

### 5.2 [SP] Nomes dos óbitos prisionais — ALINHADO
- A PoC **já adota os rótulos canônicos de SP**: `obitos_saude_*` e `obitos_suicidio_*` (singular) — renomeação feita no `03b` (antes eram `obitos_naturais_*`/`obitos_suicidios_*`). O blend no Looker não quebra mais por nome.
- **Encaminhamento:** nada a decidir — apenas registrar na nota metodológica que os rótulos espelham SP.

### 5.3 [SP] Série criminal exportada só tem 2001, 2023 e 2025
- A `dinamica_criminal.csv` exportada contém apenas esses 3 anos. Confirmar se é recorte do export, do painel ou da fonte — afeta a afirmação de "série desde 2001".

### 5.4 [SP] Formato das bases (forma, não fonte)
- Criminal e saúde no DataStudio são **long/tidy** (coluna `Crime`/`Tipo`); a PoC é **wide**. A "troca direta de base" nunca funcionou por isso, não por falta de dado. Resolvível com um passo de export dedicado.

### 5.5 [RS] Variáveis de contexto que SP carrega e a PoC não tem
- Populações censitárias históricas (`Pop_70…Pop_2022`); PIB em 3 anos; presença de estabelecimento penal por ano (`munic_ep_*` / `tem_EP` / `Tem_prisão`); infraestrutura de saúde CNES (`ambulatorial/interna/urgencia`).
- **PIB — fonte (resolvido):** a Nota Metodológica de SP confirma **IBGE** (PIB dos Municípios); o "Fundação Seade" do descritivo está errado. RS também usa IBGE — sem divergência.
- **Decisão interna:** quais desses panoramas entram no escopo do RS (CNES é nacional, sem limitação).

### 5.6 [RS] Distorção idade-série: total × fundamental
- SP usa a taxa **total**; a PoC produz a do **ensino fundamental**. Alinhar o nível para casar com SP, ou documentar a escolha.

### 5.7 [SP+RS] Tempo de pena do RS (5.12/5.13) — faixa "Até 6 meses" inflada (~78%)
- No RS, ~78% dos condenados caem em "Até 6 meses" (tempo total **e** remanescente) — implausível. Em SP é 5,1% (total) / 30,9% (remanescente). Binagem nossa validada contra SP (não é erro de soma). É **qualidade de preenchimento do SISDEPEN no RS** (a faixa vira depósito de "tempo não registrado"; `sem_informação` = 37).
- **Encaminhamento:** não usar a distribuição de pena do RS como confiável; levar à equipe de SP (comparação evidencia) e à SUSEPE-RS/SENAPPEN. Detalhe em `docs/problemas_dados.md` (item 2).

### (a preparar depois) Roteiro/briefing da reunião
Guilherme pedirá ajuda para preparar materiais de apoio para a reunião com base nestes pontos.
