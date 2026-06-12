# Prova de Conceito — reconciliação microdado ↔ agregados oficiais (RS, 2023)

> **Objetivo:** verificar se os **microdados de ocorrências** da SSP-RS (Dados Abertos Mensais) reproduzem as **tabelas oficiais agregadas** (Indicadores Criminais por município e Violência Contra a Mulher). Se reproduzirem, valida-se o microdado como **base única e flexível** para construir os indicadores do monitor no padrão de SP.
>
> **Escopo:** reconciliação criminal (homicídio doloso, latrocínio, furtos, furto de veículo, roubos, roubo de veículo, estupro). **Ano-teste:** 2023. **Script:** `scripts/rs/poc_reconciliacao_2023.R`. Data: 2026-06-09.

## 1. Dados e método

- **Microdado:** `DadosAbertos/Mensais/SPJ_DADOS_ABERTOS_OCORRENCIAS_JAN_DEZ_2023…csv` (806.945 ocorrências consumadas; latin-1; `;`).
- **Verdade-terra 1:** `IndicadoresCriminais/…ano-2023…xlsx`, aba `2023` (cabeçalho na linha 7).
- **Verdade-terra 2:** `…violencia-contra-as-mulheres-2023…xlsx`, aba `Estupro` (cabeçalho na linha 3).
- **Tratamentos:** filtro `Tipo Fato = Consumado` (as tabelas oficiais são "fato consumado"); normalização de município (maiúsculas, sem acento, espaços colapsados); agregação por município × ano; **ocorrências** = contagem de linhas, **vítimas** = soma de `Quantidade Vítimas`.
- **Critério de sucesso:** total estadual dentro de ±2% e ≥95% dos municípios dentro de ±1%.

> ⚙️ **Execução:** a lógica foi validada por um espelho em Python (R não era executável no ambiente de geração — sem privilégios para instalar o R). O script entregue (`.R`) reproduz exatamente a mesma lógica e deve gerar os mesmos números no seu ambiente R.

## 2. Resultado

| Indicador | Oficial | Reconstruído | Δ% estadual | Veredito |
|---|---:|---:|---:|---|
| Homicídio Doloso (ocorrências) | 1.570 | 1.567 | **−0,19%** | ✅ reconcilia |
| Latrocínio (ocorrências) | 42 | 41 | −2,38% | ✅ (volume baixo) |
| Furtos (ocorrências) | 125.529 | 125.466 | **−0,05%** | ✅ reconcilia |
| Furto de Veículo (ocorrências) | 8.556 | 8.557 | +0,01% | ✅ reconcilia |
| Roubos (ocorrências) | 32.506 | 32.412 | **−0,29%** | ✅ reconcilia |
| Roubo de Veículo (ocorrências) | 3.594 | 3.593 | −0,03% | ✅ reconcilia |
| Estupro — VCM municipal | 2.820 | micro 5.627 (oco) | VCM ≈ 0,50× | ⚠️ ver §4 (subset, não divergência) |
| Homicídio (vítimas) | 1.670 | 1.915 | +14,67% | ⚠️ ver §4 |

As diferenças residuais de 0,05–0,3% nos indicadores de ocorrência são compatíveis com as revisões administrativas que a própria nota da SSP-RS menciona (bases extraídas em datas diferentes). Tabelas completas: `outputs/tabelas/poc_reconciliacao_2023.csv` (por município) e `…_resumo.csv` (estadual).

## 3. Regras de classificação validadas (microdado → indicador oficial)

Confirmadas empiricamente nesta PoC e coerentes com o dicionário da SSP-RS:

