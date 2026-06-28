# =====================================================================
#  Arandu Nano 1.2 - Re-quantizacao com imatrix pt-BR ampliado
# ---------------------------------------------------------------------
#  Gera o Arandu_Nano_1.2_Q4_K_M.gguf a partir do Qwen3-1.7B base,
#  usando uma matriz de importancia calibrada num corpus pt-BR ampliado
#  (juntando treino/imatrix/calibracao_pt.txt + rag/docs/*.txt).
#
#  O ganho sobre a Nano 1.1 e incremental (corpus maior = imatrix mais
#  representativa = melhor preservacao dos pesos ativados em pt-BR). Mesma
#  RAM, mesma velocidade, mesma arquitetura. Pesos novos.
#
#  Pre-requisitos:
#   - llama\llama-imatrix.exe e llama\llama-quantize.exe (ja vem no projeto)
#   - O modelo base de alta precisao: Qwen3-1.7B-Q8_0.gguf (~1,83 GB).
#     Baixe em: https://huggingface.co/Qwen/Qwen3-1.7B-GGUF
#     e coloque na raiz do projeto (mesmo nivel deste arquivo: Arandu-nano\).
#
#  Tempo estimado: 30 min - 2h em CPU (depende do numero de chunks).
#  Uso: PowerShell -ExecutionPolicy Bypass -File regenerar_nano_1.2.ps1
# =====================================================================

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # Arandu-nano\
$BIN_IMATRIX  = Join-Path $ROOT 'llama\llama-imatrix.exe'
$BIN_QUANTIZE = Join-Path $ROOT 'llama\llama-quantize.exe'
$BASE_GGUF    = Join-Path $ROOT 'Qwen3-1.7B-Q8_0.gguf'           # entrada (alta precisao)
$CORPUS_OUT   = Join-Path $PSScriptRoot 'calibracao_pt_v2.txt'   # corpus ampliado
$IMATRIX_OUT  = Join-Path $PSScriptRoot 'imatrix_qwen3_pt_v2.dat'
$SAIDA_GGUF   = Join-Path $ROOT 'Arandu_Nano_1.2_Q4_K_M.gguf'    # saida final

function Falhar($msg) { Write-Host "`n[ERRO] $msg" -ForegroundColor Red; exit 1 }

Write-Host '== Arandu Nano 1.2 - re-quantizacao com imatrix pt-BR ampliado ==' -ForegroundColor Cyan

# 1) Pre-requisitos
if (-not (Test-Path $BIN_IMATRIX))  { Falhar "Nao achei: $BIN_IMATRIX (extraia o llama.cpp em llama\)" }
if (-not (Test-Path $BIN_QUANTIZE)) { Falhar "Nao achei: $BIN_QUANTIZE" }
if (-not (Test-Path $BASE_GGUF)) {
    Falhar "Nao achei o modelo base $($BASE_GGUF). Baixe Qwen3-1.7B-Q8_0.gguf em https://huggingface.co/Qwen/Qwen3-1.7B-GGUF e coloque na raiz."
}

# 2) Monta o corpus ampliado: calibracao_pt.txt + rag/docs/*.txt
Write-Host "`n[1/3] Montando corpus ampliado em $CORPUS_OUT ..." -ForegroundColor Yellow
$partes = @()
$base   = Join-Path $PSScriptRoot 'calibracao_pt.txt'
if (Test-Path $base) { $partes += (Get-Content -Raw -Path $base -Encoding UTF8) }
$ragDocs = Get-ChildItem (Join-Path $ROOT 'rag\docs') -Filter *.txt -ErrorAction SilentlyContinue
foreach ($f in $ragDocs) { $partes += (Get-Content -Raw -Path $f.FullName -Encoding UTF8) }
if ($partes.Count -eq 0) { Falhar 'Nenhum texto de calibracao encontrado.' }
$corpus = ($partes -join "`n`n") + "`n"
[System.IO.File]::WriteAllText($CORPUS_OUT, $corpus, (New-Object System.Text.UTF8Encoding($false)))
$tamKB = [math]::Round((Get-Item $CORPUS_OUT).Length / 1KB, 1)
Write-Host "      corpus = $tamKB KB (juntou calibracao_pt + $($ragDocs.Count) docs do RAG)"
if ($tamKB -lt 50) {
    Write-Host '      AVISO: corpus pequeno (<50 KB). Para um imatrix mais robusto,' -ForegroundColor DarkYellow
    Write-Host '             concatene tambem um corpus pt-BR maior (ex.: wikitext-pt).' -ForegroundColor DarkYellow
}

# 3) Gera a matriz de importancia
Write-Host "`n[2/3] Gerando imatrix (pode levar 10-60 min)..." -ForegroundColor Yellow
& $BIN_IMATRIX -m $BASE_GGUF -f $CORPUS_OUT -o $IMATRIX_OUT --chunks 128 -t 4
if ($LASTEXITCODE -ne 0) { Falhar 'llama-imatrix falhou' }

# 4) Re-quantiza Q8_0 -> Q4_K_M usando o imatrix
Write-Host "`n[3/3] Re-quantizando para Q4_K_M com imatrix (alguns minutos)..." -ForegroundColor Yellow
& $BIN_QUANTIZE --allow-requantize --imatrix $IMATRIX_OUT $BASE_GGUF $SAIDA_GGUF Q4_K_M 4
if ($LASTEXITCODE -ne 0) { Falhar 'llama-quantize falhou' }

Write-Host "`n[OK] Arandu Nano 1.2 gerado em:" -ForegroundColor Green
Write-Host "     $SAIDA_GGUF"
Write-Host "`nProximos passos:"
Write-Host "  1) Para ATIVAR no Arandu, edite o modelo.txt com:"
Write-Host "        Arandu_Nano_1.2_Q4_K_M.gguf"
Write-Host "     (ou crie um Usar_Nano_1.2.bat espelhando os outros .bat)"
Write-Host "  2) Para publicar no Hugging Face (repo novo ou release no mesmo repo),"
Write-Host "     use o huggingface-cli upload (veja README do projeto)."
