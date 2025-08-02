#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 15:35:00 +08:00
# Reason: Per P1-CORE-002 to implement configuration validation functionality
# Principle_Applied: KISS - Simple validation logic; SOLID - Single responsibility for config validation
# Optimization: Fast validation with detailed error reporting
# Architectural_Note (AR): Independent validation module for configuration integrity
# Documentation_Note (DW): Configuration validator as specified in enhancement plan
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        Mihomo 配置验证器                                    ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 验证配置文件的正确性和安全性
#
# 【免责声明】本工具仅供学习和技术交流使用，用户应遵守当地法律法规。
# 详细免责声明请参考主安装脚本。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

set -euo pipefail

# 配置常量
readonly MIHOMO_DIR="/etc/mihomo"
readonly CONFIG_FILE="$MIHOMO_DIR/config.yaml"
readonly LOG_DIR="$MIHOMO_DIR/logs"
readonly VALIDATION_LOG="$LOG_DIR/validation.log"
readonly ERROR_LOG="$LOG_DIR/error.log"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 验证结果统计
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0
VALIDATION_PASSED=0

# 日志函数
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $message"
    echo "[$timestamp] [INFO] $message" >> "$VALIDATION_LOG" 2>/dev/null || true
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $message"
    echo "[$timestamp] [WARN] $message" >> "$VALIDATION_LOG" 2>/dev/null || true
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $message" >&2
    echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG" 2>/dev/null || true
    echo "[$timestamp] [ERROR] $message" >> "$VALIDATION_LOG" 2>/dev/null || true
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

log_pass() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[PASS]${NC} $message"
    echo "[$timestamp] [PASS] $message" >> "$VALIDATION_LOG" 2>/dev/null || true
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
}

# 初始化环境
init_environment() {
    mkdir -p "$LOG_DIR"
    touch "$VALIDATION_LOG" "$ERROR_LOG" 2>/dev/null || true
    chmod 644 "$VALIDATION_LOG" "$ERROR_LOG" 2>/dev/null || true
    log_info "配置验证器初始化完成"
}

# 检查文件是否存在
check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        log_pass "$description 文件存在: $file"
        return 0
    else
        log_error "$description 文件不存在: $file"
        return 1
    fi
}

# 检查文件权限
check_file_permissions() {
    local file="$1"
    local expected_perm="$2"
    local description="$3"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    local actual_perm=$(stat -c "%a" "$file" 2>/dev/null || echo "000")
    
    if [ "$actual_perm" = "$expected_perm" ]; then
        log_pass "$description 权限正确: $actual_perm"
        return 0
    else
        log_warn "$description 权限异常: 期望 $expected_perm, 实际 $actual_perm"
        return 1
    fi
}

# 验证YAML语法
validate_yaml_syntax() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_error "配置文件不存在: $file"
        return 1
    fi
    
    # 使用python验证YAML语法
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "
import yaml
import sys
try:
    with open('$file', 'r', encoding='utf-8') as f:
        yaml.safe_load(f)
    print('YAML语法验证通过')
except yaml.YAMLError as e:
    print(f'YAML语法错误: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'文件读取错误: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
            log_pass "YAML语法验证通过"
            return 0
        else
            log_error "YAML语法验证失败"
            return 1
        fi
    else
        # 使用简单的语法检查
        if grep -q "^[[:space:]]*-[[:space:]]*$" "$file" || \
           grep -q "^[[:space:]]*:[[:space:]]*$" "$file"; then
            log_error "发现YAML语法错误：空值或格式问题"
            return 1
        else
            log_pass "基础YAML格式检查通过"
            return 0
        fi
    fi
}

