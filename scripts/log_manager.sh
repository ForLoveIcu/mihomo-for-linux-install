#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 15:40:00 +08:00
# Reason: Per P1-CORE-003 to implement structured log management functionality
# Principle_Applied: KISS - Simple log management operations; SOLID - Single responsibility for log handling
# Optimization: Efficient log rotation and cleanup with size control
# Architectural_Note (AR): Independent log management module for system maintenance
# Documentation_Note (DW): Log manager as specified in enhancement plan
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        Mihomo 日志管理器                                    ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 提供结构化的日志管理功能，包括轮转、清理和查看
#
# 【免责声明】本工具仅供学习和技术交流使用，用户应遵守当地法律法规。
# 详细免责声明请参考主安装脚本。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

set -euo pipefail

# 配置常量
readonly MIHOMO_DIR="/etc/mihomo"
readonly LOG_DIR="$MIHOMO_DIR/logs"
readonly CONFIG_DIR="$MIHOMO_DIR"
readonly LOG_CONFIG_FILE="$CONFIG_DIR/.log_config"

# 默认配置
readonly DEFAULT_MAX_SIZE="10M"
readonly DEFAULT_MAX_FILES=10
readonly DEFAULT_MAX_DAYS=30

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 日志文件列表
readonly LOG_FILES=(
    "mihomo.log"
    "subscription.log"
    "validation.log"
    "error.log"
    "access.log"
)

# 日志函数
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $message"
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $message"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# 初始化环境
init_environment() {
    mkdir -p "$LOG_DIR"
    
    # 创建默认配置文件
    if [ ! -f "$LOG_CONFIG_FILE" ]; then
        cat > "$LOG_CONFIG_FILE" << EOF
# Mihomo 日志管理配置
MAX_SIZE=$DEFAULT_MAX_SIZE
MAX_FILES=$DEFAULT_MAX_FILES
MAX_DAYS=$DEFAULT_MAX_DAYS
COMPRESS=true
AUTO_CLEANUP=true
EOF
        chmod 644 "$LOG_CONFIG_FILE"
        log_info "创建默认日志配置文件: $LOG_CONFIG_FILE"
    fi
    
    log_info "日志管理器初始化完成"
}

# 加载配置
load_config() {
    if [ -f "$LOG_CONFIG_FILE" ]; then
        source "$LOG_CONFIG_FILE"
        log_info "加载日志配置: $LOG_CONFIG_FILE"
    else
        log_warn "配置文件不存在，使用默认配置"
        MAX_SIZE="$DEFAULT_MAX_SIZE"
        MAX_FILES="$DEFAULT_MAX_FILES"
        MAX_DAYS="$DEFAULT_MAX_DAYS"
        COMPRESS=true
        AUTO_CLEANUP=true
    fi
}

# 转换大小单位为字节
size_to_bytes() {
    local size="$1"
    local number="${size%[KMG]*}"
    local unit="${size#$number}"
    
    case "$unit" in
        K|k) echo $((number * 1024)) ;;
        M|m) echo $((number * 1024 * 1024)) ;;
        G|g) echo $((number * 1024 * 1024 * 1024)) ;;
        *) echo "$number" ;;
    esac
}

# 获取文件大小
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 检查日志文件大小
check_log_size() {
    local log_file="$1"
    local max_size_bytes=$(size_to_bytes "$MAX_SIZE")
    local current_size=$(get_file_size "$log_file")
    
    if [ "$current_size" -gt "$max_size_bytes" ]; then
        return 0  # 需要轮转
    else
        return 1  # 不需要轮转
    fi
}

