@echo off
REM Define o modelo ativo como Arandu Mirim 1.1 quantizado em Q4_0 — variante mais
REM rapida em CPUs com AVX2/AVX-512 (repack automatico para Q4_0_4_8 / Q4_0_8_8).
REM Trade-off: qualidade ligeiramente menor que Q4_K_M. Para gerar o .gguf:
REM   PowerShell -ExecutionPolicy Bypass -File treino\imatrix\regenerar_nano_q4_0.ps1
cd /d "%~dp0"
if not exist "Arandu_Nano_1.1_Q4_0.gguf" (
  echo Arquivo Arandu_Nano_1.1_Q4_0.gguf nao encontrado nesta pasta.
  echo Gere com: PowerShell -ExecutionPolicy Bypass -File treino\imatrix\regenerar_nano_q4_0.ps1
  pause
  exit /b 1
)
echo Arandu_Nano_1.1_Q4_0.gguf> modelo.txt
echo Modelo ativo agora: Arandu Mirim 1.1 Q4_0 (mais rapido em CPUs com AVX2/AVX-512).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
