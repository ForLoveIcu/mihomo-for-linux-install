#!/bin/bash

# Mihomo Linux 安装脚本 v2.0.0 - 重构版
# 支持多架构、智能下载、完善错误处理

set -e

# 设置变量
MihomoDir="/etc/mihomo"
ConfigFile="config.yaml"
CountryFile="Country.mmdb"

# 加载资源配置
load_config() {
    # 尝试加载 resources.conf 配置文件
    if [ -f "resources.conf" ]; then
        source resources.conf
        log_info "已加载 resources.conf 配置文件"
    else
        # 内置备用配置
        log_warn "未找到 resources.conf，使用内置配置"
        ARCH_x86_64_MIHOMO="mihomo-linux-amd64-compatible-v1.19.12.gz"
        ARCH_aarch64_MIHOMO="mihomo-linux-arm64-v1.19.12.gz"
        ARCH_arm64_MIHOMO="mihomo-linux-arm64-v1.19.12.gz"
        ARCH_armv7l_MIHOMO="mihomo-linux-armv7-v1.19.12.gz"
        BUILTIN_WEBUI="metacubexd.tgz"
    fi
}

# 检测系统架构并返回对应的文件名
detect_arch_file() {
    local arch=$(uname -m)

    case $arch in
        x86_64)
            echo "${ARCH_x86_64_MIHOMO:-mihomo-linux-amd64-compatible-v1.19.12.gz}"
            ;;
        aarch64)
            echo "${ARCH_aarch64_MIHOMO:-mihomo-linux-arm64-v1.19.12.gz}"
            ;;
        arm64)
            echo "${ARCH_arm64_MIHOMO:-mihomo-linux-arm64-v1.19.12.gz}"
            ;;
        armv7l)
            echo "${ARCH_armv7l_MIHOMO:-mihomo-linux-armv7-v1.19.12.gz}"
            ;;
        *)
            log_error "不支持的架构: $arch"
            log_error "支持的架构: x86_64, aarch64, arm64, armv7l"
            exit 1
            ;;
    esac
}

# 查找文件（支持多个可能的路径）
find_file() {
    local filename=$1
    local search_paths=("." "binaries" "../binaries")

    for path in "${search_paths[@]}"; do
        if [ -f "$path/$filename" ]; then
            echo "$path/$filename"
            return 0
        fi
    done

    # 如果在搜索路径中找不到，返回原始文件名（可能在当前目录）
    echo "$filename"
    return 1
}

# 设置分发文件变量
setup_dist_files() {
    # 如果变量已经设置（从外部传入），则不覆盖
    if [ -z "$DistFile1" ]; then
        local arch_file=$(detect_arch_file)
        DistFile1=$(find_file "$arch_file")
        log_info "设置 DistFile1: $DistFile1"
    else
        log_info "使用外部设置的 DistFile1: $DistFile1"
    fi

    if [ -z "$DistFile2" ]; then
        local webui_file="${BUILTIN_WEBUI:-metacubexd.tgz}"
        DistFile2=$(find_file "$webui_file")
        log_info "设置 DistFile2: $DistFile2"
    else
        log_info "使用外部设置的 DistFile2: $DistFile2"
    fi
}

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

# 初始化配置和文件变量
log_info "初始化安装配置..."
load_config
setup_dist_files

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
echo "检查正在运行的 mihomo 进程..."
pid=$(pgrep mihomo 2>/dev/null || true)
if [ -n "$pid" ]; then
    echo "发现正在运行的 mihomo 进程 (PID: $pid)，正在终止..."
    kill -9 "$pid" 2>/dev/null || true
    sleep 1
    # 再次检查是否成功终止
    if pgrep mihomo >/dev/null 2>&1; then
        log_warn "mihomo 进程可能仍在运行，请手动检查"
    else
        log_success "mihomo 进程已成功终止"
    fi
else
    echo "未发现运行中的 mihomo 进程"
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
    echo "复制 $ConfigFile 到 $MihomoDir..."
    cp "$ConfigFile" "$MihomoDir/"
    log_success "config.yaml 复制完成"
else
    echo "找不到 config.yaml，跳过复制"
fi

# 复制 Country.mmdb 到 /etc/mihomo
if [ -f "$CountryFile" ]; then
    echo "复制 $CountryFile 到 $MihomoDir..."
    cp "$CountryFile" "$MihomoDir/"
    log_success "Country.mmdb 复制完成"
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

# 启动 mihomo 服务并设置代理环境
log_info "启动 Mihomo 服务..."
if systemctl start mihomo; then
    log_success "Mihomo 服务已启动"
    echo "🌐 管理界面: http://$(hostname -I | awk '{print $1}' 2>/dev/null || echo '127.0.0.1'):9090/ui"
    echo ""
    echo "💡 提示：重新加载 shell 配置以使用便捷命令："
    echo "   source ~/.bashrc"
else
    log_error "Mihomo 服务启动失败，请检查日志: journalctl -u mihomo"
fi
