# Recorte dos cadastros SISDEPEN na referência do Monitor SP

Auditoria de 20/11/2026. A exportação paulista arquivada contém cadastros de monitoramento e domicílio junto de estabelecimentos classificados como cela física. A hipótese de três cadastros nominalmente relacionados encontra evidência no segundo semestre de 2021, mas não corresponde a três registros do mesmo ID. Os arquivos não permitem concluir que as mesmas pessoas tenham sido contadas três vezes.

## Fontes e reprodução

- Exportação local `data/raw/bases_data_studio/base_sisdepen - Sheet1.csv`, com 1.616 linhas anuais de 2017–2025.
- Base Única `sisdepen_baseunica_2025-2_25032026-163420.xlsx`, aba 1, com 3.277 registros paulistas nos 18 ciclos de 2017–2025. A [página oficial da SENAPPEN](https://www.gov.br/senappen/pt-br/servicos/sisdepen/bases-de-dados) identifica a Base Única e os ciclos. Janeiro–junho de 2021 é o 10º ciclo e julho–dezembro, o 11º.
- Código SP fixado em `45c714419387a1b85f92df459de7399a7dedaec5`. `depen.R` cria a chave pelo nome, UF e ano e filtra somente a UF, nas linhas 27–42. Os arquivos do primeiro semestre são listados nas linhas 52–72. Capacidade é selecionada nas linhas 223–250 e população, na linha 389. [Código SP](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/depen.R#L27-L73)
- Arquivos históricos de dezembro de 2020 e 2021 preservados no commit `4db9d98a83f1c80fa7e73746578e14b42690ef8f`, ramo local `sem_02`. Foram lidos diretamente dos objetos Git, sem checkout. Esses arquivos não trazem as colunas nativas `ID` e `Tipo de Recolhimento`. Seus nomes, quesito 1.2 e valores foram confrontados com a edição da Base Única. [Arquivo histórico do 11º ciclo](https://github.com/NEV-USP/MonitorPrisional2024/blob/4db9d98a83f1c80fa7e73746578e14b42690ef8f/11o-ciclo-base-de-dados-2021-2-semestre.xlsx)

O [script reprodutível](../scripts/exploratory/auditar_recorte_sisdepen_sp.py) usa a biblioteca padrão do Python. Os [resultados compactos](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/) contêm agregados, candidatos para inspeção e hashes dos insumos. Os dados brutos, o repositório SP e os painéis não são modificados.

```powershell
python scripts/exploratory/auditar_recorte_sisdepen_sp.py
```

## Estoque do primeiro semestre em todos os anos

Pessoas são a soma do item 4.1 Total. Vagas são a soma dos totais masculino e feminino do item 1.3, com contribuição zero das células vazias, conforme a conta paulista. A coluna física abaixo usa o rótulo nativo da Base Única. Nesse primeiro semestre, ela também coincide com o filtro físico acrescido da exclusão de nomes de domicílio ou monitoramento.

| Ano | Registros exportados | Pessoas exportadas | Vagas exportadas | Registros físicos | Pessoas físicas | Vagas físicas | Cadastros adicionais |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2017 | 168 | 226.463 | 139.881 | 168 | 226.463 | 139.881 | 0 |
| 2018 | 170 | 227.600 | 142.324 | 170 | 227.600 | 142.324 | 0 |
| 2019 | 173 | 233.755 | 144.793 | 173 | 233.755 | 144.793 | 0 |
| 2020 | 188 | 218.930 | 147.963 | 176 | 218.909 | 147.942 | 12 |
| 2021 | 193 | 208.036 | 150.493 | 178 | 207.987 | 150.054 | 15 |
| 2022 | 179 | 197.529 | 154.864 | 178 | 197.441 | 149.864 | 1 |
| 2023 | 181 | 196.287 | 157.051 | 180 | 195.787 | 152.051 | 1 |
| 2024 | 183 | 201.094 | 162.199 | 182 | 200.178 | 154.199 | 1 |
| 2025 | 181 | 214.159 | 164.753 | 180 | 213.401 | 156.753 | 1 |

Os cadastros adicionais têm rótulo nativo de domicílio com monitoramento eletrônico. Sua contribuição registrada de pessoas/vagas é 21/21 em 2020, 49/439 em 2021, 88/5.000 em 2022, 500/5.000 em 2023, 916/8.000 em 2024 e 758/8.000 em 2025. Esses valores não demonstram quantas pessoas distintas existem entre modalidades nem transformam a capacidade declarada no cadastro domiciliar em vagas de celas.

Em todos os anos, a quantidade e os totais da Base Única sem filtro de modalidade coincidem com a exportação. Pelo nome, UF e ano, 1.615 de 1.616 linhas foram associadas. Todos os 1.615 pares coincidiram em pessoas e capacidade. A linha remanescente de 2024 contém `CPP Masculino ... de Butantan` no export e `CPP ... de Butantan` na Base Única. O ID 1306 tem os mesmos município, pessoas e capacidade, mas foi mantido como candidato por atributos, sem substituir automaticamente a chave. [Resumo anual](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/resumo_estoque_anual.csv) · [Linha sem par exato](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/export_sem_par_exato.csv)

## Os dois ciclos e o caso de dezembro de 2021

A contagem semestral confirma que o salto de 2021 se concentra no segundo ciclo. A coluna física mantém exclusivamente o rótulo nativo, sem aplicar a salvaguarda pelo nome.

| Ano | Junho: todos | Junho: rótulo físico | Dezembro: todos | Dezembro: rótulo físico |
| --- | ---: | ---: | ---: | ---: |
| 2017 | 168 | 168 | 168 | 168 |
| 2018 | 170 | 170 | 171 | 171 |
| 2019 | 173 | 173 | 176 | 176 |
| 2020 | 188 | 176 | 187 | 178 |
| 2021 | 193 | 178 | 232 | 199 |
| 2022 | 179 | 178 | 181 | 180 |
| 2023 | 181 | 180 | 182 | 181 |
| 2024 | 183 | 182 | 183 | 182 |
| 2025 | 181 | 180 | 181 | 180 |

No primeiro semestre de 2021 existem 178 cadastros físicos e 15 domiciliares monitorados. No segundo, existem 232 registros. A decomposição exige combinar o rótulo nativo com o nome e o quesito 1.2.

| Conjunto em 2021/2 | Registros | Pessoas | Vagas | Endereço informado |
| --- | ---: | ---: | ---: | ---: |
| Rótulo físico e nome sem marcador de modalidade | 179 | 202.395 | 151.868 | 167 |
| Rótulo físico, nome `MONITORAMENTO ELETRÔNICO - CELA FÍSICA` | 20 | 597 | 1.727 | 0 |
| Rótulo domiciliar monitorado e nome `MONITORAMENTO ... DOMICILIAR` | 33 | 62 | 327 | 0 |
| Total | 232 | 203.054 | 153.922 | 167 |

O arquivo histórico paulista do 11º ciclo confirma os três conjuntos nominais e os mesmos totais. Assim, o padrão nominal já estava naquela planilha, antes da edição consolidada de 2026. O segundo conjunto tem nome com monitoramento em cela física e rótulo nativo `Cela física`. O quesito 1.2 descreve estabelecimentos de monitoramento eletrônico, com variações de grafia e um caso que menciona domicílio. Essas diferenças podem refletir recortes ou questionários distintos; sem metadados adicionais, não demonstram erro de classificação. Aplicar a salvaguarda nominal atualmente usada no RS excluiria também esses 20 registros; isso é um cenário de recorte, e não uma decisão de identidade. [Agregados dos arquivos históricos](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/arquivos_historicos_sp_sem2.csv) · [Todos os ciclos e cenários](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/resumo_ciclos.csv)

Não há repetição do ID nativo dentro de nenhum dos 18 ciclos da Base Única. Retirar somente os sufixos explícitos de modalidade dos nomes permite localizar seis grupos de três cadastros em 2021/2. Nos seis, a unidade sem sufixo possui endereço. O cadastro `MONITORAMENTO ... CELA FÍSICA` não informa município ou endereço, e o domiciliar informa município, mas não endereço.

| Grupo nominal | IDs na ordem unidade / monitoramento em cela física / domiciliar | Pessoas registradas | Vagas registradas |
| --- | --- | --- | --- |
| CDP II da Chácara Belém | 1301 / 5730 / 4489 | 1.246 / 14 / 1 | 954 / 91 / 7 |
| CPP de Jardinópolis | 1340 / 5737 / 4516 | 1.951 / 94 / 8 | 1.080 / 188 / 11 |
| CPP III de Bauru | 1370 / 5738 / 4519 | 392 / 23 / 1 | 1.124 / 23 / 10 |
| CPP de São José do Rio Preto | 1305 / 5740 / 4531 | 2.156 / 40 / 1 | 1.079 / 50 / 34 |
| Penitenciária de Tremembé, Dr. José Augusto César Salgado | 1344 / 5731 / 4473 | 465 / 1 / 2 | 608 / 11 / 10 |
| Penitenciária de Presidente Prudente | 1369 / 5742 / 4525 | 1.504 / 7 / 2 | 943 / 150 / 39 |

Isso comprova tríades de cadastros nominalmente relacionados e modalidades declaradas diferentes. A ausência de localização nas linhas auxiliares limita a confirmação da relação física, e os dados agregados não permitem deduplicar pessoas. Outros nomes relacionados apresentam abreviações, alterações ou município ausente; as associações candidatas foram preservadas para inspeção. [Tríades, com campos de origem selecionados](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/triades_nominais_2021_2.csv) · [Associações candidatas de 2020–2021](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/associacoes_modalidades_2020_2021.csv)

## Estoque de junho, campos do segundo semestre e mortalidade

O `left_join` de `dados_sem2.R`, linha 116, parte da grade do primeiro semestre e liga o segundo pela chave nome–UF–ano. As linhas 85–96 selecionam consultas, cela para gestantes e lactantes do segundo ciclo. As linhas 123–137 somam óbitos dos dois ciclos, após substituir ausências por zero. Cadastros novos de dezembro não entram automaticamente na contagem de estabelecimentos do estoque anual. [Código SP](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/dados_sem2.R#L85-L137)

Em 2021/2, os cinco totais de óbitos dos 53 cadastros com marcador de monitoramento ou domicílio somam zero. Os 20 com nome de monitoramento em cela física somam quatro consultas médicas internas; os demais campos selecionados somam zero nesses dois conjuntos. Nessas somas, campos vazios contribuem zero, reproduzindo a operação paulista; o resultado não certifica que cada célula vazia represente ausência real de evento. Na grade de junho pareada com o export, tanto a junção por nome quanto a junção por ID recuperam 242 óbitos e 144.538 consultas internas do segundo semestre. O padrão cadastral de dezembro, portanto, não triplica automaticamente o estoque de junho nem seus óbitos anuais.

A comparação revela, contudo, efeito de mudanças de nome em outros anos. Na mesma grade pareada, a junção nominal recupera 274 óbitos do segundo semestre de 2017, contra 275 por ID; em 2022, recupera 227 contra 233; em 2023, 259 contra 261. Em 2020 e 2021 há respectivamente 12 e sete linhas sem par nominal no segundo ciclo, contra três e cinco sem par por ID, mas os totais de óbitos coincidem. Esses resultados quantificam a perda da junção nominal nessa edição, sem estabelecer que o ID deve ser usado para fundir modalidades ou entidades. [Reconciliação anual das junções](../outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20/resumo_estoque_anual.csv)

## Encaminhamento delimitado

A comparação física entre RS e SP pode ser produzida com a mesma edição nacional e regras comuns de modalidade, preservando os identificadores e apresentando separadamente a contagem dos cadastros. Para o primeiro semestre, a diferença de universo já está quantificada em todos os anos. Para 2021/2, a equipe precisa esclarecer o significado dos cadastros nomeados como monitoramento em cela física e sua relação com as unidades sem sufixo. Essa confirmação antecede qualquer fusão ou exclusão por identidade. Os resultados desta auditoria não alteram bases nem a versão candidata e não certificam a conexão ao vivo de cada gráfico paulista.
