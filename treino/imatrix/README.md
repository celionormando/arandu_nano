# Quantização com imatrix (matriz de importância)

O `Qwen_Qwen3-1.7B-Q4_K_M.gguf` distribuído no Arandu Mirim 1.1 foi
re-quantizado com uma **matriz de importância (imatrix)** calibrada em
**português do Brasil**. Isso preserva com mais precisão os pesos mais
relevantes do modelo durante a quantização de 4 bits.

## Por que isso ajuda

A quantização Q4_K_M comum trata todos os pesos da mesma forma. Com o
imatrix, o quantizador sabe **quais pesos são mais ativados** ao processar
texto em português e os preserva com mais qualidade. O resultado:

- **Mesma RAM** (mesmo formato Q4_K_M, ~1.0 GB)
- **Mesma velocidade** (~14 tok/s na CPU)
- **Qualidade ligeiramente melhor**, especialmente em português

O ganho não está no arquivo do repositório (o `.gguf` não é versionado).
Quem clonar o projeto e baixar o Qwen3-1.7B padrão pode **regenerar** o
modelo calibrado seguindo os passos abaixo.

## Como regenerar

Pré-requisitos: as ferramentas `llama-imatrix` e `llama-quantize` do
[llama.cpp](https://github.com/ggml-org/llama.cpp/releases) (binários CPU).
No Windows, se os executáveis forem bloqueados pelo SmartScreen, rode pelo
WSL (Ubuntu) — foi assim que o modelo oficial foi gerado.

### 1. Baixe o modelo base de alta precisão (Q8_0)

```sh
# Fonte: https://huggingface.co/Qwen/Qwen3-1.7B-GGUF
# arquivo: Qwen3-1.7B-Q8_0.gguf  (~1.83 GB)
```

### 2. Gere a matriz de importância com a calibração em português

```sh
llama-imatrix \
  -m Qwen3-1.7B-Q8_0.gguf \
  -f calibracao_pt.txt \
  -o imatrix_qwen3_pt.dat \
  --chunks 128 -t 4
```

> A `calibracao_pt.txt` (nesta pasta) cobre IA, fatos do Brasil, ciência,
> história e linguagem cotidiana — o mesmo domínio em que o Arandu atua.
> Para um imatrix mais robusto, concatene também um corpus maior em
> português (ex.: wikitext-pt) antes de rodar.

### 3. Re-quantize Q8_0 -> Q4_K_M usando o imatrix

```sh
llama-quantize \
  --allow-requantize \
  --imatrix imatrix_qwen3_pt.dat \
  Qwen3-1.7B-Q8_0.gguf \
  Qwen_Qwen3-1.7B-Q4_K_M.gguf \
  Q4_K_M 4
```

### 4. Substitua o modelo na raiz do projeto

Copie o `Qwen_Qwen3-1.7B-Q4_K_M.gguf` gerado para a pasta `Arandu-nano/`,
sobrescrevendo o anterior. O `modelo.txt` e os lançadores já apontam para
esse nome de arquivo — nada mais precisa mudar.

## Validação rápida

```sh
llamafile.exe -m Qwen_Qwen3-1.7B-Q4_K_M.gguf --cli \
  -p "Em uma frase: Santos Dumont era brasileiro ou frances?"
# Esperado: "Santos Dumont era brasileiro."
```

## Atalho: gerar a Arandu Mirim 1.2 (script automatizado)

Os passos 2 e 3 acima estão automatizados em [`regenerar_nano_1.2.ps1`](regenerar_nano_1.2.ps1).
O script monta um **corpus ampliado** (`calibracao_pt.txt` + `rag/docs/*.txt`),
roda o `llama-imatrix` e o `llama-quantize`, e salva o resultado como
`Arandu_Nano_1.2_Q4_K_M.gguf` na raiz do projeto.

```powershell
# Pré-requisito: baixar Qwen3-1.7B-Q8_0.gguf (~1,83 GB) na raiz do projeto.
# Fonte: https://huggingface.co/Qwen/Qwen3-1.7B-GGUF
PowerShell -ExecutionPolicy Bypass -File treino\imatrix\regenerar_nano_1.2.ps1
```

Tempo total: 30 min – 2 h em CPU (depende de `--chunks`). Para ativar a 1.2 no
Arandu, edite `modelo.txt` apontando para `Arandu_Nano_1.2_Q4_K_M.gguf`.

> **Honestidade sobre o ganho:** a 1.2 será **incrementalmente** melhor que a 1.1
> em pt-BR (corpus de calibração 3× maior, mesmo domínio). Não é um novo
> fine-tune — para um salto real de qualidade, o caminho é ampliar
> `treino/dataset_arandu.jsonl` (hoje ~40 exemplos) para 200+ e re-treinar no
> Colab usando `treino/Arandu_Nano_Finetuning.ipynb`.

## Variante rápida: Q4_0 com repack AVX2/AVX-512 (Otimização B)

CPUs Intel/AMD modernos rendem **15–25% mais tok/s** com Q4_0 do que com Q4_K_M
porque o llama.cpp faz **repack automático** dos pesos na carga, reordenando
para casar com a microarquitetura (Q4_0_8_8 em AVX-512, Q4_0_4_8 em AVX2).

```powershell
# Pré-requisito: Qwen3-1.7B-Q8_0.gguf na raiz (mesmo do regenerar_nano_1.2)
PowerShell -ExecutionPolicy Bypass -File treino\imatrix\regenerar_nano_q4_0.ps1
```

O script detecta seu CPU e avisa o ganho esperado. Saída: `Arandu_Nano_1.1_Q4_0.gguf`
na raiz. Para ativar, edite `modelo.txt` ou use `Usar_Nano_Q4_0.bat`.

> **Trade-off honesto:** Q4_0 tem **qualidade ligeiramente menor** que Q4_K_M
> (perplexidade ~3–5% pior). A imatrix pt-BR compensa boa parte. Se você notar
> respostas piores em pt-BR, volte para `Usar_Nano_1.1.bat`. CPUs **sem AVX2**
> não ganham — pode até ficar pior; o script avisa.
