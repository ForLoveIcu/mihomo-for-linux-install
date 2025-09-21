#!/bin/bash

# GitHub 镜像测试脚本
# 用于测试各个 GitHub 加速服务的可用性和速度

set -e

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

# GitHub 加速镜像列表
get_github_mirrors() {
    echo "https://ghproxylist.com/"
    echo "https://ghproxy.com/"
    echo "https://mirror.ghproxy.com/"
    echo ""  # 原始地址
}

# 测试下载速度
test_download_speed() {
    local mirror=$1
    local test_url="https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64-compatible-v1.gz"
    local download_url
    
    if [ -z "$mirror" ]; then
        download_url="$test_url"
        log_info "测试原始地址: GitHub.com"
    else
        download_url="${mirror}${test_url}"
        log_info "测试镜像: $mirror"
    fi
    
    # 测试连接性和下载速度
    local start_time=$(date +%s)
    if curl -L --connect-timeout 10 --max-time 30 -o /dev/null -s "$download_url" 2>/dev/null; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "连接成功，耗时: ${duration}秒"
        return $duration
    else
        log_error "连接失败"
        return 999
    fi
}

# 主测试函数
main() {
    log_info "开始测试 GitHub 镜像服务..."
    echo "========================================"
    
    local mirrors=($(get_github_mirrors))
    local best_mirror=""
    local best_time=999
    
    for mirror in "${mirrors[@]}"; do
        echo ""
        test_download_speed "$mirror"
        local result=$?
        
        if [ $result -lt $best_time ]; then
            best_time=$result
            if [ -z "$mirror" ]; then
                best_mirror="原始地址"
            else
                best_mirror="$mirror"
            fi
        fi
        
        echo "----------------------------------------"
    done
    
    echo ""
    log_success "测试完成！"
    log_info "最快镜像: $best_mirror (${best_time}秒)"
    
    if [ "$best_mirror" = "https://ghproxylist.com/" ]; then
        log_success "ghproxylist.com 表现最佳，符合预期！"
    elif [ $best_time -eq 999 ]; then
        log_error "所有镜像都无法连接，请检查网络连接"
    else
        log_warn "建议使用: $best_mirror"
    fi
}

# 执行测试
main "$@"
