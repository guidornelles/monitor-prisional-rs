# Revisão da síntese de indicadores + comparação das bases do DataStudio SP × painéis da PoC

*Documento de trabalho — 2026-06-19. Autor: Guilherme Souza, com revisão técnica assistida.*

> Base empírica desta revisão: as 5 bases exportadas do DataStudio de SP, salvas em
> `data/raw/bases_data_studio/`, confrontadas com os painéis gerados pela PoC em
> `outputs/tabelas/`, à luz do log em `docs/decisoes_metodologicas.md`.
> **Achado central:** as bases que o Monitor de SP realmente consome no DataStudio **não** têm o
> formato nem os nomes que os scripts da PoC produzem hoje. A diferença não é cosmética — é de
> **forma da tabela** (SP é *long/tidy*, a PoC é *wide*) e de **conteúdo derivado** (a PoC produz
> colunas que a base do Looker de SP não tem, e deixa de produzir colunas que ela tem). É exatamente
> por isso que "trocar a base" nunca funcionou direto.

---

## Parte 0 — O que são as 5 bases do DataStudio (inventário factual)

| Arquivo (DataStudio SP) | Linhas | Formato | Grão | Papel no Looker |
|---|---|---|---|---|
| `Variáveis de contexto - dados.csv` | 644 | **wide** | município | Panoramas (pop. censitária, PIB, distorção, presença de EP) |
| `Variáveis de contexto - aux.csv` | 644 | wide | município | Sheet auxiliar: `nome_municipio, cod_municipio, valor` (= valor da distorção, chave de *blend*) |
| `Variáveis de contexto - dinamica_criminal.csv` | 10.977 | **long/tidy** | município × ano × **Crime** | Série criminal + armas + prisões, com taxa já calculada |
| `Variáveis de contexto - dados_saude.csv` | 24.128 | **long/tidy** | município × ano × **Tipo** | Casos e mortes de TB/HIV/Hepatite |
| `base_sisdepen - Sheet1.csv` | 1.616 | wide | estabelecimento × ciclo | Camada prisional (530 colunas) |

Três fatos estruturais que mudam tudo:

1. **Criminal e saúde são *long*, não *wide*.** SP tem uma coluna `Crime`/`Tipo` (uma linha por indicador), enquanto a PoC tem uma coluna por indicador. O Looker depende dessa forma longa para os filtros e o seletor de indicador.
2. **As colunas identificadoras de SP têm nomes próprios e dois campos de município** (`Município` = "Adamantina (SP)" com sufixo de UF; `Município (IBGE)` = "Adamantina" limpo; `ID Município` = código; `Nome Macrorregião` = região). A PoC usa `id_municipio`, `nom_mun`, `nome_regiao_intermediaria`.
3. **SP carrega um sinalizador de presença de estabelecimento penal** em todas as camadas (`tem_EP` no criminal, `Tem_prisão` na saúde, `munic_ep_70…munic_ep_2020` no contexto). A PoC não produz nenhum deles.

---

# PARTE 1 — Revisão da síntese de indicadores (modificações sugeridas)

A síntese (`Sintese_Indicadores_Monitor_SP_RS.md`) está sólida na espinha dorsal, mas foi escrita
**antes** de você inspecionar as bases reais do DataStudio e **antes** de fechar parte das decisões
em `decisoes_metodologicas.md`. Há pelo menos um ponto factualmente desatualizado que, se for
enviado assim aos pesquisadores, vai gerar retrabalho. Eu **não enviaria** sem aplicar as correções
M1, M2 e M5 abaixo. As demais são melhorias.

## M1 — (CORREÇÃO, prioridade alta) O item 5 "Recorte regional" está desatualizado e contradiz a base de SP

A síntese ainda diz: *"SP usa 11 macrorregiões; o RS tem recortes próprios (RISP/COREDEs), não
equivalentes. Definir se a comparação será municipal/estadual."* — como **pergunta em aberto**.

Mas `decisoes_metodologicas.md` (seção "Recorte territorial") **já resolveu isso**, e a base do
DataStudio **confirma**: a coluna chama-se `Nome Macrorregião`, porém o conteúdo é a **região
geográfica intermediária do IBGE** (ex.: Adamantina → "Presidente Prudente", que é a região
intermediária do IBGE, não uma "macrorregião" administrativa). A decisão fechada é adotar o mesmo
conceito para o RS (8 regiões intermediárias).

