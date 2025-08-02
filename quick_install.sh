#!/bin/bash

# Mihomo Linux 一键安装脚本 v2.0.0
# 支持多架构、多系统、智能下载

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

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64-v1"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            log_error "不支持的架构: $arch"
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
            apt-get install -y curl wget unzip
            ;;
        centos|rhel|rocky)
            yum install -y curl wget unzip
            ;;
        *)
            log_warn "未知系统，跳过依赖安装"
            ;;
    esac
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    local max_attempts=3
    
    for i in $(seq 1 $max_attempts); do
        log_info "尝试下载 ($i/$max_attempts): $url"
        if curl -L -o "$output" "$url"; then
            log_success "下载成功: $output"
            return 0
        fi
        log_warn "下载失败，重试中..."
        sleep 2
    done
    
    log_error "下载失败: $url"
    return 1
}

# 主安装函数
main() {
    log_info "开始安装 Mihomo..."
    
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本"
        exit 1
    fi
    
    # 检测架构
    local arch=$(detect_arch)
    log_info "检测到架构: $arch"
    
    # 安装依赖
    install_dependencies
    
    # 创建目录
    mkdir -p /etc/mihomo
    mkdir -p /opt/mihomo
    
    # 下载 Mihomo 核心
    local mihomo_url="https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-${arch}.gz"
    download_file "$mihomo_url" "/tmp/mihomo.gz"
    
    # 解压并安装
    gunzip -c /tmp/mihomo.gz > /opt/mihomo/mihomo
    chmod +x /opt/mihomo/mihomo
    
    # 下载 WebUI
    local ui_url="https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
    download_file "$ui_url" "/tmp/ui.tgz"
    
    mkdir -p /etc/mihomo/ui
    tar -xzf /tmp/ui.tgz -C /etc/mihomo/ui
    
    # 创建配置文件
    if [ ! -f /etc/mihomo/config.yaml ]; then
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
    
    # 创建便捷命令
    cat > /usr/local/bin/clashon << 'EOF'
#!/bin/bash
systemctl start mihomo && echo "✅ Mihomo 已启动"
EOF
    
    cat > /usr/local/bin/clashoff << 'EOF'
#!/bin/bash
systemctl stop mihomo && echo "✅ Mihomo 已停止"
EOF
    
    chmod +x /usr/local/bin/clashon /usr/local/bin/clashoff
    
    # 清理临时文件
    rm -f /tmp/mihomo.gz /tmp/ui.tgz
    
    log_success "Mihomo 安装完成！"
    log_info "管理界面: http://$(hostname -I | awk '{print $1}'):9090"
    log_info "使用 'clashon' 启动，'clashoff' 停止"
}

# 执行主函数
main "$@"
