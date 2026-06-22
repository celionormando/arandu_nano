// Gera docs/demo.gif — demonstração animada da interface do Arandu.
// Recria a UI (cores reais do chat.html) e "atua" uma conversa pt-BR offline.
//
// Como rodar (a partir desta pasta tools_gif/):
//   npm install @resvg/resvg-js gifenc
//   node gerar_gif.mjs ../docs/demo.gif            # gera o GIF
//   node gerar_gif.mjs ../docs/demo.gif --inspect  # + PNGs de inspeção dos frames-chave
//
// Edite PERGUNTA/RESPOSTA e a timeline (seção "timeline") para mudar a demo.
import { Resvg } from "@resvg/resvg-js";
import pkg from "gifenc";
import fs from "node:fs";
import path from "node:path";
const { GIFEncoder, quantize, applyPalette } = pkg;

const W = 920, H = 575, SB = 262;
const C = {
  bg:"#0d0e10", panel:"#161718", panel2:"#212225", border:"#2a2c30",
  text:"#ececec", muted:"#8e9297", accent:"#4b8bf5", accent2:"#3b7ae0",
  userbg:"#1d1f22", green:"#3fb950", danger:"#e5534b",
};
const FONT = "Segoe UI, -apple-system, Roboto, sans-serif";

const esc = (s) => String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
const approxW = (s, size) => s.length * size * 0.535;
function rect(x,y,w,h,{r=0,fill="none",stroke="",sw=1}={}) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" ry="${r}" fill="${fill}"${stroke?` stroke="${stroke}" stroke-width="${sw}"`:""}/>`;
}
function text(x,y,s,{size=14,fill=C.text,weight=400,anchor="start"}={}) {
  return `<text x="${x}" y="${y}" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${esc(s)}</text>`;
}
// ícone de linha (viewBox 24) posicionado e escalado
function icon(x,y,paths,{scale=0.7,stroke=C.muted,sw=2}={}) {
  const p = paths.map(d=>`<path d="${d}"/>`).join("");
  return `<g transform="translate(${x},${y}) scale(${scale})" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round">${p}</g>`;
}
const IC = {
  pencil:["M12 20h9","M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"],
  search:["M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14z","m21 21-4.3-4.3"],
  book:["M4 19.5A2.5 2.5 0 0 1 6.5 17H20","M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"],
  gear:["M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z","M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-2.82 1.17V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15H4.5a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 6 9.4a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 11 4.6h.09A1.65 1.65 0 0 0 12 3.09V3a2 2 0 1 1 4 0v.09A1.65 1.65 0 0 0 17 4.6a1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"],
  send:["M22 2 11 13","M22 2 15 22 11 13 2 9 22 2z"],
  wifi:["M5 12.55a11 11 0 0 1 14 0","M8.5 16.1a6 6 0 0 1 7 0","M12 20h.01","M2 8.82a15 15 0 0 1 20 0"],
};

// ---- conteúdo da demo ----
const PERGUNTA = "Me dê 3 ideias de jantar rápido";
const RESPOSTA = [
  "Claro! Aqui vão 3 ideias rápidas:",
  "1. Macarrão alho e óleo com brócolis",
  "2. Omelete com queijo e tomate",
  "3. Wrap de frango com salada",
];
const RESP_FULL = RESPOSTA.join("\n");

