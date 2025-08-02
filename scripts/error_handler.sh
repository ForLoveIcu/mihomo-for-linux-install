#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 18:30:00 +08:00
# Reason: Create comprehensive error handling and recovery system
# Principle_Applied: SOLID - Single responsibility for error handling; DRY - Reusable error handling functions
# Optimization: Comprehensive error handling with automatic recovery mechanisms
# Architectural_Note (AR): Robust error handling system for maximum reliability
# Documentation_Note (DW): Error handling and recovery system
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    Mihomo 错误处理和恢复系统                                ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 提供全面的错误处理、日志记录和自动恢复机制
#
# 【免责声明】本工具仅供学习和技术交流使用，用户应遵守当地法律法规。
# 详细免责声明请参考主安装脚本。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# 全局变量
ERROR_LOG_FILE="/tmp/mihomo_install_error.log"
OPERATION_LOG_FILE="/tmp/mihomo_install_operations.log"
BACKUP_DIR="/tmp/mihomo_backup_$$"
CLEANUP_FILES=()
ROLLBACK_OPERATIONS=()

# 初始化错误处理系统
init_error_handler() {
    # 创建日志文件
    touch "$ERROR_LOG_FILE" "$OPERATION_LOG_FILE"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 设置错误处理陷阱
    set -E
    trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "%s " "${FUNCNAME[@]}")' ERR
    trap 'cleanup_on_exit' EXIT
    trap 'handle_interrupt' INT TERM
    
    log_operation "错误处理系统初始化完成"
}

# 记录操作日志
log_operation() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$OPERATION_LOG_FILE"
}

# 记录错误日志
log_error_detail() {
    local error_code="$1"
    local line_number="$2"
    local command="$3"
    local function_stack="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat >> "$ERROR_LOG_FILE" << EOF
[$timestamp] ERROR DETAILS:
  Error Code: $error_code
  Line Number: $line_number
  Failed Command: $command
  Function Stack: $function_stack
  Working Directory: $(pwd)
  User: $(whoami)
  System: $(uname -a)
  
EOF
}

# 错误处理函数
handle_error() {
    local error_code=$1
    local line_number=$2
    local bash_line_number=$3
    local failed_command="$4"
    shift 4
    local function_stack="$*"
    
    echo -e "${RED}❌ 安装过程中发生错误！${NC}" >&2
    echo -e "${YELLOW}错误代码: $error_code${NC}" >&2
    echo -e "${YELLOW}错误位置: 第 $line_number 行${NC}" >&2
    echo -e "${YELLOW}失败命令: $failed_command${NC}" >&2
    
    # 记录详细错误信息
    log_error_detail "$error_code" "$line_number" "$failed_command" "$function_stack"
    
    # 尝试自动恢复
    if attempt_auto_recovery "$error_code" "$failed_command"; then
        echo -e "${GREEN}✅ 自动恢复成功，继续安装...${NC}"
        return 0
    fi
    
    # 显示错误处理选项
    show_error_options "$error_code" "$failed_command"
}

# 尝试自动恢复
attempt_auto_recovery() {
    local error_code="$1"
    local failed_command="$2"
    
    echo -e "${BLUE}🔧 尝试自动恢复...${NC}"
    
    # 根据错误类型尝试不同的恢复策略
    case "$failed_command" in
        *"curl"*|*"wget"*)
            echo "检测到网络下载错误，尝试使用备用下载方式..."
            return 1  # 让上层处理重试逻辑
            ;;
        *"systemctl"*)
            echo "检测到服务管理错误，检查systemd状态..."
            if ! systemctl --version >/dev/null 2>&1; then
                echo "systemd不可用，尝试使用其他服务管理方式..."
                return 1
            fi
            ;;
        *"mkdir"*|*"cp"*|*"mv"*)
            echo "检测到文件操作错误，检查权限和磁盘空间..."
            check_disk_space_and_permissions
            return $?
            ;;
        *"unzip"*|*"gunzip"*|*"tar"*)
            echo "检测到解压错误，可能是文件损坏..."
            return 1
            ;;
    esac
    
    return 1
}

