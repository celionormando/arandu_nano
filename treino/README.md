# Treino — Arandu Nano 1.0 (modelo próprio)

Kit para criar/fine-tunar o **primeiro modelo do projeto** sobre o Llama-3.2-1B
(open source), gerando um `.gguf` que roda no llamafile na USB.

## Arquivos
- `Arandu_Nano_Finetuning.ipynb` — notebook para o Google Colab (treino + export GGUF).
- `dataset_exemplo.jsonl` — modelo de dados (8 exemplos do domínio TI/PDTI).

## Por que no Colab?
Fine-tuning precisa de GPU. O notebook do Colab dá uma GPU T4 grátis,
suficiente para LoRA de modelos 1B–7B. Treinar na CPU do notebook é inviável.

## Passo a passo
1. Acesse https://colab.research.google.com e abra `Arandu_Nano_Finetuning.ipynb`.
2. Menu **Ambiente de execução → Alterar tipo de ambiente → GPU (T4)**.
3. Rode as células em ordem.
4. Quando pedir, faça upload do seu `dataset.jsonl`.
5. Ao final, baixe o `.gguf` gerado.
6. Copie para `D:\Arandu-nano\`, renomeie para `arandu-nano-1.0-Q4_K_M.gguf`.
7. Edite `D:\Arandu-nano\modelo.txt` com esse nome (1 linha).
8. Em `chat.html`, no mapa `NOMES_MODELO`, adicione:
   `"arandu-nano-1.0-Q4_K_M.gguf":"Arandu Nano 1.0"`
9. Rode o `IA_Portatil.vbs` — agora é o seu modelo próprio rodando.

## O dataset é o que mais importa
A qualidade do modelo vem dos dados. Formato (uma linha JSON por exemplo):

```json
{"messages":[
  {"role":"system","content":"Você é o Arandu, um assistente de IA de uso geral..."},
  {"role":"user","content":"pergunta"},
  {"role":"assistant","content":"resposta ideal"}
]}
```

Dicas:
- Comece com 50–300 exemplos de boa qualidade (conversas, dúvidas e tarefas
  reais do tipo que você quer que o Arandu saiba responder bem).
- Respostas devem ser EXATAMENTE como você quer que o modelo responda
  (tom, formato, correção técnica).
- Pode incluir conversas de vários turnos (mais mensagens no `messages`).
- Mais exemplos bons = modelo melhor. Aumente o `dataset.jsonl` aos poucos.

## Próximas gerações (nomenclatura)
Ver `..\NOMENCLATURA_MODELOS.md`. Arandu (G1 eficiência) → Katu (G2 raciocínio)
→ Vera (G3 multimodal) → Taba (G4 agentes).
