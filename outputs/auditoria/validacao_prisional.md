# Validação da camada prisional — 2026-06-22 09:04

## 1. Cobertura por ano (esperado 104/103/104/103)
  2022: 104 estab  (esperado 104 — OK)
  2023: 103 estab  (esperado 103 — OK)
  2024: 104 estab  (esperado 104 — OK)
  2025: 103 estab  (esperado 103 — OK)

## 2. Óbitos ANUAIS por ano (1º+2º sem) vs baseline antigo (só 2º sem)
  2022: 152 óbitos  (antigo só-2º-sem=69; anual ≥ ✓)
  2023: 102 óbitos  (antigo só-2º-sem=52; anual ≥ ✓)
  2024: 131 óbitos  (antigo só-2º-sem=61; anual ≥ ✓)
  2025: 140 óbitos  (antigo só-2º-sem=81; anual ≥ ✓)
  > Esperado: o total ANUAL é ≥ o antigo (que pegava só o 2º semestre).

## 3. Paridade de nomes com a base do DataStudio de SP
  derivadas-alvo presentes no painel: 26/26 (OK)
  nomes ANTIGOS remanescentes (deviam sumir): nenhum  (OK)

## 4. Checagens de consistência interna
  4a) obitos_total == M+F: 0 linha(s) divergente(s)  (OK)
  4b) tipo_penal_outros >= 0 (residual): 0 negativo(s)  (OK)
  4c) continentes <= estrangeiros: 0 violação(ões)  (OK)  [Σcont=512 ; Σestrangeiros=525]
  4d) faixas de pena presentes: 16/16  (OK) — Σ presos por pena = 142109
