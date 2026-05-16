#!/bin/bash
pkill -f generateLore 2>/dev/null || true

for dir in /home/bashers/*/
do
    find "$dir" -type f -delete 2>/dev/null || true
done

rm -rf /opt/Bashrot_vault/*
vault="/opt/Bashrot_vault"
hidden="$vault/.hidden_vault"
mkdir -p "$vault" "$hidden"
chown root:bashers "$vault" "$hidden"
chmod 710 "$vault" "$hidden"
setfacl -b "$vault" "$hidden"
setfacl -m g:guards:rwx "$vault" "$hidden"
setfacl -m g:wardens:rwx "$vault" "$hidden"
setfacl -m g:bashers:--- "$vault" "$hidden"
setfacl -m g:bashers:--x "$hidden"
touch "$vault/slang.txt"
chown root:wardens "$vault/slang.txt"
chmod 640 "$vault/slang.txt"
echo "Timeline wiped. Ready for next heist."
