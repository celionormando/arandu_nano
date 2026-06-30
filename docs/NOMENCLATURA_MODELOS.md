# Nomenclatura dos Modelos do Projeto

A **Rendeia** é a plataforma — a "rendeira" que tece ideias localmente, offline,
no pendrive. Dentro dela, os modelos são organizados em três camadas:

```
Rendeia                        ← MARCA / plataforma
  ├─ Famílias por capacidade  ← geração (G1..G4)
  │   ├─ Arandu  (G1 — Eficiência)
  │   ├─ Katu    (G2 — Raciocínio)
  │   ├─ Vera    (G3 — Multimodal)
  │   └─ Taba    (G4 — Agentes)
  └─ Tier por tamanho         ← consistente entre famílias
      ├─ Mirim   (pequeno / rápido)        — em tupi-guarani: "pequeno"
      ├─ Eté     (médio / equilíbrio)      — em tupi-guarani: "verdadeiro"
      └─ Guaçu   (grande / qualidade)      — em tupi-guarani: "grande"
```

**Nome completo** (formal): `Rendeia Arandu Mirim 1.1`
**Nome curto** (uso comum): `Arandu Mirim 1.1`

> Inspiração: a marca **Rendeia** une *renda* (tradição artesã brasileira, trama,
> tecido) e *ideia* (intelecto, IA). O nome remete também ao bordado **ñanduti**
> (guarani: "teia de aranha") — uma metáfora direta da rede neural.

## Famílias

### Arandu — Geração 1.0: Fundação e Eficiência
Modelos de entrada, rápidos e de baixo custo computacional.
- **Arandu Mirim 1.0** — fine-tune próprio sobre Llama-1B (versão anterior)
- **Arandu Mirim 1.1** — Qwen3-1.7B + imatrix pt-BR (padrão atual)
- Arandu Eté 1.x — planejado (modelo maior, ~3B, quando viável em CPU+USB)
- Arandu Guaçu 1.x — planejado (~7B)

### Katu — Geração 2.0: Raciocínio e Desempenho
Modelos avançados para raciocínio lógico, análise e cruzamento de dados.
Pensam antes de responder (geram um bloco `<think>` interno).

- **Katu Mirim 2.0** — disponível (DeepSeek-R1-Distill-Qwen-1.5B). Mesma RAM do
  Arandu Mirim 1.1; foco em raciocínio. Coexiste, ativado pelo `Usar_Katu_Mini.bat`.
- Katu Eté 2.x — planejado
- Katu Guaçu 2.x — planejado

### Vera — Geração 3.0: Alta Capacidade e Visão
Modelos multimodais: leem documentos complexos, imagens e visão computacional.
- Vera Eté 3.0 — planejado
- Vera Guaçu 3.0 — planejado

### Taba — Geração 4.0: Ecossistema / Agentes
Agentes autônomos, unindo todas as capacidades.
- Taba Eté 4.0 — planejado
- Taba Guaçu 4.0 — planejado

---

## Mapeamento atual (arquivo GGUF → nome do projeto)

Definido em `chat.html` (`const NOMES_MODELO`). Ao criar/fine-tunar um modelo,
nomeie o `.gguf` e adicione a entrada no mapa.

| Arquivo GGUF | Nome exibido | Observação |
|---|---|---|
| `Qwen_Qwen3-1.7B-Q4_K_M.gguf` | **Arandu Mirim 1.1** | Qwen3-1.7B, **padrão atual** (non-thinking) |
| `Arandu_Nano_1.1_Q4_0.gguf` | Arandu Mirim 1.1 Q4_0 | mesmo modelo, quant Q4_0 c/ repack AVX-512/AVX2 (~20% mais tok/s) |
| `arandu-nano-1.0-Q4_K_M.gguf` | Arandu Mirim 1.0 | fine-tune próprio sobre Llama-1B (versão anterior) |
| `DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf` | **Katu Mirim 2.0** | **G2 — Raciocínio** (pensa antes; mesma RAM do Arandu Mirim 1.1) |
| `Llama-3.2-1B-Instruct-Q4_K_M.gguf` | Llama 1B (base) | base, rápido/leve |
| `Llama-3.2-3B-Instruct-Q4_K_M.gguf` | Llama 3B (base) | base, mais qualidade |

> **Nota sobre nomes de arquivo:** os `.gguf` mantêm seu nome técnico/legado
> (`Qwen_Qwen3-1.7B-Q4_K_M.gguf`, `Arandu_Nano_1.1_Q4_0.gguf`) — o que muda é
> apenas o **nome exibido** na interface. Renomear arquivos quebraria scripts
> e cache; o mapa em `NOMES_MODELO` faz a tradução.

O nome técnico do modelo NÃO aparece na interface — só o nome do projeto.

---

## Sobre o nome anterior "Nano"

Antes da reestruturação, o tier menor da família Arandu se chamava **Nano**
(termo da indústria de IA). A partir da v1.3, foi renomeado para **Mirim** —
mantendo coerência cultural com o resto da nomenclatura tupi-guarani (Arandu,
Katu, Eté, Guaçu) e com a marca Rendeia.

Para o usuário final isso é transparente: os arquivos `.bat` continuam com os
mesmos nomes (`Usar_Nano_1.1.bat`, etc.) por compatibilidade.
