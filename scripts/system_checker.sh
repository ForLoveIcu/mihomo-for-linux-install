#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 18:00:00 +08:00
# Reason: Create comprehensive system environment checker and fixer for maximum compatibility
# Principle_Applied: SOLID - Single responsibility for system checking; DRY - Reusable checking functions
# Optimization: Comprehensive environment detection with automatic fixing capabilities
# Architectural_Note (AR): Robust system checker for maximum compatibility across all environments
# Documentation_Note (DW): System environment checker and auto-fixer
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    Mihomo 系统环境检测和修复工具                            ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 全面检测系统环境并自动修复常见问题
#
# 【免责声明】本工具仅供学习和技术交流使用，用户应遵守当地法律法规。
# 详细免责声明请参考主安装脚本。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

set -e

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 全局变量
SYSTEM_TYPE=""
PACKAGE_MANAGER=""
SERVICE_MANAGER=""
ARCH=""
NETWORK_STATUS=""
ISSUES_FOUND=()
FIXES_APPLIED=()

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 添加问题到列表
add_issue() {
    ISSUES_FOUND+=("$1")
}

# 添加修复到列表
add_fix() {
    FIXES_APPLIED+=("$1")
}

# 检测操作系统类型
detect_system_type() {
    log_info "🔍 检测操作系统类型..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYSTEM_TYPE="$ID"
        log_success "检测到系统: $PRETTY_NAME"
        
        # 特殊处理一些系统
        case "$ID" in
            "kylin")
                log_info "检测到麒麟操作系统"
                ;;
            "uos")
                log_info "检测到统信UOS操作系统"
                ;;
            "deepin")
                log_info "检测到深度操作系统"
                ;;
        esac
        
    elif [ -f /etc/redhat-release ]; then
        SYSTEM_TYPE="rhel"
        log_success "检测到Red Hat系列系统"
    elif [ -f /etc/debian_version ]; then
        SYSTEM_TYPE="debian"
        log_success "检测到Debian系列系统"
    elif [ -f /etc/alpine-release ]; then
        SYSTEM_TYPE="alpine"
        log_success "检测到Alpine Linux"
    else
        SYSTEM_TYPE="unknown"
        log_warn "无法确定操作系统类型"
        add_issue "未知的操作系统类型"
    fi
}

# 检测包管理器
detect_package_manager() {
    log_info "📦 检测包管理器..."
    
    if command -v apt >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
        log_success "检测到包管理器: APT"
    elif command -v apt-get >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt-get"
        log_success "检测到包管理器: APT-GET"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        log_success "检测到包管理器: DNF"
    elif command -v yum >/dev/null 2>&1; then
        PACKAGE_MANAGER="yum"
        log_success "检测到包管理器: YUM"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
        log_success "检测到包管理器: Pacman"
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
        log_success "检测到包管理器: Zypper"
    elif command -v apk >/dev/null 2>&1; then
        PACKAGE_MANAGER="apk"
        log_success "检测到包管理器: APK"
    else
        PACKAGE_MANAGER="none"
        log_error "未检测到支持的包管理器"
        add_issue "缺少包管理器"
    fi
}

# 检测服务管理器
detect_service_manager() {
    log_info "⚙️  检测服务管理器..."
    
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        SERVICE_MANAGER="systemd"
        log_success "检测到服务管理器: systemd"
    elif command -v service >/dev/null 2>&1; then
        SERVICE_MANAGER="sysvinit"
        log_success "检测到服务管理器: SysV Init"
    elif command -v rc-service >/dev/null 2>&1; then
        SERVICE_MANAGER="openrc"
        log_success "检测到服务管理器: OpenRC"
    else
        SERVICE_MANAGER="none"
        log_warn "未检测到支持的服务管理器"
        add_issue "缺少服务管理器"
    fi
}

