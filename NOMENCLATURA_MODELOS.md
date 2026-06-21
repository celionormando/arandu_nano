# Nomenclatura dos Modelos do Projeto

Os modelos próprios (codados sobre open-source) usam nomes de família por geração.
Cada geração/linha tem nome próprio, curto e exclusivo (sem prefixo fixo).

## Família Arandu — Geração 1.0: Fundação e Eficiência
Modelos de entrada, rápidos e de baixo custo computacional.
- Arandu Nano 1.0
- Arandu Mini 1.0
- Arandu Base 1.0
- Arandu Base 1.5

## Família Katu — Geração 2.0: Raciocínio e Desempenho
Modelos avançados para raciocínio lógico, análise e cruzamento de dados.
- Katu Mini 2.0
- Katu Pro 2.0
- Katu Pro 2.5

## Família Vera — Geração 3.0: Alta Capacidade e Visão
Modelos multimodais: leem documentos complexos, imagens e visão computacional.
- Vera Base 3.0
- Vera Omni 3.0

## Família Taba — Geração 4.0: Ecossistema / Agentes
Agentes autônomos, unindo todas as capacidades.
- Taba Base 4.0
- Taba Omni 4.0

---

## Mapeamento atual (base open-source -> nome do projeto)
Definido em chat.html (const NOMES_MODELO). Ao criar/fine-tunar um modelo,
nomeie o .gguf e adicione a entrada no mapa.

| Arquivo GGUF | Nome exibido | Observação |
|---|---|---|
| Qwen_Qwen3-1.7B-Q4_K_M.gguf | Arandu Nano 1.1 | Qwen3-1.7B, **padrão atual** (non-thinking) |
| arandu-nano-1.0-Q4_K_M.gguf | Arandu Nano 1.0 | fine-tune próprio sobre Llama-1B (versão anterior) |
| Llama-3.2-1B-Instruct-Q4_K_M.gguf | Llama 1B (base) | base, rápido/leve |
| Llama-3.2-3B-Instruct-Q4_K_M.gguf | Llama 3B (base) | base, mais qualidade |

O nome técnico do modelo NÃO aparece na interface — só o nome do projeto.
