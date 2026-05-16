#!/bin/bash
set -euo pipefail

roster="/scripts/roster.yaml"

ensure_group() { 
	getent group "$1" &>/dev/null || groupadd "$1"
}

ensure_group bashers
ensure_group guards
ensure_group wardens

state="/var/lib/roster_state.txt"
touch "$state"

wardens=$(yq e '.roster.wardens[].username' "$roster")
guards=$(yq e '.roster.guards[].username' "$roster")
bashers=$(yq e '.roster.bashers[].username' "$roster")

create_user() {
    user="$1" 
    group="$2" 
    home="$3"
    if ! id "$user" &>/dev/null
    then
        useradd -m -d "$home" -s /bin/bash -g "$group" "$user"
    fi
}

for username in "${wardens[@]}"
do
    home="/home/wardens/$username"
    create_user "$username" "wardens" "$home"
    echo "$username" >> "$state"
    pubkey=$(yq e ".roster.wardens[] | select(.username==\"$username\") | .public_key" "$roster")
    mkdir -p "$home/.ssh"
    echo "$pubkey" > "$home/.ssh/authorized_keys"
    chmod 700 "$home/.ssh"
    chmod 600 "$home/.ssh/authorized_keys"
    chown -R "$username:wardens" "$home/.ssh"
done

for username in "${guards[@]}"
do
    home="/home/guards/$username"
    create_user "$username" "guards" "$home"
    echo "$username" >> "$state"
    pubkey=$(yq e ".roster.guards[] | select(.username==\"$username\") | .public_key" "$roster")
    mkdir -p "$home/.ssh"
    echo "$pubkey" > "$home/.ssh/authorized_keys"
    chmod 700 "$home/.ssh"
    chmod 600 "$home/.ssh/authorized_keys"
    chown -R "$username:guards" "$home/.ssh"
done

for username in "${bashers[@]}"
do
    home="/home/bashers/$username"
    drop="$home/Drop_Zone"
    create_user "$username" "bashers" "$home"
    mkdir -p "$drop"
    chown "$username:guards" "$home" "$drop"
    chmod 750 "$home" "$drop"
    echo "$username" >> "$state"

    passwd -l "$username" >/dev/null
    pubkey=$(yq e ".roster.bashers[] | select(.username==\"$username\") | .public_key" "$roster")
    mkdir -p "$home/.ssh"
    echo "$pubkey" > "$home/.ssh/authorized_keys"
    chmod 700 "$home/.ssh"
    chmod 600 "$home/.ssh/authorized_keys"
    chown -R "$username:bashers" "$home/.ssh"

    img=$(yq e ".roster.bashers[] | select(.username==\"$username\") | .image_url" "$roster")
    if [ -n "$img" ]
    then
        curl -s "$img_url" -o /tmp/avatar_$$ &>/dev/null && { jp2a /tmp/avatar_$$ --width=80 > "$home/.avatar.txt" 2>/dev/null || rm -f /tmp/avatar_$$ }
    fi
    
    [ -f "$home/.avatar.txt" ] && echo -e "\ncat ~/.avatar.txt" >> "$home/.bashrc"

cat << ALIASES >> "$home/.bashrc"
alias cap='clear'
alias sus='ls'
alias mog='tail'
ALIASES

    chown "$username:guards" "$home/.bashrc" "$home/.avatar.txt" 2>/dev/null
done

while read -r olduser
do
    if ! grep -qFx "$olduser" <(printf '%s\n' "${wardens[@]}" "${guards[@]}" "${bashers[@]}")
    then
        usermod -L "$olduser" 2>/dev/null || true
        gpasswd -d "$olduser" bashers 2>/dev/null || true
        gpasswd -d "$olduser" guards 2>/dev/null || true
        gpasswd -d "$olduser" wardens 2>/dev/null || true
        sed -i "/^$olduser$/d" "$state"
    fi
done < "$state"

echo "Roster initialised."
