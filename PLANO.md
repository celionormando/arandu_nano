# Arandu IA — Plano do Projeto (IA Portátil na USB)

## Objetivo
Plataforma de IA de chat chamada **Arandu IA**, que roda 100% LOCAL e OFFLINE
direto do pendrive (D:\Arandu-nano\), em português do Brasil, com o MÍNIMO de RAM
sem perder velocidade. FOCO: portabilidade na USB (sem instalar nada no PC) e
evolução com modelos próprios (fine-tuning).

## Identidade do Arandu
- O **Arandu** é um **assistente de IA de USO GERAL** (conversa, redação,
  resumos, tradução, ideias, dúvidas do dia a dia).
- NÃO é especializado em contratações/PDTI. SEM vínculo a InfraSA, GPCTI ou
  qualquer organização. Identidade neutra.

## Hardware alvo
- Notebook 16 GB de RAM (sobrou ~2,4 GB livres no teste); 4 núcleos físicos /
  8 lógicos; sem GPU (roda só na CPU).

## Tecnologia (motor)
- **llamafile v0.10.3** (Mozilla-Ocho): runtime + servidor num único .exe portátil.
  Open source (Apache-2.0), construído sobre o llama.cpp.
- Releases: https://github.com/Mozilla-Ocho/llamafile/releases

## Nomenclatura dos modelos (famílias) — ver NOMENCLATURA_MODELOS.md
- **Arandu** (G1.0 Fundação/Eficiência): Nano, Mini, Base, Base 1.5
- **Katu**  (G2.0 Raciocínio): Mini, Pro, Pro 2.5
- **Vera**  (G3.0 Multimodal/Visão): Base, Omni
- **Taba**  (G4.0 Agentes): Base, Omni
A interface mostra o NOME DO PROJETO (mapa NOMES_MODELO no chat.html), nunca o
arquivo técnico.

## Modelo ATIVO
- **Qwen_Qwen3-1.7B-Q4_K_M.gguf** — PADRÃO atual, exibido como "Arandu Nano 1.1".
  Qwen3-1.7B (~1,2 GB), ~12 tok/s, em modo non-thinking (/no_think injetado pelo
  chat.html só p/ Qwen). Escolhido após teste A/B: melhor qualidade que o 1B
  (e-mail, contas, explicações) mantendo velocidade e RAM. Troca: Usar_Nano_1.1.bat.
- **arandu-nano-1.0-Q4_K_M.gguf** — 1º modelo PRÓPRIO (fine-tune do Llama-1B), ~0,8 GB,
  ~14-17 tok/s. Exibido como "Arandu Nano 1.0". Troca: Usar_Nano_1.0.bat.
- Numeração: o 3º número marca a evolução da linha de entrada (Nano 1.0 -> 1.1 -> ...).
  "Mini"/"Base" ficam reservados para portes maiores (3-4B+) no futuro.
- **Iniciar_Arandu.vbs** abre direto no **Nano 1.1** (sem menu): garante o modelo padrão
  em modelo.txt e só reinicia o servidor se a versão estiver diferente. Para trocar de
  modelo manualmente, use os .bat (Usar_Nano_1.0.bat etc.).
- Modelos de base disponíveis para fallback/treino:
  - Llama-3.2-1B-Instruct-Q4_K_M.gguf  (base do Arandu Nano)
  - Llama-3.2-3B-Instruct-Q4_K_M.gguf  (mais qualidade, ~6 tok/s)
- DESCARTADOS: Phi-3.5-mini, 3B-Q3_K_L e Gemma-2-2B (este incompatível com
  flash-attn por causa do "attention softcapping" — só roda bem sem -fa, perdendo
  velocidade e RAM).