**Sugestão de novo texto para o item 5:**
> *Recorte regional — RESOLVIDO. O Monitor de SP rotula a coluna como "Nome Macrorregião", mas o
> conteúdo são as **regiões geográficas intermediárias do IBGE** (verificado na base do DataStudio).
> Adotamos o mesmo conceito para o RS (8 regiões intermediárias), com mapeamento município→região
> via diretório do IBGE. RISP/COREDEs ficam de fora (não equivalentes). Comparação por
> município/estado; "região" é camada auxiliar comparável.*

> ⚠️ Atenção de nomenclatura a registrar para a equipe: o rótulo "Macrorregião" no painel de SP é
> enganoso — não confundir com as macrorregiões administrativas. Vale manter o rótulo de SP no
> produto final (para o Looker funcionar), mas documentar que o conteúdo é "região intermediária IBGE".

## M2 — (CORREÇÃO) Homicídio: a síntese trata como um indicador único; a decisão é duas variáveis

A síntese lista "Homicídio doloso" como linha única. O `decisoes_metodologicas.md` define **duas**
variáveis: `hd_vitima` (agregado oficial "Total de vítimas de HD") e `hd_ocorrencias` (microdado),
porque o microdado **superconta vítimas ~+15%**. A base de SP tem só `Crime = "Homicídio doloso"`
(uma série). 

**Sugestão:** acrescentar uma nota na linha de Homicídio: *"No RS, mantemos duas medidas —
`hd_vitima` (agregado oficial, comparável ao de SP) e `hd_ocorrencias` (microdado). Para o produto
no formato de SP, a linha 'Homicídio doloso' é alimentada por `hd_vitima`. Pergunta pendente à
equipe SP: qual exatamente alimenta o Monitor (vítimas ou ocorrências)?"*

## M3 — (LACUNA) A síntese omite os panoramas que SP de fato carrega no contexto

A base `dados.csv` de SP carrega variáveis de contexto que **não aparecem na síntese**:

- **Populações censitárias históricas** (`Pop_70, Pop_80, Pop_91, Pop_2000, Pop_2010, Pop_2022`) — a síntese só menciona "Censos" genericamente, mas SP carrega a série completa. Sem limitação para o RS (Censos são nacionais).
- **PIB em 3 anos** (`PIB_2010, PIB_2021, PIB_2023`). **Ponto crítico de fonte:** o descritivo de SP indica **Fundação Seade** como fonte do PIB — uma fonte **estadual de SP, inexistente no RS**. Para o RS o PIB municipal vem do **IBGE** (e/ou DEE/FEE-RS). A síntese diz "IBGE — PIB municípios", o que está **certo para o RS**, mas convém anotar explicitamente: *"SP usou Fundação Seade; no RS a fonte equivalente é o IBGE (PIB dos Municípios)."*
- **Presença de estabelecimento penal por ano censitário** (`munic_ep_70…munic_ep_2020`, Sim/Não). É um indicador de contexto que SP exibe e a síntese ignora. No RS é **derivável do SISDEPEN** (quais municípios têm EP) — sem limitação.
- **Infraestrutura de saúde CNES** (`ambulatorial_*, interna_*, urgencia_*`, 2018–2023) consta no descritivo de SP. **Decisão necessária:** incluir no escopo do RS (CNES é nacional, sem limitação) ou deixar fora? Hoje não está na síntese nem na PoC.
- `IDEB_2021` e `total de estupros` (a versão antiga) aparecem marcados **"EXCLUIR"** no descritivo de SP — ou seja, SP os removeu. Bom sinal de que a síntese está certa em não os listar; vale só registrar que foram conscientemente excluídos.

**Sugestão:** acrescentar à síntese uma linha/bloco "Panoramas de contexto carregados por SP" com
pop. censitária histórica, PIB multi-ano (fonte RS = IBGE), presença de EP e (a decidir) CNES.

## M4 — (PRECISÃO) "Distorção idade-série": SP usa o **total**, a PoC usa o **fundamental**

O descritivo de SP define a variável como **"Distorção idade série total"**. A PoC produz
`distorcao_idade_serie_fund` (fundamental). São métricas diferentes do INEP. 

