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

# GitHub 加速镜像列表 - 针对网络受限环境优化
get_github_mirrors() {
    # 基于 XIU2 脚本中的可靠镜像源
    echo "https://ghfast.top/"
    echo "https://github.moeyy.xyz/"
    echo "https://gh.h233.eu.org/"
    echo "https://cors.isteed.cc/github.com"
    echo "https://hub.gitmirror.com/"
    echo "https://github.boki.moe/"
    echo "https://gh-proxy.net/"
    echo "https://ghproxy.net/"
    echo "https://gh-proxy.com/"
    echo "https://mirror.ghproxy.com/"
    echo "https://ghproxy.com/"
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
            download_url="${mirror}${original_url}"
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
                    if echo "$file_type" | grep -q "HTML\|text\|XML"; then
                        log_warn "下载的文件格式不正确 ($file_type)，可能是镜像服务问题"
                        rm -f "$output"
                        break  # 跳出重试循环，尝试下一个镜像
                    fi
                    # 检查文件大小
                    local file_size=$(stat -c%s "$output" 2>/dev/null || echo "0")
                    if [ "$file_size" -lt 1000 ]; then
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

    chmod +x /usr/local/bin/clash{on,off,status,log,restart}
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
    
    # 创建完整的便捷命令系统
    create_convenience_commands

    log_success "便捷命令已创建: clashon, clashoff, clashstatus, clashlog, clashrestart"
    
    # 清理临时文件
    rm -f /tmp/mihomo.gz /tmp/ui.tgz
    
    log_success "Mihomo 安装完成！"
    log_info "管理界面: http://$(hostname -I | awk '{print $1}'):9090"
    log_info "使用 'clashon' 启动，'clashoff' 停止"
}

# 执行主函数
main "$@"
