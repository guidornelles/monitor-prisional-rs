# Atualização do mapa para o último ano validado — 23/11/2026

O processamento, os testes locais e a conferência no Data Studio foram concluídos. O mapa e a tabela usam a referência 2025/1 no mesmo relatório e página, preservando a configuração de cores e vínculos.

## Regra do recorte

- Manter cela física e o estoque do primeiro semestre, segundo `cfg$anos_prisional` e `cfg$escolhas$prisional_semestre`.
- Derivar `mapa_ultimo_ano_validado` como coluna lógica verdadeira somente no ano `max(cfg$anos_prisional)`; na janela vigente, **2025/1 e 103 estabelecimentos**.
- A flag acompanha a janela configurada e a atualização da fonte. Ampliar o período exige ajustar a configuração, executar, validar e carregar os dados; a passagem do calendário não amplia a janela.
- A edição da Base Única contém ambos os semestres, mas o mapa não passa a usar 2025/2. Cadastros exclusivos desse segundo semestre não integram o estoque selecionado.
- Manter separados o ciclo do cadastro SISDEPEN, a consulta dos vínculos administrativos em **13/11/2026** e o ano de inauguração usado no controle da página.
- Preservar o campo de cores por ID, os agrupamentos existentes e a identificação de endereços compartilhados. Ausência de ano de inauguração não deve ser preenchida por inferência nem excluir definitivamente o estabelecimento da consulta abrangente.

## Histórico preservado

A [conferência de 13/11](../candidata_2026-11-13/README.md#mapa-prisional) registrou 104 unidades do cadastro 2024 e o cruzamento com vínculos administrativos consultados em 13/11/2026. Essa evidência antecede a mudança atual e permanece válida como registro daquela versão. Não foi localizada justificativa metodológica para manter 2024 como regra permanente.

## Processamento e controles

A execução isolada usa `outputs/temp/mapa_ultimo_ano_2026-11-23`. Os arquivos da implementação são:

- [`R/funcoes_mapa_prisional.R`](../../../R/funcoes_mapa_prisional.R): auxiliar da seleção do último ano configurado.
- [`05_planilha_final.R`](../../../scripts/rs/05_planilha_final.R): acrescenta a flag lógica ao final da tabela prisional, na coluna 552 do CSV.
- [`07_validacao_prisional.R`](../../../scripts/rs/07_validacao_prisional.R): confere campo, tipo lógico, ausência de faltantes, vetor exato, quantidade e IDs contra o estoque independente do primeiro semestre; sinaliza ciclos posteriores à janela configurada presentes na fonte.
- [`scripts/tests/test_mapa_prisional.R`](../../../scripts/tests/test_mapa_prisional.R): testes específicos do contrato do mapa, executados da raiz com `Rscript scripts/tests/test_mapa_prisional.R`.

O [guia do pipeline](../../../scripts/rs/README.md#atualizar-o-mapa-para-o-último-ano-validado) descreve o fluxo. Os testes específicos foram concluídos: o snapshot de 927 linhas e 551 colunas recebeu a flag em memória, passando a 552 colunas, com 103 valores verdadeiros em 2025/1. Todos os 551 vetores anteriores permaneceram idênticos em valores e classes. Passaram também os cenários de mudança 2024 → 2025 → 2026, lacunas e adulterações.

A execução integral de `run_all.R` terminou em **97,8 segundos**, com `05`, `07` e `08` sem falhas. A tabela exportada tem 927 linhas e 552 colunas, com 103 flags verdadeiras. A [validação prisional da execução](validacao_prisional.md) aprovou os cinco controles do mapa: marcador na última coluna, lógico e sem ausências, ano igual ao máximo configurado, quantidade e IDs iguais ao estoque independente do primeiro semestre. A [regressão das colunas anteriores](regressao_colunas_prisionais.csv) confirmou os 551 vetores preservados em valores e classes nas 927 linhas. A [validação de contexto](validacao_contexto.md) terminou com zero falhas. Estes três relatórios compactos foram copiados da execução e tiveram igualdade SHA-256 conferida; os dados de conexão permanecem no diretório temporário da equipe.

Os controles confirmaram o tipo lógico, a ausência de valores faltantes da flag, a seleção de um único ano igual ao máximo configurado, o universo de 103 IDs de 2025/1 e a preservação das 551 colunas e valores anteriores. Os casos sem ano de inauguração devem continuar no universo de origem. Em 2025/1, os 103 valores de inauguração estão presentes e vão de 1924 a 2023.

## Conexão e teste de leitura concluídos

Antes da escrita, a metainformação da aba `prisional` foi conferida: grade com 551 colunas, terminando em `UC:UE` com `atendimento_odonto`, `cela_gestantes` e `quantidade_lactantes`. O campo nativo `UF` está em O (15), com valores `RS`; o mapa usa um `CASE` de vínculos por ID. A flag foi acrescentada à posição 552, preservando as colunas existentes, o ID da planilha, a aba e a associação por chave.

A [conferência da coluna na planilha](conferencia_flag_google_sheets.json) confirmou 927 valores lógicos, sendo 103 verdadeiros e 824 falsos; o campo nativo `UF` em O foi preservado. Os esquemas das fontes `ds68` e `ds467` foram sincronizados. O filtro existente do mapa `estabelecimentos_mapa` passou a exigir `mapa_ultimo_ano_validado = TRUE` e também foi aplicado ao controle de inauguração. Na tabela, o filtro exclusivo `depen_24`, com condição de ano 2024, foi convertido no filtro `mapa_tabela_ultimo_ano_validado`, cuja condição é `mapa_ultimo_ano_validado = TRUE`. Não foi criado um filtro literal de ano 2025.

A expressão `UF` no nome do arquivo histórico `drpp_mapa_coluna_UF_prisional.tsv`, de 13/11, refere-se à **letra de coluna da planilha** (posição 552), distinta do nome do campo nativo de unidade federativa. Esse artefato não comprova recodificação do campo nativo `UF` nem descreve a grade observada antes da atualização de 23/11. A configuração de cores e vínculos por ID foi preservada; os arquivos históricos permanecem intactos.

O mínimo configurado do controle de inauguração passou de 1950 para **1924**; o máximo ficou automático em **2023**, e a seleção padrão permaneceu vazia, sem restrição inicial. A tabela abriu em **1–100/103**. O teste de 2003–2023 retornou **19 registros**, e **Redefinir** restaurou **103**, entre 1924 e 2023. A legenda mostrou 12 categorias, sem vínculo não confirmado. Como todos os anos de inauguração estão presentes em 2025/1, o teste real não contém um caso de ano ausente; a regra de preservação dessas ausências continua válida para futuras edições.

A [prova textual da página](conferencia_painel.json) registra filtros, limites, testes e o texto aplicado:

> O mapa mostra os estabelecimentos do Rio Grande do Sul registrados no primeiro semestre de 2025 no SISDEPEN, segundo o ano de inauguração. As cores indicam o vínculo administrativo consultado em 13/11/2026. Pontos com vínculos diferentes no mesmo endereço têm uma cor própria.

Os [103 IDs e suas cores](ids_cores_2025_1.csv), as [contagens das 12 categorias](contagem_categorias_cor.csv) e o [CASE por ID preservado](vinculo_regional_atual_looker.txt) permitem conferir a classificação. A [diferença para o recorte de 2024](ids_ausentes_2025_1.csv) contém somente o ID 1121, Instituto Penal de Santa Maria, ausente em 2025/1. Os 103 registros não equivalem a 103 marcadores distintos, pois há endereços compartilhados.