# 轮转单个日志文件
rotate_log_file() {
    local log_file="$1"
    local base_name="${log_file%.*}"
    local extension="${log_file##*.}"
    
    if [ ! -f "$LOG_DIR/$log_file" ]; then
        return 0
    fi
    
    log_info "轮转日志文件: $log_file"
    
    # 移动现有的轮转文件
    for ((i=MAX_FILES-1; i>=1; i--)); do
        local old_file="$LOG_DIR/${base_name}.${i}.${extension}"
        local new_file="$LOG_DIR/${base_name}.$((i+1)).${extension}"
        
        if [ -f "$old_file" ]; then
            if [ $i -eq $((MAX_FILES-1)) ]; then
                # 删除最老的文件
                rm -f "$old_file"
                log_info "删除过期日志: $old_file"
            else
                mv "$old_file" "$new_file"
            fi
        fi
    done
    
    # 轮转当前日志文件
    local rotated_file="$LOG_DIR/${base_name}.1.${extension}"
    mv "$LOG_DIR/$log_file" "$rotated_file"
    
    # 创建新的日志文件
    touch "$LOG_DIR/$log_file"
    chmod 644 "$LOG_DIR/$log_file"
    
    # 压缩轮转的文件
    if [ "$COMPRESS" = true ]; then
        gzip "$rotated_file" 2>/dev/null && {
            log_info "压缩日志文件: ${rotated_file}.gz"
        } || {
            log_warn "压缩失败: $rotated_file"
        }
    fi
    
    log_info "日志轮转完成: $log_file"
}

# 轮转所有日志文件
rotate_logs() {
    local force_rotate="${1:-false}"
    
    log_info "开始日志轮转检查"
    
    for log_file in "${LOG_FILES[@]}"; do
        local full_path="$LOG_DIR/$log_file"
        
        if [ ! -f "$full_path" ]; then
            continue
        fi
        
        if [ "$force_rotate" = true ] || check_log_size "$log_file"; then
            rotate_log_file "$log_file"
        else
            log_info "日志文件大小正常，跳过轮转: $log_file"
        fi
    done
    
    log_info "日志轮转检查完成"
}

# 清理过期日志
cleanup_old_logs() {
    local days="${1:-$MAX_DAYS}"
    
    log_info "清理 $days 天前的日志文件"
    
    local cleaned_count=0
    
    # 清理轮转的日志文件
    find "$LOG_DIR" -name "*.log.*" -type f -mtime +$days -exec rm -f {} \; -print | while read -r file; do
        log_info "删除过期日志: $file"
        cleaned_count=$((cleaned_count + 1))
    done
    
    # 清理压缩的日志文件
    find "$LOG_DIR" -name "*.log.*.gz" -type f -mtime +$days -exec rm -f {} \; -print | while read -r file; do
        log_info "删除过期压缩日志: $file"
        cleaned_count=$((cleaned_count + 1))
    done
    
    log_info "清理完成，删除了 $cleaned_count 个过期日志文件"
}

# 查看日志文件
view_log() {
    local log_name="${1:-mihomo}"
    local lines="${2:-50}"
    local follow="${3:-false}"
    
    local log_file="$LOG_DIR/${log_name}.log"
    
    if [ ! -f "$log_file" ]; then
        log_error "日志文件不存在: $log_file"
        return 1
    fi
    
    echo -e "${BLUE}=== 查看日志: $log_name (最近 $lines 行) ===${NC}"
    
    if [ "$follow" = true ]; then
        tail -f -n "$lines" "$log_file"
    else
        tail -n "$lines" "$log_file"
    fi
}

# 搜索日志内容
search_logs() {
    local pattern="$1"
    local log_name="${2:-all}"
    local context="${3:-3}"
    
    log_info "搜索日志内容: $pattern"
    
    if [ "$log_name" = "all" ]; then
        for log_file in "${LOG_FILES[@]}"; do
            local full_path="$LOG_DIR/$log_file"
            if [ -f "$full_path" ]; then
                echo -e "${BLUE}=== 搜索结果: $log_file ===${NC}"
                grep -n -C "$context" "$pattern" "$full_path" 2>/dev/null || true
                echo
            fi
        done
    else
        local log_file="$LOG_DIR/${log_name}.log"
        if [ -f "$log_file" ]; then
            echo -e "${BLUE}=== 搜索结果: $log_name ===${NC}"
            grep -n -C "$context" "$pattern" "$log_file" 2>/dev/null || {
                log_info "未找到匹配的内容"
            }
        else
            log_error "日志文件不存在: $log_file"
            return 1
        fi
    fi
}

