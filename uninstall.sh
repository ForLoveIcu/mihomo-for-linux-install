#!/bin/bash

# 设置变量
MihomoDir="/etc/mihomo"
BashrcFile="$HOME/.bashrc"
SystemdServiceFile="/etc/systemd/system/mihomo.service"

# 停止 mihomo 服务
echo "停止 mihomo 服务..."
sudo systemctl stop mihomo

# 禁用 mihomo 服务
echo "禁用 mihomo 服务..."
sudo systemctl disable mihomo

# 删除 /etc/mihomo 目录及其内容
echo "删除 /etc/mihomo 目录及其内容..."
sudo rm -rf "$MihomoDir"

# 从 ~/.bashrc 中移除对 clash_control.sh 的引用
echo "从 ~/.bashrc 中移除对 clash_control.sh 的引用..."
sed -i '/source \/etc\/mihomo\/clash_control.sh/d' "$BashrcFile"
sed -i '/source \/etc\/mihomo\/clash_control.sh/d' "/etc/bashrc"
# 重新加载 ~/.bashrc 配置
source "$BashrcFile"

# 删除 systemd 配置文件
echo "删除 systemd 配置文件..."
sudo rm -f "$SystemdServiceFile"

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
sudo systemctl daemon-reload

echo "卸载完成！"
