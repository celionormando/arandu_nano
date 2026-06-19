@echo off
REM ============================================================
REM  IA Portatil - interface ORIGINAL do llamafile (em ingles)
REM  Abre a UI embutida em http://127.0.0.1:8080
REM ============================================================
cd /d "%~dp0"

llamafile.exe ^
  -m Llama-3.2-3B-Instruct-Q4_K_M.gguf ^
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

pause
