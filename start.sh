#!/usr/bin/env bash
# Start/stop the Student Manager app + MariaDB (no Docker).
# Usage: ./start.sh [start|stop|status]   (default: start)
#
# DB strategy: use the system MariaDB if it is already running (or can be
# started without sudo); otherwise start a user-local mariadbd (datadir
# ~/.local/share/student-app/mysql, auth bypassed, bound to 127.0.0.1 —
# local dev only). No sudo required anywhere.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PID="$ROOT/.backend.pid"
FRONTEND_PID="$ROOT/.frontend.pid"
BACKEND_LOG="$ROOT/.backend.log"
FRONTEND_LOG="$ROOT/.frontend.log"
LOCAL_DATA_DIR="${MYSQL_DATA_DIR:-$HOME/.local/share/student-app/mysql}"
LOCAL_SOCKET="$LOCAL_DATA_DIR/mysql.sock"

DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-root}"
DB_NAME="studentdb"
PORT="${PORT:-8080}"
DB_URL="${DB_URL:-jdbc:mariadb://localhost:3306/$DB_NAME}"

wait_for_url() { # $1=url $2=timeout_s
  local url="$1" timeout="${2:-120}" i=0
  until curl -sf -o /dev/null "$url"; do
    i=$((i + 1))
    if [ "$i" -ge "$timeout" ]; then return 1; fi
    sleep 1
  done
}

db_running() { mariadb-admin ping --silent 2>/dev/null; }

start_local_db() {
  echo "mariadb: no system server usable — starting user-local mariadbd..."
  mkdir -p "$LOCAL_DATA_DIR"
  if [ ! -d "$LOCAL_DATA_DIR/mysql" ]; then
    mariadb-install-db --datadir="$LOCAL_DATA_DIR" --auth-root-authentication-method=normal --skip-test-db >/dev/null 2>&1
  fi
  export MYSQL_UNIX_PORT="$LOCAL_SOCKET"
  if ! db_running; then
    setsid mariadbd --datadir="$LOCAL_DATA_DIR" --socket="$LOCAL_SOCKET" \
      --bind-address=127.0.0.1 --port=3306 \
      --skip-grant-tables >"$LOCAL_DATA_DIR/mariadbd.log" 2>&1 < /dev/null &
    echo $! > "$ROOT/.mariadb.pid"
  fi
  local i=0
  until db_running; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
      echo "ERROR: user-local mariadbd did not start. See $LOCAL_DATA_DIR/mariadbd.log" >&2
      return 1
    fi
    sleep 1
  done
  echo "mariadb: running (user-local, 127.0.0.1:3306)"
}

start_db() {
  # If a local fallback server was started before, its socket env is needed.
  [ -S "$LOCAL_SOCKET" ] && export MYSQL_UNIX_PORT="$LOCAL_SOCKET"
  if db_running; then echo "mariadb: already running"; return 0; fi
  if command -v systemctl >/dev/null; then
    systemctl start mariadb 2>/dev/null || true
  fi
  if db_running; then echo "mariadb: running (system)"; return 0; fi
  start_local_db
}

ensure_db() {
  mariadb -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" 2>/dev/null && return 0
  [ -n "${MYSQL_UNIX_PORT:-}" ] && MYSQL_UNIX_PORT="$MYSQL_UNIX_PORT" mariadb -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" 2>/dev/null && return 0
  mariadb -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" 2>/dev/null && return 0
  echo "ERROR: cannot create database '$DB_NAME'. Check DB_USER/DB_PASS." >&2
  return 1
}

is_pid_live() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

stop_one() { # $1=pidfile $2=pattern
  if [ -f "$1" ]; then
    local pid; pid="$(cat "$1")"
    if is_pid_live "$pid"; then kill -- "-$(ps -o pgid= -p "$pid" | tr -d ' ')" 2>/dev/null || kill "$pid" 2>/dev/null || true; sleep 1; fi
    rm -f "$1"
  fi
  pkill -f "$2" 2>/dev/null || true
}

do_stop() {
  stop_one "$BACKEND_PID" "[s]pring-boot:run"
  stop_one "$FRONTEND_PID" "[v]ite"
  if [ -f "$ROOT/.mariadb.pid" ]; then
    local pid; pid="$(cat "$ROOT/.mariadb.pid")"
    if is_pid_live "$pid"; then kill "$pid" 2>/dev/null || true; sleep 1; fi
    rm -f "$ROOT/.mariadb.pid"
  fi
  echo "stopped (backend :$PORT, frontend :5173)"
}

do_status() {
  if [ -f "$BACKEND_PID" ] && is_pid_live "$(cat "$BACKEND_PID")"; then
    echo "backend:  running (pid $(cat "$BACKEND_PID")) http://localhost:$PORT/api/students"
  else echo "backend:  stopped"; fi
  if [ -f "$FRONTEND_PID" ] && is_pid_live "$(cat "$FRONTEND_PID")"; then
    echo "frontend: running (pid $(cat "$FRONTEND_PID")) http://localhost:5173"
  else echo "frontend: stopped"; fi
  if db_running; then echo "mariadb:  running"; else echo "mariadb:  stopped"; fi
}

spawn() { # $1=pidfile $2=logfile $@=cmd — new session so stop kills the whole group
  local pidfile="$1" logfile="$2"; shift 2
  setsid "$@" >"$logfile" 2>&1 < /dev/null &
  echo $! > "$pidfile"
}

do_start() {
  for cmd in java mvn node npm mariadb mariadbd curl; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing '$cmd'" >&2; exit 1; }
  done

  start_db
  ensure_db

  echo "backend: starting (log: .backend.log)..."
  cd "$ROOT/backend"
  export PORT DB_URL DB_USER DB_PASS
  spawn "$BACKEND_PID" "$BACKEND_LOG" mvn -q spring-boot:run
  if ! wait_for_url "http://localhost:$PORT/api/students" 240; then
    echo "ERROR: backend did not come up. See .backend.log" >&2
    tail -20 "$BACKEND_LOG" >&2 || true
    exit 1
  fi
  echo "backend:  http://localhost:$PORT/api/students"

  echo "frontend: starting (log: .frontend.log)..."
  cd "$ROOT/frontend"
  [ -d node_modules ] || npm install
  spawn "$FRONTEND_PID" "$FRONTEND_LOG" npm run dev
  if ! wait_for_url "http://localhost:5173" 90; then
    echo "ERROR: frontend did not come up. See .frontend.log" >&2
    tail -20 "$FRONTEND_LOG" >&2 || true
    exit 1
  fi
  echo "frontend: http://localhost:5173"
  echo "OK — run ./start.sh stop to stop everything."
}

case "${1:-start}" in
  start) do_start ;;
  stop) do_stop ;;
  status) do_status ;;
  *) echo "Usage: $0 [start|stop|status]" >&2; exit 1 ;;
esac
