# Tabelas do Monitor Prisional RS

Os arquivos deste diretório incluem saídas de execuções anteriores. Para atualizar o painel, use as tabelas da execução isolada em `MONITOR_RS_RUN_DIR/tabelas/` e confira a edição em seu manifesto. As abas e conexões de cada componente estão no [guia do Data Studio](../../docs/looker_studio_guia.md).

| Tabela da execução | Unidade de cada linha | Cobertura da candidata |
| --- | --- | --- |
| `painel_criminal_municipio_ano.csv` | Município × ano | 497 municípios × 4 anos, 2022–2025. Registros, população do Censo 2022, taxas por 100 mil e cobertura mensal de mandados. |
| `painel_prisional_estabelecimento.csv` | Estabelecimento de cela física × ano | 927 registros, 2017–2025. Estoques do primeiro semestre e fluxos de óbitos dos dois semestres, conforme cobertura. |
| `painel_contexto_municipio.csv` | Município | 497 municípios. Chaves IBGE, região intermediária, população de referência e atributos da tabela de contexto. |
| `painel_saude_municipio_ano.csv` | Município × ano | Dados de 2018 em diante, com cobertura própria por indicador e taxas calculadas para conferência. |
| `formato_sp/dinamica_criminal.csv` | Município × ano × indicador | 11.928 linhas. Nomes de campos usados no Data Studio, quantidades e taxas. |
| `formato_sp/dados_saude.csv` | Município × ano × indicador | 23.645 linhas após incluir tuberculose de 2025. Quantidades e indicação de presença de estabelecimento prisional. |
| `formato_sp/contexto_dados.csv` | Município | Tabela de contexto da PoC, com nomes de campos compatíveis. As fontes dos três panoramas atuais são próprias. |
| `formato_sp/mandados_estadual.csv` | Estado × ano | Totais estaduais de 2022–2025 reconciliados mensalmente. |
| `armas_rs_estadual_ano.csv` | Estado × ano | Arquivo de referência da PoC, 2022–2025, com PC, BM e total. A conexão é mantida separada da série municipal. |

O script de [panoramas históricos](../../scripts/exploratory/preparar_panoramas_historicos_rs.py) prepara `populacao_historica.csv`, `pib_historico.csv` e `tdi_2025.csv` fora de `tabelas/`, no diretório escolhido com `--saida`. Para as abas municipais do painel, filtre `Recorte = Município`. O recorte `Estado` guarda o total oficial de referência. O PIB está em mil reais correntes e a distorção idade-série está em pontos percentuais.

Em toda exportação, célula vazia representa valor indisponível e zero é um valor observado. Preserve os nomes das colunas e os tipos das chaves ao importar. As [auditorias](../auditoria/README.md) registram os totais esperados, as lacunas e as verificações por camada.
