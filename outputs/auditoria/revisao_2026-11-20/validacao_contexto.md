# Validação do contexto e das taxas

Referências: Censo 2022; PIB municipal em mil reais correntes; Inep Total/Total.

- OK — Cadastro e contexto têm os mesmos municípios, sem chaves repetidas
- OK — Cadastro RS contém oito regiões intermediárias
- OK — Regiões do contexto correspondem ao cadastro IBGE
- OK — Contexto reproduz a fonte: populacao
- OK — Contexto reproduz a fonte: pib
- OK — Contexto reproduz a fonte: distorcao_idade_serie_fund
- OK — Denominadores municipais positivos
- OK — Três fontes com ano e hash registrados
- OK — Manifesto corresponde aos arquivos efetivamente lidos e seus hashes
- OK — Cabeçalho do PIB informa mil reais correntes, sem rótulo legado em reais
- OK — Exportação mantém valores do PIB na escala original
- OK — Exportação mantém a população do Censo 2022
- OK — Exportação mantém o Inep do ano fixado
- OK — Criminal tem uma linha por município/ano e grade completa
- OK — Denominador criminal é o Censo fixado, sem duplicação
- OK — Taxa por 100 mil = numerador / Censo 2022: hd_vitima
- OK — Taxa por 100 mil = numerador / Censo 2022: hd_ocorrencias
- OK — Taxa por 100 mil = numerador / Censo 2022: tot_estupro
- OK — Taxa por 100 mil = numerador / Censo 2022: roubo_outros
- OK — Taxa por 100 mil = numerador / Censo 2022: furto_outros
- OK — Taxa por 100 mil = numerador / Censo 2022: prisoes
- OK — Taxa por 100 mil = numerador / Censo 2022: mandados_cumpridos
- OK — Exportação criminal tem seis indicadores por município/ano, sem duplicatas
- OK — Exportação preserva numerador, denominador e taxa: hd_vitima
- OK — Exportação preserva numerador, denominador e taxa: tot_estupro
- OK — Exportação preserva numerador, denominador e taxa: roubo_outros
- OK — Exportação preserva numerador, denominador e taxa: furto_outros
- OK — Exportação preserva numerador, denominador e taxa: prisoes
- OK — Exportação preserva numerador, denominador e taxa: mandados_cumpridos

Resultado: 0 falha(s).
A validação não altera as regras de cobertura nem equipara automaticamente os universos de SP e RS.
