# Arandu IA

Plataforma de IA de chat **100% local e offline**, portátil em pendrive, em
português do Brasil. Roda na CPU, com mínimo de RAM, sem instalar nada no PC.

O **Arandu** é um assistente de IA de **uso geral** (conversa, redação, resumos,
tradução, ideias, dúvidas do dia a dia). O projeto inclui um kit para criar
**modelos próprios** via fine-tuning.

## Componentes
| Arquivo | Função |
|---|---|
| `chat.html` | Interface web em pt-BR (offline): streaming, histórico, voz (TTS) |
| `IA_Portatil.vbs` | Lançador 1 clique: sobe o servidor oculto + janela mínima |
| `modelo.txt` | Define o modelo ativo (1 linha) |
| `Usar_1B_Rapido.bat` / `Usar_3B_Qualidade.bat` | Trocam o modelo ativo |
| `Desligar_IA.bat` | Encerra o servidor |
| `iniciar.bat` / `iniciar_original.bat` | Alternativas com console |
| `treino/` | Kit de fine-tuning (notebook Colab + datasets) |
| `NOMENCLATURA_MODELOS.md` | Famílias de modelos (Arandu/Katu/Vera/Taba) |
| `PLANO.md` | Documentação completa do projeto |

> **Não versionados** (grandes demais para o GitHub): os modelos `.gguf` e o
> `llamafile.exe`. Veja abaixo como obtê-los.

## Como montar (após clonar)
1. **Runtime** — baixe o `llamafile.exe`:
   https://github.com/Mozilla-Ocho/llamafile/releases (renomeie para `llamafile.exe`)
2. **Modelo base** — baixe um GGUF e coloque na pasta:
   - Llama-3.2-1B: https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF
   - Llama-3.2-3B: https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF
   (arquivo `*-Q4_K_M.gguf`)
3. Ajuste o `modelo.txt` com o nome do `.gguf` escolhido.
4. Rode o `IA_Portatil.vbs` (Windows).

## Criar seu próprio modelo (Arandu Nano)
Veja `treino/README.md`: notebook no Google Colab (GPU grátis) que faz
fine-tuning LoRA sobre o Llama-3.2-1B e exporta um `.gguf` Q4_K_M.

## Stack
- Motor: **llamafile** / llama.cpp (Apache-2.0), CPU-only
- Modelo base: **Llama 3.2** (1B/3B) quantizado Q4_K_M
- Treino: **Unsloth** (LoRA/QLoRA) no Google Colab

## Famílias de modelos
Arandu (G1 eficiência) → Katu (G2 raciocínio) → Vera (G3 multimodal) →
Taba (G4 agentes). Detalhes em `NOMENCLATURA_MODELOS.md`.
