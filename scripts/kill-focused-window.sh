#!/bin/sh
FOCUSED=$(niri msg -j focused-window 2>/dev/null)
PID=$(echo "$FOCUSED" | jq -r '.pid' 2>/dev/null)
APP_ID=$(echo "$FOCUSED" | jq -r '.app_id' 2>/dev/null)
COMM=$(ps -p "$PID" -o comm= 2>/dev/null)

case "$COMM" in
    xwayland-satell*)
        # XWayland 应用：通过 DISPLAY 找到实际应用主进程
        XWAY_PID=$(pgrep -P "$PID" Xwayland 2>/dev/null | head -1)
        if [ -n "$XWAY_PID" ]; then
            DISP=$(cat "/proc/$XWAY_PID/cmdline" 2>/dev/null | tr '\0' ' ' | grep -oE ':[0-9]+')
            if [ -n "$DISP" ] && [ -n "$APP_ID" ] && [ "$APP_ID" != "null" ]; then
                # 精确匹配进程名，取最新的（主进程）
                TARGET=$(pgrep -ox "$APP_ID" 2>/dev/null)
                [ -z "$TARGET" ] && TARGET=$(pgrep -oix "$APP_ID" 2>/dev/null)
                if [ -z "$TARGET" ]; then
                    # 回退：模糊匹配 + DISPLAY 过滤，取 PID 最小的
                    for p in $(pgrep -i "$APP_ID" 2>/dev/null); do
                        if grep -q "DISPLAY=$DISP" "/proc/$p/environ" 2>/dev/null; then
                            TARGET=$p
                            break
                        fi
                    done
                fi
                [ -n "$TARGET" ] && kill -9 "$TARGET" 2>/dev/null
            fi
        fi
        ;;
    *)
        if [ -n "$PID" ] && [ "$PID" != "null" ] && [ "$PID" -gt 0 ] 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null
        fi
        ;;
esac