// monta o SVG de um frame a partir do estado
function frameSVG(st) {
  const left = SB + 38, colW = 560;
  let s = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`;
  s += rect(0,0,W,H,{fill:C.bg});
  // ---- sidebar ----
  s += rect(0,0,SB,H,{fill:C.panel});
  s += `<line x1="${SB}" y1="0" x2="${SB}" y2="${H}" stroke="${C.border}" stroke-width="1"/>`;
  s += text(18,34,"Arandu IA",{size:15,weight:600});
  const items = [["pencil","Nova conversa"],["search","Buscar"],["book","Base de conhecimento"],["gear","Configurações"]];
  let yy = 58;
  for (const [ic,label] of items) {
    s += icon(14,yy,IC[ic],{scale:0.62});
    s += text(42,yy+13,label,{size:13.5,fill:C.text});
    yy += 34;
  }
  s += text(18,yy+18,"CONVERSAS",{size:11,fill:C.muted,weight:600});
  yy += 30;
  s += rect(8,yy-16,SB-16,30,{r:8,fill:C.panel2});
  s += text(18,yy+3,"Ideias de jantar",{size:13.5,fill:C.text});
  // status (dot + texto), embaixo
  const stStr = st.offline ? "100% offline · CPU" : "Conectado";
  s += `<line x1="0" y1="${H-44}" x2="${SB}" y2="${H-44}" stroke="${C.border}" stroke-width="1"/>`;
  s += `<circle cx="20" cy="${H-24}" r="4" fill="${C.green}"/>`;
  s += text(34,H-20,stStr,{size:12,fill:C.muted});

  // ---- topbar ----
  s += `<line x1="${SB}" y1="52" x2="${W}" y2="52" stroke="${C.border}" stroke-width="1"/>`;
  s += text(SB+22,33,"Arandu Nano 1.1",{size:15,weight:600});
  // badge offline (direita) — destaque pulsa via st.glow
  const bw = 150, bx = W-bw-20, by = 14;
  const bstroke = st.glow>0 ? C.green : C.border;
  s += rect(bx,by,bw,26,{r:13,fill:C.panel2,stroke:bstroke,sw:st.glow>0?2:1});
  s += icon(bx+10,by+5,IC.wifi,{scale:0.6,stroke:C.green,sw:2});
  s += text(bx+34,by+17,"Offline · privado",{size:12,fill:C.text});

  // ---- área de chat ----
  let y = 92;
  if (st.messages.length === 0) {
    s += text(SB+(W-SB)/2, 250, "Como posso ajudar?", {size:22,weight:600,anchor:"middle"});
    s += text(SB+(W-SB)/2, 278, "Tudo roda no seu computador, sem internet.", {size:14,fill:C.muted,anchor:"middle"});
  }
  for (const m of st.messages) {
    if (m.role === "user") {
      s += text(left, y, "Você", {size:12,fill:C.muted,weight:600});
      y += 12;
      const tw = Math.min(approxW(m.text,15)+28, colW);
      s += rect(left, y, tw, 40, {r:10, fill:C.userbg, stroke:C.border, sw:1});
      s += text(left+14, y+25, m.text, {size:15});
      y += 40 + 22;
    } else {
      s += text(left, y, "Arandu", {size:12,fill:C.muted,weight:600});
      y += 14;
      if (m.typing) {
        // três pontinhos
        for (let i=0;i<3;i++) s += `<circle cx="${left+6+i*12}" cy="${y+8}" r="3.5" fill="${C.muted}" opacity="${i===st.dot?1:0.4}"/>`;
        y += 26;
      } else {
        const lines = m.text.split("\n");
        for (let i=0;i<lines.length;i++) {
          let ln = lines[i];
          // cursor piscando na última linha durante streaming
          const cursor = (m.streaming && i===lines.length-1) ? (st.caret?" ▌":"  ") : "";
          s += text(left, y+18, ln+cursor, {size:15});
          y += 26;
        }
      }
    }
  }

  // ---- toast "uau" (offline) — canto inferior direito, acima do composer ----
  if (st.toast) {
    const tw = 320, tx = W-tw-24, ty = H-92-44-16;
    s += rect(tx,ty,tw,44,{r:10,fill:"#10240f",stroke:C.green,sw:1});
    s += icon(tx+14,ty+11,IC.wifi,{scale:0.7,stroke:C.green,sw:2});
    s += text(tx+44,ty+20,"Sem internet",{size:14,weight:600,fill:C.green});
    s += text(tx+44,ty+36,"resposta gerada no seu PC",{size:12.5,fill:C.text});
  }

  // ---- composer ----
  const cy = H-72, cx = SB+38, cw = W-SB-38-38;
  s += `<line x1="${SB}" y1="${H-92}" x2="${W}" y2="${H-92}" stroke="${C.border}" stroke-width="1"/>`;
  s += rect(cx,cy,cw-58,46,{r:12,fill:C.panel2,stroke:st.inputFocus?C.accent:C.border,sw:1});
  if (st.input) s += text(cx+14,cy+29, st.input + (st.caret?"▌":""), {size:15});
  else s += text(cx+14,cy+29,"Pergunte alguma coisa…",{size:15,fill:C.muted});
  // botão enviar
  s += rect(W-38-46,cy,46,46,{r:12,fill:C.accent});
  s += icon(W-38-34,cy+11,IC.send,{scale:0.85,stroke:"#fff",sw:2});

  // ---- tagline final ----
  if (st.tagline) {
    s += rect(SB,H-1,W-SB,1,{fill:C.border});
    s += text(SB+(W-SB)/2, H-110, "Arandu — IA 100% offline, em português.", {size:13,fill:C.muted,anchor:"middle"});
  }
  s += `</svg>`;
  return s;
}

// ---- timeline (sequência de estados) ----
const frames = [];
const push = (st, delay) => frames.push({ st:{offline:true, ...st}, delay });

// A) intro
push({ messages:[], input:"", caret:true, inputFocus:true }, 700);
// B) digitando a pergunta no composer
for (let i=1;i<=PERGUNTA.length;i++){
  push({ messages:[], input:PERGUNTA.slice(0,i), caret:i%2===0, inputFocus:true }, 38);
}
push({ messages:[], input:PERGUNTA, caret:true, inputFocus:true }, 350);
// C) enviar -> aparece bolha do usuário
push({ messages:[{role:"user",text:PERGUNTA}], input:"" }, 250);
// D) "Arandu está digitando…"
for (let k=0;k<3;k++) push({ messages:[{role:"user",text:PERGUNTA},{role:"assistant",typing:true}], dot:k%3 }, 220);
// E) streaming da resposta (revela por pedaços)
const tokens = RESP_FULL.split(/(\s+)/); // mantém espaços
let acc = "";
for (let i=0;i<tokens.length;i++){
  acc += tokens[i];
  if (tokens[i].trim()==="" ) continue;
  push({ messages:[{role:"user",text:PERGUNTA},{role:"assistant",text:acc,streaming:true,caret:true}], caret:true }, 95);
}
// F) resposta completa + destaque offline (toast + glow no badge)
push({ messages:[{role:"user",text:PERGUNTA},{role:"assistant",text:RESP_FULL}], glow:1, toast:true }, 1500);
push({ messages:[{role:"user",text:PERGUNTA},{role:"assistant",text:RESP_FULL}], glow:1, toast:true }, 1300);
// G) tagline final (sem toast, para não competir)
push({ messages:[{role:"user",text:PERGUNTA},{role:"assistant",text:RESP_FULL}], glow:1, tagline:true }, 2000);

// ---- render + encode ----
console.log(`Frames: ${frames.length}`);
const enc = GIFEncoder();
let i=0;
for (const f of frames) {
  const svg = frameSVG(f.st);
  const png = new Resvg(svg, { font:{ loadSystemFonts:true }, background:C.bg }).render();
  const data = png.pixels;
  const palette = quantize(data, 128, { format:"rgb565" });
  const index = applyPalette(data, palette, "rgb565");
  enc.writeFrame(index, png.width, png.height, { palette, delay: f.delay, repeat: 0 });
  if (++i % 10 === 0) process.stdout.write(`  ${i}/${frames.length}\r`);
}
enc.finish();
const out = path.resolve(process.argv[2] || "../docs/demo.gif");
fs.writeFileSync(out, enc.bytes());
const mb = (fs.statSync(out).size/1024/1024).toFixed(2);
console.log(`\nOK -> ${out}  (${mb} MB, ${frames.length} frames)`);

// dump de frames-chave como PNG para inspeção visual
if (process.argv[3] === "--inspect") {
  const keys = { intro:0, streaming:42, final:frames.length-2 };
  for (const [name, idx] of Object.entries(keys)) {
    const png = new Resvg(frameSVG(frames[idx].st), { font:{loadSystemFonts:true}, background:C.bg }).render();
    fs.writeFileSync(path.resolve(`inspect_${name}.png`), png.asPng());
  }
  console.log("PNGs de inspeção: inspect_intro.png, inspect_streaming.png, inspect_final.png");
}
