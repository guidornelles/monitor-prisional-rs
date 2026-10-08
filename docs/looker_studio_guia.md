# Guia — montar a PoC no Looker Studio (ex-Data Studio)

Passo a passo para publicar os painéis do Monitor Prisional RS no Looker Studio,
espelhando a estrutura do Monitor de SP. Pensado para quem nunca usou a ferramenta.

## Como o Looker Studio funciona (em 1 minuto)

Um **relatório** é um conjunto de **páginas**; cada página tem **gráficos** (tabelas,
séries, mapas, "scorecards"). Cada gráfico lê de uma **fonte de dados** (data source).
A fonte é uma planilha/tabela externa — o Looker **não** guarda os dados, ele se conecta.
Para combinar duas fontes num mesmo gráfico usa-se um **blend** (junção por uma chave).

## Passo 0 — Preparar os dados (Google Sheets)

A via mais simples e gratuita para a PoC é colocar cada painel numa **Planilha Google**:

1. Acesse https://sheets.google.com e crie uma planilha "Monitor Prisional RS".
2. Para cada painel de `outputs/tabelas/`, crie uma **aba** e importe o CSV
   (Arquivo → Importar → Upload → "Inserir nova(s) página(s)"; separador vírgula):
   - `painel_criminal_municipio_ano.csv`  → aba **criminal**
   - `painel_prisional_estabelecimento.csv` → aba **prisional**
   - `painel_contexto_municipio.csv`      → aba **contexto**
   - `painel_saude_municipio_ano.csv`     → aba **saude**
3. Confira que a 1ª linha são os nomes das colunas e que números não viraram texto
   (Formatar → Número quando preciso). Decimal: o Looker usa ponto; se o CSV veio com
   vírgula decimal, reimporte com a opção de detectar automaticamente ou ajuste a coluna.

> Alternativa: no Looker Studio há o conector **Upload de arquivo** (CSV direto), mas o
> Google Sheets é mais fácil de atualizar e reaproveitar.

## Passo 1 — Criar o relatório e as fontes

1. Acesse https://lookerstudio.google.com → **Criar** → **Relatório**.
2. Adicionar dados → conector **Planilhas Google** → escolha a planilha e a aba.
   Repita para as 4 abas (4 fontes de dados no relatório).
3. Em cada fonte, revise os **tipos de campo**:
   - `id_municipio` → **Texto** (é uma chave, não um número a somar).
   - `ano` → **Número** (ou Data, ano).
   - `nome_regiao_intermediaria`, `nom_mun` → Texto (dimensões).
   - contagens e `*_taxa_100k`, `populacao`, `pib` → **Número** (métricas).

## Passo 2 — Estrutura de páginas (espelhando SP)

Segundo a Nota Metodológica de SP, o monitor tem três blocos. Sugestão de páginas:

1. **Dados de Contexto / Panoramas** (fonte: `criminal` ou `contexto`; `saude`)
   - Panorama Populacional/Econômico: tabela e mapa de `populacao` e `pib` por município/região.
   - Panorama Educacional: `distorcao_idade_serie_fund`.
   - Panorama de Saúde (fonte `saude`): séries de casos/óbitos de TB, hepatite e HIV por ano.
2. **Dinâmica Criminal** (fonte: `criminal`)
   - Números absolutos e **taxas por 100 mil** (`*_taxa_100k`): homicídio, estupro,
     roubos/furtos "outros", prisões.
   - Mapas por município e comparativos por **região intermediária**.
3. **Dados Prisionais** (fonte: `prisional`)
   - Estrutura/capacidade, população por regime, perfil (faixas de pena, tipo penal),
     e **Mortalidade** (`obitos_*`).

## Estrutura espelhada do Monitor SP (observada no relatório oficial)

Páginas do monitor de SP, com o que replicar para o RS e a fonte/campos:

