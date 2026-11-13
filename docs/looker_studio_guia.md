# Guia da cópia de revisão no Data Studio

Este guia descreve como preparar uma versão candidata do Monitor Prisional RS a partir da [PoC gaúcha](https://datastudio.google.com/u/0/reporting/eb3f288c-0d0a-4c5d-8825-0fe8b7198cba). A navegação pública do [Monitor SP incorporado pelo NEV-USP](https://nev.prp.usp.br/projetos/monitor-do-sistema-prisional/) orienta a organização das páginas.

## Candidata de 12 de novembro de 2026 com revisão em 13 de novembro

A [cópia no Data Studio](https://datastudio.google.com/u/0/reporting/e2a2c22a-93ac-43c6-95f9-b824c81ef63f) usa a [planilha da execução candidata](https://docs.google.com/spreadsheets/d/1hvVCrj9yo3IVsQZiCdfHmQFwMLhts7ahGnPYfj6UlSs/edit) para as bases criminal, prisional, de mandados e do Panorama de Saúde. Os panoramas populacional, econômico e educacional usam a [planilha de panoramas históricos](https://docs.google.com/spreadsheets/d/1NigFj22WHgyS4Y9ER93su5YSQ7jJ8LXeWX0UWD60Uok/edit). A conexão de armas usa a fonte gaúcha já presente na PoC. A execução inicial e seu manifesto estão em `outputs/temp/candidata_2026-11-12`. As revisões de saúde e celas-seguro têm arquivos e conferências próprios, descritos abaixo.

- **Navegação e descrições.** A candidata mantém as mesmas 30 páginas, na mesma ordem do menu público da versão incorporada pelo NEV-USP. As descrições foram revistas a partir das correspondentes de SP, com adaptação de fontes, recortes, unidades e períodos ao RS.
- **Criminal.** Os totais estaduais de 2022 conferiram para furtos, homicídios dolosos e flagrantes. Os filtros municipais conferiram em Porto Alegre e Aceguá, e o cartão de armas manteve o agregado estadual nos dois recortes.
- **Mapas criminais.** As duas visualizações usam polígonos do Google com a localização configurada como **Subdivisão do país (2º nível)**, com município, UF e país na referência. O nome municipal vem da base do IBGE, mas a geometria é do Google e não foi homologada como malha oficial do IBGE. Branco pode indicar falta de dado ou de correspondência geográfica, não zero.
- **Prisional.** Em capacidade e lotação, os totais estaduais de população conferiram em 2017 (34.015) e 2025 (38.519). Em 2025, Porto Alegre exibiu 1.924 pessoas e 1.836 vagas. O filtro combinado com a Penitenciária Estadual de Porto Alegre retornou 722 pessoas e 610 vagas.
- **Panoramas.** População residente nos censos de 1970, 1980, 1991, 2000, 2010 e 2022, segundo a divisão municipal de cada edição. PIB municipal anual de 2010 a 2023 em mil reais correntes. Distorção idade-série do ensino fundamental do Inep em 2025, com médias municipais simples por região. A planilha conectada contém linhas municipais, e os CSVs de auditoria também incluem a referência estadual oficial. O script [preparar_panoramas_historicos_rs.py](../scripts/exploratory/preparar_panoramas_historicos_rs.py) gera os CSVs e o manifesto em `outputs/temp/candidata_2026-11-12/panoramas_historicos`. O filtro de Porto Alegre foi testado nos três gráficos.
- **Panorama de Saúde.** A aba `saude` foi atualizada para incluir os casos confirmados de tuberculose de 2025. Foram validados 7.846 casos em 497 municípios e 2.037 em Porto Alegre. Aids e óbitos vão até 2024, e notificações de hepatites virais, até 2023. Gráficos e controles usam a mesma aba da candidata. A validação da fonte e a exportação regenerada estão em `outputs/temp/candidata_2026-11-12/saude_tb_2025`.
- **Mapa dos estabelecimentos.** Os pontos do SISDEPEN 2024 são coloridos pelo vínculo administrativo das unidades conforme o diretório da Polícia Penal consultado em 13/11/2026. A [correspondência por ID e a fórmula](../outputs/auditoria/candidata_2026-11-13/README.md#mapa-prisional) incluem vínculo atual não confirmado e documentam o caso de endereços compartilhados. O mapa ainda aguarda fonte oficial dos limites territoriais.
- **Celas-seguro.** O gráfico de Estrutura foi conferido após a recuperação das 409 respostas de 2017 a 2020. A revisão corrigiu a rotina prisional e a coluna do quesito 2.13 na aba `prisional`. O CSV regenerado está em `outputs/temp/candidata_2026-11-13_cela_seguro/tabelas/`. [Registro do problema](problemas_dados.md#4-celas-seguro-sisdepen-213--lacuna-corrigida-em-20172020)
- **Flagrantes e mandados.** Na página [Dinâmica Criminal](https://datastudio.google.com/u/0/reporting/e2a2c22a-93ac-43c6-95f9-b824c81ef63f/page/p_x23hcbroid), o gráfico da grade original apresenta barras lado a lado por ano e responde aos filtros de município e região. Usa a aba `criminal` e inclui mandados nos municípios com doze meses informados no ano. A [página detalhada de mandados](https://datastudio.google.com/u/0/reporting/e2a2c22a-93ac-43c6-95f9-b824c81ef63f/page/p_qf1n2uf98d/edit) fica oculta na leitura. Ela mantém a tabela municipal, com 1.458 combinações de município e ano, e a comparação com os totais estaduais, que incluem registros fora do recorte municipal completo. Porto Alegre conferiu em 2022, com 1.547 mandados.
- **Conexão herdada removida.** Os 12 usos estavam em dois rascunhos ocultos de saúde (3 no primeiro e 7 na versão V02) e em dois gráficos de óbitos encobertos (um em Mortes de homens e outro em Mortes de mulheres). Os rascunhos e os gráficos encobertos foram retirados; o Panorama de Saúde e os gráficos válidos de óbitos continuam no menu público. Depois de confirmar zero usos, a conexão herdada foi desvinculada.

## 1. Preparar fontes exclusivas da candidata

Use as saídas auditadas da mesma execução do [pipeline RS](../scripts/rs/README.md). No Drive ou nas Planilhas Google, prepare arquivos ou abas próprios da candidata com data ou versão no nome:

| Aba no Google Sheets | CSV de origem | Unidade de cada linha |
| --- | --- | --- |
| `criminal` | `formato_sp/dinamica_criminal.csv` | Município × ano × indicador, 2022–2025 |
| `prisional` | `painel_prisional_estabelecimento.csv` | Estabelecimento de cela física × ano, 2017–2025 |
| `contexto` | `formato_sp/contexto_dados.csv` | Município. Tabela de contexto que acompanha a candidata. |
| `saude` | `formato_sp/dados_saude.csv` | Município × ano × indicador, com cortes próprios |
| `armas` | `armas_rs_estadual_ano.csv` | Estado × ano. O painel atual usa a conexão estadual preservada da PoC. |
| `mandados_estadual` | `formato_sp/mandados_estadual.csv` | Estado × ano. Referência reconciliada. |
| `prisoes_estadual` | Soma municipal dos flagrantes de `painel_criminal_municipio_ano.csv` e mandados de `formato_sp/mandados_estadual.csv` | Estado × ano. Gráfico da página oculta, com uma coluna por série. |
| `populacao_historica`, `pib_historico`, `tdi_2025` | CSVs com os mesmos nomes em `panoramas_historicos/`, filtrados para `Recorte = Município` | Município × ano. Estas abas ficam na planilha de panoramas. |

Os caminhos de `formato_sp/` são relativos ao diretório `tabelas/` da execução. Veja o [índice de tabelas](../outputs/tabelas/README.md) para conferir a unidade, a cobertura e a edição de cada CSV. A aba `prisoes_estadual` usa os cabeçalhos `Ano`, `Flagrantes da Polícia Civil` e `Mandados de prisão cumpridos`.

Importe em planilhas próprias da nova revisão. Preserve os cabeçalhos dos gráficos, os códigos IBGE e identificadores como chaves e as quantidades e taxas como números. Anos funcionam como dimensões. Mantenha valores ausentes em branco e preserve zeros observados. Depois da importação, confira se o número de linhas, os cabeçalhos e os tipos coincidem com o CSV.

## 2. Copiar o relatório e trocar as conexões

Em uma atualização, comece pela **candidata vigente** e use **Fazer uma cópia** para testar a nova edição. A PoC inicial serve como referência histórica. Na etapa de mapeamento de fontes, associe cada origem à correspondente fonte nova; caso a troca seja feita depois, confirme que está editando o relatório copiado. Na configuração de cada fonte e gráfico, verifique o arquivo, a aba e os campos. Duplicar um relatório pode manter conexões com as fontes originais, inclusive em gráficos combinados.

Se o painel usar mapa externo incorporado, confira também o destino do link: trocar a fonte do relatório não atualiza um mapa externo. Se não houver mapa validado para a candidata, use a tabela ou o gráfico municipal como alternativa temporária.

### Atualizar uma página ou fonte

1. Gere e audite a tabela da nova edição conforme o [guia de processamento](../scripts/rs/README.md). Registre a origem, a competência e o hash.
2. Identifique a aba conectada, os gráficos, os controles e as páginas ocultas que a utilizam. Confira o grão de cada fonte antes de reaproveitar um gráfico ou filtro.
3. Carregue o CSV validado na fonte de revisão e confira o intervalo selecionado no conector. Se houver colunas novas ou alteradas, atualize os campos no relatório de revisão e confira as agregações e filtros fixos. Mantenha a data da competência na descrição do gráfico.
4. Teste a versão de leitura da cópia. Verifique pelo menos um total, um filtro territorial, um valor ausente e um zero observado da fonte atualizada. Confira também um valor do período anterior.

Para saúde, preserve os cortes dos outros indicadores ao atualizar uma série. Para os panoramas, use apenas registros municipais nos gráficos que agregam por região. Para o painel prisional, confira as dependências de `Tem_prisão` e dos identificadores no contexto e na saúde antes de alterar a chave. O cartão de armas e as barras estaduais da página oculta têm recortes próprios.

## 3. Conferir páginas, textos e filtros

| Página | O que revisar |
| --- | --- |
| Apresentação | Identificação do RS, caráter de versão candidata, data da revisão, fontes e períodos. |
| Panoramas de população, economia e educação | Município e região intermediária. Indicar a referência do Censo, PIB e distorção idade-série do ensino fundamental, conforme a fonte da candidata. |
| Panorama de saúde | Casos e óbitos do TABNET; a disponibilidade varia por doença e ano. |
| Dinâmica criminal e mapas | Filtrar por município e região geográfica intermediária do IBGE. Exibir **Vítimas de homicídio doloso**, **Ocorrências de estupro**, roubo e furto “outros”, **Flagrantes da Polícia Civil** e **Mandados de prisão cumpridos**. |
| Dados prisionais | Filtrar por estabelecimento, município e ano. Conferir população, capacidade e ocupação. Em óbitos, explicitar a cobertura parcial de 2017–2022, especialmente 2018; não mostrar soma parcial como total anual estadual. |
| Nota metodológica | Incluir a revisão da SSP-RS em 2022, as janelas distintas, unidades de contagem, fonte do Sinesp VDE e as ressalvas de comparabilidade. |

Na página criminal, atribua as séries da secretaria à **SSP-RS**, e a de mandados ao **Sinesp VDE/MJSP**. Mostre as duas séries lado a lado no gráfico da grade original, com os controles de município e região. O indicador municipal de mandados fica vazio quando faltam meses. O cartão de armas mantém o total estadual. Na página oculta, o gráfico estadual de prisões também mantém os totais ao filtrar a tabela municipal.

Evite cruzar a base criminal com o prisional dentro do gráfico: há municípios com mais de um estabelecimento, o que pode multiplicar contagens. Se o cruzamento for indispensável, agregue antes a tabela prisional ao mesmo nível territorial e temporal e confira se a junção é única. Para taxas regionais ou estaduais, use soma dos eventos dividida pela população do mesmo universo, sem média simples de taxas municipais nem soma de denominadores repetidos por indicador. Quando faltarem municípios, não mostre a soma parcial como total da região nem divida os registros observados pela população de todo o recorte.

## 4. Validar a cópia antes de disponibilizar

1. Confira os totais estaduais por ano contra os CSVs auditados. Inclua 2022 para detectar conexão acidental com a série anterior à revisão e 2017 para verificar que a fonte prisional foi ampliada.
2. Teste os filtros em uma capital, um município pequeno e um município com várias unidades prisionais. Confira mapas, tabelas e gráficos para a mesma seleção. Verifique se endereços e localidades estão no RS.
3. Confira, em tela, as unidades, a distinção entre ausência e zero, e a atribuição da fonte de cada série. Teste se o cartão estadual de armas permanece estadual quando muda o município.
4. Registre o link da cópia, as abas, os arquivos e versões usados, os valores conferidos e as pendências. Confira as permissões do relatório e das fontes conforme o público da revisão. Use os agregados próprios da candidata nas conexões compartilhadas e mantenha os arquivos de trabalho internos no armazenamento da equipe.

Para atualizar a candidata, gere uma nova versão das entradas e valide-a antes de substituir as conexões. Preserve o manifesto e as auditorias junto às tabelas. A [matriz de decisões](decisoes_metodologicas.md) indica quais indicadores ainda exigem harmonização para a futura PoC RS–SP.
