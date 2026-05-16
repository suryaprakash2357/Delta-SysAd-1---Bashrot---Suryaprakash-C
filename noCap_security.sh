#!/bin/bash
VAULT="/opt/Bashrot_vault"
SYMLINK_COUNT=6767
CYCLE_SLEEP=2700

fake_dirs=(/usr/share/doc /usr/share/man /etc /var/log /var/tmp /tmp /usr/share/misc /usr/share/zoneinfo /usr/lib /lib)

cycler() {
    while true; do
        # Choose the latest encoded file
        real=$(ls -t "$VAULT"/lore_*.b64 2>/dev/null | head -1)
        if [ -z "$real" ]; then
            sleep "$CYCLE_SLEEP"
            continue
        fi
        hidden=$(mktemp -d /tmp/.brot_XXXXX)
        mv "$real" "$hidden/real_bashrot.b64"
        target_file="$hidden/real_bashrot.b64"

        # Clear existing symlinks
        find "$VAULT" -maxdepth 1 -type l -delete

        target_idx=$(( RANDOM % SYMLINK_COUNT + 1 ))
        for ((i=1; i<=SYMLINK_COUNT; i++)); do
            if [ $i -eq $target_idx ]; then
                ln -s "$target_file" "$VAULT/link_$i"
            else
                rand_dir=${fake_dirs[$((RANDOM % ${#fake_dirs[@]}))]}
                ln -s "$rand_dir" "$VAULT/link_$i" 2>/dev/null || \
                ln -s /tmp "$VAULT/link_$i"
            fi
        done
        echo "$target_file" > "$VAULT/.target_ref"
        chown root:wardens "$VAULT/.target_ref"; chmod 640 "$VAULT/.target_ref"
        sleep "$CYCLE_SLEEP"
    done
}

pkill -f "noCap_cycler" 2>/dev/null || true
cycler &
echo "noCap security cycler started (PID $!)"
