# ============================================================
#  empacotar.ps1 - monta o pacote de teste do Arandu (clica e roda)
#
#  Gera um .zip enxuto com APENAS o necessario para outra pessoa
#  testar o Arandu Nano 1.1: runtime + modelo + interface + lancadores.
#  Deixa de fora os modelos extras, a pasta treino/, o .git e temporarios.
#
#  Uso:
#    powershell -ExecutionPolicy Bypass -File empacotar.ps1
#    powershell -ExecutionPolicy Bypass -File empacotar.ps1 -ComRAG
#
#  -ComRAG   inclui o embedding bge-m3 + base de conhecimento (pacote maior)
#  -Saida    pasta de saida (padrao: .\dist)
#  -Versao   rotulo da versao (padrao: 1.1)
# ============================================================
param(
    [switch]$ComRAG,
    [string]$Saida  = (Join-Path $PSScriptRoot "dist"),
    [string]$Versao = "1.1"
)

$ErrorActionPreference = "Stop"
$raiz = $PSScriptRoot
$nome = "Arandu-Nano-$Versao"
$stage = Join-Path $Saida $nome
$zip   = Join-Path $Saida "$nome.zip"

Write-Host "=== Empacotando $nome ===" -ForegroundColor Cyan

# --- arquivos base (sempre) ---
$base = @(
    "chat.html",
    "llamafile.exe",
    "Qwen_Qwen3-1.7B-Q4_K_M.gguf",
    "IA_Portatil.vbs",
    "Desligar_IA.bat",
    "iniciar.sh",
    "desligar.sh",
    "README.md",
    "GUIA_DO_TESTADOR.md",
    "LICENSE"
)

# --- arquivos extras quando -ComRAG ---
$extrasRAG = @(
    "IA_Arandu_RAG.vbs",
    "iniciar_rag.sh"
)

# --- valida presenca dos arquivos antes de comecar ---
$faltando = @()
foreach ($f in $base) {
    if (-not (Test-Path (Join-Path $raiz $f))) { $faltando += $f }
}
if ($ComRAG) {
    foreach ($f in $extrasRAG) {
        if (-not (Test-Path (Join-Path $raiz $f))) { $faltando += $f }
    }
    if (-not (Test-Path (Join-Path $raiz "rag\bge-m3-Q4_K_M.gguf"))) {
        $faltando += "rag\bge-m3-Q4_K_M.gguf"
    }
}
if ($faltando.Count -gt 0) {
    Write-Host "ERRO: arquivos ausentes:" -ForegroundColor Red
    $faltando | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# --- prepara staging limpo ---
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

# --- copia base ---
foreach ($f in $base) {
    Copy-Item (Join-Path $raiz $f) (Join-Path $stage $f)
    Write-Host "  + $f"
}

# --- garante o modelo ativo = Qwen3 (Nano 1.1) ---
Set-Content -Path (Join-Path $stage "modelo.txt") -Value "Qwen_Qwen3-1.7B-Q4_K_M.gguf" -Encoding ascii -NoNewline
Write-Host "  + modelo.txt (= Qwen_Qwen3-1.7B-Q4_K_M.gguf)"

# --- RAG (opcional) ---
if ($ComRAG) {
    foreach ($f in $extrasRAG) {
        Copy-Item (Join-Path $raiz $f) (Join-Path $stage $f)
        Write-Host "  + $f"
    }
    $ragDst = Join-Path $stage "rag"
    New-Item -ItemType Directory -Path $ragDst -Force | Out-Null
    Copy-Item (Join-Path $raiz "rag\bge-m3-Q4_K_M.gguf") $ragDst
    Copy-Item (Join-Path $raiz "rag\index.js")           $ragDst
    Copy-Item (Join-Path $raiz "rag\gerar_indice.mjs")   $ragDst
    Copy-Item (Join-Path $raiz "rag\docs") $ragDst -Recurse
    Write-Host "  + rag\ (bge-m3 + index.js + docs)"
}

# --- gera o zip ---
if (Test-Path $zip) { Remove-Item $zip -Force }
Write-Host "Compactando (pode levar 1-2 min)..." -ForegroundColor Yellow
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

# --- relatorio ---
$mb = [math]::Round((Get-Item $zip).Length / 1MB, 0)
Write-Host ""
Write-Host "=== PRONTO ===" -ForegroundColor Green
Write-Host "Pacote:  $zip"
Write-Host "Tamanho: $mb MB  (RAG: $(if($ComRAG){'incluido'}else{'nao'}))"
Write-Host ""
Write-Host "Para publicar no GitHub (revise antes de rodar):" -ForegroundColor Cyan
Write-Host "  gh release create v$Versao `"$zip`" -t `"Arandu Nano $Versao`" -n `"Pacote de teste clica-e-roda.`""
