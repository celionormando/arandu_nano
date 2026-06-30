#!/usr/bin/env sh
set -eu

BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MODEL="Llama-3.2-1B-Instruct-Q4_K_M.gguf"

if [ -f "$BASE/modelo.txt" ]; then
  MODEL=$(head -n 1 "$BASE/modelo.txt" | tr -d '\r')
fi

if [ -x "$BASE/llamafile.exe" ] || [ -f "$BASE/llamafile.exe" ]; then
  EXE="$BASE/llamafile.exe"
elif [ -x "$BASE/llamafile" ] || [ -f "$BASE/llamafile" ]; then
  EXE="$BASE/llamafile"
else
  echo "llamafile nao encontrado em $BASE"
  exit 1
fi

chmod +x "$EXE" 2>/dev/null || true

server_up() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "http://127.0.0.1:8080/props" >/dev/null 2>&1
  else
    return 1
  fi
}

open_url() {
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$1" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$1" >/dev/null 2>&1 &
  else
    echo "Abra no navegador: $1"
  fi
}

if ! server_up; then
  mkdir -p "$BASE/cache"   # prompt caching: --slot-save-path requer a pasta existir
  "$EXE" --server \
    -m "$BASE/$MODEL" \
    --host 127.0.0.1 \
    --port 8080 \
    -c 2048 \
    -t 3 \
    -fa on \
    -ctk q8_0 \
    -ctv q8_0 \
    -ub 256 \
    -b 512 \
    --gpu disable \
    --sleep-idle-seconds 180 \
    --cache-reuse 256 \
    --slot-save-path "$BASE/cache" > "$BASE/llamafile-chat.log" 2>&1 &

  i=0
  while [ "$i" -lt 40 ]; do
    if server_up; then
      break
    fi
    i=$((i + 1))
    sleep 1
  done

  if ! server_up; then
    echo "Nao consegui iniciar o servidor. Veja $BASE/llamafile-chat.log"
    exit 1
  fi
fi

# tambem sobe o AJUDANTE de saude do sistema (mini painel no canto do chat),
# se houver python3. Somente leitura (RAM/disco/limpeza); NUNCA apaga nada.
# Mesmo contrato HTTP do helper Windows (porta 8099) -> o painel funciona igual.
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
if [ -n "$PY" ] && [ -f "$BASE/ferramentas/saude_sistema.py" ]; then
  if ! curl -fsS "http://127.0.0.1:8099/ping" >/dev/null 2>&1; then
    "$PY" "$BASE/ferramentas/saude_sistema.py" > "$BASE/ajudante-saude.log" 2>&1 &
  fi
fi

open_url "file://$BASE/chat.html"
echo "Arandu IA iniciado no navegador padrao."
