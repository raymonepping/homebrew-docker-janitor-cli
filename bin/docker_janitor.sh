#!/usr/bin/env bash
# --------------------------------------------------------
# docker_janitor.sh – Clean up unused Docker resources
# --------------------------------------------------------

set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

# shellcheck disable=SC2034
VERSION="1.0.2"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# shellcheck disable=SC1091
source "$LIB_DIR/docker_janitor_lib.sh"

CLEANUP_TARGETS=()
SCOPE=""
DRYRUN=1
FORCE=0
QUIET=0
VERBOSE=0
LOGFILE=""
STATS=0
DRYRUN_SUMMARY_FILE=""

print_help() {
  cat <<EOF
🧼 Usage: docker_janitor.sh [options]

🎯 Cleanup Targets:
  --cleanup <targets>       ✅ Comma-separated list:
                            images, volumes, containers, cache, networks

🔍 Scope:
  --scope safe              ✅ Only remove unused and safe items (default)
  --scope deep              ⚠️  More aggressive – may remove build cache

🧪 Dry Run Mode:
  --dryrun                  ✅ Preview what *would* be removed (default)
  --preview                 🧪 Alias for --dryrun

💣 Actual Cleanup:
  --force                   ⚠️  Actually perform cleanup (destructive!)

📊 Stats & Reporting:
  --stats                   📊 Show disk usage before/after cleanup
  --dryrun-summary          📁 Export dryrun results to logs/dryrun_targets.md
  --log <file>              📝 Write summary output to specified file
  --output summary          📄 Output format (default: summary)

🔧 Behavior:
  --quiet                   🤫 Suppress most output
  --verbose                 🔍 Enable debug output

🆘 Help & Version:
  --help                    📖 Show this help message
  --version                 🔢 Show current version

EOF
}

# -------------------------------
# 🧠 Parse Arguments
# -------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
  --cleanup)
    IFS=',' read -r -a CLEANUP_TARGETS <<<"$2"
    shift 2
    ;;
  --scope)
    SCOPE="$2"
    shift 2
    ;;
  --dryrun | --preview)
    DRYRUN=1
    shift
    ;;
  --force)
    DRYRUN=0
    FORCE=1
    shift
    ;;
  --stats)
    STATS=1
    shift
    ;;
  --log)
    LOGFILE="$2"
    shift 2
    ;;
  --quiet)
    QUIET=1
    shift
    ;;
  --verbose)
    VERBOSE=1
    shift
    ;;
  --dryrun-summary)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DRYRUN_SUMMARY_FILE="logs/dryrun_summary_${TIMESTAMP}.md"
    shift
    ;;
  --help)
    print_help
    exit 0
    ;;
  --version)
    echo "docker_janitor v$VERSION"
    exit 0
    ;;
  *)
    echo "❌ Unknown argument: $1"
    print_help
    exit 1
    ;;
  esac
done

# -------------------------------
# 🧹 Cleanup Target Setup
# -------------------------------
if [[ -n "$SCOPE" && ${#CLEANUP_TARGETS[@]} -eq 0 ]]; then
  case "$SCOPE" in
  safe) CLEANUP_TARGETS=(images containers volumes) ;;
  deep) CLEANUP_TARGETS=(images containers volumes cache networks) ;;
  *)
    echo "❌ Unknown scope: $SCOPE"
    exit 1
    ;;
  esac
fi

if [[ ${#CLEANUP_TARGETS[@]} -eq 0 ]]; then
  echo "❌ No cleanup targets specified. Use --scope or --cleanup."
  exit 1
fi

[[ $QUIET -eq 0 ]] && echo "🧼 Starting Docker Janitor ($([[ $DRYRUN -eq 1 ]] && echo DRYRUN || echo LIVE))..."

if [[ -n "$DRYRUN_SUMMARY_FILE" ]]; then
  mkdir -p "$(dirname "$DRYRUN_SUMMARY_FILE")"
  echo "## 🔍 Docker Janitor Dryrun Summary" >"$DRYRUN_SUMMARY_FILE"
  echo "Generated: $(date)" >>"$DRYRUN_SUMMARY_FILE"
  echo "" >>"$DRYRUN_SUMMARY_FILE"
fi

# -------------------------------
# 🔁 Run Cleanup Tasks
# -------------------------------
SUMMARY="## 🧼 Docker Janitor Summary\nGenerated: $(date)\n"
for target in "${CLEANUP_TARGETS[@]}"; do
  block=$(run_cleanup_task "$target" "$DRYRUN" "$FORCE" "$QUIET" "$VERBOSE")
  [[ -n "$block" ]] && SUMMARY+="$block\n"

  if [[ -n "$DRYRUN_SUMMARY_FILE" && $DRYRUN -eq 1 ]]; then
    echo "### $(echo "$target" | tr '[:lower:]' '[:upper:]')" >>"$DRYRUN_SUMMARY_FILE"
    {
      echo "### $(echo "$target" | tr '[:lower:]' '[:upper:]')"
      echo -e "$block"
    } >>"$DRYRUN_SUMMARY_FILE"

  fi

done

# -------------------------------
# 📊 Optional Disk Stats
# -------------------------------
[[ "$STATS" -eq 1 ]] && SUMMARY+="$(render_disk_stats "$DRYRUN" "$QUIET")\n"

# -------------------------------
# 📝 Output Summary
# -------------------------------
if [[ -n "$LOGFILE" ]]; then
  mkdir -p "$(dirname "$LOGFILE")"
  echo -e "$SUMMARY" >"$LOGFILE"
  [[ $QUIET -eq 0 ]] && echo "📝 Summary written to $LOGFILE"
else
  [[ $QUIET -eq 0 ]] && echo -e "$SUMMARY"
fi

[[ $QUIET -eq 0 ]] && echo "✅ Docker janitor complete."
exit 0