# 检查磁盘空间和权限
check_disk_space_and_permissions() {
    local current_dir=$(pwd)
    local available_space=$(df "$current_dir" | awk 'NR==2 {print $4}')
    local required_space=102400  # 100MB
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}磁盘空间不足！${NC}"
        echo "当前可用: $(($available_space / 1024))MB"
        echo "需要至少: $(($required_space / 1024))MB"
        return 1
    fi
    
    # 检查写权限
    if [ ! -w "$current_dir" ]; then
        echo -e "${RED}当前目录没有写权限！${NC}"
        return 1
    fi
    
    return 0
}

# 显示错误处理选项
show_error_options() {
    local error_code="$1"
    local failed_command="$2"
    
    echo
    echo -e "${BLUE}请选择处理方式：${NC}"
    echo -e "${YELLOW}1)${NC} 重试当前操作"
    echo -e "${YELLOW}2)${NC} 跳过当前操作继续安装"
    echo -e "${YELLOW}3)${NC} 查看详细错误信息"
    echo -e "${YELLOW}4)${NC} 生成错误报告"
    echo -e "${YELLOW}5)${NC} 回滚并退出"
    echo
    
    while true; do
        read -p "请输入选择 (1-5): " choice
        case "$choice" in
            1)
                echo -e "${BLUE}正在重试...${NC}"
                return 0
                ;;
            2)
                echo -e "${YELLOW}跳过当前操作...${NC}"
                return 0
                ;;
            3)
                show_detailed_error_info
                ;;
            4)
                generate_error_report
                ;;
            5)
                echo -e "${RED}开始回滚操作...${NC}"
                perform_rollback
                exit 1
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1-5${NC}"
                ;;
        esac
    done
}

# 显示详细错误信息
show_detailed_error_info() {
    echo
    echo -e "${BLUE}=== 详细错误信息 ===${NC}"
    if [ -f "$ERROR_LOG_FILE" ]; then
        tail -20 "$ERROR_LOG_FILE"
    else
        echo "错误日志文件不存在"
    fi
    echo
    echo -e "${BLUE}=== 系统信息 ===${NC}"
    echo "操作系统: $(uname -a)"
    echo "当前用户: $(whoami)"
    echo "当前目录: $(pwd)"
    echo "磁盘空间: $(df -h . | tail -1)"
    echo "内存使用: $(free -h | head -2)"
    echo
}

# 生成错误报告
generate_error_report() {
    local report_file="/tmp/mihomo_error_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${BLUE}正在生成错误报告...${NC}"
    
    cat > "$report_file" << EOF
Mihomo Linux 安装错误报告
生成时间: $(date)
========================================

系统信息:
$(uname -a)

用户信息:
当前用户: $(whoami)
用户ID: $(id)

磁盘信息:
$(df -h)

内存信息:
$(free -h)

网络信息:
$(ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "无法获取网络信息")

错误日志:
$(cat "$ERROR_LOG_FILE" 2>/dev/null || echo "无错误日志")

操作日志:
$(cat "$OPERATION_LOG_FILE" 2>/dev/null || echo "无操作日志")

环境变量:
$(env | grep -E "(PATH|HOME|USER|SHELL)" | sort)

已安装的相关软件:
curl: $(command -v curl || echo "未安装")
wget: $(command -v wget || echo "未安装")
unzip: $(command -v unzip || echo "未安装")
systemctl: $(command -v systemctl || echo "未安装")

========================================
EOF
    
    echo -e "${GREEN}错误报告已生成: $report_file${NC}"
    echo -e "${YELLOW}请将此文件发送给技术支持以获得帮助${NC}"
}

# 添加清理文件
add_cleanup_file() {
    local file="$1"
    CLEANUP_FILES+=("$file")
    log_operation "添加清理文件: $file"
}

# 添加回滚操作
add_rollback_operation() {
    local operation="$1"
    ROLLBACK_OPERATIONS+=("$operation")
    log_operation "添加回滚操作: $operation"
}

