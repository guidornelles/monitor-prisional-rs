# Spec — gerar uma base prisional no formato do DataStudio de SP (em paralelo à da PoC)

> ⚠️ **STATUS (2026-06-22): documento histórico — abordagem SUPERADA.** A ideia de uma **base
> prisional paralela** foi abandonada. Em vez disso, **corrigimos a base prisional no lugar**: o
> `sp_schema_prisional.csv` foi regenerado (377→444 colunas, capturando as ~133 que faltavam) e as
> derivadas foram portadas de `depen.R`/`dados_sem2.R`, de modo que o próprio
> `painel_prisional_estabelecimento.csv` (≈544 col) já espelha o `base_sisdepen` de SP. **Não há base
> prisional separada.** Este spec permanece como registro da análise do gap (o de-para de colunas e
> as fórmulas das derivadas continuam corretos e úteis). Para o estado atual, ver
> `docs/decisoes_metodologicas.md` e `docs/plano_correcoes_prisional_poc.md`.

*2026-06-19. Objetivo (original): além do `painel_prisional_estabelecimento.csv` atual, o pipeline
passar a emitir uma segunda base prisional com o mesmo esquema da base usada no DataStudio de SP
(`base_sisdepen`, 530 colunas). Duplicação intencional, para testar integração com o Looker.*

> Base do diff: 530 colunas (DataStudio) × 397 colunas (PoC). Resultado: **295 colunas brutas já
> casam exatamente**; ~133 brutas foram descartadas pela PoC; e há um punhado de derivadas a
> renomear, recompor ou criar. **A camada prisional não tem limitação estrutural no RS** (SISDEPEN é
> nacional; o RS preenche os mesmos campos) — o trabalho é de transformação, não de fonte.

## 0. Resumo executivo — o que é preciso, em uma frase

Um novo passo (`scripts/rs/05b_export_prisional_formato_sp.R`) que **lê a Base Única SISDEPEN
completa** (não o painel já podado), **seleciona e ordena as 530 colunas pelo header do DataStudio**,
**recompõe 6 grupos de derivadas** (pena com o binning de SP, óbitos renomeados, atendimento,
gestantes/lactantes, continentes) e grava a base paralela — validando antes na própria base de SP,
que traz raw + derivada e permite reconciliação 100%.

## 1. Fonte de entrada: a Base Única, não o painel atual

O `painel_prisional_estabelecimento.csv` **não serve** como fonte do export, porque o recorte
`sp_schema` (311/377 col) jogou fora ~133 colunas brutas que o DataStudio carrega (ver §4) e o
detalhamento por país necessário para os continentes. O export deve partir do objeto **já lido em
`03_prisional.R`** a partir da Base Única (1.782 col), com **o mesmo recorte de linhas**:

- `UF == RS` + `Tipo de Recolhimento == "Cela física"` + salvaguarda por nome;
- 1º semestre para perfil/capacidade/estrutura; **2º semestre** para mortalidade (6.8);
- cobertura esperada: 104 / 103 / 104 / 103 estabelecimentos (2022–2025).

Implicação prática: o `03_prisional.R` hoje provavelmente já reduz colunas cedo. O export precisa de
acesso ao **data frame largo antes do trim** — ou reabrir a Base Única no `05b`.

## 2. Esquema-alvo (a "fonte da verdade")

Usar o **header de `base_sisdepen - Sheet1.csv`** como lista canônica das 530 colunas (nomes exatos +
ordem). Recomendo materializá-lo num arquivo de referência versionado, p.ex.
`data/raw/schema_datastudio_prisional.csv` (1 coluna: nome; ordem = ordem final de saída). O `05b`
lê esse vetor e monta a saída coluna a coluna, na ordem dele.

## 3. Identificadores (15 primeiras colunas)

| DataStudio | Origem na PoC / Base Única |
|---|---|
| `id` | `ID` da Base Única |
| `periodo` | derivar de `Referência`/`Ano` (ano do ciclo) |
| `Situação de Preenchimento`, `Nome do Estabelecimento`, `Situação do Estabelecimento`, `Outras Denominações`, `Bairro`, `CEP`, `Âmbito`, `UF`, `Município`, `Código IBGE`, `Telefone Principal` | mesma coluna (nome idêntico) |
| `Endereço` | **NÃO é passthrough — transformar** (ver §3.1) |
| `Responsável pela Finalização` | existe na Base Única; a PoC não tinha mantido — recuperar |

