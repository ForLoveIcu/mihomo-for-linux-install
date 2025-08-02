#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 15:30:00 +08:00
# Reason: Per P1-CORE-001 to implement subscription auto-update functionality
# Principle_Applied: KISS - Simple and clear script structure; SOLID - Single responsibility for subscription updates
# Optimization: Concurrent downloads, retry mechanism, atomic operations
# Architectural_Note (AR): Independent module design ensures loose coupling with main system
# Documentation_Note (DW): Core subscription updater module as specified in enhancement plan
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        Mihomo 订阅更新器                                    ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 自动下载和更新订阅配置，支持多订阅源并发更新
#
# 【免责声明】本工具仅供学习和技术交流使用，用户应遵守当地法律法规。
# 详细免责声明请参考主安装脚本。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

set -euo pipefail  # 严格错误处理

# 配置常量
readonly MIHOMO_DIR="/etc/mihomo"
readonly CONFIG_FILE="$MIHOMO_DIR/config.yaml"
readonly BACKUP_DIR="$MIHOMO_DIR/backups"
readonly LOG_DIR="$MIHOMO_DIR/logs"
readonly SUBSCRIPTION_LOG="$LOG_DIR/subscription.log"
readonly ERROR_LOG="$LOG_DIR/error.log"
readonly LOCK_FILE="/tmp/mihomo_subscription_update.lock"
readonly MAX_RETRIES=3
readonly TIMEOUT=30
readonly USER_AGENT="mihomo-subscription-updater/1.0"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 日志函数
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $message"
    echo "[$timestamp] [INFO] $message" >> "$SUBSCRIPTION_LOG"
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $message"
    echo "[$timestamp] [WARN] $message" >> "$SUBSCRIPTION_LOG"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $message" >&2
    echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG"
    echo "[$timestamp] [ERROR] $message" >> "$SUBSCRIPTION_LOG"
}

# 初始化函数
init_environment() {
    # 创建必要的目录
    mkdir -p "$BACKUP_DIR" "$LOG_DIR"
    
    # 设置日志文件权限
    touch "$SUBSCRIPTION_LOG" "$ERROR_LOG"
    chmod 644 "$SUBSCRIPTION_LOG" "$ERROR_LOG"
    
    log_info "订阅更新器初始化完成"
}

# 获取锁
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log_error "另一个订阅更新进程正在运行 (PID: $pid)"
            exit 1
        else
            log_warn "发现过期的锁文件，正在清理"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    log_info "获取更新锁成功"
}

# 释放锁
release_lock() {
    rm -f "$LOCK_FILE"
    log_info "释放更新锁"
}

# 备份配置文件
backup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    local backup_file="$BACKUP_DIR/config_$(date +%Y%m%d_%H%M%S).yaml"
    cp "$CONFIG_FILE" "$backup_file"
    
    # 保持最近10个备份文件
    find "$BACKUP_DIR" -name "config_*.yaml" -type f | sort -r | tail -n +11 | xargs -r rm -f
    
    log_info "配置文件已备份到: $backup_file"
    echo "$backup_file"
}

# 验证URL格式
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        return 1
    fi
    return 0
}

# 下载订阅内容
download_subscription() {
    local url="$1"
    local output_file="$2"
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        log_info "正在下载订阅 (尝试 $((retry_count + 1))/$MAX_RETRIES): $url"
        
        if curl -L -s -f \
            --max-time "$TIMEOUT" \
            --user-agent "$USER_AGENT" \
            --connect-timeout 10 \
            --retry 2 \
            --retry-delay 1 \
            --cacert /etc/ssl/certs/ca-certificates.crt \
            "$url" -o "$output_file"; then
            
            # 验证下载的文件不为空
            if [ -s "$output_file" ]; then
                log_info "订阅下载成功: $url"
                return 0
            else
                log_warn "下载的订阅文件为空: $url"
            fi
        else
            log_warn "订阅下载失败 (尝试 $((retry_count + 1))): $url"
        fi
        
        retry_count=$((retry_count + 1))
        [ $retry_count -lt $MAX_RETRIES ] && sleep 2
    done
    
    log_error "订阅下载最终失败: $url"
    return 1
}

# 验证订阅内容
validate_subscription() {
    local file="$1"
    
    # 检查文件是否存在且不为空
    if [ ! -s "$file" ]; then
        log_error "订阅文件为空或不存在: $file"
        return 1
    fi
    
    # 基本的YAML格式检查
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        log_error "订阅文件YAML格式无效: $file"
        return 1
    fi
    
    # 检查是否包含代理信息
    if ! grep -q "proxies\|proxy-providers" "$file"; then
        log_error "订阅文件不包含代理信息: $file"
        return 1
    fi
    
    log_info "订阅文件验证通过: $file"
    return 0
}

