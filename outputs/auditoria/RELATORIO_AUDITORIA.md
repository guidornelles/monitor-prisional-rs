# Relatório de Auditoria — PoC Monitor Prisional RS
_Gerado por `06_auditoria.R` em 2026-06-12 14:57:14.631754._

Consolida as auditorias de cada etapa do pipeline (02–05) e diagnostica a
qualidade dos painéis finais. As decisões metodológicas que explicam cada
recorte estão em `docs/decisoes_metodologicas.md`.

## Painéis finais (inventário)

| painel | existe | linhas | colunas |
| --- | --- | --- | --- |
| painel_criminal_municipio_ano.csv | TRUE | 1.988 | 19 |
| painel_prisional_estabelecimento.csv | TRUE | 414 | 397 |
| painel_contexto_municipio.csv | TRUE | 497 | 6 |
| painel_saude_municipio_ano.csv | TRUE | 3.938 | 18 |

## Reconciliação criminal (microdado × agregado oficial)

Δ% entre o reconstruído do microdado e a coluna oficial. ⚠ 2022 furtos com anomalia conhecida (ver docs).

Fonte: `outputs/auditoria/criminal_reconciliacao.csv`

| ano | hd_oco_micro | hd_oco_ofi | furtos_total_micro | furtos_ofi | roubos_total_micro | roubos_ofi | roubo_outros_estrito | furto_outros_estrito | d_hd_% | d_furtos_% | d_roubos_% | estrito_vs_total_roubo_% |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2.022 | 1.628 | 1.632 | 96.768 | 128.047 | 35.355 | 36.950 | 32.804 | 90.235 | -0,25 | -24,43 | -4,32 | -7,2 |
| 2.023 | 1.567 | 1.570 | 125.466 | 125.529 | 32.412 | 32.506 | 29.947 | 117.357 | -0,19 | -0,05 | -0,29 | -7,6 |
| 2.024 | 1.337 | 1.338 | 105.380 | 105.373 | 20.697 | 20.771 | 19.134 | 98.451 | -0,07 | 0,01 | -0,36 | -7,6 |
| 2.025 | 968 | 970 | 106.431 | 108.562 | 18.431 | 18.673 | 17.133 | 100.162 | -0,21 | -1,96 | -1,3 | -7 |

## Prisões em flagrante (PC) — cobertura municipal

Fonte: `outputs/auditoria/prisoes_cobertura.csv`

| ano | municipios | total_prisoes |
| --- | --- | --- |
| 2.022 | 438 | 28.373 |
| 2.023 | 452 | 30.432 |
| 2.024 | 477 | 28.901 |
| 2.025 | 471 | 31.680 |

## Prisional (SISDEPEN Base Única) — cobertura cela física

Fonte: `outputs/auditoria/prisional_cobertura.csv`

| ano | estab_recorte | recorte | fonte | cols_match | cols_schema |
| --- | --- | --- | --- | --- | --- |
| 2.022 | 104 | cela_fisica | base_unica | 313 | 377 |
| 2.023 | 103 | cela_fisica | base_unica | 313 | 377 |
| 2.024 | 104 | cela_fisica | base_unica | 313 | 377 |
| 2.025 | 103 | cela_fisica | base_unica | 313 | 377 |

## Contexto — cobertura município/região/denominadores

Fonte: `outputs/auditoria/contexto_cobertura.csv`

| metrica | valor |
| --- | --- |
| municipios | 497 |
| regioes_intermediarias | 8 |
| sem_populacao | 0 |
| sem_pib | 0 |
| sem_distorcao | 0 |

## Saúde (DATASUS/TABNET) — cobertura por indicador e ano

NA = provisório/não consolidado (hepatite só até 2023; 2025 ainda provisório).

Fonte: `outputs/auditoria/saude_cobertura.csv`

| ano | municipios | casos_hepatite | casos_hiv | casos_tuberculose | obitos_hepatite | obitos_tuberculose | obitos_hiv |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2.018 | 494 | 6.281 | 3.122 | 6.479 | 343 | 301 | 1.165 |
| 2.019 | 494 | 6.005 | 3.151 | 6.989 | 275 | 280 | 1.135 |
| 2.020 | 494 | 3.285 | 2.450 | 6.038 | 231 | 283 | 1.108 |
| 2.021 | 494 | 3.480 | 2.703 | 6.291 | 192 | 346 | 1.208 |
| 2.022 | 494 | 3.872 | 2.714 | 6.935 | 182 | 337 | 1.151 |
| 2.023 | 494 | 4.250 | 2.726 | 7.382 | 179 | 354 | 972 |
| 2.024 | 494 | NA | 2.645 | 7.471 | 172 | 388 | 1.033 |
| 2.025 | 480 | NA | NA | NA | NA | NA | NA |