Omitir no formato SP (não existem lá): `ciclo`, `Referência`, `ano`, `id` minúsculo duplicado,
`id_municipio`, `nome_regiao_intermediaria`. (Se quiser, manter como apêndice ao final — mas então
não é "idêntico" ao DataStudio.)

### 3.1 `Endereço` e geolocalização no mapa (achado 2026-06-19)

**SP modificou o `Endereço`:** os 1.616 registros terminam **todos** em `" - São Paulo, Brasil"`
(estado + país anexados ao endereço bruto do SISDEPEN; o município não entra no sufixo). Ex.:
`"Rodovia Amador Bueno da Veiga, 500, Bairro Agua Quente - São Paulo, Brasil"`. Isso **não vem do
SISDEPEN** — foi incluído por SP para o gráfico de localização (Google Maps) ancorar os pontos no
estado/país certos.

**Problema no RS:** na base da PoC, os endereços são só a rua (`"Rua Catarino Andreatta, nº 155"`) —
**0 de ~414** trazem "Rio Grande do Sul" e quase nenhum tem estado/país. Num geo chart isso
geolocaliza vários **fora do RS** (nomes de rua se repetem entre estados).

**Ação no export — criar `Endereço` no padrão de SP:**
- Mínimo (espelha SP): `Endereço := paste0(<endereço bruto>, " - Rio Grande do Sul, Brasil")`.
- **Recomendado (mais robusto que SP):** incluir o município, que reduz ambiguidade de rua —
  `Endereço := paste0(<endereço bruto>, ", ", Município, " - Rio Grande do Sul, Brasil")`.
  SP omitiu o município (provavelmente porque o geo chart também lê a coluna `Município`); no RS, com
  ruas homônimas, incluir o município é a aposta segura.
- Tratar endereço bruto **vazio** (4 casos): usar `paste0(Município, " - Rio Grande do Sul, Brasil")`
  para não gerar string só com o sufixo.
- Guardar o endereço bruto original numa coluna à parte (ex. `Endereço (SISDEPEN)`) é opcional, para
  auditoria — não existe em SP, então fora do formato idêntico.

**Varredura confirmatória (2026-06-19):** varri as 530 colunas atrás de qualquer outro vetor de
geolocalização. **Não há coluna de coordenadas (lat/long) nem string de localização composta** — a
única coluna com "Brasil" nos valores é o próprio `Endereço`. Ou seja, o mapa do Looker de SP é
geocodificado **só pelo texto do `Endereço`** (+ `Município`/`UF`). Logo, o `Endereço` é o **único**
vetor a corrigir no RS. A favor: no painel do RS, `UF` = "RS" em 414/414, `Município` e `Código IBGE`
preenchidos em 414/414, e `CEP` presente em 407/414 — então dá para compor um endereço de
geocodificação confiável (e, se quiser robustez extra, anexar o CEP).

## 4. Colunas brutas (seções 1–7): 295 casam, ~133 a recuperar

As 295 que a PoC manteve **batem por nome** com o DataStudio (a PoC as copiou verbatim da Base
Única). As ~133 ausentes são seções inteiras que o `sp_schema` cortou e que o DataStudio carrega:

- **6.1** laborterapia · **6.2** remuneração · **6.3** educação (a maior) · **6.4** trabalha+estuda ·
  **6.5** auxílio-reclusão · **6.6** consultas de saúde · **6.7** agravos transmissíveis ·
  **7.3** visitas · **7.5** inspeções;
- **2.14–2.18** alas (LGBT, idosos, indígenas, estrangeiros, acessibilidade);
- subtipos de **5.5** deficiência (intelectual/física/auditiva/visual/múltiplas | Total).

Todas existem na Base Única com os mesmos rótulos SISDEPEN → recuperáveis por seleção. **Ação:** o
`05b` faz `select(all_of(schema))`, e **audita** qualquer nome do schema que não exista na Base Única
(divergência de rótulo entre ciclos). Atenção: a PoC computou para 5.5 agregados próprios
(`... | Total de pessoas ... com deficiência | M/F`) que **não existem** no DataStudio — descartar
esses e usar os subtipos do DataStudio.