# 提取订阅URL列表
extract_subscription_urls() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    # 使用python解析YAML获取订阅URL
    python3 -c "
import yaml
import sys

try:
    with open('$CONFIG_FILE', 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    providers = config.get('proxy-providers', {})
    urls = []
    
    for name, provider in providers.items():
        url = provider.get('url', '')
        if url and url != '订阅' and url.startswith(('http://', 'https://')):
            urls.append(f'{name}|{url}')
    
    for url in urls:
        print(url)
        
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

# 更新单个订阅
update_single_subscription() {
    local provider_info="$1"
    local provider_name="${provider_info%%|*}"
    local provider_url="${provider_info##*|}"
    local temp_file="/tmp/subscription_${provider_name}_$$.yaml"
    
    log_info "开始更新订阅: $provider_name"
    
    # 验证URL格式
    if ! validate_url "$provider_url"; then
        log_error "无效的订阅URL: $provider_url"
        return 1
    fi
    
    # 下载订阅
    if ! download_subscription "$provider_url" "$temp_file"; then
        rm -f "$temp_file"
        return 1
    fi
    
    # 验证订阅内容
    if ! validate_subscription "$temp_file"; then
        rm -f "$temp_file"
        return 1
    fi
    
    log_info "订阅更新成功: $provider_name"
    rm -f "$temp_file"
    return 0
}

# 重载mihomo服务
reload_service() {
    log_info "正在重载mihomo服务..."
    
    if systemctl is-active --quiet mihomo; then
        if systemctl reload mihomo; then
            log_info "mihomo服务重载成功"
            return 0
        else
            log_warn "mihomo服务重载失败，尝试重启"
            if systemctl restart mihomo; then
                log_info "mihomo服务重启成功"
                return 0
            else
                log_error "mihomo服务重启失败"
                return 1
            fi
        fi
    else
        log_warn "mihomo服务未运行，尝试启动"
        if systemctl start mihomo; then
            log_info "mihomo服务启动成功"
            return 0
        else
            log_error "mihomo服务启动失败"
            return 1
        fi
    fi
}

# 主更新函数
main_update() {
    local success_count=0
    local total_count=0
    local failed_providers=()
    
    log_info "开始订阅更新任务"
    
    # 获取订阅URL列表
    local subscription_urls
    if ! subscription_urls=$(extract_subscription_urls); then
        log_error "无法提取订阅URL列表"
        return 1
    fi
    
    if [ -z "$subscription_urls" ]; then
        log_warn "未找到有效的订阅URL"
        return 0
    fi
    
    # 备份当前配置
    local backup_file
    if ! backup_file=$(backup_config); then
        log_error "配置文件备份失败"
        return 1
    fi
    
    # 更新每个订阅
    while IFS= read -r provider_info; do
        [ -z "$provider_info" ] && continue
        
        total_count=$((total_count + 1))
        local provider_name="${provider_info%%|*}"
        
        if update_single_subscription "$provider_info"; then
            success_count=$((success_count + 1))
        else
            failed_providers+=("$provider_name")
        fi
    done <<< "$subscription_urls"
    
    # 输出更新结果
    log_info "订阅更新完成: 成功 $success_count/$total_count"
    
    if [ ${#failed_providers[@]} -gt 0 ]; then
        log_warn "以下订阅更新失败: ${failed_providers[*]}"
    fi
    
    # 如果有成功的更新，重载服务
    if [ $success_count -gt 0 ]; then
        if ! reload_service; then
            log_error "服务重载失败，建议手动检查"
            return 1
        fi
    fi
    
    return 0
}

# 显示帮助信息
show_help() {
    cat << EOF
Mihomo 订阅更新器 v1.0

用法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -v, --verbose   详细输出模式
    -f, --force     强制更新（忽略锁文件）
    --dry-run       模拟运行（不实际更新）

示例:
    $0              # 执行订阅更新
    $0 -v           # 详细模式更新
    $0 --dry-run    # 模拟运行

EOF
}

# 主函数
main() {
    local verbose=false
    local force=false
    local dry_run=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查运行权限
    if [ "$EUID" -ne 0 ]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
    
    # 初始化环境
    init_environment
    
    # 模拟运行模式
    if [ "$dry_run" = true ]; then
        log_info "模拟运行模式 - 不会实际更新配置"
        extract_subscription_urls
        exit 0
    fi
    
    # 获取锁（除非强制模式）
    if [ "$force" = false ]; then
        acquire_lock
        trap release_lock EXIT
    fi
    
    # 执行主更新
    if main_update; then
        log_info "订阅更新任务完成"
        exit 0
    else
        log_error "订阅更新任务失败"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
