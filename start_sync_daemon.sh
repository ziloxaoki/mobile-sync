#!/data/data/com.termux/files/usr/bin/bash

# -------- CONFIG --------
SCRIPT_PATH="$HOME/photo_sync.sh"
LOG_FILE="$HOME/photo_sync_daemon.log"
PID_FILE="$HOME/photo_sync_daemon.pid"

INTERVAL=${2:-3600}   # 1 hour

# -------- FUNCTIONS --------

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Daemon already running with PID $(cat $PID_FILE)"
        exit 1
    fi

    echo "Starting sync daemon..."

    (
        while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Running sync..." >> "$LOG_FILE"

            bash "$SCRIPT_PATH" >> "$LOG_FILE" 2>&1

            echo "$(date '+%Y-%m-%d %H:%M:%S') - Sync completed. Sleeping for $INTERVAL seconds..." >> "$LOG_FILE"

            sleep "$INTERVAL"
        done
    ) &

    echo $! > "$PID_FILE"
    echo "Daemon started with PID $(cat $PID_FILE)"
}

stop_daemon() {
    if [ ! -f "$PID_FILE" ]; then
        echo "No PID file found. Daemon not running?"
        exit 1
    fi

    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Daemon stopped."
    else
        echo "Process not running."
    fi

    rm -f "$PID_FILE"
}

status_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Daemon is running (PID $(cat $PID_FILE))"
    else
        echo "Daemon is not running"
    fi
}

# -------- MAIN --------

case "$1" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
