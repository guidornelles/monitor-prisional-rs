# Decisões metodológicas do Monitor Prisional RS

> Registro criado em 10/06/2026 e atualizado para a versão candidata em 12/11/2026. A configuração está em [`00_config.R`](../scripts/rs/00_config.R). Os resultados da PoC e da auditoria do Sinesp são referências datadas; para a nova execução, consultar seus arquivos de auditoria e manifesto.

## Encaminhamentos e escopo

- **26 de junho:** a reunião encaminhou o uso de vítimas de homicídio, fontes oficiais estaduais, a janela comum a partir de 2022 e as regiões intermediárias do IBGE na dinâmica criminal. A proposta de comparar apenas flagrantes respondia à falta, à época, de mandados municipalizados no RS. Os painéis por estado podem preservar séries que não passem no filtro comparativo.
- **Outubro:** não houve novos encaminhamentos para o Monitor RS na reunião. A resposta à LAI 52872 distinguiu o recorte de violência doméstica contra mulheres da base geral de estupro e explicou a diferença entre as datas de extração dos registros de 2022. A SSP-RS publicou a revisão. O [levantamento do Sinesp VDE](auditoria_sinesp_vde_2026-10-03.md) identificou mandados por município e mês e reconciliou os agregados estaduais de 2022 a 2025. Isso permite acrescentar a série sem substituir a SSP-RS.
- **12 de novembro:** a candidata do RS terá dinâmica criminal **2022–2025** e dados prisionais **2017–2025**, em `cfg$anos_criminal` e `cfg$anos_prisional`. Mandados cumpridos do Sinesp entram como série própria. Armas permanecem estaduais. A PoC comparativa é a próxima etapa, começa em **2022** e depende de base paulista e harmonização por indicador. A seleção de anos mostrada no painel paulista não define a disponibilidade na fonte. A inclusão de 2026 na camada prisional fica para o próximo ciclo anual.
- **Escopo separado:** o indicador de serviços penais a partir do módulo LEP da tese não condiciona a candidata. A publicação oficial é uma etapa distinta da [cópia de revisão no Data Studio](looker_studio_guia.md).

## Reprodutibilidade
- **Scripts numerados, `run_all.R` e `renv`:** cada etapa lê e escreve arquivos. Os insumos, as saídas e o passo a passo estão no [README do pipeline](../scripts/rs/README.md).
- Cada etapa **lê/escreve arquivos** em `data/{raw,intermediate,processed}`; nenhuma depende de objeto em memória de outra.
- Caminhos e parâmetros **centralizados** em `00_config.R` (nada hardcoded espalhado).
- **Entradas fixadas por versão:** preservar brutos com arquivo, data de extração, origem e hash. Revisões retroativas devem ser comparadas contra a versão anterior.
- **Saídas isoladas:** `MONITOR_RS_RUN_DIR` define a pasta de execução da candidata, com `processed/`, `tabelas/` e `auditoria/`. Registrar fonte e período no gráfico e evitar que a cópia do painel reutilize conexões da PoC.

## Escolhas por indicador
| Indicador | Candidata RS | Condição para comparação |
|---|---|---|
| Homicídio doloso | **Vítimas** (`hd_vitima`, agregado oficial); `hd_ocorrencias` fica para controle. | Conferir unidade e cobertura de SP por ano. A soma homicídio + feminicídio reproduziu o total de SP em 2023 no teste com o VDE; isso não autoriza repetir a soma no RS ou em outro ano. |
| Estupro | **Ocorrências consumadas** de estupro e estupro de vulnerável, ambos os sexos, nos microdados. | Confirmar unidade e rubricas em SP; não emendar a série de violência doméstica na série total. |
| Roubo e furto “outros” | Reconstrução estrita via microdado, excluindo as rubricas documentadas. | Validar a correspondência das rubricas com SP. Para reconciliar com o agregado oficial, reconstituir seu universo; não usar o valor de “outros”. |
| Flagrantes da Polícia Civil | Registros de flagrantes da SSP-RS por município × ano. | Usar o componente paulista correspondente se unidade, competência e cobertura coincidirem. |
| Mandados de prisão cumpridos | Série própria do **Sinesp VDE**, abrangência estadual, por município × ano. | Conferir unidade, órgão e referência territorial antes de comparar ou somar. |
| Armas apreendidas | Série estadual separada, sem rateio territorial. | Confirmar abrangência institucional. Os anexos da LAI não reconstituem a série municipal 2022–2025. |
| Taxas | Absolutos e taxas por 100 mil, com denominador fixo do Censo 2022 no RS. | Harmonizar o denominador antes do comparativo. Recalcular taxas regionais ou estaduais pela razão dos totais. |

