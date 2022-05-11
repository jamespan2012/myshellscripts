#!/usr/bin/env bash
cat > /etc/systemd/system/sysctl-ipt.service <<EOF
[Unit]
Description=Run a Custom Script at Startup
After=default.target
[Service]
ExecStart=sysctl -p
[Install]
WantedBy=default.target
EOF
systemctl daemon-reload
systemctl enable sysctl-ipt.service
systemctl restart sysctl-ipt.service