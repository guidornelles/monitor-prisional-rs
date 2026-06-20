#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera o DOCX editável da Síntese de Indicadores no MESMO estilo do PDF
(A4 paisagem, cabeçalhos verdes, links azuis). Compartilha o conteúdo com
gerar_sintese_pdf.py. Edições jun/2026: ponto 5 reescrito, ponto 7 novo.

Uso: python3 gerar_sintese_docx.py SAIDA.docx
"""
import sys
from docx import Document
from docx.shared import Pt, RGBColor, Inches, Twips
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

GREEN = RGBColor(0x27, 0x4E, 0x15)
LINK  = RGBColor(0x11, 0x55, 0xCC)
BLACK = RGBColor(0, 0, 0)
GRAY  = RGBColor(0x44, 0x44, 0x44)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
GREEN_HEX = "274E15"
GRID_HEX  = "BFBFBF"

# ---- conteúdo (espelha o gerador de PDF) ----
HDR = ["Indicador (Monitor SP)", "Fonte (Monitor SP)", "Período (SP)",
       "Fonte(s) possível(is) no RS", "Abrangência territorial (RS)",
       "Cobertura e granularidade temporal (RS)", "Link — SSP-RS"]
blocks = [
 ("Panorama Populacional","IBGE — Censos Demográficos","Decenal (desde a déc. de 1970)",
   [("IBGE — Censos (fonte nacional)","Municipal","Decenal","ibge.gov.br")]),
 ("Panorama Econômico (PIB)","IBGE — PIB dos municípios","Anual, desde 2010",
   [("IBGE — PIB municípios (nacional)","Municipal","Desde 2010 · anual","ibge.gov.br")]),
 ("Panorama de Saúde (tuberculose, hepatite, HIV e mortalidade)","DATASUS / Ministério da Saúde","Anual, desde 2018",
   [("DATASUS / Min. da Saúde (nacional)","Municipal","Desde 2018 · anual","datasus.saude.gov.br")]),
 ("Panorama Educacional (taxa de distorção idade-série)","INEP","Anual",
   [("INEP (nacional)","Municipal","Anual","gov.br/inep")]),
 ("Homicídio doloso","SSP-SP — ocorrências (Consultas)","Anual, desde 2001",
   [("Indicadores Criminais (tabela agregada)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais (Dados Abertos)","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos")]),
 ("Estupro (todos os tipos, incl. vulnerável; ambos os sexos)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Microdados Mensais — total, ambos os sexos (comparável a SP)","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos"),
    ("Violência Contra a Mulher — recorte da Lei Maria da Penha (relações familiares/íntimas); ~metade do total","Municipal","Desde 2012 · anual (mensal desde 2018)","ssp.rs.gov.br/indicadores-da-violencia-contra-a-mulher")]),
 ("Roubo (categoria \"outros\": exclui veículo, banco, carga)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Indicadores Criminais — \"Roubos\" (já exclui veículo; inclui banco/comércio)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais — reconstrução estrita do \"outros\"","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos")]),
 ("Furto (categoria \"outros\": exclui veículo, banco)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Indicadores Criminais — \"Furtos\" (exclui veículo; inclui abigeato e banco/comércio)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais — reconstrução estrita do \"outros\"","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos")]),
 ("Armas de fogo apreendidas","SSP-SP — Dados de Produtividade","Anual, desde 2001",
   [("Indicadores de Atividade (PC + BM)","Estadual","Desde 2007 · mensal (soma PC+BM consistente a partir de 2017)","ssp.rs.gov.br/indicadores-de-atividade"),
    ("Dados Abertos — Lei 15.610, Art. 6º, Inc. VII","Estadual","Desde 2021 · diário (registros com data)","ssp.rs.gov.br/dados-abertos")]),
 ("Prisões efetuadas (Polícia Civil: flagrantes lavrados + mandados cumpridos)","SSP-SP — Dados de Produtividade","Anual, desde 2001",
   [("Dados Abertos — Lei 15.610, Inc. IX (flagrantes lavrados pela PC)","Municipal","Desde 2021 · diário (registros com data)","ssp.rs.gov.br/dados-abertos"),
    ("Indicadores de Atividade (flagrantes + presos por mandados, PC)","Estadual","Desde 2007 · mensal (consistente a partir de 2017)","ssp.rs.gov.br/indicadores-de-atividade")]),
 ("Dados Prisionais (SISDEPEN: capacidade/lotação, perfil, saúde, educação, trabalho, morbidade/mortalidade, etc.)","SISDEPEN / SENAPPEN","Semestral, desde 2017",
   [("SISDEPEN / SENAPPEN (fonte nacional)","Município + estabelecimento","Desde 2017 · semestral","gov.br/senappen")]),
]
col_w_in = [1.05, 1.02, 0.78, 2.10, 0.70, 1.66, 1.23]  # polegadas (~9.5in úteis)

TITLE = "Monitor do Sistema Prisional — síntese de indicadores e fontes equivalentes no RS"
INTRO = ("Para cada indicador do Monitor de SP: fonte e período usados em SP; fonte(s) "
         "correspondente(s) publicada(s) pela SSP-RS; abrangência territorial e cobertura/"
         "granularidade temporal de cada fonte no RS; e o link da página da SSP-RS. "
         "Documento de trabalho — junho/2026.")
# (texto, negrito) por trecho
FOOT = [("Fontes: ",True),
        ("elaborado por Guilherme Souza (2026) a partir da Nota Metodológica do Monitor do Sistema "
         "Prisional (NEV-USP), das páginas de estatísticas da SSP-RS (Indicadores Criminais, Dados "
         "Abertos – Lei 15.610, Indicadores da Violência Contra a Mulher, Indicadores de Atividade) "
         "e dos dicionários de dados oficiais. As equivalências criminais foram validadas por "
         "reconciliação dos microdados com as tabelas oficiais (2023 e 2024).",False)]

# pontos: lista de trechos (texto, negrito)
points = [
 [("1. Estupro — qual fonte no comparativo SP↔RS? ",True),
  ("O microdado Mensal traz o estupro total (ambos os sexos), comparável à definição de SP, mas só "
   "desde 2022. A série da Violência Contra a Mulher é mais longa (desde 2012), porém — conforme o "
   "Observatório da Violência Contra a Mulher (SSP-RS) — cobre o recorte da Lei Maria da Penha "
   "(relações familiares/íntimas), correspondendo a ~metade do total (correlação municipal 0,99 com "
   "o microdado). A confirmar na fonte primária do Observatório.",False)],
 [("2. Prisões no mapa. ",True),
  ("Exibir no mapa apenas o componente de flagrante (municipalizado, Inc. IX), mantendo o total "
   "estadual completo (flagrantes + mandados)? Ou solicitar à SSP-RS o componente de mandados com "
   "município?",False)],
 [("3. Roubo/furto \"outros\". ",True),
  ("Usar a aproximação via tabela agregada (série desde 2002, mas inclui banco/comércio) ou a "
   "reconstrução estrita via microdado (idêntica à definição de SP, porém só desde 2022)?",False)],
 [("4. Confirmar com a equipe de SP ",True),
  ("a definição de \"prisões efetuadas\" (Polícia Civil: flagrantes lavrados + mandados cumpridos), "
   "conforme levantamento documental (Res. SSP-SP nº 160/2001).",False)],
 [("5. Recorte regional. ",True),
  ("Embora a Nota Metodológica do Monitor de SP fale em macrorregiões administrativas, as regiões "
   "exibidas no painel correspondem às 11 regiões geográficas intermediárias do estado de São Paulo, "
   "conforme o IBGE. O RS tem recortes próprios (RISP/COREDEs), não equivalentes. Definir se a "
   "comparação será municipal/estadual, tratando \"região\" à parte.",False)],
 [("6. Base de comparação. ",True),
  ("Comparar por ",False),("taxas (por 100 mil habitantes) e tendências",True),
  (", não por números absolutos, exibindo a janela temporal válida de cada indicador.",False)],
 [("7. Homicídios — vítimas ou ocorrências? ",True),
  ("É possível contabilizar o homicídio doloso de duas formas: por número de vítimas ou por número "
   "de ocorrências. A Nota Metodológica do Monitor de SP indica ocorrências, mas os scripts e a "
   "visualização do DataStudio parecem indicar vítimas. Confirmar com a equipe de SP qual medida "
   "efetivamente alimenta o Monitor.",False)],
]
NOTE_HEAD = "Nota sobre a coluna \"Cobertura e granularidade temporal\""
NOTE = [("A coluna mostra a ",False),("cobertura",True),(" (de que ano) e a ",False),
        ("menor unidade de desagregação",True),
        (" (dia/mês/ano/semestre) — distinta da ",False),("frequência de publicação",True),
        (" (ex.: os Dados Abertos saem semestralmente, mas têm registros com data, desagregáveis por "
         "dia). Como o Monitor de SP usa dado ",False),("anual",True),
        (", qualquer fonte do RS pode ser agregada à unidade temporal de SP; as restrições reais à "
         "comparação são o ",False),("ano de início",True),(" e a ",False),
        ("abrangência territorial",True),(" (município × estadual).",False)]

# ---------- helpers ----------
def set_cell_bg(cell, hexfill):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd"); shd.set(qn("w:val"),"clear")
    shd.set(qn("w:color"),"auto"); shd.set(qn("w:fill"),hexfill)
    tcPr.append(shd)

def set_cell_borders(cell):
    tcPr = cell._tc.get_or_add_tcPr()
    b = OxmlElement("w:tcBorders")
    for edge in ("top","left","bottom","right"):
        e = OxmlElement("w:"+edge)
        e.set(qn("w:val"),"single"); e.set(qn("w:sz"),"4")
        e.set(qn("w:space"),"0"); e.set(qn("w:color"),GRID_HEX)
        b.append(e)
    tcPr.append(b)

def cell_text(cell, text, *, bold=False, color=BLACK, size=7.5, align_left=True):
    cell.vertical_alignment = WD_ALIGN_VERTICAL.TOP
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0); p.paragraph_format.space_before = Pt(0)
    r = p.add_run(text)
    r.font.size = Pt(size); r.font.bold = bold; r.font.color.rgb = color
    r.font.name = "Arial"

def add_runs(p, parts, size=8, color=BLACK):
    for txt, bold in parts:
        r = p.add_run(txt)
        r.font.size = Pt(size); r.font.bold = bold; r.font.name = "Arial"
        r.font.color.rgb = color

def build(path):
    doc = Document()
    sec = doc.sections[0]
    sec.orientation = WD_ORIENT.LANDSCAPE
    sec.page_width, sec.page_height = Inches(11.69), Inches(8.27)  # A4 paisagem
    sec.left_margin = sec.right_margin = Inches(0.5)
    sec.top_margin = sec.bottom_margin = Inches(0.45)
    # default font
    doc.styles["Normal"].font.name = "Arial"; doc.styles["Normal"].font.size = Pt(8)

    # título
    p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(2)
    r = p.add_run(TITLE); r.font.bold=True; r.font.size=Pt(15); r.font.color.rgb=GREEN; r.font.name="Arial"
    # intro
    p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(6)
    r = p.add_run(INTRO); r.font.size=Pt(7.5); r.font.color.rgb=GRAY; r.font.name="Arial"

    # tabela
    nrows = 1 + sum(len(b[3]) for b in blocks)
    tbl = doc.add_table(rows=nrows, cols=7)
    tbl.allow_autofit = False
    for j,w in enumerate(col_w_in):
        for i in range(nrows):
            tbl.cell(i,j).width = Inches(w)
    # header
    for j,h in enumerate(HDR):
        c = tbl.cell(0,j); set_cell_bg(c, GREEN_HEX); set_cell_borders(c)
        cell_text(c, h, bold=True, color=WHITE, size=7.5)
    # corpo
    ri = 1
    for a,b,c,subs in blocks:
        r0 = ri
        for k,s in enumerate(subs):
            for j in range(7): set_cell_borders(tbl.cell(ri,j))
            cell_text(tbl.cell(ri,3), s[0], size=7.5)
            cell_text(tbl.cell(ri,4), s[1], size=7.5)
            cell_text(tbl.cell(ri,5), s[2], size=7.5)
            cell_text(tbl.cell(ri,6), s[3], color=LINK, size=7.5)
            ri += 1
        # primeiras 3 colunas: mescla vertical se múltiplas subrows
        for j,val in ((0,a),(1,b),(2,c)):
            top = tbl.cell(r0,j)
            if len(subs) > 1:
                top = top.merge(tbl.cell(ri-1,j))
            cell_text(top, val, bold=(j==0), size=7.5)

    # rodapé Fontes
    p = doc.add_paragraph(); p.paragraph_format.space_before = Pt(6)
    add_runs(p, FOOT, size=7)

    # quebra de página -> decisões
    doc.add_page_break()
    p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(3)
    r = p.add_run("Decisões e perguntas para o grupo"); r.font.bold=True; r.font.size=Pt(11); r.font.color.rgb=GREEN; r.font.name="Arial"
    for parts in points:
        p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(4)
        add_runs(p, parts, size=8)
    # nota
    p = doc.add_paragraph(); p.paragraph_format.space_before=Pt(8); p.paragraph_format.space_after=Pt(3)
    r = p.add_run(NOTE_HEAD); r.font.bold=True; r.font.size=Pt(11); r.font.color.rgb=GREEN; r.font.name="Arial"
    p = doc.add_paragraph(); add_runs(p, NOTE, size=8)

    doc.save(path)

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv)>1 else "Sintese_Indicadores_Monitor_SP_RS.docx"
    build(out); print("OK ->", out)
