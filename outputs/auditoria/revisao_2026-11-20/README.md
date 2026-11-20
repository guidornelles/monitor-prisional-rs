# Revisão da pipeline e da candidata em 20/11/2026

A execução integral da pipeline RS terminou sem falhas de validação. As entradas mantêm o Censo 2022, o PIB municipal 2023 em mil reais correntes e o Inep 2025, conforme `cfg$contexto`. O recorte prisional continua sendo cela física, com estoque do primeiro semestre e quatro especialidades no total médico.

## Evidências de processamento

- [Validação prisional](validacao_prisional.md): comparação por ID e ciclo, 86 campos do catálogo em 927 linhas, 15 séries anuais de óbitos, cobertura e somas anuais. Os alertas da fonte permanecem identificados: oito diferenças entre óbitos totais e a soma por sexo e uma unidade-ano com população positiva e capacidade zero.
- [Validação de contexto](validacao_contexto.md): referências, unidades, hashes, municípios, exportação e taxas por 100 mil habitantes; zero falhas.
- [Regressões](regressao_pipeline.csv): oito verificações aprovadas, incluindo igualdade dos 497 valores de distorção com a extração independente dos panoramas e detecção de alterações artificiais em taxa, escala do PIB e chaves.

As tabelas prisionais permaneceram iguais à execução de 15/11. A tabela criminal interna mudou apenas na variável de contexto de distorção idade-série. Os numeradores, a população e as taxas criminais foram preservados.

## Atualização e conferência da conexão

A [versão candidata](https://datastudio.google.com/u/0/reporting/e2a2c22a-93ac-43c6-95f9-b824c81ef63f) passou a se identificar como **Monitor do Sistema Prisional RS — versão candidata 2026-11-20**. A [planilha conectada](https://docs.google.com/spreadsheets/d/1hvVCrj9yo3IVsQZiCdfHmQFwMLhts7ahGnPYfj6UlSs/edit) manteve seus identificadores e abas.

Na aba `contexto`, foram atualizados os valores de `G2:G498` para o Inep 2025, com 479 valores diferentes da referência anterior, e `F1` para `PIB (mil R$ correntes)`. A leitura posterior dos 497 municípios e oito campos coincidiu com o CSV validado. O PIB não foi multiplicado por mil. A largura de F foi ajustada para permitir a leitura do cabeçalho.

No Data Studio, o esquema da fonte de contexto foi atualizado e os dados foram recarregados. A conferência mostrou o novo campo de PIB e zero gráficos diretamente associados a essa fonte. Os panoramas históricos mantiveram suas fontes próprias e os anos de exibição já aprovados.

As abas criminal e prisional não precisaram de regravação, pois as contagens conferidas já coincidiam com a execução corrigida. Foram verificadas:

- 11.928 chaves únicas de município, ano e indicador criminal, todos os numeradores e denominadores individuais, suas taxas e os 24 totais de ano e indicador;
- 927 chaves prisionais, comparando população, capacidade, médicos e os cinco totais de óbitos por causa, linha a linha com o CSV da execução;
- 2025: 31.679 registros de flagrante e 10.754 mandados municipalizados; 38.519 pessoas em cela física, 25.815 vagas e 116 médicos;
- renderização da página Pessoal com as nove edições anuais e a métrica médica preservada.

A verificação preservou as adaptações do mapa penitenciário e os demais campos da planilha. O repositório SP não foi alterado. A [consulta complementar](../../../docs/email_complementar_sp_recorte_medicos.md) permanece um rascunho para revisão e envio pelo pesquisador.
