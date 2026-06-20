// Regenera rag/index.js a partir de TODOS os arquivos .txt em rag/docs/.
//
// O index.js e' o indice pre-construido que o chat.html carrega automaticamente
// para o IndexedDB (auto-load por versao). Sempre que voce adicionar, remover ou
// editar um documento em rag/docs/, rode este script para reconstruir o indice.
//
// Pre-requisito: o servidor de EMBEDDING precisa estar no ar (porta 8091).
//   - Windows:      duplo clique em IA_Arandu_RAG.vbs (sobe chat + embedding)
//   - Linux/macOS:  ./iniciar_rag.sh
//
// Uso:
//   node rag/gerar_indice.mjs
//   (opcional) EMBED_URL=http://127.0.0.1:8091 node rag/gerar_indice.mjs
//
// A logica de chunk e de quantizacao int8 e' identica a do chat.html, para que o
// indice gerado seja compativel com a busca feita no navegador.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const EMBED_URL = (process.env.EMBED_URL || "http://127.0.0.1:8091").replace(/\/$/, "");
const HERE = path.dirname(fileURLToPath(import.meta.url));
const DOCS = path.join(HERE, "docs");
const OUT = path.join(HERE, "index.js");

// divide o texto em trechos (~700 chars com sobreposicao) — igual ao chat.html
function chunkText(t) {
  t = t.replace(/\r\n/g, "\n").trim();
  const paras = t.split(/\n{2,}/);
  const chunks = [];
  let buf = "";
  for (const p of paras) {
    if ((buf + "\n\n" + p).length > 700) { if (buf) chunks.push(buf.trim()); buf = p; }
    else buf = buf ? buf + "\n\n" + p : p;
    while (buf.length > 900) { chunks.push(buf.slice(0, 800).trim()); buf = buf.slice(700); }
  }
  if (buf.trim()) chunks.push(buf.trim());
  return chunks.filter((c) => c.length > 20);
}

// embedding -> vetor normalizado em int8 -> base64 — igual ao chat.html
async function embedInt8B64(text) {
  const r = await fetch(EMBED_URL + "/v1/embeddings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ input: text }),
  });
  if (!r.ok) throw new Error("embedding HTTP " + r.status);
  const j = await r.json();
  const v = j.data[0].embedding;
  let n = 0; for (const x of v) n += x * x; n = Math.sqrt(n) || 1;
  const u = new Uint8Array(v.length);
  for (let i = 0; i < v.length; i++) {
    let q = Math.round(v[i] / n * 127);
    q = q > 127 ? 127 : q < -128 ? -128 : q;
    u[i] = q & 0xff; // int8 em complemento de dois
  }
  return { b64: Buffer.from(u).toString("base64"), dim: v.length };
}

async function main() {
  const files = fs.readdirSync(DOCS).filter((f) => f.endsWith(".txt")).sort();
  if (!files.length) { console.error("Nenhum .txt encontrado em", DOCS); process.exit(1); }

  const chunks = [];
  let dim = 1024;
  try {
    for (const f of files) {
      const texto = fs.readFileSync(path.join(DOCS, f), "utf8");
      const cs = chunkText(texto);
      console.log(`  ${f}: ${cs.length} trecho(s)`);
      for (const c of cs) {
        const { b64, dim: d } = await embedInt8B64(c);
        dim = d;
        chunks.push({ fonte: f, texto: c, vec: b64 });
      }
    }
  } catch (e) {
    console.error("\nFalha ao gerar embeddings:", e.message);
    console.error("O servidor de embedding esta no ar (porta 8091)?");
    console.error("Inicie pelo IA_Arandu_RAG.vbs (Windows) ou ./iniciar_rag.sh (Linux/macOS).");
    process.exit(2);
  }

  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  const version = `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}${p(d.getHours())}${p(d.getMinutes())}`;
  const obj = { chunks, version, dim };
  fs.writeFileSync(OUT, "window.ARANDU_INDEX=" + JSON.stringify(obj) + ";\n", "utf8");
  console.log(`OK: ${chunks.length} trecho(s) de ${files.length} arquivo(s) -> ${OUT}`);
  console.log(`    version=${version}  dim=${dim}`);
}

main();
