# Plano de correção da camada prisional da PoC (alinhar a `depen.R` + `dados_sem2.R`)

> ✅ **STATUS (2026-06-22): IMPLEMENTADO e validado.** As correções D1–D6 foram aplicadas; o
> `03c_mortalidade.R` foi **mesclado no `03b`** (mortalidade ANUAL 1º+2º sem); o
> `sp_schema_prisional.csv` foi **regenerado (377→444)**; e o `07_validacao_prisional.R` confirma
> tudo (cobertura 104/103/104/103, óbitos anuais, continentes, 16 faixas de pena, nomes 26/26).
> `tipo_penal` (D7) mantido **corrigido** de propósito — ponto a discutir com a equipe de SP.
> Detalhe da implementação na **seção G** ao final. As seções D abaixo são o plano original.

*2026-06-19. Origem: revisão completa dos scripts do Monitor de SP (`MonitorPrisional2024`, fonte de
inspeção, só leitura). Errata e fórmulas canônicas em `docs/spec_export_prisional_formato_sp.md` §10
e na memória [[prisional-fonte-canonica-depen-dadossem2]].*

## A. Revisão completa dos scripts de SP — o que existe e onde está o erro

Inspecionei os **6** scripts `.R` do repositório de SP:

| Script SP | Papel | Tem derivadas? | Relevante p/ o erro? |
|---|---|---|---|
| `depen.R` | consolida 1º sem → `base_sisdepen` (cbind) → `Base_Sisdepen.xlsx` | **sim**: regime, pena, pena remanescente, filhos, tipo penal, **continentes**, **endereço** | **SIM** |
| `dados_sem2.R` | join 2º sem em `base_sisdepen` → reescreve `Base_Sisdepen.xlsx` | **sim**: **óbitos anuais (1º+2º)**, atendimento, cela_gestantes, lactantes | **SIM** |
| `dados municípios_variaveis.R` | contexto/criminal SP (pop multi-ano, PIB, IDEB, `hd_vitima=sum(o02)`) | sim, mas camada **não-prisional** | não (camada OK) |
| `validation/analysis.R` | **diff de colunas** entre `base_sisdepen_monitor.xlsx` e o script | — (validação do próprio SP) | referência útil |
| `validation/criminal_data_proccessing.R` | validação criminal | camada criminal | não |
| `validation/health_data_processing.R` | validação saúde (DATASUS) | camada saúde | não |

**Conclusão da revisão:** o erro de desenho está **confinado à camada prisional** (as funções de
`depen.R` + `dados_sem2.R`). As camadas criminal/saúde/contexto vêm de fontes próprias do RS e já
foram validadas por reconciliação — nada novo a corrigir nelas. Mapeei **todas** as derivadas dos
dois scripts; o inventário canônico está na seção C.

## B. Achado extra: a base de SP foi gerada com BUGS no próprio `depen.R`

Não é erro nosso, mas afeta a decisão de "espelhar SP" no `tipo_penal`:
- `tipo_penal_contra_pessoa_total` (depen.R L542) **soma por engano** um termo de `contra o
  patrimônio | Outros … | Masculino` no lugar do `contra a pessoa | Outros (122–154-A) | Total`.
- `tipo_penal_outros` **dupla-conta** os artigos do desarmamento (já contados em `desarmamento`).
- `desarmamento` no script atual soma os 5 artigos (14–18), mas a base divulgada batia com "só
  Art.14" (a auditoria da PoC mostrou isso) → a base do DataStudio saiu de **outra versão** do script.

→ A PoC **já diverge de propósito** aqui (abordagem residual + desarmamento somando os 5). Isso é uma
**decisão**, não um bug a "consertar para SP". Ver item D6.

## C. Inventário canônico das derivadas prisionais (fonte: scripts de SP)

- **`depen.R` (1º semestre):**
  - `perfil`: `mulheres/homens_presos_com_filhos_as` = Σ filhos 1..10 + "11 ou mais" (5.10). ✔ a PoC já faz igual.
  - `variaveis_3_4`: regime `provisorios/sentenciado_{fechado,semiaberto,aberto}/internacao/tratamento`×M/F = Σ(Just. Estadual+Federal+Outros) (4.1). ✔ a PoC já faz igual.
  - `variaveis_5`:
    - **pena (5.12):** `0_2`=(≤6m)+(6m–1a)+(1–2a); `2_4`; `4_8`; `8_15`; `15_20`; `20_30`; `30_mais`=(30–50)+(50–100)+(>100); `sem_info`.
    - **pena remanescente (5.13):** `0_4`=(≤6m)+(6m–1a)+(1–2a)+(2–4a); `4_8`; `8_15`; `15_20`; `20_30`; `30_50`; `50mais`=(50–100)+(>100). ✔ a PoC já faz igual.
    - **tipo penal (5.14):** grupos contra_pessoa / contra_patrimonio / dignidade_sexual / drogas / desarmamento / outros (com os bugs do item B).
  - `nacionalidade`: **`continente_{america,asia,africa,europa,oceania}` = `rowSums` de todas as colunas 5.8 que contêm o nome do continente × (Masculino|Feminino)**.
  - **Endereço:** `Endereço = paste0(Endereço, " - ", estado, ", ", pais)`.
