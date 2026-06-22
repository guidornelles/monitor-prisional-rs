# Problemas de dados encontrados

> Registro de problemas nas bases-fonte (não bugs do pipeline). Cada item: o que se sabe, o que falta saber, encaminhamento.

## 1. Furtos de 2022 — déficit no microdado aberto da SSP-RS (≈ −24%)

**O que se sabe (verificado):**
- A reconciliação microdado × oficial é boa em 2023, 2024 e 2025 (Δ furtos < 2%), mas em **2022 os furtos do microdado ficam ~24% abaixo** do oficial.
- O oficial 2022 **"Furto" = 128.047** é a coluna isolada (confirmado lendo o arquivo: "Abigeato" = 4.881 e "Furto de Veículo" = 8.953 são colunas separadas; não é total agregado).
- No microdado 2022 (`SPJ_..._JAN_DEZ_2022.csv`), o crime está em **`Tipo Enquadramento`** (o `Tipo Fato` é só "Consumado"/status). Somando **todos** os enquadramentos com "FURTO" = **104.449**; o subconjunto comparável ao "Furto" oficial (exclui furto de veículo e abigeato) = **92.793**; o `furtos_total` do pipeline = 96.768.
- Portanto, **mesmo somando todos os furtos do microdado (104.449), fica abaixo do "Furto" oficial (128.047)** — o déficit não é explicável por diferença de classificação/recorte.
- O déficit é **uniforme nos 12 meses** (~7–8 mil furtos comparáveis/mês) — não é um mês ausente ou truncamento.
- **Roubos 2022** também ficam levemente baixos (−4,3%); **homicídio** bate (−0,25%). Sugere sub-registro de **crimes patrimoniais** no microdado de 2022, pior em furtos.
- As duas cópias do microdado de 2022 baixadas são idênticas (re-download não resolve).

**O que falta saber:**
- Se o **microdado aberto de 2022 saiu incompleto** para furtos (publicação parcial pela SSP-RS), ou
- Se o **"Furto" oficial de 2022** foi construído com mapeamento de enquadramentos / fonte diferente do microdado (a tabela oficial 2022 é um arquivo por ano, com abas mensais; 2023+ usam outro layout "site-geral-e-municipios").
- Existência de uma versão corrigida/completa do microdado 2022.

**Encaminhamento:**
- Tratar **2022 com cautela** nos painéis criminais (sinalizar; não usar como base de comparação fina de furtos).
- **Consultar a SSP-RS** (ou a equipe que mantém os dados abertos) sobre a completude do microdado 2022 para furtos.
- Reavaliar se vale **usar o agregado oficial** para furtos de 2022 em vez da reconstrução do microdado (decisão pendente).

## 2. Tempo de pena do RS (SISDEPEN 5.12 e 5.13) — faixa "Até 6 meses" inflada (~78%)

**O que se sabe (verificado):**
- A **binagem do pipeline está CORRETA** (validada contra a derivada de SP, mesma fórmula): `pena_*_0_2anos` = (Até 6m)+(6m–1a)+(1–2a); `pena_remanescente_*_0_4anos` = idem + (2–4a). Não é erro de soma nosso.
- **No RS, a primeira faixa "Até 6 meses (inclusive)" concentra ~78% dos condenados**, nas DUAS bases:
  - **5.12 (tempo total de pena):** "Até 6 meses" M = 27.799; bucket 0–2 = 27.886 de ~36.578 condenados M ≈ **76%**.
  - **5.13 (pena remanescente):** "Até 6 meses" M = 28.678 de 36.578 = **78,4%**.
- **Em SP a distribuição é realista** (mesma binagem): pena total bucket 0–2 = **5,1%**; remanescente 0–4 = **30,9%**. Os maiores buckets de SP são 4–8 e 8–15 anos (esperado para população prisional).
- A inflação no RS está **espalhada por TODOS os estabelecimentos grandes** (Canoas 2.133/pop 2.452; Jacuí 1.976/2.531; ~80% da população de cada um), não num único registro — é **sistemática**.
- O campo `Número de pessoas sem informação` tem só **37** — ou seja, o "Até 6 meses" está funcionando como **depósito de "tempo não registrado"**.

**O que falta saber:**
- Por que o RS preenche a 5.12/5.13 do SISDEPEN jogando a maioria em "Até 6 meses" (erro de digitação/mapeamento da SUSEPE-RS? *default* do sistema de captação? interpretação equivocada do campo?).
- Se há algum ciclo em que o RS preenche corretamente (testar outros semestres/anos).

**Encaminhamento:**
- **NÃO usar a distribuição de tempo de pena do RS** (total nem remanescente) como confiável — **sinalizar no painel ou omitir** essa visão.
- Levar à equipe de SP (a comparação RS×SP deixa o problema evidente) e à **SUSEPE-RS / SENAPPEN** (qualidade do preenchimento da 5.12/5.13). Pena remanescente **não** serve de alternativa — sofre do mesmo problema.
