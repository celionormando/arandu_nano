@echo off
REM ============================================================
REM  IA Portatil - llamafile + Llama-3.2-3B-Instruct (Q4_K_M)
REM  Interface em PORTUGUES (chat.html). Otimizado para pouca RAM.
REM ============================================================
cd /d "%~dp0"

REM Le o modelo ativo de modelo.txt (padrao 1B se nao existir)
set "MODELO=Llama-3.2-1B-Instruct-Q4_K_M.gguf"
if exist modelo.txt set /p MODELO=<modelo.txt

REM 1) Sobe o servidor llamafile em janela propria (sem a UI em ingles)
start "Servidor IA Portatil" /min llamafile.exe ^
  --server ^
  -m "%MODELO%" ^
  --host 127.0.0.1 ^
  --port 8080 ^
  -c 2048 ^
  -t 3 ^
  -fa on ^
  -ctk q8_0 ^
  -ctv q8_0 ^
  -ub 256 ^
  -b 512 ^
  --gpu disable

REM 2) Aguarda o modelo carregar e abre o chat em portugues
echo Carregando o modelo... aguarde.
timeout /t 6 /nobreak >nul
start "" "chat.html"

echo.
echo IA Portatil iniciada. A interface abriu no navegador.
echo Para desligar: feche a janela "Servidor IA Portatil".
echo (Esta janela pode ser fechada.)
timeout /t 4 /nobreak >nul

REM ------------------------------------------------------------
REM  Flags de economia de RAM sem perder velocidade:
REM   -c 2048   contexto / -t 3 threads (1 nucleo livre = mais rapido aqui) / -fa on
REM   -ctk/-ctv q8_0  KV cache 8-bit (~metade da RAM do contexto)
REM   Se faltar RAM ("failed to create context"): troque -c 2048 por -c 1024.
REM ------------------------------------------------------------
