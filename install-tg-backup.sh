#!/bin/bash
# Installer tg-backup (jalankan sebagai root, satu folder dengan tg-backup.py)
set -e
[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root"; exit 1; }

apt-get install -y python3 curl >/dev/null 2>&1 || true

install -m 755 "$(dirname "$0")/tg-backup.py" /usr/local/bin/tg-backup.py

if [ ! -f /etc/tg-backup.conf ]; then
  # Ambil default dari menu Bot Telegram panel (kalau sudah diisi)
  D_TOKEN=""; D_ID=""
  if [ -f /etc/vpn-script/.pro-config ]; then
    D_TOKEN=$(grep -m1 '^TELEGRAM_BOT_TOKEN=' /etc/vpn-script/.pro-config | cut -d= -f2- | tr -d '"')
    D_ID=$(grep -m1 '^TELEGRAM_CHAT_ID=' /etc/vpn-script/.pro-config | cut -d= -f2- | tr -d '"')
  fi
  read -rp "BOT_TOKEN [${D_TOKEN:+pakai token panel, Enter}]: " TOKEN
  read -rp "ADMIN_ID  [${D_ID:-chat id Telegram kamu}]: " AID
  TOKEN=${TOKEN:-$D_TOKEN}; AID=${AID:-$D_ID}
  [ -n "$TOKEN" ] && [ -n "$AID" ] || { echo "Token/ID kosong"; exit 1; }
  printf 'BOT_TOKEN=%s\nADMIN_ID=%s\n' "$TOKEN" "$AID" > /etc/tg-backup.conf
  chmod 600 /etc/tg-backup.conf
fi

cat > /etc/systemd/system/tg-backup-bot.service <<'EOF'
[Unit]
Description=Telegram Backup/Restore Bot
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/tg-backup.py bot
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Backup otomatis tiap hari jam 03:00
echo '0 3 * * * root /usr/bin/python3 /usr/local/bin/tg-backup.py backup >/dev/null 2>&1' > /etc/cron.d/tg-backup

systemctl daemon-reload
systemctl enable --now tg-backup-bot
echo "Selesai. Buka bot di Telegram lalu kirim /start"
