#!/bin/bash

heist_log="/var/log/heist.log"
leaderboard_log="/var/log/trendsetters.log"
now=$(date '+%s')
streak_mult=10
clutch_bonus=100
decay_factor=20

mkdir -p "$(dirname "$leaderboard_log")"
touch "$leaderboard_log"
chown root:wardens "$leaderboard_log"
chmod 640 "$leaderboard_log"

mapfile -t all_bashers < <(ls /home/bashers 2>/dev/null)

declare -A last_success score successes

while IFS= read -r line
do
    ts=$(date -d "${line:0:19}" +%s 2>/dev/null) || continue
    [ $((now - ts)) -gt 86400 ] && continue
    user=$(echo "$line" | awk -F'|' '{gsub(/ /,""); print $2}')
    successes["$user"]+=" $ts"
    last_success["$user"]=$ts
done < "$heist_log"

active=0
for u in "${all_bashers[@]}"
do
    [ -n "${successes[$u]}" ] && ((active++))
done
[ $active -lt 1 ] && active=1

latest_overall=$(printf '%s\n' "${last_success[@]}" | sort -n | tail -1)

declare -A raw_score
for u in "${all_bashers[@]}"
do
    max_streak=0
    times=(${successes[$u]})
    for ((i=0; i<${#times[@]}; i++))
    do
        start=${times[$i]}
        end=$((start + 300))
        cnt=1
        for ((j=i+1; j<${#times[@]}; j++))
        do
            [ ${times[$j]} -le $end ] && ((cnt++)) || break
        done
        [ $cnt -gt $max_streak ] && max_streak=$cnt
    done
    streak=$(( max_streak * streak_mult ))

    if [ "${last_success[$u]}" = "$latest_overall" ] && [ -n "$latest_overall" ]
    then
        clutch=$clutch_bonus
    else
        clutch=0
    fi

    if [ -n "${last_success[$u]}" ]
    then
        hours=$(( (now - last_success[$u]) / 3600 ))
        penalty=$(echo "scale=2; $decay_factor * l(1+$hours)" | bc -l 2>/dev/null || echo 0)
    else
        penalty=10000
    fi

    raw=$(echo "$streak + $clutch - $penalty" | bc)
    raw_score["$u"]=$(printf "%.2f" "$raw")
done

declare -A final_score last_ts
for u in "${all_bashers[@]}"
do
    final_score["$u"]=$(echo "scale=2; ${raw_score[$u]} / $active" | bc)
    last_ts["$u"]=${last_success[$u]:-0}
done

sorted=$(for u in "${all_bashers[@]}"; do
    echo "${final_score[$u]} ${last_ts[$u]} $u"
done | sort -k1,1nr -k2,2nr)

prev=""
[ -f "$leaderboard_log" ] && prev=$(tail -1 "$leaderboard_log" | awk -F'|' '{print $2}')

mapfile -t prev_ranks < <(echo "$prev" | tr ' ' '\n' | awk -F: '{print $2}')
echo "TrendSetters"
rank=0
top3=""
while read -r s t user
do
    ((rank++))
    if [ $rank -gt 3 ]
    then
    	break
    old_rank=$(echo "$prev" | tr ' ' '\n' | awk -F: -v u="$user" '$2==u{print $1}')
    if [ -n "$old_rank" ]
    then
        diff=$(( old_rank - rank ))
        if [ $diff -gt 0 ]
        then 
        move="↑${diff}"; elif [ $diff -lt 0 ]; then move="↓$(( -diff ))"; else move="–"
        fi
    else
        move="new"
    fi
    printf "%d. %-15s score: %s | %s\n" "$rank" "$user" "$s" "$move"
    top3+=" $rank:$user"
done <<< "$sorted"

echo "$(date '+%d-%m-%Y %H:%M:%S') |$top3" >> "$leaderboard_log"
