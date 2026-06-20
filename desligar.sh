#!/usr/bin/env sh
set -eu

if command -v pkill >/dev/null 2>&1; then
  pkill -f "llamafile.*--server" || true
  echo "Servidores llamafile encerrados."
else
  echo "pkill nao encontrado. Encerre manualmente os processos llamafile."
fi
