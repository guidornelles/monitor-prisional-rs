# Problemas de dados encontrados

> Registro de problemas nas fontes e no processamento que afetam a leitura do Monitor.

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

## 2. Tempo de pena do RS (SISDEPEN 5.12 e 5.13) — incompatibilidade de universo

Segundo a [nota técnica da SENAPPEN, itens 5.12 e 5.13](https://www.gov.br/senappen/pt-br/servicos/sisdepen/manuais-e-apostilas/nota-tecnica-sisdepen), **pena total** é o tempo total imposto; **pena remanescente** é o saldo na data de referência. Ambos os quesitos abrangem pessoas condenadas, inclusive as que também estão presas provisoriamente em outro processo. A seção 4.1 identifica separadamente os provisórios **sem condenação**.

**O que se sabe (verificado em 13/11/2026):** a leitura independente da Base Única SISDEPEN (`sisdepen_baseunica_2025-2_25032026-163420.xlsx`, aba 1, cela física, primeiro semestre de 2017–2025) reconciliou por ID e ano **todos os 27.810 valores das 30 faixas derivadas em 927 registros** da candidata. A concentração não resulta da agregação de faixas do pipeline.

| Até seis meses no primeiro semestre de 2025 | RS | SP |
| --- | ---: | ---: |
| Pena total (5.12) | 29.453 de 38.519 (76,5%) | 1.411 de 180.396 (0,8%) |
| Pena remanescente (5.13) | 30.351 de 38.519 (78,8%) | 2.315 de 148.342 (1,6%) |

Os denominadores somam as faixas brutas de cada quesito, incluindo a categoria sem informação, para ambos os sexos e no mesmo recorte da Base Única. São **registros por faixa**, não um total validado de condenados. Em 2025/1, o denominador de cada quesito no RS iguala exatamente o estoque em **103 de 103 unidades**. Em 91 unidades, supera o estoque após descontar os provisórios sem condenação. O estoque estadual de 38.519 inclui 11.212 provisórios sem condenação, 27.249 sentenciados e 58 pessoas em medidas de segurança. Em 2024/1, ambos os quesitos igualam o estoque em 104 de 104 unidades e superam esse limite em 92.

As distribuições diferem. Em 2024/1, os dois quesitos somam 35.721 registros, com 25.985 de até seis meses no 5.12 e 26.941 no 5.13. Em 2025/1, os dois somam 38.519, com 29.453 e 30.351 na mesma faixa. Em 2024/2, os totais são 36.157 e 36.155, com 26.897 e 27.860 na faixa de até seis meses. Em 2025/2, os dois somam 41.055, com 32.006 e 33.113 nessa faixa.

O [RELIPEN retificado do 18º ciclo](https://www.gov.br/senappen/pt-br/servicos/sisdepen/relatorios/relatorios-de-informacoes-penitenciarias/relatorio-do-1o-semestre-de-2025-18-ciclo-retificado.pdf/@@display-file/file) confirma o estoque (p. 12), os provisórios (pp. 19–20) e os numeradores de até seis meses (pp. 94 e 98). Isso confirma os valores publicados na origem administrativa. Os dois gráficos da candidata, de homens e mulheres, exibem o 5.12, cuja faixa agrupada de até 2 anos soma 29.540 de 38.519 registros. A base derivada também contém o 5.13, em que a faixa de até 4 anos soma 31.537 de 38.482 registros com informação. Esses cortes são mais amplos que a faixa bruta de até seis meses. O [boletim estadual baseado no Infopen-RS](https://policiapenal.rs.gov.br/ssps-lanca-segunda-edicao-do-boletim-com-o-perfil-da-populacao-negra-no-sistema-prisional) e a [tabela 74 do Anuário FBSP 2026](https://forumseguranca.org.br/wp-content/uploads/2026/07/anuario-2026.pdf#page=361) ajudam a contextualizar o estoque e os regimes, mas usam outras datas ou universos e não validam as faixas de duração.

**O que falta saber:** se a discrepância decorre de universo incorreto na extração, uso de valor padrão, interpretação do formulário ou outro mecanismo de preenchimento. O campo sem informação com 37 registros em 2025/1 não comprova que os demais registros sem duração conhecida estejam na faixa de até seis meses. Os agregados não permitem identificar em que faixa foram contados os provisórios.

**Encaminhamento:** manter os dois gráficos de duração fora da divulgação e da comparação RS–SP até esclarecer, com Polícia Penal RS e SENAPPEN, como foram definidos o universo, o preenchimento da primeira faixa e os valores ausentes. A pena remanescente não resolve a incompatibilidade.

## 3. Cobertura do perfil prisional em 2018

No primeiro semestre de 2018, a Base Única SISDEPEN e a candidata registram **34.721 pessoas em 102 estabelecimentos de cela física** no item 4.1. A soma por sexo dos regimes e das medidas de segurança reconcilia com o estoque de cada unidade: **32.974 homens e 1.747 mulheres**. Já os blocos de idade, cor ou raça e escolaridade têm cobertura muito menor:

| Quesito do SISDEPEN | Unidades com total preenchido | Soma do quesito | Fração do estoque do item 4.1 |
| --- | ---: | ---: | ---: |
| 5.1 — Faixa etária | 20 de 102 | 5.971 | 17,2% |
| 5.2 — Cor de pele, raça ou etnia | 19 de 102 | 5.928 | 17,1% |
| 5.6 — Grau de instrução | 20 de 102 | 5.845 | 16,8% |

Na seção 5.1, os totais por sexo são **5.596 homens e 375 mulheres**; são totais do bloco etário informado, não de toda a população. No segundo semestre, o bloco etário cobre 35.863 das 36.274 pessoas em 99 das 102 unidades. É outro retrato, que não deve ser combinado silenciosamente com o estoque do primeiro semestre. Para os três quesitos, a [nota técnica da SENAPPEN](https://www.gov.br/senappen/pt-br/servicos/sisdepen/manuais-e-apostilas/nota-tecnica-sisdepen) orienta que a soma das categorias, incluindo pessoas sem informação, reconcilie com a população do item 4.1.

**Encaminhamento:** preservar 2018 nos gráficos de estoque e sexo agregado quando derivados de 4.1. Nos gráficos de idade, cor ou raça e escolaridade, sinalizar a cobertura parcial e o denominador do quesito ou omitir o ano da série comparativa. Não interpretar ausência como zero nem usar os totais por sexo do quesito etário como se fossem o estoque.

## 4. Celas-seguro (SISDEPEN 2.13) — lacuna corrigida em 2017–2020

A Base Única SISDEPEN separa as respostas do item 2.13 em duas colunas que diferem pela posição das aspas. A primeira contém as respostas até o segundo semestre de 2020 e a outra, a partir do primeiro semestre de 2021. O processamento do RS descartava a coluna histórica, deixando 409 linhas vazias no painel. O [script corrigido](../scripts/rs/03_prisional.R) reúne as duas grafias sob o cabeçalho esperado pelo painel e interrompe a execução se houver respostas divergentes para a mesma linha. A revisão de 13/11/2026 alterou somente esse campo, nas 409 linhas verificadas por ID e ano. Na candidata revisada, há 927 respostas `Sim` ou `Não` nos primeiros semestres de 2017 a 2025. Os números de unidades com cela-seguro são 67 em 2017, 67 em 2018, 67 em 2019 e 73 em 2020. A exportação de referência de SP também tem respostas `Sim` ou `Não` em todos os anos de 2017 a 2025.

## 5. Semestres e valores ausentes na referência de SP

A [Nota Metodológica do Monitor SP](referencias/Nota_Metodologica_Monitor_SP.pdf), p. 7, informa primeiro semestre para Transparência, Estabelecimentos Prisionais e Morbidade, segundo semestre para Mortalidade e substituição de `NaN` numérico por zero. No código da branch `R` de SP (`45c7144`), `dados_sem2.R` soma os óbitos por causa dos dois ciclos, exporta separadamente três tipos de consultas, cela para gestantes e lactantes do segundo semestre e converte qualquer `NA` em zero após a junção. A base paulista de referência exportada do Data Studio (`base_sisdepen - Sheet1.csv`) corrobora o código. Em 2018, os 449 óbitos exportados correspondem aos 210 do primeiro semestre mais 239 do segundo no recorte paulista de cela física da Base Única. Em 2025, as três consultas derivadas e o campo derivado de lactantes coincidem com o segundo semestre, e HIV com o primeiro. A exportação contém `0` também em campos categóricos, como cela para gestantes, cujo quesito se aplica apenas a estabelecimentos com vagas para mulheres. Os recortes de estabelecimentos e as versões da fonte podem afetar a igualdade entre totais de SP e da Base Única.

A candidata RS usa o primeiro semestre para estoques, estrutura e agravos transmissíveis. As variáveis derivadas de atendimento, cela para gestantes e lactantes vêm do segundo semestre para as unidades que também constam no primeiro. Os óbitos anuais são somados por unidade, sexo e causa quando os dois valores estão disponíveis, com contagem separada de óbitos registrados e auditoria de cobertura. Campos ausentes permanecem vazios. Antes da comparação RS–SP, confirmar com a equipe paulista os campos ligados a cada gráfico e acordar um recorte, semestre e tratamento de ausência comuns.