| Página (SP) | Conteúdo | Fonte RS / campos |
|---|---|---|
| **Apresentação** | Texto institucional + "como navegar" | texto livre |
| **Panorama Populacional** | população por município/região (série censitária) | `contexto`: `populacao` |
| **Panorama Econômico** | PIB municipal | `contexto`: `pib` |
| **Panorama de Saúde** | casos e mortes (TB/hepatite/HIV) por ano | `saude`: `casos_*`, `obitos_*` × `ano` |
| **Panorama Educacional** | distorção idade-série (Ens. Fundamental) | `contexto`: `distorcao_idade_serie_fund` |
| **Dinâmica Criminal** | filtros (região, município) + 1 série histórica por indicador (absolutos) | `criminal` |
| **Dinâmica Criminal - Mapas** | mapas por município | `criminal` (+ ressalva de mapa, Passo 5) |
| **Dados Prisionais** | por estabelecimento e município | `prisional` |

**Padrão da página "Dinâmica Criminal"** (replicar igual):
- Topo: **dois controles de filtro** — `nome_regiao_intermediaria` e `nom_mun`.
- Um **gráfico de colunas/série temporal por indicador** (eixo X = `ano`; valores rotulados):
  `hd_vitima` (homicídio), `tot_estupro`, `roubo_outros`, `furto_outros`, `prisoes`
  (+ `hd_ocorrencias` como extra). Observação: SP tem "Armas de fogo apreendidas" por
  município; no RS isso **só existe em nível estadual** — fica de fora do mapa municipal
  (ver `docs/auditoria...`/`problemas_dados.md`). Série do RS: 2022–2025 (SP usa desde 2001).
- Bloco de **texto descritivo** + "Fonte: SSP-RS".

## Passo 3 — Gráficos úteis

- **Scorecard** (número grande): total do estado de um indicador, com filtro de ano.
- **Tabela** com barras: ranking de municípios por taxa.
- **Série temporal**: indicador × `ano` (criminal 2022–2025; saúde 2018–2024).
- **Gráfico de barras**: comparação por `nome_regiao_intermediaria`.
- **Mapa**: ver Passo 5 (tem uma ressalva).

## Passo 4 — Filtros e blends

- Adicione **controles de filtro** no topo: `ano` (lista suspensa) e
  `nome_regiao_intermediaria` (lista). Eles filtram todos os gráficos da página.
- **Chave de junção:** `id_municipio` liga criminal × contexto × (município do) prisional.
  Como o `painel_criminal` **já traz** população, PIB, distorção e região embutidos, na
  maioria dos gráficos criminais **não é preciso blend**. Use blend só para cruzar fontes
  de grãos diferentes (ex.: prisional × contexto) — junção por `id_municipio`.
- Saúde liga ao resto pelo IBGE de **6 dígitos** (`cod_mun6`); se precisar cruzar com as
  demais (que usam 7 dígitos), crie um campo calculado `LEFT(id_municipio, 6)`.

## Passo 5 — Mapas (ressalva importante)

O mapa de municípios brasileiros no Looker Studio é limitado: ele reconhece melhor o
campo geográfico por **nome** (tipo Geo → Cidade, com país = Brasil) do que por código
IBGE, e pode haver ambiguidade entre municípios homônimos de outras UFs. SP contornou
isso plotando em outra ferramenta ("Dados Cartográficos" do Google) e embutindo o mapa.
Opções para o RS, da mais simples à mais robusta:

1. Começar **sem mapa**: tabelas e barras por município/região já comunicam bem.
2. Definir `nom_mun` como **Geo → Cidade** (país Brasil) e aceitar imprecisões pontuais.
3. Mapa preciso: anexar latitude/longitude dos centroides dos 497 municípios (IBGE/geobr)
   ao painel e usar o gráfico de **mapa de bolhas** por lat/long. (Posso gerar esse
   arquivo de centroides depois, se quiser.)

## Passo 6 — Compartilhar

Botão **Compartilhar** (como no Google Docs): link de visualização para o Marlon/equipe,
ou permissão de edição. As atualizações de dados são automáticas quando você edita as
planilhas Google (o Looker relê na atualização).

---
**Atualização do dado:** ao rodar o pipeline novamente, reimporte os CSVs nas mesmas abas
do Google Sheets (mesmos cabeçalhos) — os gráficos do Looker se mantêm. Para automatizar,
dá para publicar os CSVs num local fixo e usar add-ons de importação no Sheets.