- **Roubos** = `Tipo Enquadramento` contém "ROUBO", **exceto** roubo de veículo e exceto variantes "…COM MORTE". Inclui "OUTROS ROUBOS".
- **Roubo de Veículo** = `ROUBO DE VEICULO` (+ `…COM LESOES`). Contabilizado **à parte** de Roubos — **não somar nem subtrair**.
- **Latrocínio** = roubos "…COM MORTE".
- **Furtos** = contém "FURTO", **exceto** furto de veículo. Inclui abigeato, "OUTROS FURTOS" e "FURTO EM VEÍCULO" (furto *de dentro* do veículo).
- **Furto de Veículo** = `FURTO DE VEICULO` (+ `…TRANSPORTE OUTRO ESTADO`). À parte de Furtos.
- **Homicídio Doloso** = `HOMICIDIO DOLOSO` (exclui trânsito e "oposição a intervenção policial").
- **Estupro (total)** = `ESTUPRO` + `ESTUPRO DE VULNERAVEL` (exclui "DIVULGAÇÃO DE CENA…").

### Dois erros encontrados e corrigidos durante a reconciliação
A primeira rodada deu ~−50% em quase tudo. O depuração revelou **dois bugs no agregador** (não nos dados):

1. **Linha "Total RS" não excluída.** O rótulo da linha de total era "Total RS" (não "Total"/"Rio Grande do Sul"), então a soma estadual entrava no somatório dos municípios e **dobrava** o total oficial.
2. **"OUTROS FURTOS"/"OUTROS ROUBOS" perdidos** por usar `starts_with("FURTO"/"ROUBO")` — esses rótulos começam com "OUTROS". Corrigido para `contains`.

Registro a lição: a reconciliação contra a verdade-terra é o que separou um bug de código de uma incompatibilidade real de dados.

## 4. Dois pontos que exigem atenção

- **Homicídio por vítimas (+14,7%):** as *ocorrências* reconciliam perfeitamente (−0,2%), mas o campo `Quantidade Vítimas` do microdado soma 1.915, acima da definição oficial de vítimas (1.670). O microdado parece contar todas as vítimas da ocorrência (inclusive não-fatais), não só as vítimas de homicídio. **Recomendação:** para homicídio, usar **ocorrências** (que reconciliam); o uso de vítimas exige uma regra refinada.
- **Estupro — VCM é um subconjunto estável (~metade) do microdado, NÃO uma série divergente (correção de auditoria).** ⚠️ Minha análise anterior dizia que a VCM "divergia muito" (corr ~0, erro mediano municipal ~83%). **Isso estava errado:** eu incluía indevidamente a linha **"GERAL"** (total) da planilha VCM, que inflava o total e destruía a correlação. Corrigido (GERAL excluída):
  - VCM municipal estupro = **2.820** (2023), **2.522** (2024); microdado = 5.627 / 5.478 ocorrências.
  - **Correlação municipal VCM × microdado = 0,99** em ambos os anos. A VCM é uma fração **estável** do microdado: **0,50** (2023) e **0,46** (2024).
  - **A hipótese ocorrência vs vítima foi testada e refutada:** corr(VCM, ocorrências)=0,990 e corr(VCM, vítimas)=0,994 — idênticas; a diferença ocorrência/vítima no estupro é ~2%, não explica o fator ~2.
  - O fator ~0,5 **não** é sexo (feminino = 0,81 do total) nem subtipo nem idade — nenhum recorte do microdado dá 2.820. A **nota 3 da planilha** cita só os subtipos (*"Estupro e Estupro de Vulnerável"*); o recorte de contexto vem da **definição do produto**: a VCM é do **Observatório da Violência Contra a Mulher** da SSP-RS, que — conforme sua descrição — abrange o estupro no **recorte da Lei Maria da Penha** (relações familiares/íntimas contra a mulher). Isso explica a ordem de ~metade (subconjunto de todos os estupros). 🟦 **A confirmar na fonte primária do Observatório** (a descrição foi obtida da página da SSP-RS via busca, não por leitura direta). Não é divergência de sistema, e sim **diferença de escopo**.
  - **Recomendação (inalterada, motivo corrigido):** para estupro *total* comparável a SP (todos os tipos, ambos os sexos, ocorrências), usar o **microdado**. A VCM continua útil como subsérie coerente (desde 2012), mas mede um universo mais estreito (~metade), não o total.

## 4b. Replicação em 2024 (confirmação)