## Estrutura no pendrive
D:\Arandu-nano\
  ├── llamafile.exe                       (runtime, ~320 MB)
  ├── arandu-nano-1.0-Q4_K_M.gguf         (modelo PRÓPRIO ativo, ~0,8 GB)
  ├── Llama-3.2-1B-Instruct-Q4_K_M.gguf   (base, ~0,8 GB)
  ├── Llama-3.2-3B-Instruct-Q4_K_M.gguf   (base qualidade, ~2,0 GB)
  ├── modelo.txt                          (define o modelo ativo - 1 linha)
  ├── chat.html                           (interface Arandu IA, pt-BR, offline, com VOZ)
  ├── IA_Portatil.vbs                     (Windows: abre navegador padrão, lê modelo.txt)
  ├── IA_Arandu_RAG.vbs                   (Windows: chat + embedding/RAG)
  ├── iniciar.sh / iniciar_rag.sh         (Linux/macOS: navegador padrão)
  ├── desligar.sh                         (Linux/macOS: encerra servidores)
  ├── Usar_1B_Rapido.bat / Usar_3B_Qualidade.bat (trocam o modelo ativo)
  ├── Desligar_IA.bat
  ├── iniciar.bat / iniciar_original.bat  (alternativas com console)
  ├── NOMENCLATURA_MODELOS.md
  ├── treino\                             (kit de fine-tuning - ver abaixo)
  └── PLANO.md

## Como usar
- Windows: duplo clique em IA_Portatil.vbs -> sobe o servidor ESCONDIDO
  (sem console) e abre no navegador padrão. Independe da letra do drive.
  Desligar: Desligar_IA.bat.
- Linux/macOS: `chmod +x iniciar.sh iniciar_rag.sh desligar.sh` uma vez; depois
  `./iniciar.sh` para chat normal ou `./iniciar_rag.sh` para RAG. A interface abre
  no navegador padrão via `xdg-open` (Linux) ou `open` (macOS).
- Trocar modelo: editar modelo.txt (ou usar os .bat de troca). Reabrir a IA.
- Voz: botão na barra do chat ou Configurações -> lê as respostas com a síntese
  de voz disponível no navegador/sistema.

## Flags otimizadas (servidor)
  -c 2048   contexto / -t 3 threads (1 núcleo livre = mais rápido aqui) / -fa on
  -ctk q8_0 -ctv q8_0  (KV cache 8-bit, ~metade da RAM do contexto, sem perder qualidade)
  -ub 256 -b 512  (batch menor) / --gpu disable (só CPU)

## Conclusões dos testes (com dados reais)
1. RAM já no PISO: ~400 MB comprometidos (pesos via mmap, descartáveis). Não dá
   pra cortar mais sem perder qualidade (KV q4) ou contexto (-c 1024).
2. USB NÃO é o gargalo: USB vs SSD deu quase igual (~5,2 vs ~5,5 tok/s). Não vale
   copiar pro SSD; portabilidade mantida.
3. Gargalo é a CPU; MENOS threads é mais rápido neste notebook:
   -t 2 ~6,0 | -t 3 ~6,0-6,4 (escolhido) | -t 4 ~5,5 | -t 6/8 ~3,1. Deixar 1
   núcleo livre rende ~10-15%.
4. Quantização: Q4_K_M é o sweet spot. Q3 NÃO acelera nem economiza RAM relevante
   na CPU; i-quants (IQ) são MAIS LENTAS na CPU. O lever real é o nº de parâmetros
   (1B vs 3B), não o nível de quantização.
5. Auto-rodar ao plugar o USB NÃO é possível no Windows 10/11 (segurança). O VBS
   de 1 clique é o mais próximo disso.
6. Observação de RAM: contexto padrão (4096) não cabe ("failed to create context");
   usar -c 2048 (ou 1024 se faltar memória).

## Fine-tuning (modelo próprio) — kit em treino\
- Base: Llama-3.2-1B. Treino: **Unsloth no Google Colab** (GPU T4 grátis), LoRA.
- Arquivos: Arandu_Nano_Finetuning.ipynb, dataset_arandu.jsonl (~40 ex. gerais),
  dataset_exemplo.jsonl, README.md.
