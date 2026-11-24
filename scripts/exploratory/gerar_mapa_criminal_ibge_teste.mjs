import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

// Protótipo independente: lê os artefatos de teste, sem alterar a pipeline canônica.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const defaultDir = path.join(root, 'outputs/temp/mapa_criminal_ibge_teste_2026-11-23');
const opts = {};
for (let i = 2; i < process.argv.length; i++) {
  const key = process.argv[i];
  if (key === '--help') {
    console.log('node scripts/exploratory/gerar_mapa_criminal_ibge_teste.mjs [--geo arquivo.geojson] [--fatos arquivo.csv] [--agua arquivo.geojson] [--saida arquivo.html]');
    process.exit(0);
  }
  if (!['--geo', '--fatos', '--agua', '--saida', '--template'].includes(key) || !process.argv[i + 1]) throw new Error(`Argumento inválido: ${key}`);
  opts[key.slice(2)] = path.resolve(process.argv[++i]);
}
const files = {
  geo: opts.geo || path.join(defaultDir, 'geo_municipios_rs_2022.geojson'),
  fatos: opts.fatos || path.join(defaultDir, 'fatos_criminais.csv'),
  agua: opts.agua || path.join(defaultDir, 'contexto_lagoas_ibge_2022.geojson'),
  template: opts.template || path.join(root, 'scripts/exploratory/templates/mapa_criminal_ibge_teste.html'),
  saida: opts.saida || path.join(defaultDir, 'mapa_criminal_ibge_teste.html'),
};
for (const key of ['geo', 'fatos', 'agua', 'template']) if (!fs.existsSync(files[key])) throw new Error(`Insumo não encontrado (${key}): ${files[key]}`);

