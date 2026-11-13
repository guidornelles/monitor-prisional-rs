# Auditoria das incidências por tipo penal no Monitor SP

Revisão de 13/11/2026. O quesito 5.14 do SISDEPEN conta **incidências por tipo penal**. Uma pessoa pode contribuir para mais de uma incidência. Os campos de pessoas com e sem informação sobre tipificação criminal são contagens separadas. [Nota técnica do SISDEPEN, quesito 5.14](https://www.gov.br/senappen/pt-br/servicos/sisdepen/manuais-e-apostilas/nota-tecnica-sisdepen)

## Planilha histórica e exportação de referência 2017–2025

- **Planilha histórica `Base_Sisdepen.xlsx` do repositório SP, 2017–2023.** A auditoria anterior pareou 1.071 linhas de estabelecimento e ano com a Base Única do primeiro semestre. Em todas, `tipo_penal_desarmamento_masculino` reproduziu apenas o art. 14. Em 501 linhas, os arts. 15–18 tinham incidências e a soma dos cinco artigos divergia da planilha. O script anterior separava esses quatro termos da atribuição com vírgulas.
- **Exportação local mais recente do Data Studio, `data/raw/bases_data_studio/base_sisdepen - Sheet1.csv`.** Recalculamos as 18 derivadas `tipo_penal_*` da branch `R`, commit [`45c7144`, de 17/06/2026](https://github.com/NEV-USP/MonitorPrisional2024/commit/45c714419387a1b85f92df459de7399a7dedaec5), com a aba 1 de `sisdepen_baseunica_2025-2_25032026-163420.xlsx`. A reprodução usou SP, primeiros semestres de 2017–2025, todos os tipos de recolhimento para espelhar o universo da exportação e zero onde a fórmula paulista o aplica. As 29.070 comparações coincidiram nas 1.615 linhas pareadas pelo nome do estabelecimento, UF e ano. A única linha sem par por essa chave foi o CPP Masculino Dra. Marina Marigo Cardoso de Oliveira, Butantan, em 2024. O teste reproduz a exportação arquivada localmente. A vinculação e a versão dos campos no painel público devem ser confirmadas com a equipe. [Base Única SISDEPEN](https://www.gov.br/senappen/pt-br/servicos/sisdepen/bases-de-dados)

## Fórmulas verificadas na exportação paulista de referência

| Campo | O que o script faz | Evidência nas 181 linhas pareadas de 2025 |
| --- | --- | --- |
| `tipo_penal_desarmamento_*` | O commit de junho passou a somar os cinco artigos do Estatuto, do 14 ao 18, em masculino, feminino e total (`depen.R`, linhas 610–629). | O total exportado é **3.001**, dos quais **1.393** correspondem ao art. 14. |
| `tipo_penal_outros_masculino` e `tipo_penal_outros_total` | A lista explícita inclui novamente os cinco artigos do Estatuto (`depen.R`, linhas 631–651 e 675–695). Se os grupos forem somados, essas incidências aparecem duas vezes. | `outros_total` soma **7.248**. Retirar apenas a sobreposição com desarmamento resulta em **4.247**, mantendo a lista paulista das demais rubricas. |
| `tipo_penal_outros_feminino` | A vírgula após a rubrica de corrupção passiva separa os 12 termos seguintes da atribuição (`depen.R`, linhas 653–673, especialmente 661). | Os oito primeiros termos reproduzem **142**. A soma dos 20 termos listados daria **269**, ou **254** após retirar desarmamento. |
| `tipo_penal_contra_pessoa_total` | A última parcela é a rubrica de outros crimes contra o patrimônio de homens. Para espelhar os campos por sexo, a parcela correspondente seria a de outros crimes contra a pessoa, total (`depen.R`, linhas 516–542). | O total exportado é **25.917**. Substituir essa parcela resulta em **26.105**, com mudança em **59 de 181** linhas de 2025 e em **473 de 1.615** linhas da série pareada. |
| `tipo_penal_contra_patrimonio_*` | O commit de junho incluiu no feminino as seis rubricas já previstas no agrupamento paulista. O grupo soma furto simples e qualificado, roubo simples e qualificado, latrocínio e outros do grupo. O agrupamento do RS inclui todas as 13 rubricas do grupo no formulário (`depen.R`, linhas 544–566). | O CSV reproduz as seis rubricas nos três campos. `tipo_penal_contra_patrimonio_feminino` soma **2.764** em 2025. |

## Tratamento no RS e comparação

O [script do RS](../scripts/rs/03b_prisional_derivadas.R#L179) soma as rubricas dos cinco grupos nomeados conforme o formulário. Calcula `outros` como o total geral 5.14 menos a soma desses grupos, por sexo e total, com piso zero. Assim, retirar desarmamento do `outros` paulista corrige uma sobreposição específica, mas ainda deixa uma diferença de composição em relação ao residual gaúcho.

Antes da comparação, acertar com a equipe de SP o conjunto de rubricas de cada grupo, o cálculo de `outros`, o recorte de cela física e o tratamento dos campos ausentes. Recalcular as duas séries a partir da mesma edição da Base Única, testar a reconciliação por sexo e total e verificar quais campos estão conectados aos gráficos. No painel e na nota, identificar a unidade como incidências registradas em pessoas privadas de liberdade.
