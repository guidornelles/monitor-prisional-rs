# Auditoria — erro de cálculo no `tipo_penal_desarmamento` do Monitor SP (dado divulgado)

> Demonstração de que a planilha **divulgada** (`Base_Sisdepen.xlsx` do repositório do Monitor SP)
> contém o erro de cálculo identificado no script `depen.R` — não se trata de versão desatualizada do script.

## O erro (no script)
Em `depen.R` (branches `sem_01` e `R`), o cálculo de `tipo_penal_desarmamento_*` soma **apenas** a coluna
"Porte ilegal de arma de fogo de uso permitido (Art. 14)". Os demais quatro tipos do Estatuto do Desarmamento
— Disparo (Art. 15), Posse/porte restrito (Art. 16), Comércio ilegal (Art. 17), Tráfico internacional (Art. 18) —
aparecem como argumentos "soltos" dentro do `mutate` (sem `+`), portanto **não entram** no somatório.
Esses quatro tipos são somados em `tipo_penal_outros_*`, **inflando "outros"** e **subcontando "desarmamento"**.

## A auditoria (no dado divulgado)
- **Publicado:** `tipo_penal_desarmamento_masculino` do `Base_Sisdepen.xlsx` (Monitor SP; SP, 2017–2023, 1º sem).
- **Recomposição:** colunas brutas 5.14 do Estatuto do Desarmamento (Masculino, Arts. 14/15/16/17/18) da
  **Base Única SISDEPEN** (SENAPPEN), para os mesmos estabelecimentos (chave `id = Nome-SP-ano`, Referência `AAAA/1`).
- **Resultado (1.071 estabelecimentos pareados):**
  - publicado **== apenas Art.14** (fórmula bugada): **1.071 / 1.071**
  - publicado **== soma dos 5 tipos** (correto): **0 / 1.071**
  - casos em que Art.14 ≠ soma-dos-5 (erro visível): **501**; destes, publicado bate com Art.14 em **501** e com a soma em **0**.

**Conclusão:** o erro está presente no dado **divulgado**, não apenas no script. `desarmamento` está subcontado e
`outros` superestimado no Monitor SP. (Por simetria do código, `desarmamento_feminino` e `_total` têm o mesmo padrão;
auditável da mesma forma se necessário.)

## Achado ampliado — `tipo_penal` é inconsistente de forma sistêmica (não um bug isolado)
Além do desarmamento, a inspeção da branch `R` (atual) mostra:
- `tipo_penal_contra_patrimonio_feminino`: mesmo padrão de colunas soltas (só "Furto simples" somado; resto fica de fora).
- `tipo_penal_contra_pessoa_total`: último termo é de "Crimes **contra o patrimônio** | Outros... | **Masculino**" (grupo e sexo errados).
- **Composição dos grupos muda entre versões:** na `sem_01`, "contra o patrimônio" incluía estelionato, extorsão, apropriação indébita e receptação; na `R`, não (só furto/roubo/latrocínio/outros).
- Conclusão: definir o `tipo_penal_*` correto exige **fixar a composição canônica de cada grupo** — decisão metodológica, comparabilidade-crítica, a combinar com SP.

## Verificação de versões (branches do repositório SP)
Checadas as branches `sem_01`, `R` (=origin/R) e `origin/sem_02` (=origin/depen). Em **todas**, o
`tipo_penal_desarmamento_*` soma só "Porte (Art.14)" (demais tipos soltos, com `,` em vez de `+`),
e persistem os bugs de `tipo_penal_contra_patrimonio_feminino` (só "Furto simples"),
`tipo_penal_contra_pessoa_total` (termo de "contra o patrimônio | Masculino" dentro do total) e
`tipo_penal_outros_feminino` (`,+` + bloco solto). A `sem_02`/`R` corrigiram o grupo **drogas** e os
`_masculino` de pessoa/patrimônio/dignidade, mas **não** o desarmamento nem os `_feminino`/`_total` citados.
Conclusão: não há nas branches uma versão limpa do `tipo_penal`; e o erro do desarmamento chega ao dado divulgado (auditado acima).

## Implicação para o RS (paridade)
- Ao implementar `tipo_penal_desarmamento_*` para o RS, há duas opções: (a) **corrigir** (somar os 5 tipos) e documentar
  a divergência em relação ao Monitor SP; (b) **replicar** o bug para bater com SP. Recomendado: (a) + levar o achado à equipe de SP.
- Método de auditoria reaproveitável para validar outras variáveis derivadas (publicado vs recomposição da Base Única).