## Planilha final — cobertura e pareamento

`nomes_sem_match` = nomes da SSP sem correspondência no IBGE (esperado: municípios de outras UFs).

Fonte: `outputs/auditoria/planilha_final_cobertura.csv`

| tabela | linhas | municipios | nomes_sem_match |
| --- | --- | --- | --- |
| painel_criminal_municipio_ano | 1.988 | 497 | 12 |
| painel_prisional_estabelecimento | 414 | NA | NA |
| painel_contexto_municipio | 497 | 497 | NA |

## Municípios sem pareamento (SSP → IBGE)

Fonte: `outputs/auditoria/match_municipios.csv` — conferir que são todos de outras UFs.

| fonte | nom_mun | chave |
| --- | --- | --- |
| prisoes | Ararangua | ARARANGUA |
| prisoes | Bom Sucesso | BOM SUCESSO |
| prisoes | Chapeco | CHAPECO |
| prisoes | Faria Lemos | FARIA LEMOS |
| prisoes | Florianopolis | FLORIANOPOLIS |
| prisoes | Ipiranga | IPIRANGA |
| prisoes | Itapiranga | ITAPIRANGA |
| prisoes | Mage | MAGE |
| prisoes | Mondai | MONDAI |
| prisoes | Passo de Torres | PASSO DE TORRES |
| prisoes | Santa Cecilia | SANTA CECILIA |
| prisoes | Sao Paulo | SAO PAULO |

## Qualidade dos painéis (NAs e zeros por coluna)

Fonte: `outputs/auditoria/qualidade_paineis.csv`.
NAs na saúde refletem a decisão de marcar anos provisórios como NA (não 0).

