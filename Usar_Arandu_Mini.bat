@echo off
REM Define o modelo ativo como o Arandu Mini 1.0 (Qwen3-1.7B) - PADRAO atual.
cd /d "%~dp0"
echo Qwen_Qwen3-1.7B-Q4_K_M.gguf> modelo.txt
echo Modelo ativo agora: Arandu Mini 1.0 (Qwen3-1.7B, melhor qualidade).
echo Feche a IA (Desligar_IA.bat) e abra de novo para aplicar.
timeout /t 3 /nobreak >nul
