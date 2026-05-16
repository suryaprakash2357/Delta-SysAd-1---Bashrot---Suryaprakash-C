#!/bin/bash
vault="/opt/Bashrot_vault"
slang="$vault/slang.txt"
bad=(cringe simp yeet sus)

while true
do
    if [ -s "$slang" ]
    then
    	sedcmd=""
        for w in "${bad[@]}"
        do
            len=${#w}
            stars=$(for (( i=1 ; i<=len ; i++ )); do printf '*'; done)
            sedcmd+="s/\b$w\b/$stars/g;"
        done
        
        censored=$(sed -E "$sedcmd" "$slang")
        clean=$(echo "$censored" | grep -vE '^\*+$')
        word=$(echo "$clean" | shuf -n1)
        encoded=$(echo -n "$word" | base64 -w0)
        out="$vault/lore_$(date '+%s')_$RANDOM.b64"
        echo "$encoded" > "$out"
        chown root:wardens "$out"
        chmod 640 "$out"
    fi
    sleep 30
done