function csv(text) {
  const rows = []; let row = [], value = '', quoted = false;
  text = text.replace(/^\uFEFF/, '');
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      if (quoted && text[i + 1] === '"') { value += '"'; i++; }
      else quoted = !quoted;
    } else if (c === ',' && !quoted) { row.push(value); value = ''; }
    else if ((c === '\n' || c === '\r') && !quoted) {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(value); value = '';
      if (row.some(x => x !== '')) rows.push(row);
      row = [];
    } else value += c;
  }
  if (quoted) throw new Error('CSV com aspas não fechadas.');
  if (value !== '' || row.length) { row.push(value); rows.push(row); }
  const headers = rows.shift();
  if (!headers || new Set(headers).size !== headers.length) throw new Error('Cabeçalho CSV ausente ou repetido.');
  return rows.map((r, i) => {
    if (r.length !== headers.length) throw new Error(`CSV: linha ${i + 2} tem ${r.length} campos, esperados ${headers.length}.`);
    return Object.fromEntries(headers.map((h, j) => [h, r[j]]));
  });
}
function numeric(value, label) {
  if (value === '' || value === null || value === undefined || value === 'NA') return null;
  const n = Number(value);
  if (!Number.isFinite(n)) throw new Error(`Valor numérico inválido em ${label}: ${value}`);
  return n;
}
function flag(value) {
  if (value === '' || value === undefined || value === null || value === 'NA') return null;
  if (/^true$/i.test(value)) return true;
  if (/^false$/i.test(value)) return false;
  throw new Error(`Indicador lógico inválido: ${value}`);
}
function geometryStats(features) {
  let vertices = 0, polygons = 0, holes = 0;
  for (const f of features) {
    const g = f.geometry;
    if (!g || !['Polygon', 'MultiPolygon'].includes(g.type)) throw new Error(`Geometria não poligonal: ${g?.type}`);
    const parts = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
    for (const rings of parts) {
      polygons++; holes += Math.max(0, rings.length - 1);
      for (const ring of rings) for (const coordinate of ring) {
        if (!Number.isFinite(coordinate[0]) || !Number.isFinite(coordinate[1])) throw new Error('Coordenada inválida.');
        vertices++;
      }
    }
  }
  return { vertices, polygons, holes };
}
const geo = JSON.parse(fs.readFileSync(files.geo, 'utf8'));
const water = JSON.parse(fs.readFileSync(files.agua, 'utf8'));
if (geo.type !== 'FeatureCollection' || geo.features.length !== 497) throw new Error('Esperadas 497 feições municipais.');
if (water.type !== 'FeatureCollection' || water.features.length !== 2) throw new Error('Esperadas duas geometrias de águas de contexto.');
const ids = new Set();
for (const f of geo.features) {
  const id = String(f.properties.id_municipio);
  if (!/^\d{7}$/.test(id) || ids.has(id)) throw new Error(`Código municipal inválido ou repetido: ${id}`);
  ids.add(id); f.properties.id_municipio = id;
  if (!f.properties.nome || !f.properties.regiao) throw new Error(`Município sem nome/região: ${id}`);
}
const rawFacts = csv(fs.readFileSync(files.fatos, 'utf8'));
const keys = new Set();
const facts = rawFacts.map(r => {
  const id = String(r.id_municipio), year = numeric(r.ano, 'ano');
  if (!ids.has(id) || ![2022, 2023, 2024, 2025].includes(year) || !r.indicador) throw new Error(`Chave fora do universo: ${id}/${year}/${r.indicador}`);
  const key = `${id}|${year}|${r.indicador}`;
  if (keys.has(key)) throw new Error(`Fato repetido: ${key}`);
  keys.add(key);
  return {
    id_municipio: id, ano: year, indicador: r.indicador,
    quantidade: numeric(r.quantidade, 'quantidade'), populacao: numeric(r.populacao, 'populacao'),
    taxa: numeric(r.taxa, 'taxa'), taxa_original: r.taxa,
    quantidade_informada: flag(r.quantidade_informada), meses_informados: numeric(r.meses_informados, 'meses_informados'),
  };
});
const indicators = [...new Set(facts.map(r => r.indicador))].sort((a, b) => a.localeCompare(b, 'pt-BR'));
if (indicators.length !== 6 || facts.length !== 497 * 4 * 6) throw new Error(`Grade criminal incompleta: ${facts.length} fatos e ${indicators.length} indicadores.`);
const stats = geometryStats(geo.features), waterStats = geometryStats(water.features);
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const payload = {
  meta: {
    projeto: 'Monitor Prisional RS — teste cartográfico', data_prototipo: '2026-11-23', generated_at: new Date().toISOString(),
    ano_malha: 2022, anos: [2022, 2023, 2024, 2025], municipios: 497,
    indicadores: indicators, geometry: stats, agua: waterStats,
    fontes: ['IBGE — malha municipal 2022', 'SSP-RS — indicadores e registros de flagrante', 'Sinesp VDE — mandados cumpridos', 'IBGE — população do Censo 2022'],
    arquivos: Object.fromEntries(['geo', 'fatos', 'agua'].map(k => [k, { arquivo: path.basename(files[k]), sha256: sha(files[k]) }])),
    nota: 'As taxas são os valores originais dos fatos. Não há recálculo ou agregação regional. Geometrias e anéis são preservados; projeção Mercator apenas para exibição.',
  },
  geo, water, facts,
};
const template = fs.readFileSync(files.template, 'utf8');
if (template.split('__MONITOR_PAYLOAD_JSON__').length !== 2) throw new Error('Template precisa de um único marcador de dados.');
const json = JSON.stringify(payload).replace(/</g, '\\u003c').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
const html = template.replace('__MONITOR_PAYLOAD_JSON__', json);
fs.mkdirSync(path.dirname(files.saida), { recursive: true });
fs.writeFileSync(files.saida, html, 'utf8');
console.log(JSON.stringify({ arquivo: files.saida, bytes: Buffer.byteLength(html), municipios: ids.size, fatos: facts.length, indicadores: indicators.length, agua: water.features.length, geometria: stats, sem_quantidade_informada: facts.filter(x => x.quantidade_informada === false).length }, null, 2));
