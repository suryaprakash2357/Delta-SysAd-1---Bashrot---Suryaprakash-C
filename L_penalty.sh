#!/bin/bash
PIPE=/var/run/penalty.pipe
PENALTY_DIR=/home/wardens/penalty_reports
SCORE_DIR=/var/lib/penalty
THRESHOLD=100

mkdir -p "$PENALTY_DIR" "$SCORE_DIR"
chown root:wardens "$PENALTY_DIR"; chmod 770 "$PENALTY_DIR"
[ -p "$PIPE" ] || mkfifo "$PIPE"
chown root:bashers "$PIPE"; chmod 620 "$PIPE"

# Add trap to global bashrc if missing
if ! grep -q "$PIPE" /etc/bash.bashrc; then
    cat <<'HOOK' >> /etc/bash.bashrc
if groups | grep -q '\bbashers\b'; then
    trap 'echo "$(date +%s) $USER $BASH_COMMAND" >> /var/run/penalty.pipe' DEBUG
fi
HOOK
fi

# Penalty daemon
daemon() {
    declare -A WEIGHTS=(
        ["rm"]=50     ["rmdir"]=50  ["dd"]=50    ["mkfs"]=50   ["shred"]=50
        ["kill"]=30   ["pkill"]=30  ["reboot"]=50 ["shutdown"]=50
        ["passwd"]=40 ["su"]=50     ["sudo"]=50
        ["cat.*wardens"]=30 ["less.*wardens"]=30
        ["cd.*wardens"]=10  ["ls.*wardens"]=10
    )

    while read -r ts user cmd; do
        weight=0
        for pat in "${!WEIGHTS[@]}"; do
            if echo "$cmd" | grep -Eq "$pat"; then
                weight=${WEIGHTS[$pat]}
                break
            fi
        done
        if [ "$weight" -gt 0 ] && id "$user" &>/dev/null; then
            echo "[$(date -d "@$ts" '+%F %T')] $cmd" >> "$PENALTY_DIR/$user.txt"
            scorefile="$SCORE_DIR/$user.score"
            old=$(cat "$scorefile" 2>/dev/null || echo 0)
            new=$((old + weight))
            echo "$new" > "$scorefile"
            if [ "$new" -ge "$THRESHOLD" ]; then
                home=$(eval echo ~"$user")
                usermod -s /bin/rbash "$user"
                cp "$home/.bashrc" "$home/.bashrc.bak"
                cat > "$home/.bashrc" << 'ALIASRC'
export PATH=/bin:/usr/bin
alias cap='clear'
alias sus='ls'
alias mog='tail'
ALIASRC
                chown "$user:bashers" "$home/.bashrc"
                echo "sleep 1800; usermod -s /bin/bash $user; cp $home/.bashrc.bak $home/.bashrc; rm -f $home/.bashrc.bak" | at now + 30 minutes
                echo 0 > "$scorefile"
            fi
        fi
    done < "$PIPE"
}

# Kill old daemon if running
pkill -f "penalty_daemon" 2>/dev/null || true
daemon &
echo $! > /var/run/penalty_daemon.pid
echo "Penalty system active."