- Lições aprendidas (já corrigidas no notebook):
  - Usar **SFTConfig** (não TrainingArguments) + save_strategy="no" +
    report_to="none" -> evita PicklingError ao salvar.
  - Exportar GGUF: Unsloth salva em subpasta `<nome>_gguf/` -> usar glob recursivo.
  - Download do .gguf: via **Google Drive** (files.download falha p/ arquivos grandes).
- Trazer p/ USB: baixar .gguf -> renomear arandu-nano-1.0-Q4_K_M.gguf -> ajustar
  modelo.txt -> adicionar no mapa NOMES_MODELO do chat.html.
- O que mais importa: AMPLIAR o dataset (50 -> 200 -> 500+ exemplos de qualidade).

## Memória que aprende (camadas, tudo no USB) — IMPLEMENTADO
Objetivo: o Arandu aprender com o uso (perfil do usuário + conhecimento) SEM depender
só do RAG, respeitando o contexto de 2048 tokens. Padrão: **índice + expansão sob demanda**
(o mesmo "stub & hydrate" de um MEMORY.md): no prompt vai sempre só o ESSENCIAL; o detalhe
entra quando é solicitado e sai depois, liberando espaço.
- Armazenamento (no pendrive, privado, fora do git): `memoria\`
  - `perfil.md`   -> essencial do usuário (vai SEMPRE no system prompt; manter curto)
  - `indice.json` -> mapa [{id,titulo,resumo,palavras,tipo,atualizado}] (vai SEMPRE; barato)
  - `itens\<id>.md` -> detalhe completo de cada item (hidratado SÓ quando a pergunta casa)
- Persistência: rotas novas no ajudante 8099 (`saude_sistema.ps1`), pois o chat é file://
  e o navegador não grava em disco sozinho:
  GET `/memoria` · GET `/memoria/item?id=` · POST `/memoria/perfil` · POST `/memoria/item`
  · POST `/memoria/remover`. IDs validados (sem path traversal); UTF-8 sem BOM.
  (Corrigido: preflight CORS no OPTIONS — Allow-Headers Content-Type — p/ POST JSON de file://.)
- No chat.html: carrega a memória no início; o roteador leve (`memRotear`, por palavra-chave,
  SEM embedding) casa a pergunta com 1–2 IDs e hidrata o detalhe; injeta perfil + índice +
  detalhe no system. Painel "Memória" (sidebar/topo) p/ ver/editar perfil e itens.
- Aprendizado automático barato (sem 2ª passada do modelo): captura comandos do usuário
  ("meu nome é...", "lembre-se que...", "anote que...") e grava na hora.
- Upload de DOCUMENTOS (no painel Memória): arrastar/escolher .pdf, imagens, .txt/.md/.csv/.json/.log ->
  vira item tipo "D" no USB. O texto fica fora do prompt; na pergunta, hidrata SÓ o trecho
  relevante (`memTrechoRelevante` quebra em blocos e escolhe os que casam, cabe no orçamento).
  Palavras-chave do doc (até 40, `memPalavrasChave`) são só p/ roteamento -> não custam tokens.
  Limite ~120k chars.
- PDF digital: extraído com **pdf.js** (empacotado em `vendor/pdfjs\`, ~1,5 MB), carregado SÓ
  quando chega um PDF (não pesa no boot). Worker pré-carregado como global -> roda na thread
  principal quando o navegador bloqueia Web Worker (caso do file://).
- OCR (imagens e PDF escaneado): rota `/ocr` no ajudante 8099 roda o **Tesseract** portátil
  (ferramentas\tesseract\, baixado à parte como o Piper; idiomas via tessdata). O navegador
  manda a imagem (PDF escaneado é rasterizado por página com o pdf.js) e recebe o texto, que
  entra no mesmo fluxo de itens. Sem Tesseract -> 503 e aviso amigável. Descartado o
  baidu/Unlimited-OCR (3B, 6,78 GB, exige GPU/CUDA — fere RAM/velocidade/portabilidade). Word ainda não.
  Limitação conhecida: termo MUITO raro num doc grande pode não ser roteado pelo índice de
  palavras -> é aí que o RAG por embedding (camada semântica, mais cara) complementa.
- Camadas (custo sob as premissas de RAM/velocidade/2048): perfil+conversas = baratas e
  automáticas; fine-tune = barato em runtime (conhecimento recorrente vai p/ os pesos);
  RAG = o mais caro (2º modelo na RAM + come contexto) -> só sob demanda.

## Multilíngue — IMPLEMENTADO
- O cérebro (Qwen3) já é multilíngue: custa **zero RAM extra**, custa só ~25 tokens
  no prompt para "trancar" o idioma. Default = **auto** (preserva comportamento atual).
- `cfg.idioma` (auto/pt/en/es/fr/de) com seletor em Configurações; injeta `IDIOMAS[k].instr`
  curta no system. Identidade do Arandu neutralizada ("a partir de um pendrive", sem fixar
  o idioma; "ou equivalente em outro idioma" para "o que é o Arandu").
- Captura automática multilíngue: regex de "meu nome é / my name is / me llamo / je
  m'appelle / ich heisse" e "lembre-se / remember / recuerda / souviens-toi / merke dir".
- Voz: `vozEscolhida()` prefere voz do sistema que case com o BCP-47 do idioma escolhido
  (en-US/es-ES/fr-FR/de-DE); cai em pt-BR se não houver. Piper só tem pt-BR; outros idiomas
  via Web Speech do SO sem peso extra no USB.

## Status
1. [x] Motor llamafile + interface Arandu IA (chat.html, pt-BR, voz, streaming fluido)
2. [x] Lançador 1 clique (IA_Portatil.vbs, navegador padrão) + troca de modelo (modelo.txt)
3. [x] Otimizações (KV q8_0, flash attn, -t 3) e benchmarks documentados
4. [x] Nomenclatura de famílias (Arandu/Katu/Vera/Taba) definida
5. [x] MARCO: 1º modelo próprio treinado e implantado — **Arandu Nano 1.0** rodando na USB
6. [ ] Ampliar dataset e retreinar o Arandu Nano (melhorar qualidade)
7. [x] MARCO: memória em camadas (perfil + índice + itens sob demanda) gravada no USB,
       com aprendizado automático por comando + UPLOAD de documentos (PDF/imagem/texto):
       pdf.js p/ PDF digital, Tesseract (rota /ocr) p/ imagem e PDF escaneado, com
       seleção de trecho relevante — testado de ponta a ponta
8. [x] MARCO: multilíngue (auto/pt/en/es/fr/de) — seletor em Configurações, captura
       automática de memória nos 5 idiomas, voz do SO pelo BCP-47 do idioma escolhido

## Roadmap
1. [x] TTS leve (Web Speech API) — falar respostas.
2. [ ] Ampliar dataset -> Arandu Nano 1.x melhor; depois Arandu Mini/Base.
3. [ ] TTS de alta qualidade OFFLINE: Piper (vozes pt-BR ~60 MB, cabe na USB).
4. [ ] Voz de ENTRADA (falar com a IA): whisperfile (STT offline) ou Web Speech.
5. [ ] RAG (conhecimento via documentos): CAMADA acima da API (embeddings ->
       vetores -> injeta no prompt). NÃO exige forkar o motor; pode ser no chat.html.
6. [ ] Controle do motor: llamafile/llama.cpp são Apache-2.0; compilar do fonte
       só se quiser alterar a lógica de inferência (RAG e fine-tuning não precisam).
7. [ ] Gerações futuras: Katu (raciocínio), Vera (multimodal), Taba (agentes).