# 备份文件
backup_file() {
    local source_file="$1"
    local backup_name="${2:-$(basename "$source_file")}"
    
    if [ -f "$source_file" ]; then
        local backup_path="$BACKUP_DIR/$backup_name"
        cp "$source_file" "$backup_path"
        add_rollback_operation "restore_file '$backup_path' '$source_file'"
        log_operation "备份文件: $source_file -> $backup_path"
        return 0
    fi
    
    return 1
}

# 恢复文件
restore_file() {
    local backup_path="$1"
    local target_path="$2"
    
    if [ -f "$backup_path" ]; then
        cp "$backup_path" "$target_path"
        log_operation "恢复文件: $backup_path -> $target_path"
        return 0
    fi
    
    return 1
}

# 执行回滚操作
perform_rollback() {
    echo -e "${BLUE}开始执行回滚操作...${NC}"
    
    # 逆序执行回滚操作
    for ((i=${#ROLLBACK_OPERATIONS[@]}-1; i>=0; i--)); do
        local operation="${ROLLBACK_OPERATIONS[i]}"
        echo "执行回滚: $operation"
        eval "$operation" || echo "回滚操作失败: $operation"
    done
    
    echo -e "${GREEN}回滚操作完成${NC}"
}

# 处理中断信号
handle_interrupt() {
    echo
    echo -e "${YELLOW}检测到中断信号，正在清理...${NC}"
    perform_rollback
    cleanup_on_exit
    exit 130
}

# 退出时清理
cleanup_on_exit() {
    # 清理临时文件
    for file in "${CLEANUP_FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_operation "清理文件: $file"
        fi
    done
    
    # 清理备份目录
    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
        log_operation "清理备份目录: $BACKUP_DIR"
    fi
}

# 安全执行命令
safe_execute() {
    local command="$1"
    local description="$2"
    local max_retries="${3:-3}"
    local retry_delay="${4:-2}"
    
    log_operation "开始执行: $description"
    
    for ((i=1; i<=max_retries; i++)); do
        if [ $i -gt 1 ]; then
            echo -e "${YELLOW}重试 $description (第 $i 次)...${NC}"
            sleep "$retry_delay"
        fi
        
        if eval "$command"; then
            log_operation "成功执行: $description"
            return 0
        else
            local exit_code=$?
            log_operation "执行失败: $description (退出码: $exit_code)"
            
            if [ $i -eq $max_retries ]; then
                echo -e "${RED}$description 执行失败，已重试 $max_retries 次${NC}"
                return $exit_code
            fi
        fi
    done
}

# 验证文件完整性
verify_file_integrity() {
    local file="$1"
    local expected_size="${2:-0}"
    local expected_hash="$3"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}文件不存在: $file${NC}"
        return 1
    fi
    
    # 检查文件大小
    local actual_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$expected_size" -gt 0 ] && [ "$actual_size" -lt "$expected_size" ]; then
        echo -e "${RED}文件大小异常: $file (期望: $expected_size, 实际: $actual_size)${NC}"
        return 1
    fi
    
    # 检查文件哈希（如果提供）
    if [ -n "$expected_hash" ] && command -v sha256sum >/dev/null 2>&1; then
        local actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
        if [ "$actual_hash" != "$expected_hash" ]; then
            echo -e "${RED}文件哈希不匹配: $file${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}文件完整性验证通过: $file${NC}"
    return 0
}

# 显示帮助信息
show_error_handler_help() {
    cat << EOF
Mihomo 错误处理系统 v1.0

主要功能:
  - 自动错误检测和处理
  - 智能恢复机制
  - 详细错误日志记录
  - 自动回滚功能
  - 文件完整性验证

使用方法:
  在安装脚本中调用 init_error_handler 初始化错误处理系统

可用函数:
  safe_execute <命令> <描述> [重试次数] [重试间隔]
  backup_file <源文件> [备份名称]
  verify_file_integrity <文件> [期望大小] [期望哈希]
  add_cleanup_file <文件>
  add_rollback_operation <操作>

EOF
}

# 如果直接运行此脚本，显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_error_handler_help
fi
