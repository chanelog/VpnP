#!/bin/bash
# ============================================================
#  CHANELOG VPN SCRIPT - RESOURCE MONITOR (PRO)
#  Jalan via cron tiap 10 menit. Kirim alert Telegram kalau
#  RAM/Disk/Load server ngelewatin ambang batas.
# ============================================================
SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

STATE_DIR="$SCRIPT_DIR/.resource-monitor-state"
mkdir -p "$STATE_DIR"
COOLDOWN_SEC=3600   # jangan spam alert yang sama lebih dari 1x/jam

RAM_ALERT_PCT="${RAM_ALERT_PCT:-85}"
DISK_ALERT_PCT="${DISK_ALERT_PCT:-90}"
LOAD_ALERT_PCT="${LOAD_ALERT_PCT:-200}"   # % dari kapasitas core (load1/core*100)

mem_pct=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')
disk_pct=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
load1=$(cut -d' ' -f1 /proc/loadavg)
cores=$(nproc)
load_pct=$(awk -v l="$load1" -v c="$cores" 'BEGIN{printf "%.0f", (l/c)*100}')

check_and_alert() {
  local key="$1" value="$2" threshold="$3" label="$4" unit="$5"
  [[ "$value" -lt "$threshold" ]] && return 0

  local state_file="$STATE_DIR/$key"
  local last=$(cat "$state_file" 2>/dev/null || echo 0)
  local now=$(date +%s)
  if (( now - last >= COOLDOWN_SEC )); then
    tg_notify "⚠️ <b>Resource Server Tinggi</b>

Domain: <code>$(get_domain)</code>
$label: <code>${value}${unit}</code> (ambang: ${threshold}${unit})"
    echo "$now" > "$state_file"
  fi
}

check_and_alert "ram" "$mem_pct" "$RAM_ALERT_PCT" "RAM Usage" "%"
check_and_alert "disk" "$disk_pct" "$DISK_ALERT_PCT" "Disk Usage" "%"
check_and_alert "load" "$load_pct" "$LOAD_ALERT_PCT" "CPU Load" "% dari kapasitas"