# 验证必需字段
validate_required_fields() {
    local file="$1"
    local required_fields=("mixed-port" "external-controller" "proxy-providers")
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if grep -q "^[[:space:]]*${field}:" "$file"; then
            log_pass "必需字段存在: $field"
        else
            log_error "缺少必需字段: $field"
            missing_fields+=("$field")
        fi
    done
    
    if [ ${#missing_fields[@]} -eq 0 ]; then
        return 0
    else
        log_error "缺少 ${#missing_fields[@]} 个必需字段: ${missing_fields[*]}"
        return 1
    fi
}

# 验证端口配置
validate_ports() {
    local file="$1"
    local ports=()
    
    # 提取端口配置
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*(mixed-port|port|socks-port|redir-port|tproxy-port):[[:space:]]*([0-9]+) ]]; then
            local port="${BASH_REMATCH[2]}"
            ports+=("$port")
        fi
    done < "$file"
    
    # 验证端口范围
    for port in "${ports[@]}"; do
        if [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
            if [ "$port" -lt 1024 ]; then
                log_warn "使用特权端口: $port (需要root权限)"
            else
                log_pass "端口配置正确: $port"
            fi
        else
            log_error "端口超出有效范围: $port"
        fi
    done
    
    return 0
}

# 验证代理提供者
validate_proxy_providers() {
    local file="$1"
    local provider_count=0
    local valid_providers=0
    
    # 检查是否有proxy-providers配置
    if ! grep -q "^[[:space:]]*proxy-providers:" "$file"; then
        log_warn "未找到proxy-providers配置"
        return 1
    fi
    
    # 统计提供者数量
    provider_count=$(grep -c "^[[:space:]]*[a-zA-Z0-9_-]*:[[:space:]]*$" "$file" | head -1)
    
    # 检查URL配置
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*url:[[:space:]]*[\"\'](https?://[^\"\']+)[\"\'] ]]; then
            local url="${BASH_REMATCH[1]}"
            if [[ "$url" =~ ^https?:// ]] && [ "$url" != "订阅" ]; then
                log_pass "有效的订阅URL: $url"
                valid_providers=$((valid_providers + 1))
            else
                log_warn "无效或占位符URL: $url"
            fi
        fi
    done < "$file"
    
    if [ $valid_providers -gt 0 ]; then
        log_pass "找到 $valid_providers 个有效的代理提供者"
        return 0
    else
        log_error "未找到有效的代理提供者URL"
        return 1
    fi
}

# 验证规则配置
validate_rules() {
    local file="$1"
    
    if grep -q "^[[:space:]]*rules:" "$file"; then
        local rule_count=$(grep -c "^[[:space:]]*-[[:space:]]*" "$file" | head -1)
        if [ "$rule_count" -gt 0 ]; then
            log_pass "规则配置存在，包含 $rule_count 条规则"
        else
            log_warn "规则配置存在但为空"
        fi
    else
        log_warn "未找到规则配置"
    fi
    
    return 0
}

# 验证DNS配置
validate_dns() {
    local file="$1"
    
    if grep -q "^[[:space:]]*dns:" "$file"; then
        log_pass "DNS配置存在"
        
        # 检查DNS服务器配置
        if grep -q "nameserver:" "$file"; then
            log_pass "DNS服务器配置存在"
        else
            log_warn "未找到DNS服务器配置"
        fi
    else
        log_warn "未找到DNS配置"
    fi
    
    return 0
}

# 验证TUN配置
validate_tun() {
    local file="$1"
    
    if grep -q "^[[:space:]]*tun:" "$file"; then
        log_pass "TUN配置存在"
        
        # 检查TUN是否启用
        if grep -q "enable:[[:space:]]*true" "$file"; then
            log_pass "TUN模式已启用"
        else
            log_info "TUN模式未启用"
        fi
    else
        log_info "未找到TUN配置"
    fi
    
    return 0
}

# 安全检查
security_check() {
    local file="$1"
    
    # 检查是否允许局域网访问
    if grep -q "allow-lan:[[:space:]]*true" "$file"; then
        log_warn "已启用局域网访问，请确保网络安全"
    else
        log_pass "局域网访问已禁用"
    fi
    
    # 检查外部控制器配置
    if grep -q "external-controller:[[:space:]]*0\.0\.0\.0:" "$file"; then
        log_warn "外部控制器绑定到所有接口，存在安全风险"
    else
        log_pass "外部控制器配置相对安全"
    fi
    
    # 检查是否有密码保护
    if grep -q "secret:" "$file"; then
        log_pass "已配置API密码保护"
    else
        log_warn "未配置API密码保护，建议添加secret配置"
    fi
    
    return 0
}

# 主验证函数
main_validate() {
    local config_file="${1:-$CONFIG_FILE}"
    local validation_passed=true
    
    log_info "开始配置文件验证: $config_file"
    
    # 基础文件检查
    if ! check_file_exists "$config_file" "配置文件"; then
        return 1
    fi
    
    # 文件权限检查
    check_file_permissions "$config_file" "644" "配置文件"
    
    # YAML语法验证
    if ! validate_yaml_syntax "$config_file"; then
        validation_passed=false
    fi
    
    # 必需字段验证
    if ! validate_required_fields "$config_file"; then
        validation_passed=false
    fi
    
    # 端口配置验证
    validate_ports "$config_file"
    
    # 代理提供者验证
    if ! validate_proxy_providers "$config_file"; then
        validation_passed=false
    fi
    
    # 规则配置验证
    validate_rules "$config_file"
    
    # DNS配置验证
    validate_dns "$config_file"
    
    # TUN配置验证
    validate_tun "$config_file"
    
    # 安全检查
    security_check "$config_file"
    
    # 输出验证结果
    echo
    echo "========== 验证结果汇总 =========="
    echo -e "${GREEN}通过项目: $VALIDATION_PASSED${NC}"
    echo -e "${YELLOW}警告项目: $VALIDATION_WARNINGS${NC}"
    echo -e "${RED}错误项目: $VALIDATION_ERRORS${NC}"
    echo "================================"
    
    if [ $VALIDATION_ERRORS -eq 0 ]; then
        log_info "配置文件验证通过"
        return 0
    else
        log_error "配置文件验证失败，发现 $VALIDATION_ERRORS 个错误"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
Mihomo 配置验证器 v1.0

用法: $0 [选项] [配置文件]

选项:
    -h, --help      显示此帮助信息
    -v, --verbose   详细输出模式
    -q, --quiet     静默模式（仅显示错误）
    --security      仅执行安全检查

参数:
    配置文件        要验证的配置文件路径（默认: $CONFIG_FILE）

示例:
    $0                          # 验证默认配置文件
    $0 /path/to/config.yaml     # 验证指定配置文件
    $0 --security               # 仅执行安全检查

EOF
}

# 主函数
main() {
    local verbose=false
    local quiet=false
    local security_only=false
    local config_file="$CONFIG_FILE"
    
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
            -q|--quiet)
                quiet=true
                shift
                ;;
            --security)
                security_only=true
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                config_file="$1"
                shift
                ;;
        esac
    done
    
    # 初始化环境
    init_environment
    
    # 执行验证
    if [ "$security_only" = true ]; then
        log_info "执行安全检查模式"
        security_check "$config_file"
    else
        main_validate "$config_file"
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
