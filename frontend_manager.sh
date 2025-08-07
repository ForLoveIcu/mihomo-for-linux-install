#!/bin/bash

# Mihomo 前端管理脚本
# 版本: v2.2.2+
# 更新时间: 2025-08-07

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置文件路径
RESOURCES_CONF="/etc/mihomo/resources.conf"
MIHOMO_DIR="/etc/mihomo"
UI_DIR="$MIHOMO_DIR/ui"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 加载配置文件
load_config() {
    if [ -f "$RESOURCES_CONF" ]; then
        source "$RESOURCES_CONF"
    else
        log_error "配置文件不存在: $RESOURCES_CONF"
        exit 1
    fi
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo bash frontend_manager.sh"
        exit 1
    fi
}

# 获取当前前端
get_current_frontend() {
    if [ -f "$UI_DIR/.frontend_info" ]; then
        cat "$UI_DIR/.frontend_info"
    else
        echo "unknown"
    fi
}

# 显示前端信息
show_frontend_info() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Mihomo 前端管理工具${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
    
    local current_frontend=$(get_current_frontend)
    echo -e "${BLUE}当前前端:${NC} $current_frontend"
    echo ""
    
    echo -e "${YELLOW}可用前端:${NC}"
    echo "  1. metacubexd  - 官方前端，功能完整，稳定可靠"
    echo "  2. zashboard   - 现代化设计，移动端友好，界面美观"
    echo ""
}

# 下载并安装 MetaCubeXD
install_metacubexd() {
    log_info "正在安装 MetaCubeXD 前端..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 下载前端文件
    log_info "下载 MetaCubeXD..."
    if ! curl -fsSL "$METACUBEXD_DOWNLOAD_URL" -o metacubexd.tgz; then
        log_error "MetaCubeXD 下载失败"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 备份现有前端
    if [ -d "$UI_DIR" ]; then
        log_info "备份现有前端..."
        mv "$UI_DIR" "${UI_DIR}.backup.$(date +%s)"
    fi
    
    # 创建 UI 目录
    mkdir -p "$UI_DIR"
    
    # 解压前端文件
    log_info "解压 MetaCubeXD..."
    tar -xzf metacubexd.tgz -C "$UI_DIR" --strip-components=1
    
    # 记录前端信息
    echo "metacubexd" > "$UI_DIR/.frontend_info"
    echo "MetaCubeXD v$METACUBEXD_VERSION" > "$UI_DIR/.frontend_version"
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_success "MetaCubeXD 安装完成"
}

# 下载并安装 Zashboard
install_zashboard() {
    log_info "正在安装 Zashboard 前端..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 下载前端文件
    log_info "下载 Zashboard..."
    if ! curl -fsSL "$ZASHBOARD_DOWNLOAD_URL" -o zashboard.zip; then
        log_error "Zashboard 下载失败"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 备份现有前端
    if [ -d "$UI_DIR" ]; then
        log_info "备份现有前端..."
        mv "$UI_DIR" "${UI_DIR}.backup.$(date +%s)"
    fi
    
    # 创建 UI 目录
    mkdir -p "$UI_DIR"
    
    # 解压前端文件
    log_info "解压 Zashboard..."
    unzip -q zashboard.zip -d "$UI_DIR"
    
    # 记录前端信息
    echo "zashboard" > "$UI_DIR/.frontend_info"
    echo "Zashboard $ZASHBOARD_VERSION" > "$UI_DIR/.frontend_version"
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_success "Zashboard 安装完成"
}

# 切换前端
switch_frontend() {
    local target_frontend="$1"
    
    case "$target_frontend" in
        "metacubexd"|"1")
            install_metacubexd
            ;;
        "zashboard"|"2")
            install_zashboard
            ;;
        *)
            log_error "不支持的前端: $target_frontend"
            log_info "支持的前端: metacubexd, zashboard"
            return 1
            ;;
    esac
    
    # 重启服务以应用更改
    if systemctl is-active --quiet mihomo; then
        log_info "重启 Mihomo 服务..."
        systemctl restart mihomo
        log_success "服务已重启"
    fi
}

# 显示使用帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  info                显示当前前端信息"
    echo "  switch <frontend>   切换前端 (metacubexd|zashboard)"
    echo "  install <frontend>  安装指定前端"
    echo "  help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 info                    # 显示前端信息"
    echo "  $0 switch metacubexd       # 切换到 MetaCubeXD"
    echo "  $0 switch zashboard        # 切换到 Zashboard"
    echo ""
}

# 交互式前端选择
interactive_mode() {
    show_frontend_info
    
    echo -e "${YELLOW}请选择要安装的前端:${NC}"
    echo "  1) MetaCubeXD (官方推荐)"
    echo "  2) Zashboard (现代化界面)"
    echo "  q) 退出"
    echo ""
    
    read -p "请输入选择 [1-2, q]: " choice
    
    case "$choice" in
        1|"metacubexd")
            switch_frontend "metacubexd"
            ;;
        2|"zashboard")
            switch_frontend "zashboard"
            ;;
        q|Q)
            log_info "已退出"
            exit 0
            ;;
        *)
            log_error "无效选择: $choice"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    check_root
    load_config
    
    case "${1:-interactive}" in
        "info")
            show_frontend_info
            ;;
        "switch")
            if [ -z "$2" ]; then
                log_error "请指定要切换的前端"
                show_help
                exit 1
            fi
            switch_frontend "$2"
            ;;
        "install")
            if [ -z "$2" ]; then
                log_error "请指定要安装的前端"
                show_help
                exit 1
            fi
            switch_frontend "$2"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "interactive"|"")
            interactive_mode
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
