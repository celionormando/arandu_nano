# Quantização com imatrix (matriz de importância)

O `Qwen_Qwen3-1.7B-Q4_K_M.gguf` distribuído no Arandu Nano 1.1 foi
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