## Recorte territorial e regional
🟩 **Unidade base:** município. **Região:** o Monitor de SP usa as **regiões geográficas intermediárias do IBGE** (verificado: a coluna `nome_regiao_intermediaria` consta na `populacao_municipios_sp.xlsx`, e as regiões exibidas no painel batem com as regiões intermediárias do IBGE para SP). **Decisão:** adotar o **mesmo conceito para o RS** — regiões geográficas intermediárias do IBGE (RS tem 8). O mapeamento município→região vem do **diretório de municípios do IBGE** (mesma fonte que SP usou via basedosdados); no módulo de contexto, obteremos `cod_ibge → nome_regiao_intermediaria` de fonte IBGE reprodutível (divisão regional 2017 / pacote `geobr` ou SIDRA), sem depender de billing GCP.

Nos dados prisionais, município é a localização do estabelecimento, não sua área de captação de presos. O painel usa estabelecimento e município. Regionalizações penitenciárias podem ser acrescentadas em etapa própria.

### Notas sobre unidade e composição
- **`hd_vitima` e `hd_ocorrencias`:** a reunião confirmou que a intenção é exibir vítimas. No RS, somar o campo “Quantidade Vítimas” do microdado de referência não reproduziu o agregado oficial, por isso a série principal vem desse agregado. A inspeção dos scripts de SP encontrou contagem de registros e período parcial para a extração de 2025; o acordo sobre a unidade não resolve a implementação em todos os anos.
- **Composição de "roubo/furto outros":** SP exclui veículo, banco, carga "e outras variações". A reconstrução estrita exclui veículo + banco/comércio/carga/transporte (e abigeato no furto). **Confirmar com SP** a lista exata de subtipos do "outros".

## Validação criminal e revisão de 2022

