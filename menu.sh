#!/bin/bash
# ============================================================
#   CHANELOG VPN TUNNEL MANAGER — PRO EDITION
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

BOX_TOP="╭──────────────────────────────────────────────────────────╮"
BOX_MID="├──────────────────────────────────────────────────────────┤"
BOX_BOT="╰──────────────────────────────────────────────────────────╯"
LINE="──────────────────────────────────────────────────────────"

# Cetak baris dalam box, auto-pad ke lebar box. Pakai python3 buat
# hitung lebar visible (bukan bash ${#str} -- itu ngitung BYTE, bukan
# karakter, dan bisa salah kalau locale terminal bukan UTF-8).
box_line() {
  local text="$1"
  local visible vislen pad
  visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  vislen=$(python3 -c "import sys; print(len(sys.argv[1]))" "$visible" 2>/dev/null)
  [[ -z "$vislen" ]] && vislen=${#visible}
  pad=$((56 - vislen))
  ((pad < 0)) && pad=0
  printf "│  %b%*s│\n" "$text" "$pad" ""
}

dot() { [[ "$1" == "1" ]] && echo -e "${GREEN}●${NC}" || echo -e "${RED}●${NC}"; }

show_header() {
  clear
  local domain=$(get_domain)
  local ip=$(get_server_ip)
  local mem=$(get_mem_usage)
  local disk=$(get_disk_usage)
  local uptime=$(get_uptime)
  local load=$(get_load_avg)
  local cpu_cores=$(get_cpu_cores)
  local vmess_count=$(count_vmess)
  local vless_count=$(count_vless)
  local trojan_count=$(count_trojan)
  local ss_count=$(count_ss)
  local ssh_count=$(count_ssh)
  local total_akun=$((vmess_count + vless_count + trojan_count + ss_count + ssh_count))

  local xray_on=0 nginx_on=0 db_on=0 stunnel_on=0 haproxy_on=0
  systemctl is-active --quiet xray     && xray_on=1
  systemctl is-active --quiet nginx    && nginx_on=1
  systemctl is-active --quiet dropbear && db_on=1
  systemctl is-active --quiet stunnel4 2>/dev/null && stunnel_on=1
  systemctl is-active --quiet haproxy  2>/dev/null && haproxy_on=1

  local mux_badge="${DIM}nonaktif${NC}"
  [[ -f "$SCRIPT_DIR/.multiplex-443-active" ]] && mux_badge="${GREEN}aktif — SNI bebas${NC}"

  local pro_badge="${DIM}belum di-setup${NC}"
  if [[ -f "$PRO_CONFIG" ]]; then
    if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
      pro_badge="${GREEN}aktif${NC} ${DIM}(limit sesi + Telegram)${NC}"
    else
      pro_badge="${GREEN}aktif${NC} ${DIM}(limit sesi)${NC}"
    fi
  fi

  echo -e "${CYAN}$BOX_TOP${NC}"
  box_line "${WHITE}${BOLD}CHANELOG VPN TUNNEL MANAGER${NC}"
  box_line "${PURPLE}PRO EDITION${NC}"
  echo -e "${CYAN}$BOX_MID${NC}"
  box_line "${YELLOW}Domain${NC}   ${WHITE}$domain${NC}"
  box_line "${YELLOW}IP VPS${NC}   ${WHITE}$ip${NC}"
  box_line "${YELLOW}Uptime${NC}   ${WHITE}$uptime${NC}   ${YELLOW}Load${NC} ${WHITE}$load${NC}"
  box_line "${YELLOW}CPU${NC}      ${WHITE}${cpu_cores} core${NC}   ${YELLOW}RAM${NC} ${WHITE}$mem${NC}"
  box_line "${YELLOW}Disk${NC}     ${WHITE}$disk${NC}"
  echo -e "${CYAN}$BOX_MID${NC}"
  box_line "$(dot $xray_on) Xray   $(dot $nginx_on) Nginx   $(dot $db_on) Dropbear"
  box_line "$(dot $stunnel_on) Stunnel4   $(dot $haproxy_on) HAProxy"
  echo -e "${CYAN}$BOX_MID${NC}"
  box_line "${YELLOW}Multiplex 443${NC}  $mux_badge"
  box_line "${YELLOW}Fitur Pro${NC}      $pro_badge"
  echo -e "${CYAN}$BOX_MID${NC}"
  box_line "${WHITE}${total_akun} akun aktif${NC}  ${DIM}(VMess $vmess_count · VLess $vless_count · Trojan $trojan_count · SS $ss_count · SSH $ssh_count)${NC}"
  echo -e "${CYAN}$BOX_BOT${NC}"
}

menu_item() {
  printf "  ${YELLOW}[%-2s]${NC} %s\n" "$1" "$2"
}

main_menu() {
  show_header
  echo ""
  echo -e "  ${WHITE}${BOLD}PROTOKOL${NC}"
  echo -e "  ${DIM}$LINE${NC}"
  menu_item 1  "SSH / SSH-WS / SSH-SSL"
  menu_item 2  "VMess WS"
  menu_item 3  "VLess WS"
  menu_item 4  "Trojan WS/gRPC"
  menu_item 5  "Shadowsocks WS/gRPC"
  echo ""
  echo -e "  ${WHITE}${BOLD}SISTEM${NC}"
  echo -e "  ${DIM}$LINE${NC}"
  menu_item 6  "Nginx Management"
  menu_item 7  "Dropbear Management"
  menu_item 8  "HAProxy SSH-WS SSL"
  menu_item 9  "Change Domain"
  menu_item 10 "Update Script"
  menu_item 12 "Status Layanan"
  menu_item 13 "System Info"
  echo ""
  echo -e "  ${PURPLE}${BOLD}LAINNYA${NC}"
  echo -e "  ${DIM}$LINE${NC}"
  echo -e "  ${RED}[11]${NC} Uninstall"
  echo -e "  ${DIM}[0]${NC}  Exit"
  echo -e "  ${DIM}$LINE${NC}"
  echo ""
  echo -ne "  ${WHITE}Pilih menu [0-13]${NC}: "
  read -r choice

  case "$choice" in
    1) bash $SCRIPT_DIR/menu/sshws.sh ;;
    2) bash $SCRIPT_DIR/menu/vmess.sh ;;
    3) bash $SCRIPT_DIR/menu/vless.sh ;;
    4) bash $SCRIPT_DIR/menu/trojan.sh ;;
    5) bash $SCRIPT_DIR/menu/ss.sh ;;
    6) bash $SCRIPT_DIR/menu/nginx.sh ;;
    7) bash $SCRIPT_DIR/menu/dropbear.sh ;;
    8) bash $SCRIPT_DIR/menu/haproxy.sh ;;
    9) bash $SCRIPT_DIR/menu/changedomain.sh ;;
    10) bash $SCRIPT_DIR/menu/update.sh ;;
    11) bash $SCRIPT_DIR/menu/uninstall.sh ;;
    12) bash $SCRIPT_DIR/menu/services.sh ;;
    13) bash $SCRIPT_DIR/menu/sysinfo.sh ;;
    0) clear; exit 0 ;;
    *) echo -e "  ${RED}[!] Pilihan tidak valid!${NC}"; sleep 1; main_menu ;;
  esac
}

main_menu
