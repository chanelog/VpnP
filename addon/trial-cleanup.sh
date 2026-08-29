#!/bin/bash
# ============================================================
#  CHANELOG VPN SCRIPT - TRIAL CLEANUP (PRO)
#  Jalan via cron tiap 1 menit. Hapus akun trial yang udah
#  lewat waktu presisi (menit), gak nunggu expiry harian biasa.
# ============================================================
SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"
cleanup_expired_trials