## 5. Derivadas — 4 grupos prontos (renomear) e 3 a recompor/criar

> **Princípio confirmado (observação do pesquisador):** muitas colunas do DataStudio são
> **duplicatas com nome amigável** de perguntas brutas do SISDEPEN, mantidas **lado a lado** com o
> rótulo-pergunta original, só para os gráficos ficarem legíveis (ex.: `cela_gestantes` ↔ "2.1 Há
> cela adequada/ dormitório para gestantes?"; `quantidade_lactantes` ↔ "5.9 … | Quantidade de
> lactantes"; `atendimento_odonto` ↔ "2.4 … Consultório odontológico"). Outras são agregações
> (`continente_*`, `obitos_*`, `provisorios_*`, `tipo_penal_*`). **Em todos os casos o DataStudio
> mantém as duas versões** (bruta + amigável) — então o export deve fazer o mesmo: preservar a coluna
> bruta da pergunta E criar a versão amigável. É exatamente o que o esquema-alvo de 530 colunas já
> embute; basta segui-lo.

### 5.1 Já calculadas pela PoC, casam direto (nome idêntico)
`provisorios_*`, `sentenciado_{fechado,semiaberto,aberto}_*`, `internacao_*`, `tratamento_*`,
`mulheres/homens_presos_com_filhos_as`, todo o bloco `tipo_penal_*` e **`pena_remanescente_*`** (5.13)
— este reconcilia 100%. `obitos_criminais_*`, `obitos_acidentais_*`, `obitos_desconhecida_*` idem.

### 5.2 Óbitos — renomear **e corrigir o semestre** (canônico: `dados_sem2.R`)
- Nomes canônicos: `obitos_saude_*` (não `obitos_naturais_*`), `obitos_suicidio_*` (singular, não
  `obitos_suicidios_*`); `obitos_criminais/acidentais/desconhecida_*` iguais. Remover `obitos_total_geral`.
- **Correção de método (importante):** o `dados_sem2.R` calcula óbitos **anuais = 1º sem + 2º sem**
  (`obitos_saude_total = saude_total[2º sem] + 6.8[1º sem]`, etc.). A PoC pegou **só o 2º semestre**
  → **subcontagem da mortalidade** (perde os óbitos do 1º semestre). Ver errata §10.

### 5.3 Recompor com o binning de SP (pena, seção 5.12)
O DataStudio usa **`pena_{m,f}_{0_2, 2_4, 4_8, 8_15, 15_20, 20_30, 30_mais, sem_info}`**; a PoC usa
`0_4, 1_8, 30_50, 50_mais`. **Ação:** re-somar das colunas brutas 5.12 com os cortes do DataStudio
(que devem coincidir com as categorias nativas do SISDEPEN). Validar somando o total por sexo.

### 5.4 Criar do zero (com fonte conhecida)
- **`cela_gestantes`** — recode de `2.1 Há cela adequada/ dormitório para gestantes?` (Sim/Não → 1/0). Fonte já na PoC.
- **`quantidade_lactantes`** — = `5.9 ... | Quantidade de lactantes`. Fonte já na PoC (renomear).
- **`atendimento_estabelecimento` / `atendimento_externo` / `atendimento_odonto`** — confirmado no
  `dados_sem2.R`: renomeação direta de **6.6** (2º semestre): `Consultas médicas realizadas no
  estabelecimento | Total`, `Consultas médicas realizadas externamente | Total` e **`Consultas
  odontológicas | Total`** (odonto vem de 6.6, **não** do 2.4). `cela_gestantes` = `2.1 …` e
  `quantidade_lactantes` = `5.9 … Quantidade de lactantes`, ambos do 2º semestre.

### 5.5 `continente_{america,asia,africa,europa,oceania}` — DETERMINÍSTICO (não precisa de lookup)
**Reavaliado em 2026-06-19 com a Base Única em mãos.** A seção 5.8 da Base Única **já vem agrupada
por continente → país**: 209 categorias de país (América 38 · Ásia 51 · África 54 · Europa 52 ·
Oceania 15), cada continente com um `| Outros países do continente X |`. O continente **está no
próprio nome da coluna** — não há necessidade de um lookup externo país→continente.

**Definição confirmada empiricamente (na base de SP):**
- `continente_X` = **soma de todas as colunas `5.8 | <X> | <país> | Total`** daquele continente
  (incluindo `Outros países do continente X`), por estabelecimento. É **por pessoa (M+F)** — sem
  recorte de sexo, como no DataStudio.
- Conta **só estrangeiros**. Os brasileiros ficam em `Brasileiro nato`/`Brasileiro naturalizado`
  (fora dos continentes) e o `Sem informação sobre a nacionalidade` **não entra** em continente
  algum — isso explica o resíduo medido na base de SP: Σcontinentes = 9.388 vs `Estrangeiros - total`
  = 10.155 (−767 = sem informação/não classificados).

**Único cuidado (validação, não bloqueio):** o DataStudio só exportou `Estrangeiros - total`, então
a reconstrução vem da **Base Única**, não do painel podado nem da base do DataStudio. Recomenda-se
reconciliar `continente_X` calculado da Base Única (linhas de SP) contra o `continente_X` do
DataStudio para fixar 100% o tratamento de `Outros países` e do `Sem informação` (esperado: bate, com
o resíduo indo todo para "sem informação"). **Sem dependência de fonte externa e sem limitação no RS.**

## 6. Validação (faça na base de SP primeiro — ela é o gabarito)

A `base_sisdepen` de SP traz **raw + derivada** no mesmo arquivo. Antes de aplicar ao RS:
1. recomputar cada derivada (pena com binning SP, atendimento, gestantes, lactantes, óbitos) a partir
   das colunas brutas da **própria base de SP** e **reconciliar 100%** com a coluna derivada que ela
   já traz — isso fixa a fórmula exata (sobretudo `atendimento_*` e o mapa de faixas de pena);
2. para `continente_*`, reconciliar a soma dos continentes com `Estrangeiros - total` (deve bater o
   total de estrangeiros);
3. só então rodar no RS e auditar: nº e ordem de colunas == header do DataStudio; cobertura
   104/103/104/103; sem duplicatas de `id`×`periodo`.
Gravar auditoria em `outputs/auditoria/prisional_formato_sp_cobertura.csv`.

## 7. Onde plugar no pipeline

- Novo script **`scripts/rs/05b_export_prisional_formato_sp.R`**, chamado no `run_all.R` após o `05`.
- Entrada: Base Única (via `01b`/`03`); schema-alvo em `data/raw/schema_datastudio_prisional.csv`.
- Saída: **`outputs/tabelas/base_sisdepen_rs.csv`** (530 col, grão estabelecimento×ciclo).
- O `painel_prisional_estabelecimento.csv` atual **permanece intacto** (duplicação intencional).

## 8. Esforço e ordem sugerida

1. Materializar o schema-alvo (header do DataStudio) — trivial.
2. Seleção + ordenação das 295+133 brutas a partir da Base Única + auditoria de nomes — baixo.
3. Renomear óbitos e mapear identificadores — trivial.
4. **`Endereço` no padrão SP** (sufixo município + "Rio Grande do Sul, Brasil") — trivial, mas **alto
   impacto** (corrige a geolocalização fora do RS). Ver §3.1.
5. Recompor faixas de pena (binning SP) + validar na base SP — médio.
6. Criar `cela_gestantes`, `quantidade_lactantes`, `atendimento_*` (reverse-engineering na base SP) — médio.
7. `continente_*` — **determinístico** (somar as colunas 5.8 por continente da Base Única); só
   reconciliar contra a base de SP. Deixou de ser incerteza/lookup — baixo/médio.

## 9. Limitações do RS nesta camada

Nenhuma estrutural — SISDEPEN é base nacional e o RS preenche os mesmos campos. O único risco é
**preenchimento ausente** em campos específicos de alguns estabelecimentos do RS (deixar vazio/NA
como a base de SP faz, sem imputar). **`continente_*` deixou de ser risco:** a Base Única (esquema
nacional, idêntico para o RS) traz a 5.8 já detalhada por continente→país (209 países), então o RS
tem a mesma fonte que SP usou.

## 10. Verificação contra os scripts canônicos de SP (`depen.R` + `dados_sem2.R`) e ERRATA da PoC

**2026-06-19 — inspeção direta do repositório de SP (`MonitorPrisional2024`, só leitura).** As
colunas agregadas **não** precisavam ser reconstruídas por engenharia reversa: estão escritas nos
dois scripts. Isto vira a **fonte canônica das fórmulas** e revela divergências da PoC que afetam
**também o painel prisional atual** (não só o export).

**Quem gera o quê:**
- **`depen.R`** (1º semestre, `cbind` final → `Base_Sisdepen.xlsx`): identificação, regime (4.1),
  pena (5.12), tipo penal (5.14), filhos (5.10), **continentes (5.8)** e **o sufixo de `Endereço`**.
- **`dados_sem2.R`** (2º semestre, faz `left_join` em `base_sisdepen`): **óbitos anuais (6.8, 1º+2º
  sem)**, atendimento (6.6), `cela_gestantes` (2.1), `quantidade_lactantes` (5.9). Sobrescreve o
  `Base_Sisdepen.xlsx` — é a base que alimenta o DataStudio.

**Fórmulas canônicas confirmadas:**
- **`continente_X = rowSums` de todas as colunas que contêm o nome do continente** (`América`,
  `Ásia`, `África`, `Europa`, `Oceania`) **e** (`Masculino`|`Feminino`) — i.e., soma dos países da
  5.8 por continente, M+F. Determinístico.
- **`Endereço = paste0(Endereço, " - ", estado, ", ", pais)`** com `estado='São Paulo'`,
  `pais='Brasil'`. Para o RS: `estado='Rio Grande do Sul'` → sufixo `" - Rio Grande do Sul, Brasil"`.
  (SP **não** inclui o município; nossa recomendação de incluí-lo é melhoria opcional.)
- **Faixas de pena (5.12):** `0_2` = (Até 6m)+(6m–1a)+(1–2a); `2_4`; `4_8`; `8_15`; `15_20`; `20_30`;
  `30_mais` = (30–50)+(50–100)+(>100); `sem_info`.
- **Óbitos = 1º sem + 2º sem** (anual).

### ⚠️ ERRATA — divergências da PoC vs. os scripts de SP (corrigir)

| # | Item | SP (canônico) | PoC (atual) | Impacto |
|---|---|---|---|---|
| 1 | **Óbitos / semestre** | anual = 1º + 2º sem | **só 2º sem** | **subcontagem da mortalidade** no painel atual — corrigir |
| 2 | **Faixas de pena** | `0_2/2_4/4_8/8_15/15_20/20_30/30_mais` | `0_4/1_8/…/30_50/50_mais` | binning incompatível com SP |
| 3 | **Nome dos óbitos** | `obitos_saude`, `obitos_suicidio` | `obitos_naturais`, `obitos_suicidios` | quebra blend no Looker |
| 4 | **atendimento/gestantes/lactantes** | gerados no `dados_sem2.R` | ausentes | faltam no painel |
| 5 | **Endereço** | sufixo estado+país | sem sufixo | geolocalização fora do RS |
| 6 | **continentes** | `rowSums` 5.8 por continente | ausentes | painel de origem não reproduzível |

**Observação sobre `tipo_penal` (desarmamento/outros):** no `depen.R` atual, `desarmamento` **soma os
5 artigos** (14,15,16,17,18) — **não** "só o Art.14". Mas os mesmos artigos são **somados de novo
dentro de `tipo_penal_outros`** (dupla contagem). Como a auditoria da PoC encontrou a base divulgada
batendo com "só Art.14", a base do DataStudio pode ter saído de uma **versão diferente** do script.
**Recomendação:** para `tipo_penal`, validar contra os **valores da base do DataStudio** (gabarito),
não contra o `depen.R`, antes de fixar a fórmula.

**Conclusão (responde à dúvida levantada):** sim, houve um descompasso no desenho da PoC — ela
reconstruiu as agregadas em vez de seguir `depen.R`/`dados_sem2.R`, e por isso divergiu em pena,
óbitos (nome **e** semestre), endereço, continentes e nas colunas do `dados_sem2.R`. O caminho certo
do `05b` é **portar as fórmulas desses dois scripts** (que já temos), não reinventá-las — e as
correções 1–3 valem **também para o painel prisional atual**, não só para o export.
