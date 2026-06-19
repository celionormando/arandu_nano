@echo off
REM Define o modelo ativo como o 1B (rapido, ~14 tok/s, ~400 MB RAM).
cd /d "%~dp0"
echo Llama-3.2-1B-Instruct-Q4_K_M.gguf> modelo.txt
echo Modelo ativo agora: 1B (rapido).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
