
#!/bin/sh

BACKLIGHT="/sys/class/backlight/acpi_video0"
STATE_FILE="/run/lid-backlight-brightness"
LOG="/run/lid-backlight-debug.log"

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
}

get_lid_state() {
    for f in /proc/acpi/button/lid/*/state; do
        [ -r "$f" ] || continue
        awk '{print $2; exit}' "$f"
        return
    done
}

[ -w "$BACKLIGHT/brightness" ] || exit 0

case "$(get_lid_state)" in
    closed)
        # Save the original brightness only once.
        if [ ! -s "$STATE_FILE" ]; then
            CURRENT=$(cat "$BACKLIGHT/brightness")

            if [ "$CURRENT" -gt 0 ] 2>/dev/null; then
                echo "$CURRENT" > "$STATE_FILE"
            else
                echo 5 > "$STATE_FILE"
            fi
        fi

        log "Lid closed; waiting 1 second"
        sleep 1

        # Re-check the lid state before turning off the backlight.
        if [ "$(get_lid_state)" = "closed" ]; then
            echo 0 > "$BACKLIGHT/brightness"
            log "Backlight off; brightness=$(cat "$BACKLIGHT/brightness")"
        else
            log "Lid reopened; skipped backlight off"
        fi
        ;;

    open)
        # Allow transient lid-state changes to settle.
        sleep 0.3

        if [ "$(get_lid_state)" = "open" ]; then
            if [ -s "$STATE_FILE" ]; then
                RESTORE=$(cat "$STATE_FILE")

                case "$RESTORE" in
                    ''|*[!0-9]*) RESTORE=5 ;;
                esac
            else
                RESTORE=5
            fi

            echo "$RESTORE" > "$BACKLIGHT/brightness"
            rm -f "$STATE_FILE"
            log "Lid open; restored brightness=$RESTORE"
        else
            log "Lid closed again; skipped restore"
        fi
        ;;
esac
