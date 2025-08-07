#!/bin/bash

# Mihomo Linux 安装脚本 v2.0.0 - 重构版
# 支持多架构、智能下载、完善错误处理

set -e

# 设置变量
MihomoDir="/etc/mihomo"
ConfigFile="config.yaml"
CountryFile="Country.mmdb"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 /etc/mihomo 目录是否存在
if [ -d "$MihomoDir" ]; then
    read -p "/etc/mihomo 目录已存在，是否覆盖？[y/N]: " choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo "取消安装"
        exit 0
    fi
    echo "正在覆盖 /etc/mihomo 目录..."
    rm -rf "$MihomoDir"
fi

# 创建 /etc/mihomo 目录
echo "创建目录 /etc/mihomo..."
mkdir -p "$MihomoDir"

# 检查并终止正在运行的 mihomo 进程
echo "发现正在运行的 mihomo 进程，正在终止..."
pid=$(pgrep mihomo)
if [ -n "$pid" ]; then
    kill -9 "$pid"
fi

# 解压文件
echo "解压文件 $DistFile1 和 $DistFile2..."
if [ -f "$DistFile1" ]; then
    gunzip -c "$DistFile1" > "$MihomoDir/mihomo"
    chmod +x "$MihomoDir/mihomo"
else
    echo "找不到文件 $DistFile1，跳过解压"
fi

if [ -f "$DistFile2" ]; then
    mkdir -p "$MihomoDir/ui"
    tar -xvzf "$DistFile2" -C "$MihomoDir/ui"
else
    echo "找不到文件 $DistFile2，跳过解压"
fi

# 复制 config.yaml 文件到 /etc/mihomo
if [ -f "$ConfigFile" ]; then
    cp "$ConfigFile" "$MihomoDir/"
else
    echo "找不到 config.yaml，跳过复制"
fi

# 复制 Country.mmdb 到 /etc/mihomo
if [ -f "$CountryFile" ]; then
    echo "复制 $CountryFile 到 $MihomoDir..."
    sudo cp "$CountryFile" "$MihomoDir/"
else
    echo "找不到文件 $CountryFile，跳过复制"
fi

# 创建 systemd 配置文件
echo "创建 systemd 配置文件..."
cat > /etc/systemd/system/mihomo.service << EOF
[Unit]
Description=mihomo Daemon, Another Clash Kernel.
After=network.target NetworkManager.service systemd-networkd.service iwd.service

[Service]
Type=simple
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
Restart=always
ExecStartPre=/usr/bin/sleep 1s
ExecStart=/etc/mihomo/mihomo -d /etc/mihomo
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload

# 启动 mihomo 服务
echo "启动 mihomo 服务..."
systemctl start mihomo

# 创建代理控制脚本
echo "创建代理控制脚本..."
cat > /etc/mihomo/clash_control.sh << 'EOF'
#!/bin/bash
# shellcheck disable=SC2015
# shellcheck disable=SC2155

# clash快捷指令
function clashon() {
    sudo systemctl start mihomo && echo '已开启代理环境' || echo '启动失败: 执行 "systemctl status mihomo" 查看日志' || return 1
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
}

function clashoff() {
    sudo systemctl stop mihomo && echo '已关闭代理环境' || echo '关闭失败: 执行 "systemctl status mihomo" 查看日志' || return 1
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
}

function clashui() {
    local local_ip=$(hostname -I | awk '{print $1}')
    local public_ip=$(curl -s ifconfig.me)
    local port=9090
    echo "内网 UI 地址: http://$local_ip:$port/ui"
    echo "公网 UI 地址: http://$public_ip:$port/ui"
}

function clashuninstall() {
    echo "🗑️  启动 Mihomo 卸载程序..."
    if [ -f "/etc/mihomo/uninstall.sh" ]; then
        sudo bash /etc/mihomo/uninstall.sh
    elif [ -f "$(dirname "${BASH_SOURCE[0]}")/uninstall.sh" ]; then
        sudo bash "$(dirname "${BASH_SOURCE[0]}")/uninstall.sh"
    else
        echo "❌ 未找到卸载脚本"
        echo "请手动下载并运行: https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh"
        echo "或使用命令: curl -fsSL https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh | sudo bash"
    fi
}

function clashfrontend() {
    echo "🎨 启动前端管理工具..."
    if [ -f "/etc/mihomo/frontend_manager.sh" ]; then
        sudo bash /etc/mihomo/frontend_manager.sh "$@"
    else
        echo "❌ 前端管理脚本不存在"
        echo "请重新安装或手动下载: https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/frontend_manager.sh"
    fi
}
EOF

# 给脚本加上执行权限
chmod 755 /etc/mihomo/clash_control.sh

# 添加到 ~/.bashrc 中
echo "将代理控制命令添加到 ~/.bashrc..."
echo "source /etc/mihomo/clash_control.sh" >> /etc/bashrc

# 重新加载 ~/.bashrc 配置
source ~/.bashrc

echo "安装完成！可以通过以下命令控制代理："
echo "- 启动代理环境: clashon"
echo "- 关闭代理环境: clashoff"
echo "- 查看 Web 面板地址: clashui"
echo "- 前端界面管理: clashfrontend"
echo "- 完整卸载程序: clashuninstall"
echo "注意：执行代理控制命令时需要管理员权限（sudo）。"

clashon