# 检测系统架构
detect_architecture() {
    log_info "🏗️  检测系统架构..."
    
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armhf)
            ARCH="armv7"
            ;;
        armv6l)
            ARCH="armv6"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        mips64le)
            ARCH="mips64le"
            ;;
        mips64)
            ARCH="mips64"
            ;;
        mipsle)
            ARCH="mipsle"
            ;;
        mips)
            ARCH="mips"
            ;;
        ppc64le)
            ARCH="ppc64le"
            ;;
        s390x)
            ARCH="s390x"
            ;;
        *)
            ARCH="unknown"
            log_warn "未知的系统架构: $arch"
            add_issue "不支持的系统架构: $arch"
            ;;
    esac
    
    if [ "$ARCH" != "unknown" ]; then
        log_success "检测到系统架构: $arch -> $ARCH"
    fi
}

# 检测网络连接
detect_network() {
    log_info "🌐 检测网络连接..."
    
    # 检测DNS解析
    if nslookup github.com >/dev/null 2>&1 || dig github.com >/dev/null 2>&1; then
        log_success "DNS解析正常"
    else
        log_warn "DNS解析可能有问题"
        add_issue "DNS解析异常"
    fi
    
    # 检测网络连通性
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_success "网络连通性正常"
        NETWORK_STATUS="good"
    elif ping -c 1 -W 5 114.114.114.114 >/dev/null 2>&1; then
        log_success "国内网络连通性正常"
        NETWORK_STATUS="limited"
    else
        log_warn "网络连通性异常"
        NETWORK_STATUS="poor"
        add_issue "网络连接问题"
    fi
    
    # 检测GitHub访问
    if curl -s --connect-timeout 5 --max-time 10 https://api.github.com >/dev/null 2>&1; then
        log_success "GitHub访问正常"
    else
        log_warn "GitHub访问受限，建议使用代理加速版"
        add_issue "GitHub访问受限"
    fi
}

# 检测必需工具
check_required_tools() {
    log_info "🔧 检测必需工具..."
    
    local required_tools=("curl" "wget" "unzip" "gzip" "tar")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "✓ $tool 已安装"
        else
            log_warn "✗ $tool 未安装"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        add_issue "缺少必需工具: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# 检测可选工具
check_optional_tools() {
    log_info "🛠️  检测可选工具..."
    
    local optional_tools=("python3" "jq" "bc" "crontab")
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "✓ $tool 已安装"
        else
            log_warn "✗ $tool 未安装（可选）"
        fi
    done
}

# 检测磁盘空间
check_disk_space() {
    log_info "💾 检测磁盘空间..."
    
    local available_space=$(df /tmp | awk 'NR==2 {print $4}')
    local required_space=102400  # 100MB in KB
    
    if [ "$available_space" -gt "$required_space" ]; then
        log_success "磁盘空间充足: $(($available_space / 1024))MB 可用"
    else
        log_error "磁盘空间不足: 需要至少100MB，当前只有$(($available_space / 1024))MB"
        add_issue "磁盘空间不足"
    fi
}

# 检测权限
check_permissions() {
    log_info "🔐 检测权限..."
    
    if [ "$EUID" -eq 0 ]; then
        log_success "当前用户具有root权限"
    else
        log_error "当前用户没有root权限"
        add_issue "权限不足"
        return 1
    fi
    
    # 检测关键目录的写权限
    local test_dirs=("/etc" "/usr/local/bin" "/tmp")
    
    for dir in "${test_dirs[@]}"; do
        if [ -w "$dir" ]; then
            log_success "✓ $dir 目录可写"
        else
            log_error "✗ $dir 目录不可写"
            add_issue "$dir 目录权限问题"
        fi
    done
}

# 检测安全模块
check_security_modules() {
    log_info "🛡️  检测安全模块..."
    
    # 检测SELinux
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")
        case "$selinux_status" in
            "Enforcing")
                log_warn "SELinux处于强制模式，可能影响服务运行"
                add_issue "SELinux强制模式"
                ;;
            "Permissive")
                log_info "SELinux处于宽松模式"
                ;;
            "Disabled")
                log_success "SELinux已禁用"
                ;;
        esac
    fi
    
    # 检测AppArmor
    if command -v aa-status >/dev/null 2>&1; then
        if aa-status >/dev/null 2>&1; then
            log_info "AppArmor已启用"
        else
            log_success "AppArmor未启用"
        fi
    fi
    
    # 检测防火墙
    if command -v ufw >/dev/null 2>&1; then
        local ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            log_warn "UFW防火墙已启用，可能需要开放端口"
            add_issue "防火墙可能阻止端口访问"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state >/dev/null 2>&1; then
            log_warn "firewalld已启用，可能需要开放端口"
            add_issue "防火墙可能阻止端口访问"
        fi
    fi
}

