#!/bin/bash
vault="/opt/Bashrot_vault"
hidden="$vault/.hidden_vault"

mkdir -p "$vault" "$hidden"
chown root:bashers "$vault" "$hidden"
chmod 710 "$vault"
chmod 710 "$hidden"

setfacl -b "$vault" "$hidden"
setfacl -m g:guards:rwx "$vault" "$hidden"
setfacl -m g:wardens:rwx "$vault" "$hidden"
setfacl -m g:bashers:--- "$vault" "$hidden"
setfacl -m g:bashers:--x "$hidden"

touch "$vault/slang.txt"
chown root:wardens "$vault/slang.txt"
chmod 640 "$vault/slang.txt"

echo "Vault ready."
