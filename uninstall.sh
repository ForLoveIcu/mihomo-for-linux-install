#!/bin/bash

echo "正在卸载 mihomo..."

# 停止服务
systemctl stop mihomo
systemctl disable mihomo

# 删除服务文件
rm -f /etc/systemd/system/mihomo.service
systemctl daemon-reload

# 删除程序目录
rm -rf /etc/mihomo

# 从 bashrc 中移除
sed -i '/clash_control.sh/d' /etc/bashrc

echo "mihomo 已完全卸载"
