#!/bin/bash

# Mihomo Linux 一键安装脚本 v2.2.2
# 支持多架构、多系统、智能下载、资源配置管理、覆盖安装
# 项目地址: https://github.com/ForLoveIcu/mihomo-for-linux-install

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 加载资源配置
load_config() {
    # 内置基本配置（作为备用）
    MIHOMO_VERSION="v1.19.12"
    WEBUI_VERSION="v1.19.12"

    # 架构文件映射 - 使用正确的文件名
    declare -A ARCH_FILES=(
        ["x86_64"]="mihomo-linux-amd64-compatible-v1.19.12.gz"
        ["aarch64"]="mihomo-linux-arm64-v1.19.12.gz"
        ["arm64"]="mihomo-linux-arm64-v1.19.12.gz"
        ["armv7l"]="mihomo-linux-armv7-v1.19.12.gz"
    )

    # 下载地址
    MIHOMO_BASE_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.19.12"
    WEBUI_DOWNLOAD_URL="https://github.com/MetaCubeX/metacubexd/releases/download/v1.189.0/compressed-dist.tgz"

    log_info "已加载内置资源配置 (Mihomo $MIHOMO_VERSION)"
}

# 检测系统架构并返回对应的下载文件名
detect_arch() {
    local arch=$(uname -m)

    # 直接返回对应的文件名
    case $arch in
        x86_64)
            echo "mihomo-linux-amd64-compatible-v1.19.12.gz"
            ;;
        aarch64|arm64)
            echo "mihomo-linux-arm64-v1.19.12.gz"
            ;;
        armv7l)
            echo "mihomo-linux-armv7-v1.19.12.gz"
            ;;
        *)
            log_error "不支持的架构: $arch"
            log_error "支持的架构: x86_64, aarch64, arm64, armv7l"
            exit 1
            ;;
    esac
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    local os=$(detect_os)
    log_info "安装必要依赖..."
    
    case $os in
        ubuntu|debian)
            apt-get update
            apt-get install -y curl wget unzip file
            ;;
        centos|rhel|rocky)
            yum install -y curl wget unzip file
            ;;
        *)
            log_warn "未知系统，跳过依赖安装。请确保已安装 curl, wget, unzip, file"
            ;;
    esac
}

# GitHub 加速镜像列表 - 仅包含经过实际测试可用的镜像
get_github_mirrors() {
    # 经过实际测试确认可用的镜像服务
    echo "https://ghfast.top/"
    echo "https://cors.isteed.cc/github.com"
    echo "https://hub.gitmirror.com/"
    echo ""  # 原始地址作为最后备选
}

# 智能下载文件 - 支持多镜像加速
download_file() {
    local original_url=$1
    local output=$2
    local max_attempts=3

    # 获取镜像列表
    local mirrors=($(get_github_mirrors))

    # 遍历每个镜像进行下载尝试
    for mirror in "${mirrors[@]}"; do
        local download_url
        if [ -z "$mirror" ]; then
            # 空镜像表示使用原始地址
            download_url="$original_url"
            log_info "尝试原始地址下载: GitHub.com"
        else
            # 使用镜像加速
            download_url="${mirror}${original_url#https://}"
            log_info "尝试镜像加速下载: $mirror"
        fi

        # 对每个镜像进行多次重试
        for i in $(seq 1 $max_attempts); do
            log_info "下载尝试 ($i/$max_attempts): $(basename "$output")"
            if curl -L --connect-timeout 8 --max-time 120 -o "$output" "$download_url" 2>/dev/null; then
                # 验证下载的文件
                if [ -f "$output" ]; then
                    # 检查文件格式
                    local file_type=$(file "$output" 2>/dev/null || echo "unknown")
                    if echo "$file_type" | grep -q "HTML\|XML"; then
                        log_warn "下载的文件格式不正确 ($file_type)，可能是镜像服务问题"
                        rm -f "$output"
                        break
                    fi
                    # 检查文件大小
                    local file_size=$(stat -c%s "$output" 2>/dev/null || echo "0")
                    if [ "$file_size" -lt 100 ]; then
                        log_warn "下载的文件太小 (${file_size} bytes)，可能不是正确的文件"
                        rm -f "$output"
                        break
                    fi
                    log_success "下载成功: $output (${file_size} bytes)"
                    return 0
                fi
            fi
            log_warn "下载失败，重试中..."
            sleep 1
        done

        if [ -z "$mirror" ]; then
            log_warn "原始地址下载失败"
        else
            log_warn "镜像 $mirror 下载失败，尝试下一个镜像..."
        fi
    done

    log_error "所有镜像下载失败: $original_url"
    log_error "请检查网络连接或稍后重试"
    return 1
}

