#!/usr/bin/env bash
# --------------------------------------------------------
# docker_janitor_lib.sh – Support functions for Docker janitor
# --------------------------------------------------------

print_task() {
  [[ "$4" -eq 0 ]] && echo -e "$1  $2"
}

get_bytes() {
  docker system df --format '{{.Size}}' 2>/dev/null | grep -Eo '[0-9.]+[MG]B' | awk '
    /MB/ { sum += $1 * 1024 * 1024 }
    /GB/ { sum += $1 * 1024 * 1024 * 1024 }
    END { printf "%.0f", sum }'
}

human_size_bytes() {
  awk -v b="$1" 'BEGIN {
    if (b == "" || b == 0) { print "0.00 B"; exit }
    split("B KB MB GB TB", units);
    for (i = 0; b >= 1024 && i < 4; i++) b /= 1024;
    printf "%.2f %s", b, units[i]
  }'
}

human_size() {
  local num=${1:-0}
  awk -v sum="$num" '
  function human(x) {
    split("B KB MB GB TB", unit);
    for (i = 1; x >= 1024 && i < 5; i++) x /= 1024;
    return sprintf("%.2f %s", x, unit[i]);
  }
  BEGIN { print human(sum) }'
}

run_cleanup_task() {
  # shellcheck disable=SC2034
  local task="$1" dryrun="$2" force="$3" quiet="$4" verbose="$5"
  local ids count size size_hr summary_block=""

  case "$task" in
  images)
    ids=$(docker images -f "dangling=true" -q)
    count=$(echo "$ids" | grep -c . || echo 0)
    size=$(docker images -f "dangling=true" --format "{{.Size}}" | grep -Eo '[0-9.]+' | awk '{s+=$1} END {print s*1024*1024}')
    size_hr=$(human_size "${size:-0}")
    [[ "$quiet" -eq 0 ]] && echo "📦  $count dangling image(s) ($size_hr)"
    [[ "$dryrun" -eq 0 ]] && docker image prune -f >/dev/null
    summary_block+="\n### 🖼️ Images\n$count image(s) cleaned (estimated $size_hr)"
    ;;
  containers)
    ids=$(docker ps -a -f "status=exited" -q)
    count=$(echo "$ids" | grep -c . || echo 0)
    size=$(docker ps -a -f "status=exited" --format "{{.Size}}" | grep -Eo '[0-9.]+' | awk '{s+=$1} END {print s*1024*1024}')
    size_hr=$(human_size "${size:-0}")
    [[ "$quiet" -eq 0 ]] && echo "📦  $count exited container(s) ($size_hr)"
    [[ "$dryrun" -eq 0 ]] && docker container prune -f >/dev/null
    summary_block+="\n### 🧱 Containers\n$count container(s) cleaned (estimated $size_hr)"
    ;;
  volumes)
    ids=$(docker volume ls -f "dangling=true" -q)
    count=$(echo "$ids" | grep -c . | tr -d '[:space:]')
    [[ "$quiet" -eq 0 ]] && echo "📦  $count dangling volume(s)"

    skipped=()

    if [[ "$dryrun" -eq 0 && "$count" -gt 0 ]]; then
      for vol in $ids; do
        if ! docker volume rm "$vol" &>/dev/null; then
          skipped+=("$vol")
          [[ "$quiet" -eq 0 || "$verbose" -eq 1 ]] && echo "⚠️  Skipped volume: $vol"
        fi
      done
    fi

    cleaned_count=$((count - ${#skipped[@]}))
    summary_block+="\n### 🗃️ Volumes\n$cleaned_count volume(s) cleaned"

    if [[ "${#skipped[@]}" -gt 0 ]]; then
      summary_block+="\n⚠️  Skipped volume(s):"
      for vol in "${skipped[@]}"; do
        summary_block+="\n- $vol"
      done
    fi
    ;;

  cache)
    if docker buildx du &>/dev/null; then
      local size_raw size_bytes count
      size_raw=$(docker buildx du | grep -Eo '[0-9.]+[MG]B' | head -1 || echo "0MB")
      # shellcheck disable=SC2034
      size_bytes=$(echo "$size_raw" | awk '/MB/ { printf "%.0f", $1 * 1024 * 1024 } /GB/ { printf "%.0f", $1 * 1024 * 1024 * 1024 }' || echo 0)
      count=$(docker buildx du | grep -c '^/' || echo 0)
      [[ "$quiet" -eq 0 ]] && echo "📦  $count buildx cache entries ($size_raw)"
      [[ "$dryrun" -eq 0 ]] && docker buildx prune -f >/dev/null
      summary_block+="\n### 🧱 Buildx Cache\n$count entry(s) cleaned (estimated $size_raw)"
    else
      [[ "$quiet" -eq 0 ]] && echo "⚠️  Docker BuildKit does not support 'buildx du' on this system"
      summary_block+="\n### 🧱 Buildx Cache\nSkipped — buildx du not available"
    fi
    ;;
  networks)
    prunable=$(docker network ls --filter "dangling=true" -q)
    count=$(echo "$prunable" | grep -c . || echo 0)
    [[ "$quiet" -eq 0 ]] && echo "📦  $count unused network(s)"
    [[ "$dryrun" -eq 0 ]] && docker network prune -f >/dev/null
    summary_block+="\n### 🌐 Networks\n$count network(s) cleaned"
    ;;
  *)
    [[ "$quiet" -eq 0 ]] && echo "⚠️  Unknown cleanup task: $task"
    ;;
  esac

  echo -e "$summary_block"
}

render_disk_stats() {
  local dryrun=$1
  local quiet=$2
  local before after diff sign diff_hr before_hr after_hr

  before=$(get_bytes)

  [[ "$dryrun" -eq 0 ]] && sleep 1
  after=$(get_bytes)

  diff=$((after - before))
  sign=$(awk -v d="$diff" 'BEGIN { if (d == 0) print "±"; else if (d > 0) print "+"; else print "-" }')
  diff_hr=$(human_size_bytes "$diff")
  before_hr=$(human_size_bytes "$before")
  after_hr=$(human_size_bytes "$after")

  local stats_block="\n### 📊 Disk Usage Stats\nBefore: $before_hr\nAfter: $after_hr\nDelta: $sign$diff_hr"

  # [[ "$quiet" -eq 0 ]] && echo -e "$stats_block"
  echo -e "$stats_block"
}