**Sugestão:** alinhar com SP (usar a taxa **total**), ou documentar explicitamente a escolha do
fundamental como divergência consciente. Hoje a síntese não especifica o nível — convém fixar.

## M5 — (PRECISÃO) Taxas: SP usa população do **ano** do indicador; a PoC usa população fixa de 2022

Verificado: no painel criminal da PoC, `populacao` é **constante** (ex.: Aceguá = 4.170 em 2022,
2023, 2024 e 2025) e as taxas saem dessa base fixa. Na base de SP, a coluna `população` **varia por
ano** (ex.: em 2001 usa a população de 2000). 

Para uma janela curta (2022–2025) o erro é pequeno, mas é uma divergência metodológica real que um
revisor vai apontar. **Sugestão:** ou (a) usar estimativas populacionais anuais do IBGE para o
denominador das taxas, ou (b) declarar na nota metodológica que, na janela 2022–2025, adota-se a
população do Censo 2022 como denominador fixo. Não deixar implícito.

## M6 — (CLAREZA) Armas e prisões: tornar a divergência estrutural mais visível

A síntese já trata armas (estadual) e prisões (flagrante municipal) nas notas, mas a base de SP
revela algo que reforça o ponto: **em SP, "Armas de fogo apreendidas" e "Prisões efetuadas" são
linhas `Crime` no grão municipal**, lado a lado com homicídio/roubo/furto. No RS isso é impossível
no mesmo grão:

- **Armas:** só existem em nível **estadual** → no produto formato-SP, a linha "Armas de fogo apreendidas" **não pode** ser preenchida por município (ficaria vazia/estadual à parte).
- **Prisões:** só o componente **flagrante** é municipalizável; mandados são estaduais.

**Sugestão:** elevar isso de "nota de rodapé" para uma **coluna explícita na tabela-síntese**
("Grão possível no RS: municipal / estadual"), porque é a diferença que mais compromete a paridade
visual com o painel de SP. É o tipo de limitação que precisa estar na cara dos pesquisadores.

## M7 — (VERIFICAR) A série criminal exportada de SP tem só 3 anos (2001, 2023, 2025)

A `dinamica_criminal.csv` exportada contém **apenas** os anos 2001, 2023 e 2025 (645 municípios × 6
crimes por ano). Não sei se é (a) um recorte do export que você fez, (b) o Monitor exibe só
baseline + recentes, ou (c) a fonte só tem esses cortes. **Isso muda a leitura da síntese sobre
janela temporal.** Recomendo confirmar com a equipe SP antes de afirmar "série desde 2001" na
síntese — pode ser que o painel mostre pontas, não série contínua.

---

# PARTE 2 — Bases DataStudio × painéis da PoC: semelhanças, diferenças e spec de-para

Visão geral do gap, camada por camada. Em seguida, o de-para detalhado.

| Camada | PoC gera (hoje) | SP consome (DataStudio) | Gap principal |
|---|---|---|---|
| Criminal | `painel_criminal_municipio_ano.csv` (**wide**, 19 col) | `dinamica_criminal.csv` (**long**, col `Crime`) | Forma (pivot wide→long) + nomes + `tem_EP` + taxa por ano |
| Saúde | `painel_saude_municipio_ano.csv` (**wide**) | `dados_saude.csv` (**long**, col `Tipo`) | Forma + nomes dos `Tipo` + `Tem_prisão` |
| Contexto | `painel_contexto_municipio.csv` (6 col) | `dados.csv` (21 col) | Falta pop. histórica, PIB multi-ano, `munic_ep_*`, CNES |
| Prisional | `painel_prisional_estabelecimento.csv` (397 col) | `base_sisdepen` (530 col) | **Conjunto derivado divergente** (ver 2.4) |

## 2.1 — Camada CRIMINAL

**Semelhanças:** mesmo grão lógico (município × ano), mesmos 6 indicadores conceituais, taxa por
100 mil presente nos dois.

**Diferenças e o que falta:**

1. **Forma:** PoC é *wide* (uma coluna por crime); SP é *long* (coluna `Crime`). É preciso
   **pivotar (melt)** os painéis da PoC para o formato longo.
2. **Identificadores:** renomear/duplicar campos.
3. **Taxa:** SP traz uma linha com `quantidade`, `população` e `taxa`; a PoC traz quantidade e taxa
   em colunas separadas por indicador. No formato longo, `taxa = quantidade / população × 100000`.