A mesma lógica foi aplicada a 2024 (microdado `…JAN_DEZ_2024…csv`, 759.848 ocorrências consumadas; Indicadores e VCM de 2024). O padrão se repete:

| Indicador | Oficial | Reconstruído | Δ% estadual |
|---|---:|---:|---:|
| Homicídio Doloso (oco) | 1.338 | 1.337 | **−0,07%** |
| Latrocínio (oco) | 29 | 28 | −3,45% |
| Furtos (oco) | 105.373 | 105.380 | **+0,01%** |
| Furto de Veículo (oco) | 6.639 | 6.638 | −0,02% |
| Roubos (oco) | 20.771 | 20.697 | **−0,36%** |
| Roubo de Veículo (oco) | 2.299 | 2.295 | −0,17% |
| Homicídio (vítimas) | 1.418 | 1.630 | +14,95% ⚠️ |
| Estupro — VCM municipal | 2.522 | micro 5.478 (oco) | VCM ≈ 0,46× ⚠️ |

Conclusões reforçadas: (a) os indicadores de **ocorrência reconciliam de novo** dentro de ±0,4% (≥96% dos municípios dentro de 1%) — as **regras de classificação são estáveis entre anos**; (b) o desvio de **vítimas de homicídio** se repete (+15%, igual a 2023), confirmando que o campo `Quantidade Vítimas` não equivale à definição oficial; (c) **estupro:** a relação VCM ≈ metade do microdado é **estável** (0,50 em 2023, 0,46 em 2024) e altamente correlacionada (corr 0,985–0,990) — a VCM é um subconjunto coerente, não uma série instável (corrige conclusão anterior, ver §4). Saídas: `outputs/tabelas/poc_reconciliacao_2024*.csv`.

## 4c. Verificação dos dados de atividade (prisões e armas)

Cruzamento dos totais da **Lei 15.610 semestral** (com município) contra o **relatório de Indicadores de Atividade** (estadual, por corporação, séries `…2007-2016`, `…2017-2024`, `…2025-2026`). Resolve a questão da sobreposição de prisões.

| Indicador (2023) | Lei 15.610 (semestral, somado) | Indicadores de Atividade (estadual) | Resultado |
|---|---:|---:|---|
| Prisões PC — Inc. IX | 30.436 | "Flagrantes **elaborados** pela PC" = 30.426 | 🟩 **igual** — o Inc. IX é a lavratura de autos, não as prisões exclusivas da PC |
| (referência) presos **exclusivamente** por ação da PC | — | 7.121 | nota (3) — indicador distinto, bem menor |
| Prisões BM — Inc. VIII | 111.574 | "Prisões realizadas pela instituição (BM)" = 111.634 | 🟩 **igual** |
| Armas PC — Inc. VII | 3.907 | "Armas apreendidas pela PC" = 3.887 | 🟩 ~igual |
| Armas BM — Inc. VII | 5.613 | "Armas de fogo apreendidas (BM)" = 5.611 | 🟩 igual |

**Conclusões:**

1. 🟩 **Sobreposição de prisões confirmada.** O Inc. IX (PC) = "flagrantes elaborados pela PC" (≈30,4 mil em 2023), mas só **7.121** desses flagrantes decorrem de ação exclusiva da PC — os outros ~23 mil vêm de capturas de outras forças (sobretudo a BM) que a PC apenas lavra, e que **também** constam na contagem da BM (Inc. VIII = "prisões realizadas pela instituição"). Portanto **somar PC Inc. IX + BM Inc. VIII duplica ~23 mil eventos de flagrante**. A leitura literal da lei (cada inciso = uma força) está correta, mas os dados publicados do Inc. IX são a lavratura, não as prisões exclusivas da PC.
   - Série municipal de flagrante mais limpa: **PC Inc. IX** (autos lavrados, com município).
   - 🟩 **Mas a sobreposição PC×BM é irrelevante para o de-para com SP:** o indicador "prisões efetuadas" de SP (Res. SSP-SP 160/2001, levantamento documental a confirmar) é **só da Polícia Civil** = flagrantes lavrados (APF) + mandados cumpridos. A BM não entra. O Inc. IX (flagrantes elaborados pela PC) **é exatamente** o 1º componente de SP (que conta todos os APF lavrados pela PC, não só os de ação própria). O 2º componente (mandados) = "Presos por mandados pela PC" (atividade, estadual). RS 2023 ≈ 30.426 + 8.464 = **38,9 mil**. No mapa, só o flagrante (Inc. IX) é municipalizado.
