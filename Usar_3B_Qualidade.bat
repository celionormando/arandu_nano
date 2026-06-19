@echo off
REM Define o modelo ativo como o 3B (mais lento ~6 tok/s, melhor qualidade).
cd /d "%~dp0"
echo Llama-3.2-3B-Instruct-Q4_K_M.gguf> modelo.txt
echo Modelo ativo agora: 3B (qualidade).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
