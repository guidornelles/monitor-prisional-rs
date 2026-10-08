# Viabilidade de uma camada criminal municipal para Minas Gerais

Pesquisa e verificação em 4 de outubro de 2026. O objetivo é avaliar as fontes criminais públicas necessárias a um monitor de MG inspirado nos monitores SP e RS. Este documento registra fatos observados, inferências de viabilidade e questões metodológicas pendentes. Não implementa um monitor nem promove fontes ou indicadores canônicos.

**Conclusão:** existe uma base pública consistente para uma camada criminal municipal de MG: homicídios consumados, estupros, roubos, furtos e lesões corporais, com município e mês, desde 2012. A Sejusp disponibiliza tabelas agrupadas e bases completas por registro. Os dados estaduais são mais adequados que o SINESP para os recortes municipais patrimoniais e sexuais. A reprodução exata dos seis indicadores criminais de SP ainda não está demonstrada: as categorias precisam de harmonização e não foram localizadas séries públicas municipais adequadas de armas apreendidas e prisões efetuadas.

## Fontes públicas e nível de verificação

A principal porta de entrada é a [página de Dados Abertos da Sejusp](https://www.seguranca.mg.gov.br/index.php/transparencia/dados-abertos). Os links atuais conduzem a CSVs agrupados, painéis Power BI, um manual metodológico e uma pasta pública de bases completas. A conferência aprofundou o conteúdo dos arquivos, além da descrição do portal.

Foram baixados e preservados **19 arquivos integrais, 392,19 MiB**: dez CSVs agrupados, três planilhas de violência doméstica/feminicídio, cinco dicionários `datapackage.json` e um manual PDF. Os dez CSVs somam **3.725.904 linhas**. Além disso, foram inventariados 15 CSVs completos na pasta pública oficial e lidos os primeiros 64 KiB de cinco deles. Essas leituras parciais comprovam cabeçalhos e alguns registros, mas não constituem validação integral das bases completas.

| Fonte ou conjunto | Recorte comprovado nos arquivos | Período disponível verificado | Formato e acesso | Unidade |
| --- | --- | --- | --- | --- |
| Crimes violentos, com naturezas separadas | 853 municípios × mês × natureza; código municipal; RISP; RMBH | 2012–2026; atualização até agosto/2026 | Três CSVs agrupados integrais; bases completas públicas | Registros |
| Vítimas de homicídio consumado | 853 municípios × mês; RISP e RMBH | 2012–agosto/2026 | CSV agrupado integral; cabeçalho da base completa verificado | Vítimas |
| Furto consumado | 853 municípios × mês | 2012–agosto/2026 | CSV agrupado integral; bases completas anunciadas na pasta | Registros |
| Lesão corporal consumada | 853 municípios × mês | 2012–agosto/2026 | CSV agrupado integral | Registros |
| Roubos e furtos por alvo | 853 municípios × mês × sete alvos | Agrupados: 2021–agosto/2026; completos: nomes dos arquivos indicam 2015–agosto/2026 | Dois CSVs agrupados integrais; cabeçalhos completos amostrados | Registros |
| Veículos furtados e roubados | 853 municípios × mês | Agrupados: 2012–agosto/2026; completos: nomes indicam 2015–agosto/2026 | Dois CSVs agrupados integrais; amostra completa de roubo | Veículos |
| Violência doméstica e familiar contra a mulher | Município × mês; aba de dados com data do fato, natureza e tentado/consumado | 2019–2023 e 2024–agosto/2026 | Duas planilhas XLSX baixadas; abas e cabeçalhos inspecionados | Vítimas/contagem de envolvidos segundo a planilha |
| Feminicídio, tentado e consumado | Município e data do fato; mês, ano, RISP, RMBH e quantidade de vítimas | 2019–agosto/2026 | XLSX baixado, aba de dados com 2.740 linhas além do cabeçalho | Vítimas |
| Vítimas de acidentes de trânsito | Dicionário prevê município, mês, coordenadas e características dos envolvidos | Recursos anuais catalogados: 2011–2026 | Metadados e dicionário verificados; conteúdo integral não perfilado | Envolvidos/vítimas conforme filtros |
| MVI, elucidação, vitimização e letalidade de profissionais | Relatórios e anexos específicos | Publicações listadas para 2021–2023 ou 2021–2022, conforme tema | PDFs e anexos; não tratados como série mensal pronta | Variável por publicação |

As [estatísticas de violência contra a mulher](https://www.seguranca.mg.gov.br/index.php/component/sppagebuilder/page/261) constituem uma fonte adicional, sem substituir o total de estupros da população: são um recorte temático e têm metodologia da PCMG. O [catálogo de crimes violentos](https://www.dados.mg.gov.br/dataset/crimes-violentos) e o [catálogo de furtos](https://www.dados.mg.gov.br/dataset/sejusp_furto_consumado) permitem descobrir recursos em formato legível por máquina.

## Desagregação além do município

Os CSVs agrupados têm nome e código do município, mês e ano **do fato**, RISP e indicador de RMBH. Nos arquivos inspecionados o código municipal possui seis dígitos: a integração com códigos IBGE de sete dígitos exige tabela oficial de correspondência, sem acrescentar um dígito por suposição. RISP é uma regionalização da segurança pública de MG; não equivale automaticamente às macrorregiões de SP ou às regiões intermediárias do IBGE.

Nas cinco amostras das [bases completas públicas](https://drive.google.com/drive/folders/1CjziaHx_ehpY6XozeV5FIR-zoCfCjh8k), confirmou-se a presença de identificador do REDS, quantidade, natureza principal, data e horário, dia da semana, faixas horárias, causa presumida, meio utilizado, tipo de local, bairro e município. As bases de alvos acrescentam a classificação do alvo; a de veículos acrescenta tipo e situação do veículo. Esses campos permitem, em princípio, análises abaixo do município e por características da ocorrência. Sua completude e consistência não foram medidas integralmente.

A amostra de vítimas de homicídio acrescenta idade aparente, sexo, cútis, escolaridade, relação vítima/autor e território do envolvido. É necessário distinguir o município **do fato** do município **do envolvido**. A presença de campos demográficos também não comprova preenchimento adequado. Nessa amostra o cabeçalho é compatível com `cp1252`; os outros quatro cabeçalhos foram lidos como UTF-8. O coletor deve detectar e registrar codificação por recurso.

Há uma inconsistência territorial já visível na amostra completa de crimes violentos: um registro de Belo Horizonte apresenta `Rmbh = NÃO`. Isso pede validação do campo contra uma referência territorial antes de utilizá-lo. Não se estima a frequência desse problema a partir da amostra.

## Correspondência com os indicadores do monitor SP

O script SP foi inspecionado na branch `R`, commit `45c7144`, em modo de leitura. Ele exporta homicídio doloso, estupros total, roubo outros, furto outros, armas de fogo apreendidas e prisões efetuadas. A avaliação abaixo se refere à correspondência substantiva, além da disponibilidade técnica.

| Indicador pretendido | Evidência em MG | Classificação de viabilidade | Condição para uso |
| --- | --- | --- | --- |
| Homicídio doloso | Homicídio consumado em registros e em vítimas; SINESP também oferece homicídio doloso municipal | Viável com limpeza/padronização, com equivalência metodológica pendente | Selecionar a unidade; confirmar tratamento de dolo/culpa e feminicídio; reconciliar definições e versões |
| Estupros total | Naturezas consumadas e tentadas, com e sem vulnerabilidade, separadas por município/mês | Viável com limpeza/padronização | Definir soma canônica, tentativas e natureza principal; comparar registros com registros, sem trocar por vítimas |
| Roubo outros de SP | Roubo consumado/tentado e estratificação por alvo | Metodologicamente problemático para equivalência automática | Construir um de-para substantivo; não equiparar o alvo Outros de MG ao indicador Outros de SP |
| Furto outros de SP | Furto consumado e estratificação por alvo | Metodologicamente problemático para equivalência automática | Ratificar exclusões e unidade; os dados municipais nativos são utilizáveis, mas a equivalência não está provada |
| Armas de fogo apreendidas | SINESP estadual; bases públicas municipais apropriadas não localizadas | Inviável com os dados municipais atuais; viável apenas com nova coleta para preencher essa lacuna | Obter dados por município/mês, instituição, espécie e critério de contagem |
| Prisões efetuadas | SINESP municipal de mandados cumpridos; nenhuma série equivalente de todas as prisões localizada | Inviável com os dados atuais para equivalência integral; viável apenas com nova coleta | Separar flagrantes, mandados, pessoas, atos de prisão, adultos/adolescentes e instituição |
| Mandados cumpridos, como indicador adicional | SINESP municipal, com abrangências estadual e PF separadas | Viável com limpeza/padronização | Manter rótulo próprio e abrangência; não renomear como prisões efetuadas |
| Roubos e furtos consumados nativos de MG | Tabelas municipais mensais completas, com unidade de registros | Imediatamente viável para descrição de MG | Publicar com o conceito de MG; harmonização entre estados permanece uma etapa própria |

**Homicídios:** o [manual de crimes violentos](https://www.seguranca.mg.gov.br/images/0_planilhas-e-pdfs/manual%20crimes%20OBS/Metolodogia%20-%20Crimes%20Violentos%20VF%20-%2015.12.pdf) informa que o REDS não distingue dolo e culpa no registro inicial. Portanto, o rótulo Homicídio Consumado não basta para demonstrar equivalência com Homicídio Doloso. Em 2025, os arquivos agrupados têm 2.213 registros de homicídio e 2.407 vítimas; a rubrica separada de feminicídio consumado tem 104 registros. Esses valores mostram a necessidade de ratificar unidade e composição, sem aplicar a MG a soma experimental usada na auditoria de SP.

**Estupros:** em 2025 há 1.386 registros de estupro consumado e 4.105 de estupro de vulnerável consumado: soma exploratória de 5.491 registros. As duas rubricas tentadas somam mais 328. A escolha de incluir tentativas precisa ser explícita e consistente com o indicador de referência. Esses números não medem vítimas nem prevalência real da violência sexual.

**Patrimoniais:** os sete alvos agrupados são cargas, estabelecimento comercial, instituição financeira, Outros, residência, transeunte e transporte coletivo. A categoria Outros de MG é residual dentro dessa divisão; não corresponde, só pelo nome, a Roubo/Furto Outros de SP. A investigação deve esclarecer onde ficam veículos nessa classificação e como se relacionam com os totais de registros. As tabelas de veículos medem objetos: em 2025, 24.457 veículos furtados e 3.597 roubados. Subtrair esses valores dos totais de registros mistura unidades. Uma reconstrução pode exigir vincular os arquivos completos pelo identificador e contar os registros após as exclusões; as cinco amostras não ratificam essa reconstrução.

**Armas:** o campo Meio Utilizado = ARMAS DE FOGO em ocorrências não conta armas apreendidas. Também não informa o conjunto dos crimes dos artigos 14–18 do Estatuto do Desarmamento. A auditoria de equivalência deve distinguir esses três conceitos.

## Qualidade, cobertura e mudanças metodológicas

Nos dez CSVs agrupados, foram confirmados 853 municípios, ausência de valores negativos e nulos na medida, e ausência de chaves repetidas na granularidade natureza × alvo, quando aplicável, × código municipal × mês × ano. Os 19 hashes dos arquivos integrais foram conferidos. Os controles somam **59 verificações aprovadas**, descritas em `controles_integridade.csv`; isso não substitui validação das definições criminais.

A soma dos sete alvos reproduz os furtos totais em todas as **61.416 combinações município × mês** de 2021–2026 da grade publicada. Para roubos, **61.415 de 61.416** combinações coincidem; há diferença de um registro em Belo Horizonte, dezembro/2022: alvos = 630 e total = 629. O resíduo foi preservado para análise, sem correção dos dados originais. Essa comparação inclui meses da grade ainda não observados; não prova cobertura substantiva desses meses.

**2026 é parcial:** os arquivos estão atualizados até agosto. Os CSVs mantêm a grade de setembro a dezembro preenchida com zeros; em crimes violentos, são 12.795 linhas por mês futuro, todas zeradas. Esses meses precisam receber status não disponível e ser excluídos do cálculo do ano observado. Nas planilhas de violência doméstica de 2026, os meses posteriores a agosto aparecem vazios, exigindo regra equivalente.

**Revisão histórica:** o manual informa que desde a publicação de agosto/2025 a atualização dos crimes violentos passou a substituir a base histórica integral, incorporando registros tardios. A descrição textual do CKAN ainda menciona a pesquisa dos três meses anteriores. Há, portanto, documentação em diferentes versões; para desenho do coletor, priorizar o manual atualizado e confirmar a regra institucional vigente.

**Mudança de taxonomia:** os arquivos têm 13 naturezas em 2012–2018, 14 em 2019–2024 e 15 em 2025–2026. A rubrica Feminicídio Tentado aparece inteiramente zerada em 2019–2024 na tabela de crimes violentos. As planilhas próprias de feminicídio têm dados tentados/consumados nesse período. Não tratar a grade antiga zerada como prova de ausência de feminicídios; também não somar os dois produtos automaticamente. A composição histórica de homicídios e feminicídios exige um de-para versionado.

## Coleta automática

**Fato observado:** os CSVs agrupados e XLSXs foram obtidos por HTTP público, sem autenticação, com URL, data da coleta, tamanho e SHA-256 registrados. Os arquivos completos amostrados responderam a solicitações HTTP Range com status 206. Há caminho concreto de aquisição automática sem extração dos gráficos Power BI.

A API CKAN `package_search` retornou cinco conjuntos da organização Sejusp, com 32 recursos e os respectivos links. Porém, nos dois recursos testados — crimes violentos 2026 e furtos — `datastore_search` retornou sucesso **com zero registros**, apesar de `datastore_active = true`. Os downloads CSV correspondentes tinham conteúdo. A API de catálogo é útil para descobrir URLs; o DataStore não foi confirmado como canal de leitura de dados e não deve ser a única rota de coleta.

**Inferência técnica:** a ingestão por download é viável com limpeza/padronização. Os nomes dos arquivos e suas pastas mudam por mês; é melhor descobrir os links atuais na página oficial ou no catálogo, validar o esquema e preservar cada snapshot. O coletor deve conferir datas, janela efetivamente observada, codificação, naturezas novas, chaves municipais, unidade, revisões e somas de controle. O relatório não testa uma rotina agendada de atualização nem sua estabilidade ao longo de vários meses.

## Fontes complementares e limites da busca

O [Observatório de Segurança Pública](https://www.seguranca.mg.gov.br/index.php/component/sppagebuilder/page/265) lista relatórios de MVI/elucidação e vitimização/letalidade de profissionais. A [PCMG](https://www.policiacivil.mg.gov.br/site-pc/pagina/transparencia) encaminha o usuário às estatísticas da Sejusp e a diagnósticos próprios. Pesquisas dirigidas sobre armas, tráfico e prisões retornaram sobretudo relatórios, notícias de operações e fontes estaduais agregadas; não foi identificada uma série municipal completa apropriada aos dois indicadores de produtividade do monitor. Isso é uma lacuna da pesquisa, não demonstração de que tais informações não existam no sistema administrativo.

As [perguntas frequentes da Sejusp](https://www.seguranca.mg.gov.br/images/0_planilhas-e-pdfs/transparencia/documentos/06_fev_2024_perguntas_frequentes_sejusp_v1.2.pdf) indicam a PCMG como gestora de latrocínio e lesão corporal seguida de morte e orientam o e-SIC para dados não disponíveis. O SINESP pode complementar essas rubricas em município/mês. Para tráfico e armas, a fonte nacional permanece estadual no recorte MG examinado.

Como complemento prisional, a [página da população prisional de MG](https://www.seguranca.mg.gov.br/index.php/component/sppagebuilder/page/266) é indexada com bancos por sexo/escolaridade e sexo/faixa etária de janeiro/2017 a junho/2024. O acesso direto retornou HTTP 403 nesta execução; os arquivos não foram examinados. Não se afirma atualização atual, granularidade por estabelecimento ou adequação integral a partir desse anúncio. SISDEPEN e fontes nacionais de contexto permitem, em princípio, ampliar o desenho SP/RS, mas sua cobertura específica de MG e vinculação territorial precisam de auditoria própria. A viabilidade criminal não resolve sozinha a viabilidade de todos os módulos prisionais.

## Proposta de encaminhamento

**Recomendação:** avançar com a avaliação de MG. Há fontes públicas suficientes para uma camada municipal de criminalidade ampla, com atualização mensal e possibilidade de coleta uniforme. Começar por anos completos recentes, por exemplo 2023–2025, preservando a série desde 2012 para análise das mudanças de metodologia. Utilizar os CSVs oficiais agrupados como base de totais e os arquivos completos para investigar classificações e recortes adicionais.

Antes de integrar um produto comparável entre SP, RS e MG, resolver quatro decisões: (1) homicídios em vítimas ou registros, com tratamento de feminicídio e dolo/culpa; (2) composição de estupros e tentativas; (3) reconstrução das categorias patrimoniais Outros; (4) aquisição de produtividade policial municipal. Um pedido dirigido à Sejusp/PCMG/PMMG pode solicitar séries município × mês desde 2012 de armas e prisões, com instituição, definição, unidade e histórico de revisão, além do de-para das categorias. Nenhum pedido foi enviado nesta tarefa.

A fonte estadual MG deve ser prioritária para o conteúdo municipal. O SINESP é um complemento e referência de reconciliação, especialmente para categorias não cobertas pelas tabelas agrupadas. Uma réplica completa de SP não deve ser prometida enquanto as lacunas de produtividade e equivalência permanecerem abertas.

## Evidências e reprodução

- Originais e manifesto: `data/raw/sejusp_mg/2026-10-04/`; os arquivos grandes estão ignorados pelo Git.
- Perfil, cobertura por indicador/ano e arquivo/mês, catálogo de recursos, amostras de cabeçalhos, testes CKAN, resíduos e controles: `outputs/tabelas/viabilidade_mg_2026-10-04/`.
- Aquisição exploratória: `scripts/exploratory/inventario_fontes_mg.py`.
- Perfil e reconciliação: `scripts/exploratory/perfil_fontes_mg.py`.
- Inspeção limitada das bases completas: `scripts/exploratory/inspecionar_bases_completas_mg.py`.
- Referência do escopo SP: `docs/inventario_repositorio_sp.md` e inspeção do script `validation/criminal_data_proccessing.R` na branch `R` do repositório SP.

Os scripts são exploratórios e vinculados ao snapshot, separados de `scripts/rs/run_all.R`. A aquisição recusa substituir arquivos integrais já existentes por bytes diferentes. Não foram modificados arquivos de SP, produtos canônicos, fontes brutas por edição manual, commits ou publicações remotas.
