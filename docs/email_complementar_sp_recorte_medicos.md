# Consulta complementar à equipe SP — recorte prisional e médicos

> Rascunho para revisão de Guilherme. Não enviado.

**Assunto:** Monitor Prisional RS–SP — esclarecimentos adicionais sobre os dados do SISDEPEN

Olá, Fernando e Marlon,

Complementando meu e-mail anterior, gostaria de confirmar alguns pontos sobre o tratamento dos dados do SISDEPEN, para definir uma base comum de comparação entre os monitores de SP e do RS.

**1. População, vagas e estabelecimentos em cela física**

No RS, optamos por considerar apenas o recorte de cela física, deixando de fora os registros domiciliares e de monitoramento eletrônico. No [`depen.R` de SP, revisão `45c7144`, linhas 27–42](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/depen.R#L27-L42), o filtro seleciona a UF, sem restringir o tipo de recolhimento.

Na tabela do Monitor de SP que tenho como referência, essa diferença aparece a partir de 2020. Considerando o primeiro semestre de cada ano, há 12 cadastros domiciliares monitorados adicionais em 2020, 15 em 2021 e um por ano de 2022 a 2025. Em 2017–2019, os totais coincidem com o recorte de cela física.

Em 2025, por exemplo, a tabela reúne 214.159 pessoas e 164.753 vagas. Restringindo a “Cela física” na [Base Única do SISDEPEN](https://www.gov.br/senappen/pt-br/servicos/sisdepen/bases-de-dados), seriam 213.401 pessoas e 156.753 vagas. A diferença vem de um cadastro de “Domiciliar com monitoramento eletrônico”, que informa 758 pessoas e 8 mil vagas. Portanto, sua inclusão altera tanto a população quanto a capacidade utilizadas no cálculo da ocupação.

Essa inclusão é intencional nos gráficos de população, capacidade e ocupação de SP? Para o comparativo, podemos trabalhar com o recorte de cela física nos dois estados?

**2. Cadastros de monitoramento no segundo semestre de 2021**

Separadamente, encontramos no segundo semestre de 2021 seis grupos em que o nome de uma unidade aparece em três cadastros: um sem menção a monitoramento, outro com “MONITORAMENTO ELETRÔNICO - CELA FÍSICA” e outro com “MONITORAMENTO ELETRÔNICO - DOMICILIAR”. Esse padrão já aparece na [planilha paulista do 11º ciclo](https://github.com/NEV-USP/MonitorPrisional2024/blob/4db9d98a83f1c80fa7e73746578e14b42690ef8f/11o-ciclo-base-de-dados-2021-2-semestre.xlsx).

Na Base Única, por exemplo, o CDP II da Chácara Belém tem um cadastro com 1.246 pessoas (ID 1301), um de monitoramento em cela física com 14 pessoas (ID 5730) e um domiciliar com uma pessoa (ID 4489). Os dois cadastros de monitoramento não informam endereço, e o ID 5730 está classificado no tipo de recolhimento “Cela física”.

Isso não permite concluir que haja repetição de pessoas, mas deixa uma dúvida sobre a relação entre os registros. Vocês sabem se eles representam parcelas distintas da população sob responsabilidade da unidade? Como esses cadastros devem entrar nos indicadores do Monitor?

**3. Categorias médicas**

O [`depen.R` de SP, revisão `45c7144`, linhas 353–355](https://github.com/NEV-USP/MonitorPrisional2024/blob/45c714419387a1b85f92df459de7399a7dedaec5/depen.R#L353-L355), seleciona três categorias médicas do quesito 3.1: clínicos gerais, psiquiatras e outras especialidades. No RS, somamos também ginecologistas, mantendo as quatro categorias.

Vocês podem confirmar quais categorias alimentam o gráfico de médicos e se a ausência do campo de ginecologistas nessa seleção é intencional?

Obrigado pela ajuda!

Guilherme Souza
Doutorando em Políticas Públicas — UFRGS