# 创建便捷命令
create_convenience_commands() {
    # clashon - 启动服务
    cat > /usr/local/bin/clashon << 'EOF'
#!/bin/bash
echo "🚀 启动 Mihomo 服务..."
if systemctl start mihomo; then
    echo "✅ Mihomo 服务已启动"
    echo "🌐 管理界面: http://$(hostname -I | awk '{print $1}'):9090"
else
    echo "❌ 启动失败，请检查日志: journalctl -u mihomo"
fi
EOF

    # clashoff - 停止服务并清理代理
    cat > /usr/local/bin/clashoff << 'EOF'
#!/bin/bash
echo "🛑 停止 Mihomo 服务..."
if systemctl stop mihomo; then
    echo "✅ Mihomo 服务已停止"
    # 清理系统代理
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    unset all_proxy ALL_PROXY no_proxy NO_PROXY
    echo "🧹 系统代理已清理"
else
    echo "❌ 停止失败，请检查日志: journalctl -u mihomo"
fi
EOF

    # clashstatus - 查看状态
    cat > /usr/local/bin/clashstatus << 'EOF'
#!/bin/bash
echo "📊 Mihomo 服务状态"
systemctl status mihomo --no-pager
echo ""
echo "🔌 端口监听状态"
netstat -tlnp | grep -E ":(7890|7891|9090)" || echo "没有监听端口"
EOF

    # clashlog - 查看日志
    cat > /usr/local/bin/clashlog << 'EOF'
#!/bin/bash
echo "📋 Mihomo 实时日志 (Ctrl+C 退出)"
journalctl -u mihomo -f
EOF

    # clashrestart - 重启服务
    cat > /usr/local/bin/clashrestart << 'EOF'
#!/bin/bash
echo "🔄 重启 Mihomo 服务..."
systemctl restart mihomo && echo "✅ Mihomo 服务已重启"
EOF

    # clashuninstall - 完整卸载
    cat > /usr/local/bin/clashuninstall << 'EOF'
#!/bin/bash
echo "🗑️  启动 Mihomo 卸载程序..."
if [ -f "/etc/mihomo/uninstall.sh" ]; then
    bash /etc/mihomo/uninstall.sh
elif [ -f "$(dirname "$0")/uninstall.sh" ]; then
    bash "$(dirname "$0")/uninstall.sh"
elif [ -f "/usr/local/share/mihomo/uninstall.sh" ]; then
    bash /usr/local/share/mihomo/uninstall.sh
else
    echo "❌ 未找到卸载脚本"
    echo "请手动下载并运行: https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh"
    echo "或使用命令: curl -fsSL https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh | sudo bash"
fi
EOF

    # clashfrontend - 前端管理
    cat > /usr/local/bin/clashfrontend << 'EOF'
#!/bin/bash
echo "🎨 启动前端管理工具..."
if [ -f "/etc/mihomo/frontend_manager.sh" ]; then
    bash /etc/mihomo/frontend_manager.sh "$@"
else
    echo "❌ 前端管理脚本不存在"
    echo "请重新安装或手动下载: https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/frontend_manager.sh"
fi
EOF

    chmod +x /usr/local/bin/clash{on,off,status,log,restart,uninstall,frontend}
}

# 前端选择函数
choose_frontend() {
    echo ""
    echo -e "${CYAN}🎨 选择前端界面${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
    echo "请选择要安装的前端界面："
    echo ""
    echo "  1) MetaCubeXD (推荐)"
    echo "     • 官方维护，功能完整"
    echo "     • 稳定可靠，兼容性好"
    echo "     • 适合生产环境使用"
    echo ""
    echo "  2) Zashboard"
    echo "     • 现代化设计，界面美观"
    echo "     • 移动端友好，响应式布局"
    echo "     • 基于 Vue 3，性能优秀"
    echo ""

    while true; do
        read -p "请输入选择 [1-2] (默认: 1): " frontend_choice
        frontend_choice=${frontend_choice:-1}

        case "$frontend_choice" in
            1)
                SELECTED_FRONTEND="metacubexd"
                log_info "已选择: MetaCubeXD"
                break
                ;;
            2)
                SELECTED_FRONTEND="zashboard"
                log_info "已选择: Zashboard"
                break
                ;;
            *)
                echo "❌ 无效选择，请输入 1 或 2"
                ;;
        esac
    done
}


# 安装 MetaCubeXD 前端
install_metacubexd() {
    log_info "安装 MetaCubeXD 前端..."
    local download_url="https://github.com/MetaCubeX/metacubexd/releases/download/v1.189.0/compressed-dist.tgz"
    download_file "$download_url" "/tmp/ui.tgz"
    rm -rf /etc/mihomo/ui
    mkdir -p /etc/mihomo/ui
    tar -xzf /tmp/ui.tgz -C /etc/mihomo/ui
    echo "metacubexd" > /etc/mihomo/ui/.frontend_info
    echo "MetaCubeXD v1.189.0" > /etc/mihomo/ui/.frontend_version
    log_success "MetaCubeXD 前端安装完成"
}

