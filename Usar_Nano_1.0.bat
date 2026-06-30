@echo off
REM Define o modelo ativo como o Arandu Mirim 1.0 (fine-tune proprio Llama-1B) - mais rapido.
cd /d "%~dp0"
echo arandu-nano-1.0-Q4_K_M.gguf> modelo.txt
echo Modelo ativo agora: Arandu Mirim 1.0 (modelo proprio, mais rapido).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