- **`dados_sem2.R` (2º semestre, join em `base_sisdepen`):**
  - **óbitos = 1º sem (do `base_sisdepen`) + 2º sem**: `obitos_{saude,criminais,suicidio,acidentais,desconhecida}_{m,f,total}`.
  - **atendimento** (6.6, 2º sem): `atendimento_estabelecimento` (Consultas no estabelecimento|Total), `atendimento_externo` (externamente|Total), `atendimento_odonto` (**Consultas odontológicas|Total**).
  - `cela_gestantes` (2.1, 2º sem), `quantidade_lactantes` (5.9, 2º sem).

## D. Plano de correção no repositório RS (por arquivo)

Prioridade: **D1–D3 são bugs de correção** (afetam números já publicados no painel). D4–D5 são
**colunas faltantes**. D6 é **decisão**. Validar tudo em Python contra a base de SP antes de fechar
o R (sandbox não roda R).

### D1 — Óbitos: somar 1º + 2º semestre (era só 2º)  ·  `scripts/rs/03c_mortalidade.R`  · **BUG**
- **Hoje:** `ref_alvo <- paste0(cfg$anos, "/2")` → lê só o 2º semestre → **subcontagem** da mortalidade.
- **Canônico:** anual = 6.8 do 1º sem **+** 6.8 do 2º sem, por estabelecimento×ano.
- **Correção:** ler os **dois** semestres (`paste0(anos,"/1")` e `/2`), e somar por `id` (Nome+UF+ano).
  Manter o recorte cela física. Corrigir também o comentário do cabeçalho (atribui errado ao `dados_sem2.R`).
- **Impacto:** os totais de óbitos do painel mudam (sobem) — revalidar a auditoria (hoje 69/52/61/81).

### D2 — Óbitos: renomear para os rótulos de SP  ·  `03c` (e `05_planilha_final.R`)  · **BUG de nome**
- `obitos_naturais_*` → **`obitos_saude_*`**; `obitos_suicidios_*` → **`obitos_suicidio_*`** (singular).
- `obitos_total_geral` **não existe** em SP → remover do produto que espelha SP (pode manter como auditoria interna).

### D3 — Faixas de pena: usar o binning de SP  ·  `scripts/rs/03b_prisional_derivadas.R`  · **BUG de binning**
- **Hoje:** `0_4`(inclui 2–4), `1_8`(na verdade 4–8, rótulo errado), `30_50`, `50_mais`.
- **Corrigir para:** `pena_{m,f}_{0_2, 2_4, 4_8, 8_15, 15_20, 20_30, 30_mais, sem_info}` (fórmulas na seção C).
- `pena_remanescente_*` **já está correto** — não mexer.

### D4 — Criar `continente_*`  ·  `03b` (ou nova função)  · **coluna faltante**
- `continente_X = rowSums` das colunas 5.8 que contêm o nome do continente (`América/Ásia/África/Europa/Oceania`) × (Masculino|Feminino).
- **Requer** as colunas 5.8 **por país** da Base Única (estão lá; o recorte `sp_schema` atual pode tê-las descartado — garantir que `03_prisional.R`/`03b` leiam a Base Única larga, não a versão podada).
- Determinístico, sem lookup externo, sem limitação no RS.

### D5 — Criar `atendimento_*`, `cela_gestantes`, `quantidade_lactantes`  ·  novo passo (ou `03c`)  · **colunas faltantes**
- Vêm do **2º semestre** (como em `dados_sem2.R`): `atendimento_estabelecimento/externo/odonto` de 6.6 (odonto = "Consultas odontológicas | Total"); `cela_gestantes` de 2.1; `quantidade_lactantes` de 5.9.
- Como já abriremos o 2º sem no D1, faz sentido gerá-las **no mesmo passo** do 03c (ou um `03d`).

### D6 — `Endereço` com sufixo estado+país  ·  `03_prisional.R` ou `05_planilha_final.R`  · **coluna faltante / geolocalização**
- `Endereço := paste0(Endereço, " - Rio Grande do Sul, Brasil")` (espelha SP, que usa estado+país).
- Opcional (mais robusto que SP): incluir o município — `paste0(Endereço, ", ", Município, " - Rio Grande do Sul, Brasil")`. Tratar endereço vazio (usar só `Município - RS - Brasil`).
- Corrige a geolocalização de estabelecimentos fora do RS no mapa.