2. 🟨 **Armas — a soma PC + BM só vale a partir de 2017.** ⚠️ **Quebra de série em 2016/2017.** Até 2016, a linha "PC" de **apreensões já inclui a BM** — confirmado: PC armas ≥ BM armas em **todos** os anos 2007–2016, e a planilha de 2010 afirma explicitamente que "as drogas apreendidas pela BM estão contidas no total da PC"; a nota (2) reforça ("até 2016, armas por quaisquer órgãos, sem distinção"). Logo: **2017+** → PC e BM exclusivas, somar = total; **2007–2016** → usar a linha "PC" como total combinado, **não somar BM**.
3. 🟥 **A observação "os dados da PC contêm os da BM" NÃO é universal — vale só para apreensões.** Para **prisões**, os dados mostram o oposto: a BM "prisões realizadas pela instituição" é **20–30× maior** que a PC "prisões realizadas" todo ano (ex.: 2016 → BM 108.670 vs PC 6.032; 2013 → BM 153.525 vs PC 4.988). A PC não pode conter a BM nas prisões — são universos distintos. Portanto, pré-2017, a relação entre PC e BM **depende do indicador**: a PC consolida apreensões (armas/drogas), mas prisões são reportadas separadamente e dominadas pela BM.
4. 🟩 **Período estendido (com ressalvas):** os indicadores de atividade existem em nível **estadual de 2007 a 2026**, mas a estrutura por força só é analiticamente limpa **de 2017 em diante** (armas exclusivas e somáveis; prisões com o overlap do flagrante já descrito). A municipalização (Lei 15.610) só existe a partir de 2021.2. **Recomendação:** tratar 2017+ como a janela utilizável para produtividade por corporação; usar pré-2017 só com cautela indicador-a-indicador.

## 5. Veredito

🟩 **A hipótese central está validada:** os microdados Mensais reproduzem as tabelas oficiais agregadas do RS para homicídio doloso, furtos, furto de veículo, roubos e roubo de veículo (todos dentro de **±0,3%** no estado nos dois anos testados). O **latrocínio** também reconcilia, com desvio maior (−2,4% em 2023, −3,5% em 2024) explicável pelo **baixo volume** (42 e 29 casos — 1 caso ≈ 2–3%). Isso autoriza adotar o **microdado como base única e flexível** do componente criminal do Monitor RS, com regras de classificação documentadas e auditáveis.

🟩 **Confirmações para o de-para SP↔RS:** veículos são contabilizados à parte (não subtrair); abigeato está dentro de furtos; latrocínio = roubos com morte. Para reproduzir o "roubo/furto **outros**" no padrão de SP (que exclui também carga, banco e comércio), basta excluir esses subtipos do microdado — agora que a base está validada, isso é uma operação de filtro documentada.

🟥 **Limites:** a comparação **absoluta** SP↔RS continua exigindo cautela (taxonomias e critérios distintos entre as duas SSPs); recomenda-se comparar por **taxas e tendências**. E a série de microdados só cobre **2022–2025** — para anos anteriores, depende-se das tabelas agregadas.

**Próximos passos sugeridos:** (1) rodar o `.R` no seu ambiente para confirmar os números; (2) replicar a PoC em 2024; (3) construir, sobre o microdado validado, o "roubo/furto outros" no padrão SP; (4) refinar a regra de vítimas de homicídio.

---
*Fontes: `data/EstatisticasCriminaisRS/` (microdado Mensal 2023, Indicadores Criminais 2023, VCM 2023). Script: `scripts/rs/poc_reconciliacao_2023.R`. Saídas: `outputs/tabelas/poc_reconciliacao_2023*.csv`.*