4. **`tem_EP`:** SP carrega o sinalizador de presença de estabelecimento penal; a PoC não. Derivável
   do SISDEPEN (municípios com EP).
5. **Armas/Prisões:** ver M6 — entram como `Crime` em SP; no RS, armas é estadual e prisões é só
   flagrante.

**De-para de valores da coluna `Crime`:**

| PoC (coluna wide) | SP (`Crime`, valor) | Observação RS |
|---|---|---|
| `hd_vitima` | `Homicídio doloso` | usar `hd_vitima` como série oficial |
| `tot_estupro` | `Estupros - total` | microdado total, só desde 2022 |
| `roubo_outros` | `Total de roubo - outros` | reconstrução estrita |
| `furto_outros` | `Total de furto - outros` | reconstrução estrita; **cautela 2022** (déficit −24%) |
| `prisoes` | `Prisões efetuadas` | só flagrantes (mandados são estaduais) |
| *(estadual, fora do painel municipal)* | `Armas de fogo apreendidas` | **não municipalizável no RS** |
| `hd_ocorrencias` | *(não existe em SP)* | extra RS; não exportar no formato-SP |

**De-para de colunas (identificadores e métricas):**

| PoC | SP (DataStudio) |
|---|---|
| `id_municipio` | `ID Município` |
| `nom_mun` | `Município (IBGE)` |
| *(derivar: `nom_mun` + " (RS)")* | `Município` |
| `nome_regiao_intermediaria` | `Nome Macrorregião` |
| `ano` | `Ano` |
| *(valor do indicador)* | `quantidade` |
| `populacao` | `população` |
| `*_taxa_100k` | `taxa` |
| *(derivar do SISDEPEN)* | `tem_EP` |

## 2.2 — Camada SAÚDE

**Semelhanças:** mesmo grão (município × ano), mesmos 6 indicadores (casos e mortes de TB/HIV/Hepatite).

**Diferenças e o que falta:**

1. **Forma:** PoC *wide*; SP *long* (coluna `Tipo`). Pivotar.
2. **`Tem_prisão`:** SP carrega; a PoC não.
3. **Sem população/taxa em SP:** a base de saúde de SP **não tem** `população` nem `taxa` (só
   `quantidade`). A PoC computa taxas de saúde. Para paridade, ou suprimir as taxas no produto
   formato-SP, ou confirmar com a equipe se elas calculam a taxa no próprio Looker.
4. **Janela:** SP 2018–2024; PoC 2018–2025 (2025 = NA). Praticamente alinhado.

**De-para de valores da coluna `Tipo`:**

| PoC (coluna wide) | SP (`Tipo`, valor) |
|---|---|
| `casos_hiv` | `Casos_HIV` |
| `casos_tuberculose` | `Casos_tub` |
| `casos_hepatite` | `Casos_Hepatite` |
| `obitos_hiv` | `morte_HIV` |
| `obitos_tuberculose` | `morte_tub` |
| `obitos_hepatite` | `morte_Hepatite` |

(Identificadores: mesmo de-para da camada criminal: `id_municipio`→`ID Município`,
`nom_mun`→`Município (IBGE)`, `nome_regiao_intermediaria`→`Nome Macrorregião`, `ano`→`Ano`,
valor→`quantidade`.)

## 2.3 — Camada CONTEXTO

**Semelhanças:** ambas no grão município, com PIB, distorção, identificadores.

**Diferenças e o que falta (a PoC produz só 6 das 21 colunas de SP):**

| SP (`dados.csv`) | PoC tem? | O que falta / fonte RS |
|---|---|---|
| `Município`, `Município (IBGE)`, `ID Município` | parcial | criar campo "(RS)" e nomes/limpos |
| `Nome Macrorregião` | ✅ (`nome_regiao_intermediaria`) | só renomear |
| `Pop_70 … Pop_2022` (6 censos) | ❌ (só 1 pop.) | IBGE — Censos (nacional, sem limitação) |
| `PIB_2010, PIB_2021, PIB_2023` | parcial (1 ano) | **IBGE** (não Seade); confirmar anos |
| `IDEB_2021` | ❌ | SP marcou **EXCLUIR** — não precisa |
| `Distorção idade-serie` (total) | ⚠️ (PoC usa fundamental) | alinhar nível (ver M4) |
| `munic_ep_70 … munic_ep_2020` | ❌ | derivar do SISDEPEN (presença de EP por ano) |
| CNES (`ambulatorial/interna/urgencia`) | ❌ | CNES nacional — decidir se entra |