### D7 — `tipo_penal`: decisão, não correção automática  ·  `03b`  · **DECISÃO**
- A PoC já diverge de propósito de SP (corrige o bug do desarmamento e usa "outros" residual). Para o
  Monitor do RS isso só muda **valores do RS** (não há blend de números com SP), e os **nomes de
  coluna batem**. Recomendo **manter a versão corrigida** e documentar a divergência para a equipe de
  SP — mas é decisão sua. Não mexer sem definir.

## E. Decisões que preciso de você antes de implementar

1. **Escopo agora:** corrigir só os **bugs** (D1–D3) — que afetam números já no painel — ou já incluir
   as **colunas faltantes** (D4–D6) na mesma rodada?
2. **`obitos_total_geral`:** remover de vez ou manter como coluna interna de auditoria?
3. **Endereço:** espelhar SP (estado+país) ou a versão robusta com município?
4. **`tipo_penal` (D7):** manter a versão corrigida da PoC (recomendado) ou espelhar SP "bug a bug"?

## F. Validação (sandbox não roda R → validar em Python)

- Para cada derivada corrigida, **recompor a partir da base de SP** (que tem raw + derivada) e
  reconciliar 100% antes de aplicar ao RS — vale sobretudo para pena (binning), óbitos (anual) e
  continentes.
- Reabrir a auditoria do RS após D1 (óbitos sobem) e conferir cobertura 104/103/104/103.
- Rodar o `validation/analysis.R` (conceito) adaptado: diff de colunas do nosso produto vs. o header
  da base do DataStudio, para garantir paridade de nomes.

---

## G. Implementação realizada (2026-06-19)

### G.1 Análise do fluxo — consolidação de 03b + 03c
**Decisão: unir o antigo `03c_mortalidade.R` no `03b_prisional_derivadas.R`.** SP precisa de dois
scripts (`depen.R` 1º sem + `dados_sem2.R` 2º sem) porque os dados brutos dele vêm em **arquivos
separados por semestre**. Nossa fonte é a **Base Única** (todos os ciclos num arquivo, com a coluna
`Referência` "AAAA/S"): os dois semestres são apenas um **filtro** sobre o mesmo arquivo. Logo, faz
sentido fazer numa **leitura só** o que SP faz em duas etapas. Ganhos: as 3 leituras do arquivo de
70 MB (03 + 03b + 03c) caem para 2 (03 + 03b), e a mortalidade — que **deixou de ser "só 2º sem"** e
virou anual — fica no mesmo passo das demais derivadas. (Mantivemos o 03 separado: ele produz a base
**bruta** espelhando o esquema de SP; o 03b produz as **derivadas**. Poderiam ser fundidos numa
leitura única no futuro, mas a separação bruto/derivado é clara e de baixo risco.)

### G.2 Arquivos alterados
- **`03b_prisional_derivadas.R`** — reescrito (consolida 03b+03c): pena com **binning de SP** (D3),
  **continentes** (D4), **óbitos ANUAIS 1º+2º sem** com nomes de SP `obitos_saude/suicidio` (D1+D2),
  **atendimento/cela_gestantes/quantidade_lactantes** do 2º sem (D5). Lê a Base Única 1×. tipo_penal
  mantido **corrigido** (D7).
- **`03_prisional.R`** — `Endereço` para o mapa (D6): anexa `", <Município> - Rio Grande do Sul,
  Brasil"`, com **guarda anti-duplicação** (se o município já está na linha, não repete; endereço
  vazio usa só `Município - RS - Brasil`).
- **`03c_mortalidade.R`** — virou **stub de descontinuação** (lógica no 03b).
- **`05_planilha_final.R`** — removido o join separado da mortalidade (vem nas derivadas).
- **`run_all.R`** / **`00_config.R`** — atualizados (03c fora do fluxo; nota do `prisional_semestre`).

### G.3 Validação em Python (sandbox não roda R) — contra a base de SP
Reconstruí as fórmulas a partir dos **ciclos 2022 (1º+2º sem)** e comparei com os valores derivados
da base do DataStudio de SP (179 estabelecimentos pareados):

| Derivada | Reconciliação |
|---|---|
| Pena (`0_2`, `2_4`, `30_mais`) | **100%** (somas idênticas) |
| Mortalidade anual (`obitos_saude/suicidio/criminais_total`) | **100%** (confirma 1º+2º sem e os nomes) |
| Continentes (`america/asia/africa/europa/oceania`) | **177/179 idênticos**; 2 estabelecimentos divergem por **versão do extrato** SISDEPEN (ex.: Penit. de Itaí, dado de nacionalidade revisado), **não** por fórmula |

**Pendências de validação (rodar no R, com a Base Única):** reauditar os óbitos do RS após D1 (sobem
vs. a versão antiga só-2º-sem: 69/52/61/81) e conferir a cobertura 104/103/104/103; rodar o pipeline
e gerar o diff de nomes contra o header do DataStudio.