Na candidata, usar o microdado revisado da [SSP-RS](https://www.ssp.rs.gov.br/dados-abertos), com data de extração de **23/06/2026**. No teste de outubro, a revisão gerou **128.244 furtos** na reconstrução do agregado, contra **128.047** na tabela oficial então guardada (**+0,15%**), e **36.882 roubos** contra **36.950** (**−0,18%**). Na composição estrita, o teste produziu 119.345 furtos “outros”, 33.933 roubos “outros” e 5.862 ocorrências de estupro. São resultados da versão testada, não uma garantia de coincidência por município ou mês. A execução candidata precisa registrar as versões usadas e repetir a reconciliação, inclusive para a atualização de 2025.

### Referência histórica da PoC de junho

Reconciliação dos **totais** reconstruídos do microdado então usado vs. a coluna oficial dos Indicadores Criminais:

| Ano | Δ homicídio | Δ furtos | Δ roubos | Veredito |
|---|---:|---:|---:|---|
| 2023 | −0,19% | −0,05% | −0,29% | ✅ reconcilia |
| 2024 | −0,07% | +0,01% | −0,36% | ✅ reconcilia |
| 2025 | −0,21% | −1,96% | −1,30% | 🟨 desvio leve (revisão recente?) |
| 2022 | −0,25% | **−24,4%** | −4,3% | 🟥 **anomalia — investigar** |

**Achado da versão antiga de 2022** (ver [problemas dos dados](problemas_dados.md)):
- Oficial 2022 **"Furto" = 128.047** (coluna isolada; "Abigeato"=4.881 e "Furto de Veículo"=8.953 são colunas à parte — não é total agregado).
- Microdado 2022: **todos** os enquadramentos com "FURTO" = **104.449**; o subconjunto comparável (exclui furto de veículo e abigeato) = **92.793**; nosso `furtos_total` = 96.768. Mesmo a soma de TODOS os furtos do microdado fica abaixo do "Furto" oficial.
- Déficit **uniforme nos 12 meses** (~7–8 mil/mês) → não é mês faltante, é descompasso sistemático.
- Roubos 2022 também levemente baixos (−4,3%); homicídio bate. 2023–2025 reconciliam.
- **Situação:** a resposta à LAI explicou a diferença de datas de extração e anunciou atualização. O déficit estadual medido nessa versão não caracteriza a extração revisada; permanece como evidência da mudança de versão.

O "outros estrito" fica ~7% abaixo do total de roubos (a exclusão banco/comércio/carga) — por construção, e por isso **não** se compara diretamente com a coluna oficial "Roubos".

## Panorama de Saúde — `04b_saude.R`
🟩 **Espelha SP** (Notas Metodológicas): por município×ano, **casos notificados e mortes** por tuberculose, hepatite e HIV (DATASUS). SP compila isso **manualmente do TABNET**.
🟩 **Decisão: TABNET para tudo (canônico), em `04b_saude.R`.** Como os CASOS notificados (TB/hepatite/HIV) só existem via TABNET (o `microdatasus` não cobre esses SINAN — verificado na doc oficial: só dengue/chikungunya/zika/malária/chagas/leishmaniose/leptospirose), optou-se por fazer **também a mortalidade pelo TABNET (SIM/CID-10)**, unificando o fluxo, evitando a dependência do `microdatasus` (install_github, read.dbc no Windows, FTP instável) e espelhando o método de SP. São ~6 exportações (linha=Município residência, coluna=Ano, filtro UF=RS): casos TB (`tubercbr.def`), hepatite (`hepabr.def`), HIV (aids.gov.br); óbitos TB/hepatite/HIV (SIM, filtrando CID-10 A15–A19 / B15–B19 / B20–B24).
- **Alternativa opcional:** `01c_download_datasus.R` faz só a mortalidade via `microdatasus` (SIM-DO), para quem preferir automatizar essa parte.
- 🟩 `04b_saude.R` (ingestão) escrito e **validado** contra o export real de tuberculose: formato largo (`"Município de residência";"2018"...;"Total"`), código IBGE de 6 díg. + nome, `-`=0, rodapé "Total"/`&` descartados; reproduz exatamente os totais do TABNET (6.479…7.846/ano) e os 6 díg. casam 100% com o IBGE. O mesmo parser serve para hepatite/HIV/óbitos (indicador inferido do nome do arquivo). Junção por `substr(id_municipio,1,6)`.
- 🟩 **Período: 2018–2025** (como SP). Camada com janela própria; painel separado (`painel_saude_municipio_ano.csv`), não no painel criminal (2022–2025).
- 🟩 **Cobertura temporal heterogênea → NA por indicador (não 0).** Lacuna estrutural (ano ausente para um indicador) = NA, não zero; zeros reais vêm do "-" do TABNET. Corte por **último ano consolidado** (`cfg$saude_ano_max*`; valores além = NA, provisório): **casos_hepatite até 2023** (SINAN hepatites virais consolidado só até 2023, conforme nota do TABNET); **demais até 2024** (SINAN casos e SIM óbitos: 2025 ainda provisório em jun/2026). Validado: 6 indicadores, hepatite NA em 2024–2025, tudo NA em 2025.
- 🟩 **Seis exportações ingeridas** (TB/hepatite/HIV × casos/óbitos). Totais conferem com a linha "Total" do TABNET.

🟩 **Correção (qualidade):** a API do IBGE devolveu 1 registro vazio (498 linhas = 497 municípios + 1 NA), que tornava `id_municipio` float. Corrigido na fonte (`01_download.R` filtra NA) e defensivamente no `04_contexto.R`.

## Planilha final / crosswalk municipal — `05_planilha_final.R`
🟩 **Saída espelhando o Looker de SP** (tabelas separadas, blendadas pela chave municipal):
- `painel_criminal_municipio_ano.csv` — grão município × ano; inclui `hd_vitima`, `hd_ocorrencias`, `tot_estupro`, `roubo_outros`, `furto_outros`, flagrantes da PC, `mandados_cumpridos` e campos de contexto e taxas. Grade esperada **497 × 4**, com 1.988 linhas sem duplicatas; ausência de informação não é zero observado.
- `painel_prisional_estabelecimento.csv` — camada SISDEPEN por estabelecimento (≈544 col), enriquecida com `nome_regiao_intermediaria` via `Código IBGE`. É a base prisional que vai ao DataStudio (não há export prisional separado — foi corrigida no lugar).
- `painel_contexto_municipio.csv` — denominadores/panoramas + `munic_ep` (município tem presídio? do SISDEPEN) e `ano_ep` (menor ano de inauguração do presídio do município → vira `tem_EP` no criminal).

🟩 **Export formato-SP — `05b_export_formato_sp.R` (camada de apresentação):** re-emite as bases internas com os NOMES e o FORMATO que o Looker de SP já usa (importação plug-and-play, sem renomear campo a campo). NÃO recalcula nada — só renomeia/pivota. Saídas em `outputs/tabelas/formato_sp/`: `contexto_dados.csv` (wide), `dinamica_criminal.csv` e `dados_saude.csv` (LONGO, com coluna `Crime`/`Tipo` + `taxa` + `tem_EP`/`Tem_prisão`). Decisões de contexto: distorção = Ensino **Fundamental** (conforme a **Nota Metodológica de SP**; ⚠️ o **descritivo/script de SP menciona o total** — divergência interna de SP, **a confirmar com a equipe**; a PoC usa o fundamental, consistente com a Nota); PIB = **IBGE** (Nota confirma; não Seade); sem histórico de pop/PIB; IDEB fora.

🟩 **Validação — `07_validacao_prisional.R`:** confere cobertura, óbitos anuais, paridade de nomes com a base do DataStudio, e consistências (óbitos M+F, tipo_penal_outros≥0, continentes≤estrangeiros, 16 faixas de pena). Saída em `outputs/auditoria/validacao_prisional.md`.

🟩 **Crosswalk de nome de município (SSP→IBGE):** chave = nome normalizado (maiúsculas, sem acento; apóstrofo deletado, hífen→espaço). Resolve "Sant'Ana"↔"Santana", "Entre-Ijuís", "Xangri-lá", "Não-Me-Toque". Mais um **mapa de aliases explícito** (15 entradas) para divergências de grafia e **erros de digitação na fonte** ("Aceguaá"=Aceguá, "São Josedo Ouro"=São José do Ouro, "Estância Velhas"=Estância Velha, "DR"=Doutor, "Pinto Bandeira (Bento Gonç)"=Pinto Bandeira). Preferiu-se mapa explícito a fuzzy às cegas (auditável). Resultado: **495/497** municípios com flagrantes pareados; residual não-pareado = ~13 registros (0,04% das prisões), todos de **outras UFs** (SC/RJ/SP/MG/PR), corretamente descartados. Auditoria em `outputs/auditoria/match_municipios.csv`.

## Flagrantes, mandados e armas

- **Flagrantes da Polícia Civil — `02b_atividade.R`:** contagem de registros da SSP-RS (Lei nº 15.610/2021, art. 6º, IX) por município × ano, somando os arquivos semestrais. Na PoC de junho, o campo `prisoes` continha apenas flagrantes e o painel o chamava de “Prisões efetuadas”. A candidata identifica a série como **Flagrantes da Polícia Civil**.
- **Mandados de prisão cumpridos — `02c_mandados_sinesp.R`:** série própria do VDE, abrangência estadual. A auditoria de outubro reconciliou 6.966, 8.464, 8.579 e 10.754 mandados no RS, respectivamente de 2022 a 2025. A reconciliação é estadual: há municípios sem valores e municípios com meses parciais. O total municipal só é exibido com 12 meses informados. O agregado estadual é auditado separadamente e não deve ser inferido pela soma dos municípios exibidos.
- **Diferença para SP:** a [SSP-SP](https://www.ssp.sp.gov.br/assets/estatistica/trimestral/arquivos/2022-04.htm) inclui flagrantes e prisões por mandado em “Prisões efetuadas”, separando esse indicador de pessoas presas. A fonte gaúcha de flagrantes conta registros; a unidade e o território de referência do VDE gaúcho ainda precisam ser confirmados antes de somar os componentes para comparação. Os dois componentes permanecem separados na candidata.
- **Armas apreendidas:** série separada em nível estadual, fora do mapa municipal e dos filtros de município e região. A LAI trouxe dados localizados, mas sem série comparável para 2022–2025. Não ratear o agregado estadual entre municípios.
- ⚠️ **Encoding (problema de dados):** os CSVs de flagrante variam entre **UTF-8 e CP850 (DOS)**. Ler CP850 como latin1 gera mojibake ("SÆO LEOPOLDO") que vira chave duplicada de município (inflou 2022 de 438 para 558). `02b` escolhe o encoding por bytes (menos caracteres suspeitos) e normaliza nome (maiúsculas + sem acento) para casar com o IBGE. Também há **bloco de título** antes do cabeçalho (detectado dinamicamente) e **rodapé** ("Fonte:"/"Extração:") descartado pelo filtro de município vazio.
- ⏳ **Match município→IBGE:** ~522 chaves distintas (2022–2025) vs 497 do IBGE — excesso são municípios de outros estados/variantes; o join no `05` casa por nome normalizado e **audita os não-pareados** (para não perder município real do RS por divergência de grafia).

## Derivadas prisionais — `03b_prisional_derivadas.R` (consolida o que SP faz em depen.R + dados_sem2.R)
🟩 **ATUALIZAÇÃO (2026-06):** após inspeção dos scripts de SP (`depen.R` + `dados_sem2.R`, repositório de SP, só leitura), portamos as fórmulas FIÉIS desses scripts em vez de reinventar — corrigindo várias divergências (ver `docs/plano_correcoes_prisional_poc.md`). O antigo `03c_mortalidade.R` foi **mesclado no 03b** (DESCONTINUADO): como nossa fonte é a Base Única (todos os ciclos num arquivo, com `Referência` "AAAA/S"), os semestres são só um filtro — uma leitura faz tudo. Cobertura: 104/103/104/103 estab. (cela física, por ano).

- **Regime (4.1):** `provisorios/sentenciado_fechado/semiaberto/aberto/internacao/tratamento × M/F` = soma Just. Estadual+Federal+Outros — fiel a SP.
- **Pena (5.12) — binning de SP (corrigido):** `pena_{m,f}_{0_2,2_4,4_8,8_15,15_20,20_30,30_mais,sem_info}` (era `0_4/1_8/30_50/50_mais` — errado; agora bate 100% com a derivada de SP). **Pena remanescente (5.13):** `pena_remanescente_{m,f}_{0_4,4_8,8_15,15_20,20_30,30_50,50mais}` (sempre esteve correto).
  - ⚠️ **Anomalia de DADO do RS (não de cálculo):** a faixa "Até 6 meses" do RS concentra ~78% dos condenados (5.12 e 5.13), vs 5,1%/30,9% em SP — a distribuição de tempo de pena do RS é **não-confiável**. Ver `docs/problemas_dados.md` item 2.
- **Filhos (5.10):** `mulheres/homens_presos_com_filhos_as` = soma de 1..10 e "11 ou mais".
- **Tipo penal (5.14) — CORRIGIDO** (decisões do pesquisador; ver `docs/auditoria_tipo_penal_sp.md`): `desarmamento` = soma dos 5 tipos; `contra_patrimonio` AMPLO (13 subtipos); `outros` = RESIDUAL (total 5.14 − 5 grupos, sem dupla contagem). ⚠️ Diverge do output de SP de propósito (SP tem bug); levar à equipe de SP.
- **Continentes (5.8):** `continente_{america,asia,africa,europa,oceania}` = `rowSums` das colunas 5.8 que contêm o nome do continente × M/F (origem dos estrangeiros). Brasileiros ficam em `brasileiro_nato` (= "Brasileiro nato" M+F) e nas colunas raw; "Sem informação" não entra em continente. Fiel a `depen.R::nacionalidade`.
- **Mortalidade (6.8):** `obitos_{saude,criminais,suicidio,acidentais,desconhecida}_{m,f,total}` soma os dois semestres quando ambos os valores existem. `obitos_registrados` conserva a soma disponível separadamente. Um campo ausente não vira zero. A cobertura é parcial de 2017 a 2022. Em 2018, 10 de 102 estabelecimentos informaram algum valor do bloco no primeiro semestre e 58 de 102 no segundo; 8 tinham todos os campos nos dois ciclos. O resultado observado não representa o total estadual anual. Os valores 152/102/131/140 da PoC são referências de 2022–2025 sob as regras anteriores.
- **2º semestre (como `dados_sem2.R`):** `atendimento_{estabelecimento,externo,psicologico,odonto}` (6.6 consultas), `cela_gestantes` (2.1), `quantidade_lactantes` (5.9).
- **Outras variáveis pedidas:** `populacao_total` (4.1 | Total), `capacidade_total` (1.3 M+F Total), `total_medicos` (4 categorias de médico do 3.1), `brasileiro_nato`. Agravos transmissíveis (6.7: HIV/Sífilis/Tuberculose/Hepatite/Outros) ficam nas colunas raw por sexo.

## Camada prisional (SISDEPEN-RS) — `03_prisional.R`
🟩 **Fonte: Base Única consolidada da SENAPPEN** (`cfg$escolhas$sisdepen_fonte = "base_unica"`). Decisão revista após inspeção: a SENAPPEN publica, sim, uma **Base Única** ("Todos os ciclos em arquivo único") via SharePoint, além dos arquivos por ciclo. Verificado no arquivo consolidado (28.825 linhas, ciclos 2016–2025, 1.782 colunas).

**Por que a Base Única, e não os arquivos por ciclo (como SP fez):**
1. **`Tipo de Recolhimento` (cela física/domiciliar) vem 100% preenchido em TODOS os anos (2016–2025).** Nos arquivos por ciclo, esse campo só existe a partir de 2024 — o que obrigava a uma aproximação em 2022–2023 (via `1.2 Tipo de estabelecimento`). A Base Única **elimina a aproximação**: recorte cela física nativo e exato em toda a série.
2. Traz **`ID` de estabelecimento estável entre ciclos** (protege contra mudança de nomenclatura — alinhado à filosofia de crosswalk da tese) e `ciclo`/`Ano`/`Referência` (empilhamento longitudinal embutido).
3. **Esquema único de 1.782 colunas** — sem a heterogeneidade entre ciclos (arquivos por ciclo variam: 2022 tinha 1.334 colunas; 2024, 1.737).
4. É a fonte canônica usada na tese do pesquisador, que atualiza os ciclos a partir dela.

**O que SP fez (evidência do `depen.R`, repositório SP):** leu arquivos **por ciclo**, 1º semestre, 2017→2023, com único filtro `UF == "SP"` — **sem recorte por tipo/recolhimento**. SP não precisou filtrar porque sua janela terminou em 2023, antes de o campo existir nos arquivos por ciclo. **Erro de SP a corrigir:** SP manteve no Monitor estabelecimentos que são apenas cadastros de prisão domiciliar / monitoração eletrônica (inflando contagens — caso de 2021, em que a administração de SP triplicou cadastros do mesmo estabelecimento: cela física + domiciliar + domiciliar c/ monit. eletrônica). Nosso recorte corrige isso.

🟩 **Recorte (`cfg$escolhas$prisional_recorte = "cela_fisica"`):** `UF == RS` + `Tipo de Recolhimento == "Cela física"` + **salvaguarda por nome** (exclui registros tipados cela física mas nomeados domiciliar/monitoração — replica o filtro duplo da tese; em RS hoje não há nenhum, mas guarda ciclos futuros). O `03` produz o **1º semestre** (perfil/capacidade/estrutura, como SP); a mortalidade ANUAL (1º+2º sem) é calculada no `03b` (o `prisional_semestre` agora só parametriza a base bruta do 03).

🟩 **Endereço para o mapa:** o `03` anexa ao `Endereço` o município + "Rio Grande do Sul, Brasil" (espelha o `depen.R`, que anexa "São Paulo, Brasil"), com guarda anti-duplicação. Sem isso, ruas homônimas geolocalizam fora do RS. Também deriva `ano_inauguracao` (do campo 1.6) para o filtro do mapa por ano.

🟩 **Esquema REGENERADO (2026-06) — `data/raw/sp_schema_prisional.csv` (444 colunas):** o esquema antigo (377) era um recorte **incompleto** que deixava seções inteiras de fora (6.1–6.7, 7.3/7.5, 2.14–2.18, subtipos de 5.5). Regeneramos o esquema a partir do que SP **de fato mantém** — header da base do DataStudio (`base_sisdepen`) ∩ Base Única — preservando a ordem de colunas de SP. Resultado: **444/444** colunas casam (painel ≈ 544 col com as derivadas, espelhando as 530 de SP). As variáveis DERIVADAS por SP (regime, pena, óbitos, continentes, atendimento…) NÃO entram no esquema — são computadas no `03b`.

**Cobertura RS (cela física, 1º sem):** a extração candidata soma 927 registros de estabelecimento e ano. De 2017 a 2025, a cobertura foi 99/102/104/104/104/104/103/104/103. Use `prisional_cobertura.csv` e `prisional_mortalidade_cobertura.csv` da execução para verificar os nove anos e a cobertura dos fluxos. Na validação antiga, a aproximação por ciclo de 2022 dava 107 registros e a Base Única com o campo nativo retornava 104.

🟩 **Reprodutibilidade — resolvida (era o único trade-off):** a Base Única é baixada de forma **scriptável** direto do SharePoint, anexando `&download=1` ao link de compartilhamento (testado: download estável, mesmo md5 em repetições). `01b_download_sisdepen.R` faz o download (URL em `cfg$sisdepen_baseunica_url`), confere **md5** (`cfg$sisdepen_baseunica_md5 = a4ab2749887c49879b47b10fc72d86b4`, 70.983.784 bytes — o que `download.file` produz) e grava manifesto. Fallback: se o SharePoint devolver HTML de interstício, o script avisa e o download manual cobre. Os arquivos **por ciclo** (gov.br, `baixar_ciclos = TRUE`) ficam como validação independente. Arquivo localizado por `00_config.R::arquivo_baseunica` (padrão `*baseunica*.xlsx`).
- **Nome de arquivo versionado:** o `01b` salva com o nome que o SharePoint informa no `Content-Disposition` (via `httr2`), que embute o **timestamp do release** (ex.: `sisdepen_baseunica_2025-2_25032026-163420.xlsx` = 25/03/2026 16:34:20). Assim cada versão é autoidentificável e não sobrescreve outra — alinhado ao tratamento de *mutability of administrative data*. `arquivo_baseunica()` localiza por `*baseunica*.xlsx` e usa o mais recente.
- **Nota de proveniência:** o **canônico é o arquivo baixado pelo script** (md5 `a4ab2749`, 70.983.784 bytes), não cópias manuseadas. A cópia no repo da tese (md5 `2ca60a94`, +1.448 bytes) difere por reescrita do Excel ou release anterior — ~1,4 KB em 71 MB, irrelevante para os dados. Confirmar equivalência pelos números da auditoria do `03` (RS cela física 104/103/104/103). O md5 é checado como **aviso** (não erro): nova versão da SENAPPEN gera novo nome + novo md5; atualizar `cfg$sisdepen_baseunica_md5`.
- *Nota de qualidade:* a coluna `Ano` da Base Única mistura tipos em 2025 (texto `"2025"` e número `2025`); usamos `Referência` ("AAAA/S") para semestre/ano, que é consistente.