## 2.4 — Camada PRISIONAL (a mais delicada)

> ⚠️ **CORREÇÃO (2026-06-19, após diff coluna a coluna das 530):** uma versão anterior desta seção
> afirmava que a base do DataStudio **não continha** regime/pena/tipo penal/filhos. **Isso estava
> errado** — eu havia inspecionado só o início e o fim das 530 colunas. O diff completo mostra que a
> base do DataStudio **tem sim** `provisorios_*`, `sentenciado_*`, `internacao_*`, `tratamento_*`,
> `pena_*`, `pena_remanescente_*`, filhos e todo o bloco `tipo_penal_*`. As diferenças reais estão
> abaixo (itens A–E) e detalhadas em `docs/spec_export_prisional_formato_sp.md`.

Aqui está o achado que mais contraria a expectativa "olhando só os scripts". A base
`base_sisdepen` de SP no DataStudio tem **530 colunas**: as colunas brutas do SISDEPEN (seções
1–7) **mais um amplo conjunto de derivadas** (regime, pena, pena remanescente, filhos, tipo penal,
óbitos, continentes, atendimento, gestantes/lactantes). Confrontando com o que a PoC
calcula em `03b`/`03c` (`painel_prisional_estabelecimento.csv`, 397 col), o diff exato é:

**A. Derivadas que a base de SP TEM e a PoC NÃO produz (faltam):**

- `continente_america`, `continente_asia`, `continente_africa`, `continente_europa`, `continente_oceania` (nacionalidade/origem)
- `atendimento_estabelecimento`, `atendimento_externo`, `atendimento_odonto`
- `cela_gestantes`, `quantidade_lactantes`

`cela_gestantes` (de 2.1) e `quantidade_lactantes` (de 5.9) são recodes triviais de colunas que a
PoC já mantém. `atendimento_*` saem de 2.4/6.6. **`continente_*` é a exceção:** a base do DataStudio
só traz "Estrangeiros - total" (não por país), então SP derivou os continentes a partir do
detalhamento **por país** da microdados completa (Base Única) + um lookup país→continente. Sem
limitação de dados no RS (SISDEPEN é nacional), mas exige a fonte por país. Detalhe no spec.

**B. Conflito de NOMES nos óbitos (mesma informação, rótulo diferente):**

| PoC (`03c`) | SP (`base_sisdepen`) | Situação |
|---|---|---|
| `obitos_naturais_*` | `obitos_saude_*` | **nome diferente** → renomear |
| `obitos_suicidios_*` (plural) | `obitos_suicidio_*` (singular) | **nome diferente** → renomear |
| `obitos_criminais_*` | `obitos_criminais_*` | ✅ igual |
| `obitos_acidentais_*` | `obitos_acidentais_*` | ✅ igual |
| `obitos_desconhecida_*` | `obitos_desconhecida_*` | ✅ igual |
| `obitos_total_geral` | *(não existe em SP)* | extra da PoC |

**C. Faixas de `pena` com binning DIFERENTE (mesma seção 5.12, cortes distintos):**

| DataStudio (`pena_{m,f}_*`) | PoC (`pena_{m,f}_*`) |
|---|---|
| `0_2`, `2_4`, `4_8`, `8_15`, `15_20`, `20_30`, `30_mais`, `sem_info` | `0_4`, `1_8`, `8_15`, `15_20`, `20_30`, `30_50`, `50_mais`, `sem_info` |

Coincidem só `8_15/15_20/20_30/sem_info`. Para o formato SP é preciso **re-somar** as faixas das
colunas brutas 5.12 com os cortes do DataStudio. (Curiosamente, `pena_remanescente_*` — seção 5.13 —
**bate 100%** entre os dois: `0_4,4_8,8_15,15_20,20_30,30_50,50mais`.)