# 显示日志统计信息
show_log_stats() {
    log_info "日志文件统计信息"
    echo
    
    printf "%-20s %-10s %-15s %-20s\n" "日志文件" "大小" "行数" "最后修改时间"
    printf "%-20s %-10s %-15s %-20s\n" "--------" "----" "----" "----------"
    
    for log_file in "${LOG_FILES[@]}"; do
        local full_path="$LOG_DIR/$log_file"
        if [ -f "$full_path" ]; then
            local size=$(du -h "$full_path" | cut -f1)
            local lines=$(wc -l < "$full_path" 2>/dev/null || echo "0")
            local mtime=$(stat -c "%Y" "$full_path" 2>/dev/null | xargs -I {} date -d "@{}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "未知")
            
            printf "%-20s %-10s %-15s %-20s\n" "$log_file" "$size" "$lines" "$mtime"
        else
            printf "%-20s %-10s %-15s %-20s\n" "$log_file" "不存在" "-" "-"
        fi
    done
    
    echo
    
    # 显示磁盘使用情况
    local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1 || echo "0")
    log_info "日志目录总大小: $total_size"
    
    # 显示轮转文件统计
    local rotated_count=$(find "$LOG_DIR" -name "*.log.*" -type f | wc -l)
    log_info "轮转文件数量: $rotated_count"
}

# 显示帮助信息
show_help() {
    cat << EOF
Mihomo 日志管理器 v1.0

用法: $0 <命令> [选项]

命令:
    rotate [--force]           轮转日志文件
    cleanup [天数]             清理过期日志文件
    view <日志名> [行数]       查看日志文件
    follow <日志名> [行数]     实时跟踪日志文件
    search <模式> [日志名]     搜索日志内容
    stats                      显示日志统计信息
    config                     显示当前配置
    init                       初始化日志环境

日志名称:
    mihomo, subscription, validation, error, access

示例:
    $0 rotate                  # 检查并轮转大文件
    $0 rotate --force          # 强制轮转所有日志
    $0 cleanup 7               # 清理7天前的日志
    $0 view mihomo 100         # 查看mihomo日志最近100行
    $0 follow error            # 实时跟踪错误日志
    $0 search "ERROR" all      # 在所有日志中搜索ERROR
    $0 stats                   # 显示日志统计信息

EOF
}

# 显示配置信息
show_config() {
    log_info "当前日志管理配置"
    echo
    echo "配置文件: $LOG_CONFIG_FILE"
    echo "日志目录: $LOG_DIR"
    echo "最大文件大小: $MAX_SIZE"
    echo "最大文件数量: $MAX_FILES"
    echo "保留天数: $MAX_DAYS"
    echo "启用压缩: $COMPRESS"
    echo "自动清理: $AUTO_CLEANUP"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    local command="$1"
    shift
    
    # 初始化环境和加载配置
    init_environment
    load_config
    
    case "$command" in
        rotate)
            local force_rotate=false
            if [ $# -gt 0 ] && [ "$1" = "--force" ]; then
                force_rotate=true
            fi
            rotate_logs "$force_rotate"
            ;;
        cleanup)
            local days="${1:-$MAX_DAYS}"
            cleanup_old_logs "$days"
            ;;
        view)
            local log_name="${1:-mihomo}"
            local lines="${2:-50}"
            view_log "$log_name" "$lines" false
            ;;
        follow)
            local log_name="${1:-mihomo}"
            local lines="${2:-50}"
            view_log "$log_name" "$lines" true
            ;;
        search)
            if [ $# -eq 0 ]; then
                log_error "请提供搜索模式"
                exit 1
            fi
            local pattern="$1"
            local log_name="${2:-all}"
            search_logs "$pattern" "$log_name"
            ;;
        stats)
            show_log_stats
            ;;
        config)
            show_config
            ;;
        init)
            init_environment
            log_info "日志环境初始化完成"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
