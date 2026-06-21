@echo off
REM Define o modelo ativo como o Arandu Nano 1.0 (modelo proprio, fine-tune do Llama-1B).
cd /d "%~dp0"
echo arandu-nano-1.0-Q4_K_M.gguf> modelo.txt
echo Modelo ativo agora: Arandu Nano 1.0 (modelo proprio, mais rapido).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