# 安装 Zashboard 前端
install_zashboard() {
    log_info "安装 Zashboard 前端..."
    local download_url="https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
    download_file "$download_url" "/tmp/ui.zip"
    rm -rf /etc/mihomo/ui
    mkdir -p /etc/mihomo/ui
    unzip -q /tmp/ui.zip -d /etc/mihomo/ui
    echo "zashboard" > /etc/mihomo/ui/.frontend_info
    echo "Zashboard latest" > /etc/mihomo/ui/.frontend_version
    log_success "Zashboard 前端安装完成"
}

# 安装前端界面
install_frontend() {
    # 如果没有选择前端，进行选择
    if [ -z "$SELECTED_FRONTEND" ]; then
        choose_frontend
    fi

    case "$SELECTED_FRONTEND" in
        "metacubexd")
            install_metacubexd
            ;;
        "zashboard")
            install_zashboard
            ;;
        *)
            log_warn "未知前端选择，使用默认的 MetaCubeXD"
            install_metacubexd
            ;;
    esac
}

# 主安装函数
main() {
    log_info "开始安装 Mihomo..."

    # 加载配置
    load_config

    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本"
        exit 1
    fi

    # 检查并处理已存在的安装
    if [ -f "/opt/mihomo/mihomo" ] || [ -d "/etc/mihomo" ]; then
        log_warn "检测到 Mihomo 已安装。"
        read -p "是否要覆盖安装？[y/N]: " choice
        choice=${choice:-N}

        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            log_info "操作已取消。"
            exit 0
        fi

        if systemctl is-active --quiet mihomo; then
            log_info "正在停止现有的 Mihomo 服务..."
            systemctl stop mihomo
        fi
    fi
    
    # 检测架构并获取对应的文件名
    local arch_name=$(uname -m)
    local arch_file=$(detect_arch)
    log_info "检测到架构: $arch_name"
    log_info "目标版本: $MIHOMO_VERSION"
    log_info "下载文件: $arch_file"

    # 验证架构文件名不为空
    if [ -z "$arch_file" ]; then
        log_error "无法确定架构对应的文件名"
        exit 1
    fi

    # 安装依赖
    install_dependencies

    # 创建目录
    mkdir -p /etc/mihomo
    mkdir -p /opt/mihomo

    # 下载 Mihomo 核心
    local mihomo_url="${MIHOMO_BASE_URL}/${arch_file}"
    log_info "下载地址: $mihomo_url"
    download_file "$mihomo_url" "/tmp/mihomo.gz"
    
    # 解压并安装
    gunzip -c /tmp/mihomo.gz > /opt/mihomo/mihomo
    chmod +x /opt/mihomo/mihomo
    
    # 安装前端界面
    if [ ! -f "/etc/mihomo/ui/.frontend_info" ]; then
        install_frontend
    else
        log_info "检测到已安装前端UI，跳过安装。如需更换，请使用 'clashfrontend' 命令。"
    fi
    
    # 创建配置文件
    if [ ! -f "/etc/mihomo/config.yaml" ]; then
        cat > /etc/mihomo/config.yaml << 'EOF'
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
external-controller: 0.0.0.0:9090
external-ui: ui

dns:
  enable: true
  listen: 0.0.0.0:53
  nameserver:
    - 8.8.8.8
    - 1.1.1.1

proxies: []

proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - DIRECT

rules:
  - DOMAIN-SUFFIX,local,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - MATCH,PROXY
EOF
    fi
    
    # 创建 systemd 服务
    cat > /etc/systemd/system/mihomo.service << 'EOF'
[Unit]
Description=Mihomo Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/opt/mihomo/mihomo -d /etc/mihomo
WorkingDirectory=/etc/mihomo

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载并启动服务
    systemctl daemon-reload
    systemctl enable mihomo
    systemctl start mihomo
    
    # 创建完整的便捷命令系统
    create_convenience_commands

    log_success "便捷命令已创建: clashon, clashoff, clashstatus, clashlog, clashrestart, clashuninstall, clashfrontend"

    # 下载并安装管理脚本
    log_info "安装管理脚本..."
    if download_file "https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh" "/etc/mihomo/uninstall.sh"; then
        chmod +x /etc/mihomo/uninstall.sh
    fi
    if download_file "https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/frontend_manager.sh" "/etc/mihomo/frontend_manager.sh"; then
        chmod +x /etc/mihomo/frontend_manager.sh
    fi
    log_success "管理脚本已安装到 /etc/mihomo/"

    # 清理临时文件
    rm -f /tmp/mihomo.gz /tmp/ui.tgz /tmp/ui.zip
    
    log_success "Mihomo 安装完成！"
    log_info "管理界面: http://$(hostname -I | awk '{print $1}'):9090"
    log_info "使用 'clashon' 启动，'clashoff' 停止"
}

# 执行主函数
main "$@"
