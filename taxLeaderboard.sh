#!/bin/bash

log="/var/log/tax_deletions.log"
if [ -f "$log" ]
then
	echo "No Tax Log"
	exit
fi

echo "TAX LEADERBOARD (total KB deleted)"

awk -F'|' '{
    split($2,a," ");
    user=a[1];
    kb=$3;
    sum[user]+=kb
} END {
    for (u in sum) printf "%s\t%.0f KB\n", u, sum[u]
}' "$log" | sort -rn -k2
