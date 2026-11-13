# Monitor Prisional RS

O Monitor Prisional RS reúne dados públicos sobre estabelecimentos prisionais, pessoas privadas de liberdade e o contexto dos municípios gaúchos. A **versão candidata**, revisada em 13 de novembro de 2026, adapta a estrutura do [Monitor do Sistema Prisional de São Paulo, do NEV-USP](https://nev.prp.usp.br/projetos/monitor-do-sistema-prisional/). A autoria da adaptação é de Guilherme Souza, doutorando em Políticas Públicas na UFRGS.

**[Abrir a versão candidata no Data Studio](https://datastudio.google.com/reporting/e2a2c22a-93ac-43c6-95f9-b824c81ef63f)** · [Entender as fontes e as escolhas](docs/decisoes_metodologicas.md) · [Consultar a auditoria comparativa RS–SP](docs/auditoria_metodologica_sp_rs.md)

## O que está disponível

| Área | Cobertura da candidata | O que se pode consultar |
| --- | --- | --- |
| Sistema prisional | 2017–2025 | Estabelecimentos com celas físicas, ocupação, perfil, condições de custódia, saúde e fiscalização. A cobertura varia por quesito e ano. |
| Dinâmica criminal | 2022–2025 | Vítimas de homicídio doloso, ocorrências consumadas de estupro, roubo e furto e duas séries de atividade policial por município e região intermediária. As apreensões de armas têm total estadual. |
| População, economia e educação | Censos de 1970 a 2022, PIB de 2010 a 2023 e distorção idade-série de 2025 | População residente, PIB em valores correntes e atraso escolar no ensino fundamental. |
| Saúde dos municípios | Desde 2018, com último ano entre 2023 e 2025 | Casos e óbitos de tuberculose, hepatites virais e aids, com cortes indicados no painel. |

As fontes são [SSP-RS](https://www.ssp.rs.gov.br/estatisticas), [Sinesp VDE](https://www.gov.br/mj/pt-br/assuntos/sua-seguranca/seguranca-publica/estatistica), [SISDEPEN](https://www.gov.br/senappen/pt-br/servicos/sisdepen/bases-de-dados), [IBGE/SIDRA](https://sidra.ibge.gov.br/), [Inep](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/indicadores-educacionais/taxas-de-distorcao-idade-serie) e [DATASUS](https://datasus.saude.gov.br/informacoes-de-saude-tabnet/).

As barras de flagrantes e mandados têm unidades diferentes. Em 2018, idade, raça/cor e escolaridade no SISDEPEN cobrem cerca de 17% da população prisional gaúcha. As faixas de duração da pena seguem em revisão porque os totais declarados em 2024 e 2025 abrangem um universo maior que o previsto no quesito. A comparação entre RS e SP é a próxima etapa e depende de regras comuns de contagem, cobertura e período. [Problemas de dados e evidências](docs/problemas_dados.md)

## Como os dados chegam ao painel

1. **Fixar as fontes.** Registrar arquivo, data de extração, período coberto e código de verificação de cada versão. Conservar os arquivos oficiais.
2. **Gerar as tabelas.** Usar os scripts de R para as bases criminal, prisional, de contexto e de saúde. Uma rotina auxiliar em Python prepara os panoramas históricos.
3. **Conferir os resultados.** Validar chaves, cobertura, valores ausentes, totais e diferenças em relação à versão anterior. Conferir os indicadores de cada fonte com o mesmo recorte.
4. **Atualizar a candidata.** Carregar as tabelas nas fontes de revisão do Data Studio, testar filtros e gráficos, revisar os textos e registrar quais arquivos alimentaram a versão.

O [guia do processamento](scripts/rs/README.md) traz os comandos e os insumos. O [guia de atualização do painel](docs/looker_studio_guia.md) mostra as abas, a conexão das fontes e as conferências antes de disponibilizar a nova versão. O [índice de tabelas](outputs/tabelas/README.md) explica o que cada arquivo mede. Os [controles da execução de referência](outputs/auditoria/candidata_2026-11-13/README.md) registram os resultados e os arquivos gerados.

## Como citar

> SOUZA, Guilherme. *Monitor Prisional RS*. Versão candidata, revisão de 13 de novembro de 2026. Adaptação do Monitor do Sistema Prisional do NEV-USP.