# 自动修复缺少的工具
auto_fix_missing_tools() {
    log_info "🔨 尝试自动修复缺少的工具..."
    
    if [ "$PACKAGE_MANAGER" = "none" ]; then
        log_error "无法自动修复：缺少包管理器"
        return 1
    fi
    
    local tools_to_install=()
    
    # 检查并添加需要安装的工具
    for tool in curl wget unzip gzip tar; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            tools_to_install+=("$tool")
        fi
    done
    
    if [ ${#tools_to_install[@]} -eq 0 ]; then
        log_success "所有必需工具都已安装"
        return 0
    fi
    
    log_info "正在安装缺少的工具: ${tools_to_install[*]}"
    
    case "$PACKAGE_MANAGER" in
        "apt"|"apt-get")
            apt update >/dev/null 2>&1
            apt install -y "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
        "dnf")
            dnf install -y "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
        "yum")
            yum install -y "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
        "pacman")
            pacman -Sy --noconfirm "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
        "zypper")
            zypper install -y "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
        "apk")
            apk add "${tools_to_install[@]}" >/dev/null 2>&1
            ;;
    esac
    
    # 验证安装结果
    local failed_tools=()
    for tool in "${tools_to_install[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "✓ $tool 安装成功"
            add_fix "安装了 $tool"
        else
            log_error "✗ $tool 安装失败"
            failed_tools+=("$tool")
        fi
    done
    
    if [ ${#failed_tools[@]} -eq 0 ]; then
        return 0
    else
        add_issue "无法安装: ${failed_tools[*]}"
        return 1
    fi
}

# 生成安装建议
generate_install_suggestions() {
    if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
        return 0
    fi

    log_info "📋 生成安装建议..."
    echo
    echo -e "${YELLOW}发现以下问题，建议解决后再安装：${NC}"
    echo

    for issue in "${ISSUES_FOUND[@]}"; do
        echo -e "  ${RED}•${NC} $issue"

        # 针对具体问题提供解决建议
        case "$issue" in
            *"缺少必需工具"*)
                echo -e "    ${BLUE}建议${NC}: 运行以下命令安装缺少的工具："
                case "$PACKAGE_MANAGER" in
                    "apt"|"apt-get")
                        echo -e "    ${GREEN}sudo apt update && sudo apt install -y curl wget unzip gzip tar${NC}"
                        ;;
                    "dnf")
                        echo -e "    ${GREEN}sudo dnf install -y curl wget unzip gzip tar${NC}"
                        ;;
                    "yum")
                        echo -e "    ${GREEN}sudo yum install -y curl wget unzip gzip tar${NC}"
                        ;;
                    "pacman")
                        echo -e "    ${GREEN}sudo pacman -Sy curl wget unzip gzip tar${NC}"
                        ;;
                    *)
                        echo -e "    ${GREEN}请使用系统包管理器安装: curl wget unzip gzip tar${NC}"
                        ;;
                esac
                ;;
            *"权限不足"*)
                echo -e "    ${BLUE}建议${NC}: 使用root权限运行安装脚本："
                echo -e "    ${GREEN}sudo bash install.sh${NC}"
                ;;
            *"网络连接问题"*)
                echo -e "    ${BLUE}建议${NC}: 检查网络连接或使用代理加速版："
                echo -e "    ${GREEN}bash install_proxy.sh${NC}"
                ;;
            *"GitHub访问受限"*)
                echo -e "    ${BLUE}建议${NC}: 使用代理加速版安装脚本："
                echo -e "    ${GREEN}bash install_proxy.sh${NC}"
                ;;
            *"磁盘空间不足"*)
                echo -e "    ${BLUE}建议${NC}: 清理磁盘空间或选择其他安装位置"
                ;;
            *"SELinux强制模式"*)
                echo -e "    ${BLUE}建议${NC}: 临时设置SELinux为宽松模式："
                echo -e "    ${GREEN}sudo setenforce 0${NC}"
                ;;
            *"防火墙"*)
                echo -e "    ${BLUE}建议${NC}: 安装后手动开放端口7890和9090"
                ;;
        esac
        echo
    done
}

