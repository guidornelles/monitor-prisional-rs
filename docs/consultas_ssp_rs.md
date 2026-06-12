# Consultas a fazer à SSP-RS (dados oficiais)

> Pontos que dependem de explicação/confirmação oficial da Secretaria da Segurança Pública do RS.
> Atualizar com as respostas quando obtidas.

## 1. Furtos de 2022 — déficit no microdado aberto (≈ −24%)
- O microdado aberto `SPJ_..._JAN_DEZ_2022` reproduz homicídio e (quase) roubos, mas os **furtos ficam ~24% abaixo** do "Furto" da tabela oficial de Indicadores Criminais (128.047). Mesmo somando TODOS os enquadramentos com "FURTO" (104.449) fica abaixo. Déficit uniforme nos 12 meses; roubos também levemente baixos; 2023–2025 reconciliam.
- **Perguntar:** o microdado aberto de 2022 saiu incompleto para crimes patrimoniais/furtos? Há versão corrigida? Ou o "Furto" oficial de 2022 usa mapeamento de enquadramentos/fonte diferente do microdado? (Detalhe técnico em `docs/problemas_dados.md`.)

## 2. Estupros — diferença microdado × VCM/agregado
- Identificada diferença sistemática entre a contagem de estupros do microdado e a base de Violência Contra a Mulher / agregado (a relação ~metade já observada, ligada ao escopo Lei Maria da Penha). Falta **explicação oficial** sobre o que cada base contabiliza (universo, sexo da vítima, tipo penal — estupro vs estupro de vulnerável) para documentar a comparação com segurança.
- **Perguntar:** definição exata e universo de cada fonte de estupro (microdado SPJ vs VCM vs Indicadores), para alinhar o conceito usado no Monitor.

---
_Relacionado:_ pontos de comparabilidade com a equipe de SP em `docs/pontos_reuniao_equipe_sp.md`.
