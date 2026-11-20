# Consulta complementar à equipe SP — recorte prisional e médicos

> Rascunho de 20/11/2026 para revisão de Guilherme. Não enviado. As referências descrevem os arquivos e o código auditados; não comprovam a configuração de todos os gráficos ao vivo.

**Assunto:** Monitor Prisional RS–SP — confirmação do universo prisional e das categorias médicas

Olá, Fernando e Marlon,

Podem nos ajudar a confirmar duas escolhas para a comparação RS–SP?

1. **Universo e cadastros por modalidade.** A [auditoria de 2017–2025](https://github.com/guidornelles/monitor-prisional-rs/blob/main/docs/auditoria_recorte_sisdepen_sp_2026-11-20.md) encontrou coincidência com cela física em 2017–2019 e cadastros domiciliares monitorados adicionais: 12 em 2020, 15 em 2021 e um por ano em 2022–2025. O [`depen.R`, revisão `45c7144`, linhas 27–42](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/depen.R#L27-L42), filtra apenas UF. Em 2025/1, são 181 registros, 214.159 pessoas e 164.753 vagas na exportação, ante 180, 213.401 e 156.753 em “Cela física”. O registro adicional, de tipo nativo “Domiciliar com monitoramento eletrônico”, informa 758 pessoas e 8 mil vagas, afetando as duas parcelas da ocupação. Essa inclusão é intencional? No RS mantemos cela física (103 estabelecimentos e 38.519 pessoas); podemos usar esse recorte no comparativo?

   O exame do [11º ciclo, segundo semestre de 2021](https://github.com/NEV-USP/MonitorPrisional2024/blob/4db9d98a83f1c80fa7e73746578e14b42690ef8f/11o-ciclo-base-de-dados-2021-2-semestre.xlsx), em conjunto com a Base Única, identificou seis grupos nominais com três IDs: unidade sem sufixo, `MONITORAMENTO ELETRÔNICO - CELA FÍSICA` e `MONITORAMENTO ELETRÔNICO - DOMICILIAR`. Na Base Única, CDP II da Chácara Belém aparece nos IDs 1301/5730/4489, com 1.246/14/1 pessoas. A segunda linha tem tipo nativo “Cela física”; as duas linhas de monitoramento não informam endereço. Podem esclarecer a natureza desses cadastros, sua relação com a unidade sem sufixo e o tratamento pretendido? A relação física entre eles e a eventual sobreposição de pessoas permanecem questões em aberto.

2. **Médicos.** O [`depen.R`, revisão `45c7144`, linhas 353–355](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/depen.R#L353-L355), exporta três campos do quesito 3.1: clínicos gerais, psiquiatras e outras especialidades. Isso não permite deduzir a soma usada no gráfico. A seleção é intencional e quais campos compõem a métrica exibida? No RS preservamos as quatro categorias, incluindo ginecologistas.

Obrigado pela ajuda!

Atenciosamente,
Guilherme Souza
Doutorando em Políticas Públicas — UFRGS

## Referências do RS para revisão do rascunho

- [Auditoria do recorte SISDEPEN de SP, 2017–2025](auditoria_recorte_sisdepen_sp_2026-11-20.md): confronto da exportação com a Base Única e exame separado dos ciclos de 2021.
- [Recorte de cela física em `03_prisional.R`](../scripts/rs/03_prisional.R): função `aplicar_recorte`, com tipo de recolhimento nativo e salvaguarda por nome.
- [Total médico em `03b_prisional_derivadas.R`](../scripts/rs/03b_prisional_derivadas.R): `total_medicos`, soma das quatro categorias médicas do quesito 3.1.
- [Decisões metodológicas](decisoes_metodologicas.md#encaminhamentos-e-escopo): preservação das escolhas RS em 20/11; os recortes comparativos devem ser harmonizados sem substituir a série gaúcha.
- [Auditoria metodológica SP–RS](auditoria_metodologica_sp_rs.md#sistema-prisional): evidências, diferenças de universo e limites da inspeção.

## Quadro de apoio — primeiro semestre de cada ano em SP

Exportação auditada comparada com o filtro nativo `Tipo de Recolhimento = Cela física` na Base Única. Registros são cadastros da fonte, não uma identificação independente de estabelecimentos físicos. O segundo semestre de 2021 é examinado separadamente na auditoria vinculada acima.

| Ano | Registros exportados | Registros cela física | PPL exportada | PPL cela física | Vagas exportadas | Vagas cela física |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2017 | 168 | 168 | 226.463 | 226.463 | 139.881 | 139.881 |
| 2018 | 170 | 170 | 227.600 | 227.600 | 142.324 | 142.324 |
| 2019 | 173 | 173 | 233.755 | 233.755 | 144.793 | 144.793 |
| 2020 | 188 | 176 | 218.930 | 218.909 | 147.963 | 147.942 |
| 2021 | 193 | 178 | 208.036 | 207.987 | 150.493 | 150.054 |
| 2022 | 179 | 178 | 197.529 | 197.441 | 154.864 | 149.864 |
| 2023 | 181 | 180 | 196.287 | 195.787 | 157.051 | 152.051 |
| 2024 | 183 | 182 | 201.094 | 200.178 | 162.199 | 154.199 |
| 2025 | 181 | 180 | 214.159 | 213.401 | 164.753 | 156.753 |