# 显示修复结果
show_fix_results() {
    if [ ${#FIXES_APPLIED[@]} -gt 0 ]; then
        echo
        echo -e "${GREEN}已自动修复以下问题：${NC}"
        for fix in "${FIXES_APPLIED[@]}"; do
            echo -e "  ${GREEN}✓${NC} $fix"
        done
        echo
    fi
}

# 生成系统报告
generate_system_report() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    系统环境检测报告                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}系统信息：${NC}"
    echo -e "  操作系统: $SYSTEM_TYPE"
    echo -e "  系统架构: $ARCH"
    echo -e "  包管理器: $PACKAGE_MANAGER"
    echo -e "  服务管理器: $SERVICE_MANAGER"
    echo -e "  网络状态: $NETWORK_STATUS"
    echo

    if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ 系统环境检查通过，可以正常安装！${NC}"
        echo
        echo -e "${BLUE}推荐安装方式：${NC}"
        if [ "$NETWORK_STATUS" = "good" ]; then
            echo -e "  ${GREEN}bash install.sh${NC} (标准版)"
        else
            echo -e "  ${GREEN}bash install_proxy.sh${NC} (代理加速版)"
        fi
    else
        echo -e "${RED}❌ 发现 ${#ISSUES_FOUND[@]} 个问题需要解决${NC}"
        generate_install_suggestions
    fi

    show_fix_results
}

# 主检测函数
main_check() {
    echo -e "${BLUE}🔍 开始系统环境全面检测...${NC}"
    echo

    # 基础系统检测
    detect_system_type
    detect_architecture
    detect_package_manager
    detect_service_manager

    # 网络环境检测
    detect_network

    # 工具和权限检测
    check_required_tools
    check_optional_tools
    check_disk_space
    check_permissions

    # 安全模块检测
    check_security_modules

    # 尝试自动修复
    if [ ${#ISSUES_FOUND[@]} -gt 0 ]; then
        echo
        log_info "🔧 尝试自动修复发现的问题..."
        auto_fix_missing_tools
    fi

    # 生成报告
    generate_system_report

    # 返回检测结果
    if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
Mihomo 系统环境检测工具 v1.0

用法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -q, --quiet     静默模式（仅显示结果）
    -f, --fix       尝试自动修复问题
    --report        仅生成系统报告

示例:
    $0              # 执行完整检测
    $0 --fix        # 检测并尝试修复
    $0 --report     # 仅显示系统信息

EOF
}

# 主函数
main() {
    local quiet=false
    local fix_mode=false
    local report_only=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -f|--fix)
                fix_mode=true
                shift
                ;;
            --report)
                report_only=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [ "$report_only" = true ]; then
        detect_system_type
        detect_architecture
        detect_package_manager
        detect_service_manager
        detect_network
        generate_system_report
    else
        main_check
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