**D. ~133 colunas BRUTAS que a base do DataStudio carrega e a PoC descartou:** seções inteiras de
trabalho/educação/saúde/visitas/inspeção que o recorte `sp_schema` da PoC deixou de fora — **6.1**
(laborterapia), **6.2** (remuneração), **6.3** (educação, a maior), **6.4**, **6.5**
(auxílio-reclusão), **6.6** (consultas de saúde), **6.7** (agravos transmissíveis), **7.3**
(visitas), **7.5** (inspeções), **2.14–2.18** (alas LGBT/idosos/indígenas/estrangeiros/
acessibilidade) e os subtipos de **5.5** (deficiência). Como elas existem na **Base Única**, o
export precisa partir dela (não do painel já podado).

**E. Identificadores:** SP usa `id`, `periodo`; a PoC usa `ID`, `ciclo`, `Referência`, `ano`,
`periodo`, `id` (+ `id_municipio`, `nome_regiao_intermediaria`). Mapear `Referência`/`Ano` →
`periodo`; os demais são extras a omitir (ou manter como apêndice).

---

## Parte 3 — O que é necessário nos scripts da PoC para gerar o formato SP

Resumo operacional (sem implementação — conforme combinado). Caberia uma nova etapa no pipeline
(ex.: `06_export_formato_sp.R`) que **lê os painéis já validados** e produz os arquivos no
formato/nomes do DataStudio. Em ordem de esforço:

1. **Pivotar criminal e saúde de wide→long** com colunas `Crime`/`Tipo` (de-para das seções 2.1 e
   2.2). Esforço baixo, impacto alto — é o que destrava o "trocar a base" no Looker.
2. **Renomear identificadores** para os rótulos de SP e criar os campos `Município` (com "(RS)") e
   o duplo nome. Esforço trivial.
3. **Alinhar nomes dos óbitos prisionais** (`naturais→saude`, `suicidios→suicidio`). Esforço trivial,
   mas **obrigatório** para o blend do Looker.
4. **Derivar `tem_EP` / `Tem_prisão` / `munic_ep_*`** a partir do SISDEPEN e juntar às camadas.
   Esforço baixo.
5. **Enriquecer o contexto** com pop. censitária histórica e PIB multi-ano (fonte **IBGE**, não
   Seade) — e decidir CNES e nível da distorção (M4). Esforço médio (novas ingestões).
6. **Derivar as 10 colunas prisionais faltantes** (continentes, atendimento, cela/lactantes).
   Esforço baixo.
7. **Decidir o destino das derivadas prisionais "extras"** (regime/pena/tipo penal) — *só depois* de
   confirmar com SP qual base alimenta o painel (ver 2.4-C). Pode economizar muito trabalho.

### Limitações do RS que persistem mesmo após o alinhamento de formato

Estas **não** se resolvem renomeando ou pivotando — são de dados, e precisam ficar explícitas no
produto enviado aos pesquisadores:

- **Armas de fogo:** só estadual no RS. A linha `Crime = "Armas de fogo apreendidas"` do formato-SP
  **não tem preenchimento municipal** — fica em tabela estadual à parte.
- **Prisões:** só o flagrante é municipal; mandados são estaduais. `Prisões efetuadas` no RS ≠
  definição plena de SP.
- **Janela criminal:** estupro e "outros" estrito só desde **2022** (microdado); SP exibe série mais
  longa. E **2022 de furtos é anômalo** (−24%, ver `problemas_dados.md`) — sinalizar.
- **Distorção idade-série:** confirmar nível (total × fundamental) para casar com SP.
- **PIB:** fonte RS é IBGE (SP usou Seade) — valores não são produzidos pela mesma instituição.

---

## Síntese executiva

1. **Não enviar a síntese sem as correções M1, M2 e M5.** O item de recorte regional está
   factualmente desatualizado e contradiz a própria base de SP.
2. **A migração direta nunca ia funcionar** porque o problema é de *forma* (wide × long) e de
   *vocabulário* (nomes de `Crime`/`Tipo`/óbitos), não de fonte. Um passo de export dedicado
   (`06_export_formato_sp.R`) resolve a maior parte com esforço baixo.
3. **A maior incerteza está na camada prisional:** a base do DataStudio de SP tem um conjunto
   derivado **menor e diferente** do que a PoC produz. Confirmar com a equipe SP qual base alimenta
   o painel prisional **antes** de continuar replicando regime/pena/tipo penal — possivelmente é
   esforço desperdiçado.
4. **Pergunta nova para a equipe SP** (além das que já estão na síntese): a série
   `dinamica_criminal` exportada só tem 2001/2023/2025 — é recorte do painel ou da fonte?
