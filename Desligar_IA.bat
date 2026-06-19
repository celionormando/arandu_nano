@echo off
REM Encerra o servidor da IA Portatil que roda em segundo plano.
taskkill /IM llamafile.exe /F >nul 2>&1
if %errorlevel%==0 (
  echo IA Portatil desligada.
) else (
  echo Nenhum servidor da IA estava rodando.
)
timeout /t 2 /nobreak >nul
