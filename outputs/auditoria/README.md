# Auditorias do Monitor Prisional RS

Use as auditorias da mesma execução que produziu as tabelas. Em uma execução isolada, a pasta é `MONITOR_RS_RUN_DIR/auditoria/`. Os arquivos deste diretório incluem registros de execuções anteriores. Compare os resultados com a edição anterior quando trocar um insumo ou um recorte.

| Verificação | Arquivos | Como ler |
| --- | --- | --- |
| Criminal | `criminal_reconciliacao.csv`, `criminal_reconciliacao_municipal.csv` | Confronte microdados e indicadores oficiais de mesma unidade e rubrica. Confira 1.988 chaves município × ano. Separe diferenças de revisão, cobertura e composição. |
| Flagrantes da PC | `prisoes_cobertura.csv`, `match_municipios.csv` | Compare os oito arquivos semestrais e a correspondência de municípios. Os flagrantes contam registros do fato na SSP-RS. |
| Mandados cumpridos | `mandados_sinesp_proveniencia.csv`, `mandados_sinesp_cobertura_anual.csv`, `mandados_sinesp_reconciliacao_mensal.csv`, `mandados_sinesp_sem_localizacao.csv` | Confira o snapshot, os 48 totais mensais, a localização dos registros e os 12 meses por total municipal. O total estadual tem reconciliação própria. |
| Prisional | `prisional_cobertura.csv`, `prisional_mortalidade_cobertura.csv`, `validacao_prisional.md` | Confira 927 estabelecimentos-ano, a janela de 2017–2025, o semestre dos estoques, as duas competências dos óbitos e os quesitos com lacunas. |
| Contexto e saúde | `contexto_cobertura.csv`, `saude_cobertura.csv` | Confira 497 municípios no cadastro de contexto e os cortes de saúde por indicador. A tuberculose soma 7.846 casos em 2025, com os outros indicadores em branco nesse ano. |
| Junções e saídas | `planilha_final_cobertura.csv`, `qualidade_paineis.csv`, `RELATORIO_AUDITORIA.md` | Confira cardinalidade, duplicatas, valores faltantes e os alertas que requerem revisão. |

As evidências adicionais da candidata de novembro incluem o manifesto de exportações em `outputs/temp/candidata_2026-11-12/auditoria/`, a revisão de saúde em `outputs/temp/candidata_2026-11-12/saude_tb_2025/` e a revisão de celas-seguro em `outputs/temp/candidata_2026-11-13_cela_seguro/`. Para os panoramas, `manifesto_panoramas.json` reúne totais oficiais, cobertura por ano e hashes dos insumos. Para a candidata revisada, guarde os hashes dos arquivos efetivamente conectados, pois o manifesto inicial antecede correções pontuais.

Na conferência no Data Studio, registre versão e aba, seleção testada, valor esperado, valor apresentado e pendências. O [guia do painel](../../docs/looker_studio_guia.md) traz referências para os testes de filtros, mapas e gráficos.
