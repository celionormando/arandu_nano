# =====================================================================
#  Arandu Nano 1.1 Q4_0 — re-quantizacao para CPUs com AVX2/AVX-512
# ---------------------------------------------------------------------
#  Gera Arandu_Nano_1.1_Q4_0.gguf a partir do Qwen3-1.7B-Q8_0.gguf base,
#  usando a MESMA imatrix pt-BR ja gerada e o quant Q4_0 puro.
#
#  Por que Q4_0 (e nao Q4_K_M)?
#  - O llama.cpp moderno faz REPACK automatico do Q4_0 para Q4_0_8_8 (AVX-512)
#    ou Q4_0_4_8 (AVX2) na hora do carregamento. Isso reordena os pesos pra
#    casar com a microarquitetura do CPU e acelera a inferencia em 15-25%.
#  - Trade-off: Q4_0 tem qualidade ligeiramente inferior ao Q4_K_M
#    (perplexidade ~3-5% pior). A imatrix pt-BR compensa boa parte.
#
#  Pre-requisitos:
#   - llama\llama-quantize.exe (ja vem no projeto)
#   - Qwen3-1.7B-Q8_0.gguf na raiz (baixe de huggingface.co/Qwen/Qwen3-1.7B-GGUF)
#   - imatrix_qwen3_pt_v2.dat (gerado pelo regenerar_nano_1.2.ps1) OU
#     imatrix_qwen3_pt.dat (gerado pela receita original) — se nenhum existir,
#     o script ainda funciona, so sem o benefico da imatrix.
#
#  Tempo: 2-5 min (so re-quantiza, nao recalcula imatrix).
#  Uso:   PowerShell -ExecutionPolicy Bypass -File regenerar_nano_q4_0.ps1
# =====================================================================

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # Arandu-nano\
$BIN_QUANTIZE = Join-Path $ROOT 'llama\llama-quantize.exe'
$BASE_GGUF    = Join-Path $ROOT 'Qwen3-1.7B-Q8_0.gguf'
$SAIDA_GGUF   = Join-Path $ROOT 'Arandu_Nano_1.1_Q4_0.gguf'

# Prefere a imatrix v2 (corpus ampliado); cai na v1 se nao houver
$IMATRIX_V2 = Join-Path $PSScriptRoot 'imatrix_qwen3_pt_v2.dat'
$IMATRIX_V1 = Join-Path $PSScriptRoot 'imatrix_qwen3_pt.dat'
$IMATRIX    = $null
if (Test-Path $IMATRIX_V2)      { $IMATRIX = $IMATRIX_V2 }
elseif (Test-Path $IMATRIX_V1)  { $IMATRIX = $IMATRIX_V1 }

function Falhar($msg) { Write-Host "`n[ERRO] $msg" -ForegroundColor Red; exit 1 }

Write-Host '== Arandu Nano 1.1 Q4_0 — re-quantizacao para CPUs com AVX2/AVX-512 ==' -ForegroundColor Cyan

# 1) Pre-requisitos
if (-not (Test-Path $BIN_QUANTIZE)) {
    Falhar "Nao achei: $BIN_QUANTIZE (extraia o llama.cpp em llama\)"
}
if (-not (Test-Path $BASE_GGUF)) {
    Falhar "Nao achei o modelo base $BASE_GGUF.`n        Baixe Qwen3-1.7B-Q8_0.gguf em https://huggingface.co/Qwen/Qwen3-1.7B-GGUF e coloque na raiz."
}

# 2) Detecta capacidade do CPU
Write-Host "`n[1/2] Verificando suporte do CPU local..." -ForegroundColor Yellow
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class _CpuFeat {
    [DllImport("kernel32.dll")]
    public static extern bool IsProcessorFeaturePresent(uint feat);
}
"@
$avx2  = [_CpuFeat]::IsProcessorFeaturePresent(40)
$avx512= [_CpuFeat]::IsProcessorFeaturePresent(41)
$cpuNm = (Get-CimInstance Win32_Processor).Name
Write-Host "      CPU: $cpuNm"
Write-Host "      AVX2: $avx2  |  AVX-512F: $avx512"
if ($avx512) {
    Write-Host "      -> ganho esperado: ~20-25%% (repack para Q4_0_8_8 na carga)" -ForegroundColor Green
} elseif ($avx2) {
    Write-Host "      -> ganho esperado: ~15-20%% (repack para Q4_0_4_8 na carga)" -ForegroundColor Green
} else {
    Write-Host "      -> AVISO: CPU sem AVX2/AVX-512 — Q4_0 pode ser igual ou PIOR que Q4_K_M aqui." -ForegroundColor DarkYellow
    Write-Host "         Considere parar e manter o Q4_K_M." -ForegroundColor DarkYellow
}

# 3) Re-quantiza
Write-Host "`n[2/2] Re-quantizando para Q4_0 (alguns minutos)..." -ForegroundColor Yellow
if ($IMATRIX) {
    Write-Host "      usando imatrix: $(Split-Path -Leaf $IMATRIX)"
    & $BIN_QUANTIZE --allow-requantize --imatrix $IMATRIX $BASE_GGUF $SAIDA_GGUF Q4_0 4
} else {
    Write-Host "      AVISO: imatrix pt-BR nao encontrada — gerando Q4_0 puro." -ForegroundColor DarkYellow
    Write-Host "             Para qualidade melhor, rode regenerar_nano_1.2.ps1 primeiro p/ gerar a imatrix."
    & $BIN_QUANTIZE --allow-requantize $BASE_GGUF $SAIDA_GGUF Q4_0 4
}
if ($LASTEXITCODE -ne 0) { Falhar 'llama-quantize falhou' }

$tamMB = [math]::Round((Get-Item $SAIDA_GGUF).Length / 1MB, 1)
Write-Host "`n[OK] Arandu Nano 1.1 Q4_0 gerado em:" -ForegroundColor Green
Write-Host "     $SAIDA_GGUF  ($tamMB MB)"

Write-Host "`nProximos passos:"
Write-Host "  1) Para ATIVAR no Arandu, edite o modelo.txt com:"
Write-Host "        Arandu_Nano_1.1_Q4_0.gguf"
Write-Host "     (ou use o Usar_Nano_Q4_0.bat na raiz)"
Write-Host "  2) Reabra com Iniciar_Arandu.vbs e compare os tok/s (visivel no chat)"
Write-Host "     com o Usar_Nano_1.1.bat (Q4_K_M, padrao atual)."
