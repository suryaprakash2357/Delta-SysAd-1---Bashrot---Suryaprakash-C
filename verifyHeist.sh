#!/bin/bash

vault="/opt/Bashrot_vault"
slang="$vault/slang.txt"
heist_log="/var/log/heist.log"
bashdir="/home/bashers"

mkdir -p "$(dirname "$heist_log")"
touch "$heist_log"
chown root:wardens "$heist_log"
chmod 640 "$heist_log"

mapfile -t dropzones < <(find "$bashdir" -type d -name Drop_Zone 2>/dev/null)

inotifywait -m -q -e close_write,moved_to --format '%w%f' "${dropzones[@]}" 2>/dev/null |

while IFS= read -r newfile
do
    content=$(cat "$newfile" 2>/dev/null)
    if [ -n "$content" ] && grep -qFx "$content" "$slang" 2>/dev/null
    then
        user=$(echo "$newfile" | awk -F/ '{print $4}')
        wall "Heist Successful ! $user has stolen the Bashrot : $content"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | $user | SUCCESS | $content" >> "$heist_log"
    fi
done