| painel | coluna | n | n_na | n_zero |
| --- | --- | --- | --- | --- |
| painel_criminal_municipio_ano.csv | id_municipio | 1.988 | 0 | 0 |
| painel_criminal_municipio_ano.csv | ano | 1.988 | 0 | 0 |
| painel_criminal_municipio_ano.csv | hd_vitima | 1.988 | 0 | 1.080 |
| painel_criminal_municipio_ano.csv | hd_ocorrencias | 1.988 | 0 | 1.081 |
| painel_criminal_municipio_ano.csv | tot_estupro | 1.988 | 0 | 364 |
| painel_criminal_municipio_ano.csv | roubo_outros | 1.988 | 0 | 791 |
| painel_criminal_municipio_ano.csv | furto_outros | 1.988 | 0 | 5 |
| painel_criminal_municipio_ano.csv | prisoes | 1.988 | 0 | 177 |
| painel_criminal_municipio_ano.csv | populacao | 1.988 | 0 | 0 |
| painel_criminal_municipio_ano.csv | pib | 1.988 | 0 | 0 |
| painel_criminal_municipio_ano.csv | distorcao_idade_serie_fund | 1.988 | 0 | 8 |
| painel_criminal_municipio_ano.csv | hd_vitima_taxa_100k | 1.988 | 0 | 1.080 |
| painel_criminal_municipio_ano.csv | hd_ocorrencias_taxa_100k | 1.988 | 0 | 1.081 |
| painel_criminal_municipio_ano.csv | tot_estupro_taxa_100k | 1.988 | 0 | 364 |
| painel_criminal_municipio_ano.csv | roubo_outros_taxa_100k | 1.988 | 0 | 791 |
| painel_criminal_municipio_ano.csv | furto_outros_taxa_100k | 1.988 | 0 | 5 |
| painel_criminal_municipio_ano.csv | prisoes_taxa_100k | 1.988 | 0 | 177 |
| painel_prisional_estabelecimento.csv | ID | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | ciclo | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | ano | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | periodo | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | CEP | 414 | 0 | 7 |
| painel_prisional_estabelecimento.csv | Código IBGE | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Presos provisórios / Masculino | 414 | 0 | 397 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Presos provisórios / Feminino | 414 | 0 | 409 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Presos provisórios / Total | 414 | 0 | 395 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime fechado / Masculino | 414 | 0 | 105 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime fechado / Feminino | 414 | 0 | 383 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime fechado / Total | 414 | 0 | 86 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime semiaberto / Masculino | 414 | 0 | 268 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime semiaberto / Feminino | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime semiaberto / Total | 414 | 0 | 260 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime aberto / Masculino | 414 | 0 | 395 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime aberto / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime aberto / Total | 414 | 0 | 395 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime Disciplinar Diferenciado (RDD) / Masculino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime Disciplinar Diferenciado (RDD) / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Regime Disciplinar Diferenciado (RDD) / Total | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Medidas de segurança de internação / Masculino | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Medidas de segurança de internação / Feminino | 414 | 0 | 404 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Medidas de segurança de internação / Total | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Outro(s). Qual(is)? / Masculino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Outro(s). Qual(is)? / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Outro(s). Qual(is)? / Total | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Masculino / Total | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Feminino / Total | 414 | 0 | 364 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Celas interditadas/ desativadas e respectivas vagas / Celas não aptas | 414 | 0 | 399 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Celas interditadas/ desativadas e respectivas vagas / Vagas desativadas - Masculino | 414 | 0 | 398 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Celas interditadas/ desativadas e respectivas vagas / Vagas desativadas - Feminino | 414 | 0 | 408 |
| painel_prisional_estabelecimento.csv | 1.3 Capacidade do estabelecimento / Celas interditadas/ desativadas e respectivas vagas / Total de vagas desativadas | 414 | 0 | 392 |
| painel_prisional_estabelecimento.csv | 2.2 Possui berçário e/ou centro de referência materno-infantil? (apenas para estabelecimentos com vagas para mulheres) / Sim. Capacidade de bebês: / Quantidade | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 2.3 Possui creche? (apenas para estabelecimentos com vagas para mulheres) / Sim. Capacidade de crianças: / Quantidade | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 2.4 Módulo de saúde / Consultório médico / Quantidade | 414 | 0 | 207 |
| painel_prisional_estabelecimento.csv | 2.4 Módulo de saúde / Consultório odontológico / Quantidade | 414 | 0 | 236 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Sala de aula / Quantidade de salas | 414 | 0 | 102 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Sala de aula / Capacidade para quantas pessoas | 414 | 0 | 103 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Sala de informática / Quantidade de salas | 414 | 0 | 362 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Sala de informática / Capacidade para quantas pessoas | 414 | 0 | 361 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Biblioteca / Quantidade de salas | 414 | 0 | 111 |
| painel_prisional_estabelecimento.csv | 2.5 Módulo de educação / Biblioteca / Capacidade para quantas pessoas | 414 | 0 | 134 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Cargos administrativos / Total | 414 | 0 | 7 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Enfermeiros / Total | 414 | 0 | 233 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Psicólogos / Total | 414 | 0 | 136 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Dentistas / Total | 414 | 0 | 247 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Assistentes sociais / Total | 414 | 0 | 97 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Médicos - clínicos gerais / Total | 414 | 0 | 235 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Médicos – psiquiatras / Total | 414 | 0 | 363 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Médicos - outras especialidades / Total | 414 | 0 | 401 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Pedagogos / Total | 414 | 0 | 394 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Professores / Total | 414 | 0 | 229 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Policial Civil em atividade exclusiva no estabelecimento prisional / Total | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 3.1 Quantidade de Servidores que atuam no Sistema Prisional / Policial Militar em atividade exclusiva no estabelecimento prisional / Total | 414 | 0 | 354 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Presos provisórios (sem condenação) / Total | 414 | 0 | 52 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Presos sentenciados - regime fechado / Total | 414 | 0 | 60 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Presos sentenciados - regime semiaberto / Total | 414 | 0 | 11 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Presos sentenciados - regime aberto / Total | 414 | 0 | 51 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Medida de segurança - internação / Total | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Medida de segurança - tratamento ambulatorial / Total | 414 | 0 | 409 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Total | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | 4.1 População prisional / Quantas pessoas privadas de liberdade estão em Regime Disciplinar Diferenciado? | 414 | 0 | 410 |
| painel_prisional_estabelecimento.csv | 4.3 O estabelecimento tem controle da informação sobre quantos presos sentenciados no regime fechado já foram beneficiados por decisão judicial com o regime semiaberto e aguardam vaga para transferência? / Sim. Quantos / Masculino | 414 | 0 | 386 |
| painel_prisional_estabelecimento.csv | 4.3 O estabelecimento tem controle da informação sobre quantos presos sentenciados no regime fechado já foram beneficiados por decisão judicial com o regime semiaberto e aguardam vaga para transferência? / Sim. Quantos / Feminino | 414 | 0 | 404 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Entradas / Número de inclusões originárias / Masculino | 414 | 0 | 49 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Entradas / Número de inclusões originárias / Feminino | 414 | 0 | 208 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Entradas / Número de inclusões originárias / Total | 414 | 0 | 26 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Alvarás de soltura / Masculino | 414 | 0 | 35 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Alvarás de soltura / Feminino | 414 | 0 | 212 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Alvarás de soltura / Total | 414 | 0 | 12 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Abandonos / Masculino | 414 | 0 | 340 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Abandonos / Feminino | 414 | 0 | 402 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Abandonos / Total | 414 | 0 | 334 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Total de óbitos / Masculino | 414 | 0 | 308 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Total de óbitos / Feminino | 414 | 0 | 406 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Saídas / Total de óbitos / Total | 414 | 0 | 304 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Número de inclusões por transferências ou remoções / Masculino | 414 | 0 | 32 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Número de inclusões por transferências ou remoções / Feminino | 414 | 0 | 207 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Número de inclusões por transferências ou remoções / Total | 414 | 0 | 10 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Transferências/ remoções - deste para outro estabelecimento. / Masculino | 414 | 0 | 34 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Transferências/ remoções - deste para outro estabelecimento. / Feminino | 414 | 0 | 201 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Transferências/remoções / Transferências/ remoções - deste para outro estabelecimento. / Total | 414 | 0 | 11 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Permissão de saída / Masculino | 414 | 0 | 311 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Permissão de saída / Feminino | 414 | 0 | 384 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Permissão de saída / Total | 414 | 0 | 302 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Saída temporária / Masculino | 414 | 0 | 235 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Saída temporária / Feminino | 414 | 0 | 366 |
| painel_prisional_estabelecimento.csv | 4.5 Movimentação no Sistema Prisional (total do período de referência) / Autorizações de saída / Saída temporária / Total | 414 | 0 | 222 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 18 a 24 anos / Masculino | 414 | 0 | 34 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 18 a 24 anos / Feminino | 414 | 0 | 252 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 18 a 24 anos / Total | 414 | 0 | 9 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 25 a 29 anos / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 25 a 29 anos / Feminino | 414 | 0 | 237 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 25 a 29 anos / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 30 a 34 anos / Masculino | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 30 a 34 anos / Feminino | 414 | 0 | 237 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 30 a 34 anos / Total | 414 | 0 | 4 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 35 a 45 anos / Masculino | 414 | 0 | 28 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 35 a 45 anos / Feminino | 414 | 0 | 228 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 35 a 45 anos / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 46 a 60 anos / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 46 a 60 anos / Feminino | 414 | 0 | 252 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 46 a 60 anos / Total | 414 | 0 | 6 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 61 a 70 anos / Masculino | 414 | 0 | 51 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 61 a 70 anos / Feminino | 414 | 0 | 351 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / 61 a 70 anos / Total | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Mais de 70 anos / Masculino | 414 | 0 | 168 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Mais de 70 anos / Feminino | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Mais de 70 anos / Total | 414 | 0 | 164 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Não informado / Masculino | 414 | 0 | 371 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Não informado / Feminino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Não informado / Total | 414 | 0 | 370 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Masculino / Total | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Feminino / Total | 414 | 0 | 211 |
| painel_prisional_estabelecimento.csv | 5.1 Quantidade de pessoas privadas de liberdade por faixa etária / Total | 414 | 0 | 2 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Branca / Masculino | 414 | 0 | 27 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Branca / Feminino | 414 | 0 | 215 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Branca / Total | 414 | 0 | 3 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Preta / Masculino | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Preta / Feminino | 414 | 0 | 286 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Preta / Total | 414 | 0 | 6 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Parda / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Parda / Feminino | 414 | 0 | 232 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Parda / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Amarela / Masculino | 414 | 0 | 146 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Amarela / Feminino | 414 | 0 | 358 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Amarela / Total | 414 | 0 | 129 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Indígena / Masculino | 414 | 0 | 237 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Indígena / Feminino | 414 | 0 | 383 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Indígena / Total | 414 | 0 | 230 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Não informado / Masculino | 414 | 0 | 411 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Não informado / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Não informado / Total | 414 | 0 | 411 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Masculino / Total | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Feminino / Total | 414 | 0 | 211 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Total | 414 | 0 | 2 |
| painel_prisional_estabelecimento.csv | 5.2 Quantidade de pessoas privadas de liberdade por cor de pele/raça/etnia / Se houver indígenas, destacar povo indígena ao qual pertence e respectivo idioma (campos abertos) / Quantidade | 414 | 0 | 351 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Área Urbana - Municípios do Interior / Masculino | 414 | 0 | 382 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Área Urbana - Municípios do Interior / Feminino | 414 | 0 | 390 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Área Urbana - Municípios em Regiões Metropolitanas / Masculino | 414 | 0 | 392 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Área Urbana - Municípios em Regiões Metropolitanas / Feminino | 414 | 0 | 407 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Zona Rural / Masculino | 414 | 0 | 401 |
| painel_prisional_estabelecimento.csv | 5.3 Quantidade de pessoas privadas de liberdade por procedência / Zona Rural / Feminino | 414 | 0 | 410 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Solteiro/a / Masculino | 414 | 0 | 28 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Solteiro/a / Feminino | 414 | 0 | 214 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Solteiro/a / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / União estável/amasiado / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / União estável/amasiado / Feminino | 414 | 0 | 236 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / União estável/amasiado / Total | 414 | 0 | 6 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Casado/a / Masculino | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Casado/a / Feminino | 414 | 0 | 272 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Casado/a / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Separado/a judicialmente / Masculino | 414 | 0 | 56 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Separado/a judicialmente / Feminino | 414 | 0 | 331 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Separado/a judicialmente / Total | 414 | 0 | 36 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Divorciado/a / Masculino | 414 | 0 | 89 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Divorciado/a / Feminino | 414 | 0 | 336 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Divorciado/a / Total | 414 | 0 | 59 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Viúvo/a / Masculino | 414 | 0 | 178 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Viúvo/a / Feminino | 414 | 0 | 343 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Viúvo/a / Total | 414 | 0 | 139 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Não informado / Masculino | 414 | 0 | 410 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Não informado / Feminino | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Não informado / Total | 414 | 0 | 408 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Masculino | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Feminino | 414 | 0 | 211 |
| painel_prisional_estabelecimento.csv | 5.4 Estado civil / Total | 414 | 0 | 2 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Total de pessoas privadas de liberdade com deficiência / Masculino | 414 | 0 | 269 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Total de pessoas privadas de liberdade com deficiência / Feminino | 414 | 0 | 392 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Total de pessoas privadas de liberdade com deficiência / Total | 414 | 0 | 260 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Masculino | 414 | 0 | 269 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Feminino | 414 | 0 | 392 |
| painel_prisional_estabelecimento.csv | 5.5 Pessoas com deficiência / Total | 414 | 0 | 260 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Analfabeto / Masculino | 414 | 0 | 61 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Analfabeto / Feminino | 414 | 0 | 359 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Analfabeto / Total | 414 | 0 | 44 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Alfabetizado (sem cursos regulares) / Masculino | 414 | 0 | 48 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Alfabetizado (sem cursos regulares) / Feminino | 414 | 0 | 371 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Alfabetizado (sem cursos regulares) / Total | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Incompleto / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Incompleto / Feminino | 414 | 0 | 223 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Incompleto / Total | 414 | 0 | 6 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Completo / Masculino | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Completo / Feminino | 414 | 0 | 252 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Fundamental Completo / Total | 414 | 0 | 5 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Incompleto / Masculino | 414 | 0 | 31 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Incompleto / Feminino | 414 | 0 | 244 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Incompleto / Total | 414 | 0 | 7 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Completo / Masculino | 414 | 0 | 30 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Completo / Feminino | 414 | 0 | 248 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Médio Completo / Total | 414 | 0 | 7 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Incompleto / Masculino | 414 | 0 | 90 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Incompleto / Feminino | 414 | 0 | 325 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Incompleto / Total | 414 | 0 | 65 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Completo / Masculino | 414 | 0 | 152 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Completo / Feminino | 414 | 0 | 354 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino Superior Completo / Total | 414 | 0 | 123 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino acima de Superior Completo / Masculino | 414 | 0 | 389 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino acima de Superior Completo / Feminino | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Ensino acima de Superior Completo / Total | 414 | 0 | 388 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Não Informado / Masculino | 414 | 0 | 314 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Não Informado / Feminino | 414 | 0 | 400 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Não Informado / Total | 414 | 0 | 311 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Masculino | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Feminino | 414 | 0 | 211 |
| painel_prisional_estabelecimento.csv | 5.6 Quantidade de pessoas privadas de liberdade por grau de instrução / Total | 414 | 0 | 2 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Certidão de Nascimento / Masculino | 414 | 0 | 50 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Certidão de Nascimento / Feminino | 414 | 0 | 302 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / R.G. / Masculino | 414 | 0 | 34 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / R.G. / Feminino | 414 | 0 | 218 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / C.P.F. / Masculino | 414 | 0 | 34 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / C.P.F. / Feminino | 414 | 0 | 222 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Título de eleitor / Masculino | 414 | 0 | 72 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Título de eleitor / Feminino | 414 | 0 | 351 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Certificado de reservista / Masculino | 414 | 0 | 227 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Certificado de reservista / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / CTPS (Carteira de Trabalho) / Masculino | 414 | 0 | 62 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / CTPS (Carteira de Trabalho) / Feminino | 414 | 0 | 337 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Cartão SUS / Masculino | 414 | 0 | 37 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Cartão SUS / Feminino | 414 | 0 | 226 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / RNE (presos estrangeiros) / Masculino | 414 | 0 | 390 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / RNE (presos estrangeiros) / Feminino | 414 | 0 | 404 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Passaporte (presos estrangeiros) / Masculino | 414 | 0 | 379 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Passaporte (presos estrangeiros) / Feminino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Número de pessoas com algum dos documentos acima / Masculino | 414 | 0 | 133 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Número de pessoas com algum dos documentos acima / Feminino | 414 | 0 | 278 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Número de pessoas sem documentos / Masculino | 414 | 0 | 404 |
| painel_prisional_estabelecimento.csv | 5.7 Número de pessoas privadas de liberdade com documentos pessoais / Número de pessoas sem documentos / Feminino | 414 | 0 | 411 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Brasileiro nato / Masculino | 414 | 0 | 24 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Brasileiro nato / Feminino | 414 | 0 | 211 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Brasileiro naturalizado / Masculino | 414 | 0 | 400 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Brasileiro naturalizado / Feminino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Estrangeiros - total / Masculino | 414 | 0 | 245 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Estrangeiros - total / Feminino | 414 | 0 | 384 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Sem informação sobre a nacionalidade / Masculino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 5.8 Quantidade de pessoas privadas de liberdade por nacionalidade / Sem informação sobre a nacionalidade / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 5.9 Faixa etária dos filhos que estão no estabelecimento (aplicável apenas para estabelecimentos com mulheres) / Quantidade de gestantes/parturientes | 414 | 0 | 405 |
| painel_prisional_estabelecimento.csv | 5.9 Faixa etária dos filhos que estão no estabelecimento (aplicável apenas para estabelecimentos com mulheres) / Quantidade de lactantes | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 5.10 Número de filhos/as / Sem filhos / Masculino | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | 5.10 Número de filhos/as / Sem filhos / Feminino | 414 | 0 | 241 |
| painel_prisional_estabelecimento.csv | 5.11 Número de pessoas privadas de liberdade que possuem visitantes cadastrados / Pessoas com visitantes cadastrados / Masculino | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | 5.11 Número de pessoas privadas de liberdade que possuem visitantes cadastrados / Pessoas com visitantes cadastrados / Feminino | 414 | 0 | 214 |
| painel_prisional_estabelecimento.csv | 5.12 Quantidade de pessoas privadas de liberdade por tempo total de penas (presos/as condenados/as e ) / Número de pessoas sem informação / Masculino | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | 5.12 Quantidade de pessoas privadas de liberdade por tempo total de penas (presos/as condenados/as e ) / Número de pessoas sem informação / Feminino | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | 5.13 Quantidade de pessoas privadas de liberdade por tempo de pena remanescente (presos/as condenados/as e) / Número de pessoas sem informação / Masculino | 414 | 0 | 411 |
| painel_prisional_estabelecimento.csv | 5.13 Quantidade de pessoas privadas de liberdade por tempo de pena remanescente (presos/as condenados/as e) / Número de pessoas sem informação / Feminino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade com informação sobre tipificação criminal / Masculino | 414 | 0 | 129 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade com informação sobre tipificação criminal / Feminino | 414 | 0 | 266 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade com informação sobre tipificação criminal / Total | 414 | 0 | 111 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade sem informação sobre tipificação criminal / Masculino | 414 | 0 | 390 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade sem informação sobre tipificação criminal / Feminino | 414 | 0 | 399 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Número de pessoas privadas de liberdade sem informação sobre tipificação criminal / Total | 414 | 0 | 386 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Masculino | 414 | 0 | 33 |
| painel_prisional_estabelecimento.csv | 5.14 Quantidade de incidências por tipo penal / Feminino | 414 | 0 | 217 |
| painel_prisional_estabelecimento.csv | id_municipio | 414 | 0 | 0 |
| painel_prisional_estabelecimento.csv | provisorios_masculino | 414 | 0 | 75 |
| painel_prisional_estabelecimento.csv | provisorios_feminino | 414 | 0 | 233 |
| painel_prisional_estabelecimento.csv | sentenciado_fechado_masculino | 414 | 0 | 84 |
| painel_prisional_estabelecimento.csv | sentenciado_fechado_feminino | 414 | 0 | 241 |
| painel_prisional_estabelecimento.csv | sentenciado_semiaberto_masculino | 414 | 0 | 35 |
| painel_prisional_estabelecimento.csv | sentenciado_semiaberto_feminino | 414 | 0 | 295 |
| painel_prisional_estabelecimento.csv | sentenciado_aberto_masculino | 414 | 0 | 70 |
| painel_prisional_estabelecimento.csv | sentenciado_aberto_feminino | 414 | 0 | 358 |
| painel_prisional_estabelecimento.csv | internacao_masculino | 414 | 0 | 403 |
| painel_prisional_estabelecimento.csv | internacao_feminino | 414 | 0 | 410 |
| painel_prisional_estabelecimento.csv | tratamento_masculino | 414 | 0 | 410 |
| painel_prisional_estabelecimento.csv | tratamento_feminino | 414 | 0 | 413 |
| painel_prisional_estabelecimento.csv | pena_masculino_0_4anos | 414 | 0 | 29 |
| painel_prisional_estabelecimento.csv | pena_masculino_1_8anos | 414 | 0 | 49 |
| painel_prisional_estabelecimento.csv | pena_masculino_8_15anos | 414 | 0 | 37 |
| painel_prisional_estabelecimento.csv | pena_masculino_15_20anos | 414 | 0 | 41 |
| painel_prisional_estabelecimento.csv | pena_masculino_20_30anos | 414 | 0 | 42 |
| painel_prisional_estabelecimento.csv | pena_masculino_30_50anos | 414 | 0 | 58 |
| painel_prisional_estabelecimento.csv | pena_masculino_50_maisanos | 414 | 0 | 127 |
| painel_prisional_estabelecimento.csv | pena_masculino_sem_info | 414 | 0 | 412 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_0_4anos | 414 | 0 | 28 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_4_8anos | 414 | 0 | 37 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_8_15anos | 414 | 0 | 38 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_15_20anos | 414 | 0 | 50 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_20_30anos | 414 | 0 | 61 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_30_50anos | 414 | 0 | 132 |
| painel_prisional_estabelecimento.csv | pena_remanescente_masculino_50maisanos | 414 | 0 | 232 |
| painel_prisional_estabelecimento.csv | pena_feminino_0_4anos | 414 | 0 | 217 |
| painel_prisional_estabelecimento.csv | pena_feminino_1_8anos | 414 | 0 | 307 |
| painel_prisional_estabelecimento.csv | pena_feminino_8_15anos | 414 | 0 | 285 |
| painel_prisional_estabelecimento.csv | pena_feminino_15_20anos | 414 | 0 | 310 |
| painel_prisional_estabelecimento.csv | pena_feminino_20_30anos | 414 | 0 | 295 |
| painel_prisional_estabelecimento.csv | pena_feminino_30_50anos | 414 | 0 | 360 |
| painel_prisional_estabelecimento.csv | pena_feminino_50_maisanos | 414 | 0 | 408 |
| painel_prisional_estabelecimento.csv | pena_feminino_sem_info | 414 | 0 | 414 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_0_4anos | 414 | 0 | 213 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_4_8anos | 414 | 0 | 300 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_8_15anos | 414 | 0 | 273 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_15_20anos | 414 | 0 | 346 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_20_30anos | 414 | 0 | 345 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_30_50anos | 414 | 0 | 383 |
| painel_prisional_estabelecimento.csv | pena_remanescente_feminino_50maisanos | 414 | 0 | 406 |
| painel_prisional_estabelecimento.csv | mulheres_presas_com_filhos_as | 414 | 0 | 215 |
| painel_prisional_estabelecimento.csv | homens_presos_com_filhos_as | 414 | 0 | 31 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_pessoa_masculino | 414 | 0 | 35 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_pessoa_feminino | 414 | 0 | 295 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_pessoa_total | 414 | 0 | 12 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_patrimonio_masculino | 414 | 0 | 34 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_patrimonio_feminino | 414 | 0 | 251 |
| painel_prisional_estabelecimento.csv | tipo_penal_contra_patrimonio_total | 414 | 0 | 10 |
| painel_prisional_estabelecimento.csv | tipo_penal_dignidade_sexual_masculino | 414 | 0 | 51 |
| painel_prisional_estabelecimento.csv | tipo_penal_dignidade_sexual_feminino | 414 | 0 | 326 |
| painel_prisional_estabelecimento.csv | tipo_penal_dignidade_sexual_total | 414 | 0 | 33 |
| painel_prisional_estabelecimento.csv | tipo_penal_drogas_masculino | 414 | 0 | 36 |
| painel_prisional_estabelecimento.csv | tipo_penal_drogas_feminino | 414 | 0 | 229 |
| painel_prisional_estabelecimento.csv | tipo_penal_drogas_total | 414 | 0 | 12 |
| painel_prisional_estabelecimento.csv | tipo_penal_desarmamento_masculino | 414 | 0 | 45 |
| painel_prisional_estabelecimento.csv | tipo_penal_desarmamento_feminino | 414 | 0 | 330 |
| painel_prisional_estabelecimento.csv | tipo_penal_desarmamento_total | 414 | 0 | 20 |
| painel_prisional_estabelecimento.csv | tipo_penal_outros_masculino | 414 | 0 | 47 |
| painel_prisional_estabelecimento.csv | tipo_penal_outros_feminino | 414 | 0 | 310 |
| painel_prisional_estabelecimento.csv | tipo_penal_outros_total | 414 | 0 | 25 |
| painel_prisional_estabelecimento.csv | obitos_naturais_masculino | 414 | 2 | 360 |
| painel_prisional_estabelecimento.csv | obitos_naturais_feminino | 414 | 2 | 408 |
| painel_prisional_estabelecimento.csv | obitos_naturais_total | 414 | 2 | 358 |
| painel_prisional_estabelecimento.csv | obitos_criminais_masculino | 414 | 2 | 406 |
| painel_prisional_estabelecimento.csv | obitos_criminais_feminino | 414 | 2 | 411 |
| painel_prisional_estabelecimento.csv | obitos_criminais_total | 414 | 2 | 405 |
| painel_prisional_estabelecimento.csv | obitos_suicidios_masculino | 414 | 2 | 386 |
| painel_prisional_estabelecimento.csv | obitos_suicidios_feminino | 414 | 2 | 410 |
| painel_prisional_estabelecimento.csv | obitos_suicidios_total | 414 | 2 | 384 |
| painel_prisional_estabelecimento.csv | obitos_acidentais_masculino | 414 | 2 | 407 |
| painel_prisional_estabelecimento.csv | obitos_acidentais_feminino | 414 | 2 | 412 |
| painel_prisional_estabelecimento.csv | obitos_acidentais_total | 414 | 2 | 407 |
| painel_prisional_estabelecimento.csv | obitos_desconhecida_masculino | 414 | 2 | 369 |
| painel_prisional_estabelecimento.csv | obitos_desconhecida_feminino | 414 | 2 | 410 |
| painel_prisional_estabelecimento.csv | obitos_desconhecida_total | 414 | 2 | 367 |
| painel_prisional_estabelecimento.csv | obitos_total_geral | 414 | 2 | 300 |
| painel_contexto_municipio.csv | id_municipio | 497 | 0 | 0 |
| painel_contexto_municipio.csv | populacao | 497 | 0 | 0 |
| painel_contexto_municipio.csv | pib | 497 | 0 | 0 |
| painel_contexto_municipio.csv | distorcao_idade_serie_fund | 497 | 0 | 2 |
| painel_saude_municipio_ano.csv | cod_mun6 | 3.938 | 0 | 0 |
| painel_saude_municipio_ano.csv | id_municipio | 3.938 | 0 | 0 |
| painel_saude_municipio_ano.csv | populacao | 3.938 | 0 | 0 |
| painel_saude_municipio_ano.csv | ano | 3.938 | 0 | 0 |
| painel_saude_municipio_ano.csv | casos_hepatite | 3.938 | 1.130 | 996 |
| painel_saude_municipio_ano.csv | casos_hiv | 3.938 | 1.474 | 1.284 |
| painel_saude_municipio_ano.csv | casos_tuberculose | 3.938 | 662 | 1.175 |
| painel_saude_municipio_ano.csv | obitos_hepatite | 3.938 | 2.475 | 955 |
| painel_saude_municipio_ano.csv | obitos_tuberculose | 3.938 | 2.230 | 1.047 |
| painel_saude_municipio_ano.csv | obitos_hiv | 3.938 | 1.726 | 1.168 |
| painel_saude_municipio_ano.csv | casos_hepatite_taxa_100k | 3.938 | 1.130 | 996 |
| painel_saude_municipio_ano.csv | casos_hiv_taxa_100k | 3.938 | 1.474 | 1.284 |
| painel_saude_municipio_ano.csv | casos_tuberculose_taxa_100k | 3.938 | 662 | 1.175 |
| painel_saude_municipio_ano.csv | obitos_hepatite_taxa_100k | 3.938 | 2.475 | 955 |
| painel_saude_municipio_ano.csv | obitos_tuberculose_taxa_100k | 3.938 | 2.230 | 1.047 |
| painel_saude_municipio_ano.csv | obitos_hiv_taxa_100k | 3.938 | 1.726 | 1.168 |

## Ressalvas conhecidas (ver docs/decisoes_metodologicas.md)

- **Criminal 2022 — furtos:** microdado ~24% abaixo do oficial; investigar antes de usar 2022.
- **`prisoes` = só flagrantes (PC):** mandados existem só em nível estadual no RS (divergência de SP).
- **`ap_armas` ausente no município:** só há dado estadual no RS (não municipalizável).
- **Prisional cela física:** recorte nativo (2024+) e por nome; exclui domiciliar/monitoração eletrônica.
- **Saúde:** cobertura temporal heterogênea (hepatite até 2023; demais até 2024; 2025 provisório = NA).
- **Taxas por 100 mil:** denominador = população Censo 2022 (mesma para todos os anos — simplificação da PoC).
