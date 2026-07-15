#!/bin/sh
FOCUSED=$(niri msg -j focused-window 2>&1)
APP_ID=$(echo "$FOCUSED" | jq -r '.app_id' 2>/dev/null)
PID=$(echo "$FOCUSED" | jq -r '.pid' 2>/dev/null)

if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
    exit 1
fi

TARGET=""
for p in $(pgrep -x "$APP_ID" 2>/dev/null); do
    ppid=$(ps -p "$p" -o ppid= 2>/dev/null | tr -d ' ')
    if [ "$ppid" = "1" ] || [ "$ppid" = "1199" ]; then
        TARGET="$p"
        break
    fi
done

if [ -z "$TARGET" ]; then
    for p in $(pgrep -ix "$APP_ID" 2>/dev/null); do
        ppid=$(ps -p "$p" -o ppid= 2>/dev/null | tr -d ' ')
        if [ "$ppid" = "1" ] || [ "$ppid" = "1199" ]; then
            TARGET="$p"
            break
        fi
    done
fi

if [ -z "$TARGET" ] && [ -n "$PID" ] && [ "$PID" != "null" ]; then
    TARGET="$PID"
fi

if [ -n "$TARGET" ] && [ "$TARGET" -gt 0 ] 2>/dev/null; then
    kill "$TARGET" 2>/dev/null
    sleep 0.3
    if ! ps -p "$TARGET" > /dev/null 2>&1; then
        for p in $(pgrep -ix "$APP_ID" 2>/dev/null); do
            kill "$p" 2>/dev/null
        done
    fi
fi
