#!/bin/bash
# ============================================================
#  CHANELOG VPN SCRIPT - BANDWIDTH QUOTA (PRO)
#  Jalan via cron tiap 5 menit. Ngitung pemakaian data per akun
#  SSH (lewat iptables owner-match), kunci akun yang kuotanya
#  abis. Counter iptables gak survive reboot -- makanya kita
#  simpan progres kumulatif terpisah di usage.db.
# ============================================================
SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

command -v iptables >/dev/null 2>&1 || exit 0
touch "$DB_USAGE"

get_chain_bytes() {
  local username="$1"
  iptables -L "quota_${username}" -v -x -n 2>/dev/null | awk '/RETURN/ {print $2; exit}'
}

while IFS='|' read -r user pass exp created limit quota_mb; do
  [[ -z "$user" ]] && continue
  quota_mb="${quota_mb:-0}"
  [[ "$quota_mb" =~ ^[0-9]+$ ]] || quota_mb=0
  [[ "$quota_mb" -eq 0 ]] && continue   # 0 = unlimited, skip tracking

  ensure_quota_chain "$user"
  current_bytes=$(get_chain_bytes "$user")
  [[ -z "$current_bytes" ]] && current_bytes=0

  old_line=$(grep "^$user|" "$DB_USAGE" 2>/dev/null)
  old_cumulative=0
  old_snapshot=0
  if [[ -n "$old_line" ]]; then
    old_cumulative=$(echo "$old_line" | cut -d'|' -f2)
    old_snapshot=$(echo "$old_line" | cut -d'|' -f3)
  fi

  # Counter iptables lebih kecil dari snapshot lama = kena reset (reboot dll),
  # anggap bytes saat ini sbg delta baru, bukan dikurangi (biar gak jadi negatif)
  if [[ "$current_bytes" -lt "$old_snapshot" ]]; then
    delta=$current_bytes
  else
    delta=$(( current_bytes - old_snapshot ))
  fi
  new_cumulative=$(( old_cumulative + delta ))

  grep -v "^$user|" "$DB_USAGE" > "$DB_USAGE.tmp" 2>/dev/null
  echo "$user|$new_cumulative|$current_bytes" >> "$DB_USAGE.tmp"
  mv "$DB_USAGE.tmp" "$DB_USAGE"

  used_mb=$(( new_cumulative / 1024 / 1024 ))
  if [[ "$used_mb" -ge "$quota_mb" ]]; then
    if ! passwd -S "$user" 2>/dev/null | awk '{print $2}' | grep -q "^L$"; then
      passwd -l "$user" >/dev/null 2>&1
      pkill -9 -u "$user" 2>/dev/null
      logger -t vpn-script "bandwidth-quota: '$user' kuota habis (${used_mb}MB/${quota_mb}MB), akun dikunci"
      tg_notify "📵 <b>Kuota Habis, Akun Dikunci</b>

Username: <code>$user</code>
Domain: <code>$(get_domain)</code>
Pemakaian: <code>${used_mb}MB</code> / <code>${quota_mb}MB</code>"
    fi
  fi
done < <(list_ssh)
