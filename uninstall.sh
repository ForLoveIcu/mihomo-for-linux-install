#!/bin/bash

# Mihomo 完整卸载脚本
# 版本: v2.2.2+
# 更新时间: 2025-08-07

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo bash uninstall.sh"
        exit 1
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${YELLOW}⚠️  警告：即将完全卸载 Mihomo 及其所有相关文件${NC}"
    echo ""
    echo "将要删除的内容："
    echo "  • Mihomo 系统服务"
    echo "  • /etc/mihomo/ 目录及所有配置文件"
    echo "  • 便捷命令 (clashon, clashoff, clashui, clashstatus, clashlog, clashrestart)"
    echo "  • Shell 配置中的相关设置"
    echo "  • 环境变量配置"
    echo ""

    read -p "确定要继续卸载吗？[y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
}

# 停止并禁用服务
stop_service() {
    log_info "停止 Mihomo 服务..."

    if systemctl is-active --quiet mihomo; then
        systemctl stop mihomo
        log_success "Mihomo 服务已停止"
    else
        log_warning "Mihomo 服务未运行"
    fi

    if systemctl is-enabled --quiet mihomo 2>/dev/null; then
        systemctl disable mihomo
        log_success "Mihomo 服务已禁用"
    else
        log_warning "Mihomo 服务未启用"
    fi
}

# 删除系统服务文件
remove_service_files() {
    log_info "删除系统服务文件..."

    if [ -f "/etc/systemd/system/mihomo.service" ]; then
        rm -f /etc/systemd/system/mihomo.service
        log_success "已删除 /etc/systemd/system/mihomo.service"
    else
        log_warning "系统服务文件不存在"
    fi

    systemctl daemon-reload
    log_success "已重新加载 systemd 配置"
}

# 删除程序目录和文件
remove_program_files() {
    log_info "删除程序目录和文件..."

    if [ -d "/etc/mihomo" ]; then
        rm -rf /etc/mihomo
        log_success "已删除 /etc/mihomo/ 目录"
    else
        log_warning "/etc/mihomo/ 目录不存在"
    fi
}

# 删除便捷命令
remove_convenience_commands() {
    log_info "删除便捷命令..."

    local commands=("clashon" "clashoff" "clashui" "clashstatus" "clashlog" "clashrestart" "clashuninstall")
    local removed_count=0

    for cmd in "${commands[@]}"; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            rm -f "/usr/local/bin/$cmd"
            log_success "已删除便捷命令: $cmd"
            ((removed_count++))
        fi
    done

    if [ $removed_count -eq 0 ]; then
        log_warning "未找到便捷命令文件"
    else
        log_success "共删除 $removed_count 个便捷命令"
    fi
}

# 清理 Shell 配置
clean_shell_config() {
    log_info "清理 Shell 配置..."

    # 清理系统级配置
    local system_configs=("/etc/bashrc" "/etc/bash.bashrc" "/etc/profile")
    local cleaned_system=0

    for config in "${system_configs[@]}"; do
        if [ -f "$config" ]; then
            if grep -q "clash_control.sh\|mihomo" "$config" 2>/dev/null; then
                sed -i '/clash_control\.sh/d' "$config"
                sed -i '/mihomo.*proxy/d' "$config"
                log_success "已清理 $config"
                ((cleaned_system++))
            fi
        fi
    done

    # 清理用户级配置
    local cleaned_users=0
    for user_home in /home/*; do
        if [ -d "$user_home" ] && [ -f "$user_home/.bashrc" ]; then
            local username=$(basename "$user_home")
            if grep -q "clash_control.sh\|mihomo" "$user_home/.bashrc" 2>/dev/null; then
                sed -i '/clash_control\.sh/d' "$user_home/.bashrc"
                sed -i '/mihomo.*proxy/d' "$user_home/.bashrc"
                log_success "已清理用户 $username 的 .bashrc"
                ((cleaned_users++))
            fi
        fi
    done

    # 清理 root 用户配置
    if [ -f "/root/.bashrc" ]; then
        if grep -q "clash_control.sh\|mihomo" "/root/.bashrc" 2>/dev/null; then
            sed -i '/clash_control\.sh/d' "/root/.bashrc"
            sed -i '/mihomo.*proxy/d' "/root/.bashrc"
            log_success "已清理 root 用户的 .bashrc"
            ((cleaned_users++))
        fi
    fi

    if [ $cleaned_system -eq 0 ] && [ $cleaned_users -eq 0 ]; then
        log_warning "未找到需要清理的 Shell 配置"
    else
        log_success "已清理 $cleaned_system 个系统配置和 $cleaned_users 个用户配置"
    fi
}

# 清理环境变量
clean_environment() {
    log_info "清理当前会话的代理环境变量..."

    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY

    log_success "已清理代理环境变量"
    log_warning "注意：其他终端会话的环境变量需要手动重启终端或重新登录"
}

# 验证卸载结果
verify_uninstall() {
    log_info "验证卸载结果..."

    local issues=0

    # 检查服务状态
    if systemctl list-unit-files | grep -q "mihomo.service"; then
        log_error "系统服务文件仍然存在"
        ((issues++))
    fi

    # 检查目录
    if [ -d "/etc/mihomo" ]; then
        log_error "/etc/mihomo/ 目录仍然存在"
        ((issues++))
    fi

    # 检查便捷命令
    local remaining_commands=()
    local commands=("clashon" "clashoff" "clashui" "clashstatus" "clashlog" "clashrestart" "clashuninstall")
    for cmd in "${commands[@]}"; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            remaining_commands+=("$cmd")
            ((issues++))
        fi
    done

    if [ ${#remaining_commands[@]} -gt 0 ]; then
        log_error "以下便捷命令仍然存在: ${remaining_commands[*]}"
    fi

    if [ $issues -eq 0 ]; then
        log_success "✅ 卸载验证通过，所有组件已完全移除"
        return 0
    else
        log_error "❌ 发现 $issues 个问题，卸载可能不完整"
        return 1
    fi
}

# 显示卸载完成信息
show_completion_info() {
    echo ""
    echo -e "${GREEN}🎉 Mihomo 卸载完成！${NC}"
    echo ""
    echo "已完成的操作："
    echo "  ✅ 停止并禁用 Mihomo 系统服务"
    echo "  ✅ 删除所有程序文件和配置"
    echo "  ✅ 移除便捷命令"
    echo "  ✅ 清理 Shell 配置"
    echo "  ✅ 清理环境变量"
    echo ""
    echo -e "${YELLOW}注意事项：${NC}"
    echo "  • 请重启终端或重新登录以确保环境变量完全清理"
    echo "  • 如果使用了自定义配置，请手动检查相关文件"
    echo "  • 感谢使用 Mihomo for Linux！"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    Mihomo 完整卸载工具${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    check_root
    confirm_uninstall

    echo ""
    log_info "开始卸载 Mihomo..."

    stop_service
    remove_service_files
    remove_program_files
    remove_convenience_commands
    clean_shell_config
    clean_environment

    echo ""
    if verify_uninstall; then
        show_completion_info
        exit 0
    else
        log_error "卸载过程中发现问题，请检查上述错误信息"
        exit 1
    fi
}

# 执行主函数
main "$@"
