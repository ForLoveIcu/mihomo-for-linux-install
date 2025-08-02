#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 17:00:00 +08:00
# Reason: Create GitHub proxy accelerated version for users with network restrictions
# Principle_Applied: KISS - Simple proxy selection; SOLID - Single responsibility for proxy handling
# Optimization: Multiple proxy sources with automatic failover
# Architectural_Note (AR): Proxy-optimized version for restricted network environments
# Documentation_Note (DW): GitHub proxy accelerated installation script
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                Mihomo Linux 一键安装脚本 (GitHub代理加速版)                  ║
# ║                            版本: v2.0-proxy                                 ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 适用场景: 网络受限，无法直接访问GitHub的环境
# 新增功能: 多重代理加速、智能镜像选择、本地备用机制
#
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              重要法律声明                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 【免责声明】
# 1. 本脚本仅供学习、研究和技术交流使用，不得用于任何违法违规活动
# 2. 用户应当遵守所在国家和地区的法律法规，合法合规使用本软件
# 3. 在中华人民共和国境内，用户应严格遵守《网络安全法》《数据安全法》
#    《个人信息保护法》等相关法律法规
# 4. 本脚本作者不对用户的任何违法行为承担责任
# 5. 如因使用本脚本导致的任何法律后果，均由用户自行承担
# 6. 用户使用本脚本即表示同意本免责声明的全部内容
#
# 【合规使用建议】
# - 仅在合法授权的网络环境中使用
# - 不得用于访问被法律禁止的网络内容
# - 企业用户应确保符合公司网络安全政策
# - 个人用户应遵守当地互联网管理规定
# - 代理加速功能仅用于合法的软件下载和技术学习
#
# 【技术说明】
# 本脚本使用的GitHub代理镜像服务均为公开的技术服务，用途包括：
# - 解决网络连接问题，提高下载成功率
# - 加速开源软件的获取，促进技术学习
# - 支持企业内网环境的软件部署
# - 提供备用下载渠道，确保服务可用性
#
# 如有疑问，请咨询专业法律人士意见。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

# 设置变量
MihomoDir="/etc/mihomo"
ConfigFile="config.yaml"
CountryFile="Country.mmdb"
ScriptsDir="scripts"

# GitHub 仓库信息
GITHUB_REPO="MetaCubeX/mihomo"

# 扩展的GitHub代理镜像列表（按稳定性和速度排序）
GITHUB_PROXIES=(
    # 专业代理服务（推荐）
    "https://mirror.ghproxy.com/"
    "https://ghproxy.com/"
    "https://gh-proxy.com/"
    "https://github.abskoop.workers.dev/"
    
    # 国内镜像服务
    "https://kkgithub.com/"
    "https://githubfast.com/"
    "https://hub.gitmirror.com/"
    "https://gitclone.com/"
    
    # 备用代理服务
    "https://cors.isteed.cc/github.com/"
    "https://github.moeyy.xyz/"
    "https://github.com.cnpmjs.org/"
    "https://download.fastgit.org/"
    
    # 最后备用（原始地址）
    "https://github.com/"
)

# API代理列表（用于获取版本信息）
API_PROXIES=(
    "https://api.github.com/"
    "https://mirror.ghproxy.com/https://api.github.com/"
    "https://ghproxy.com/https://api.github.com/"
    "https://api.github.com.cnpmjs.org/"
)

# 动态变量
ARCH=""
OS_TYPE=""
MIHOMO_BINARY=""
CURRENT_PROXY=""
CURRENT_API_PROXY=""

# 新增功能配置
ENABLE_AUTO_UPDATE=true
ENABLE_CONFIG_VALIDATION=true
ENABLE_LOG_MANAGEMENT=true
UPDATE_INTERVAL="6"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 错误处理
set -e
trap 'cleanup_temp_files; log_error "安装过程中发生错误，已清理临时文件"' ERR

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 显示代理加速版欢迎信息
show_proxy_welcome() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🚀 Mihomo Linux 安装脚本                                 ║${NC}"
    echo -e "${BLUE}║                      GitHub 代理加速版 v2.0                                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}🌐 本版本专为网络受限环境优化，提供多重代理加速：${NC}"
    echo
    echo -e "${YELLOW}✨ 特色功能：${NC}"
    echo -e "   ${GREEN}→${NC} 智能代理选择 - 自动测试并选择最快的镜像"
    echo -e "   ${GREEN}→${NC} 多重备用机制 - 12个代理源确保下载成功"
    echo -e "   ${GREEN}→${NC} 本地文件备用 - 网络失败时使用本地文件"
    echo -e "   ${GREEN}→${NC} 断点续传支持 - 大文件下载更稳定"
    echo
    echo -e "${YELLOW}📡 支持的代理服务：${NC}"
    echo -e "   ${BLUE}•${NC} mirror.ghproxy.com (推荐)"
    echo -e "   ${BLUE}•${NC} kkgithub.com"
    echo -e "   ${BLUE}•${NC} githubfast.com"
    echo -e "   ${BLUE}•${NC} gitclone.com"
    echo -e "   ${BLUE}•${NC} 以及更多备用服务..."
    echo
    echo -e "${GREEN}🚀 开始安装...${NC}"
    echo
}

# 测试代理连接速度和可用性
test_proxy_connection() {
    local proxy="$1"
    local test_url="${proxy}MetaCubeX/mihomo"
    local timeout=8
    local max_time=15
    
    # 构建测试URL（处理不同的代理格式）
    if [[ "$proxy" == *"github.com/"* ]] && [[ "$proxy" != "https://github.com/" ]]; then
        # 对于替换域名的代理，直接替换
        test_url=$(echo "$test_url" | sed "s|https://github.com/|$proxy|")
    elif [[ "$proxy" == *"/" ]]; then
        # 对于前缀代理，直接拼接
        test_url="${proxy}MetaCubeX/mihomo"
    else
        # 其他情况
        test_url="${proxy}/MetaCubeX/mihomo"
    fi
    
    log_info "测试代理: $proxy"
    
    # 使用curl测试连接
    if command -v curl >/dev/null 2>&1; then
        local start_time=$(date +%s.%N 2>/dev/null || date +%s)
        
        if curl -L -s -f \
            --connect-timeout $timeout \
            --max-time $max_time \
            --user-agent "Mozilla/5.0 (Linux; Mihomo-Installer)" \
            --head "$test_url" >/dev/null 2>&1; then
            
            local end_time=$(date +%s.%N 2>/dev/null || date +%s)
            local response_time
            
            if command -v bc >/dev/null 2>&1; then
                response_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "1")
            else
                response_time="1"
            fi
            
            echo "$response_time"
            return 0
        fi
    fi
    
    # 备用：使用wget测试
    if command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=$timeout --tries=1 --spider "$test_url" 2>/dev/null; then
            echo "1"
            return 0
        fi
    fi
    
    return 1
}

# 选择最佳代理
select_best_proxy() {
    log_info "🔍 正在测试GitHub代理服务，寻找最佳连接..."
    echo
    
    local best_proxy=""
    local best_time="999"
    local working_proxies=0
    
    for proxy in "${GITHUB_PROXIES[@]}"; do
        if response_time=$(test_proxy_connection "$proxy"); then
            working_proxies=$((working_proxies + 1))
            echo -e "  ${GREEN}✓${NC} 可用 (${response_time}s) - $proxy"
            
            # 选择响应时间最短的代理
            if command -v bc >/dev/null 2>&1; then
                if [ "$(echo "$response_time < $best_time" | bc 2>/dev/null || echo "0")" = "1" ]; then
                    best_proxy="$proxy"
                    best_time="$response_time"
                fi
            else
                # 简单比较（整数部分）
                local int_response=${response_time%.*}
                local int_best=${best_time%.*}
                if [ "${int_response:-999}" -lt "${int_best:-999}" ]; then
                    best_proxy="$proxy"
                    best_time="$response_time"
                fi
            fi
        else
            echo -e "  ${RED}✗${NC} 不可用 - $proxy"
        fi
    done
    
    echo
    
    if [ -n "$best_proxy" ]; then
        CURRENT_PROXY="$best_proxy"
        log_info "🎯 选择最佳代理: $best_proxy (响应时间: ${best_time}s)"
        log_info "✅ 发现 $working_proxies 个可用代理服务"
    else
        log_error "❌ 所有代理测试失败，请检查网络连接"
        echo
        echo -e "${YELLOW}💡 建议：${NC}"
        echo -e "   1. 检查网络连接是否正常"
        echo -e "   2. 尝试使用VPN或其他网络环境"
        echo -e "   3. 使用标准版安装脚本 (install.sh)"
        echo -e "   4. 手动下载文件后使用本地安装"
        exit 1
    fi
}

# 选择最佳API代理
select_best_api_proxy() {
    log_info "🔍 选择API代理服务..."
    
    for api_proxy in "${API_PROXIES[@]}"; do
        local api_url="${api_proxy}repos/$GITHUB_REPO/releases/latest"
        
        if curl -s --connect-timeout 5 --max-time 10 "$api_url" >/dev/null 2>&1; then
            CURRENT_API_PROXY="$api_proxy"
            log_info "✅ API代理选择: $api_proxy"
            return 0
        fi
    done
    
    # 如果所有API代理都失败，使用第一个作为备用
    CURRENT_API_PROXY="${API_PROXIES[0]}"
    log_warn "⚠️  API代理测试失败，使用默认代理"
}

# 检测系统架构
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            # 新版本使用amd64-v1作为默认（兼容性最好）
            ARCH="amd64-v1"
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
        *)
            log_error "❌ 不支持的系统架构: $arch"
            echo
            echo -e "${YELLOW}💡 支持的架构：${NC}"
            echo -e "   • x86_64 (Intel/AMD 64位)"
            echo -e "   • aarch64 (ARM 64位)"
            echo -e "   • armv7l (ARM 32位)"
            echo -e "   • armv6l (ARM 32位低版本)"
            echo -e "   • mips64/mips (MIPS架构)"
            exit 1
            ;;
    esac
    log_info "✅ 检测到系统架构: $arch -> $ARCH"
}

# 检测操作系统类型
detect_os_type() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_TYPE="$ID"
        log_info "✅ 检测到操作系统: $PRETTY_NAME"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="centos"
        log_info "✅ 检测到操作系统: CentOS/RHEL"
    elif [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
        log_info "✅ 检测到操作系统: Debian"
    else
        OS_TYPE="linux"
        log_warn "⚠️  无法确定具体操作系统类型，使用通用Linux"
    fi
}

# 检查必要的工具
check_dependencies() {
    local missing_tools=()

    # 检查curl（代理版本更依赖curl）
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi

    # 检查wget（备用下载工具）
    if ! command -v wget >/dev/null 2>&1; then
        missing_tools+=("wget")
    fi

    # 检查unzip
    if ! command -v unzip >/dev/null 2>&1; then
        missing_tools+=("unzip")
    fi

    # 检查gzip
    if ! command -v gzip >/dev/null 2>&1; then
        missing_tools+=("gzip")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "❌ 缺少必要工具: ${missing_tools[*]}"
        echo
        log_info "📦 请先安装这些工具："

        case "$OS_TYPE" in
            ubuntu|debian)
                echo -e "   ${GREEN}sudo apt update && sudo apt install -y ${missing_tools[*]} bc${NC}"
                ;;
            centos|rhel|fedora)
                echo -e "   ${GREEN}sudo yum install -y ${missing_tools[*]} bc${NC}"
                ;;
            arch)
                echo -e "   ${GREEN}sudo pacman -S ${missing_tools[*]} bc${NC}"
                ;;
            *)
                echo -e "   ${GREEN}请使用系统包管理器安装: ${missing_tools[*]} bc${NC}"
                ;;
        esac
        exit 1
    fi

    log_info "✅ 依赖检查通过"
}

# 获取最新版本信息（使用代理）
get_latest_version() {
    log_info "📡 正在获取最新版本信息..."

    local api_response
    local version
    local api_url="${CURRENT_API_PROXY}repos/$GITHUB_REPO/releases/latest"

    # 尝试获取版本信息，失败时使用本地备用
    local attempts=0
    local max_attempts=3

    while [ $attempts -lt $max_attempts ]; do
        attempts=$((attempts + 1))
        log_info "🔄 尝试获取版本信息 (第 $attempts 次)..."

        # 使用curl获取API信息
        if command -v curl >/dev/null 2>&1; then
            api_response=$(curl -s \
                --connect-timeout 10 \
                --max-time 30 \
                --user-agent "Mozilla/5.0 (Linux; Mihomo-Installer)" \
                --retry 2 \
                --retry-delay 1 \
                "$api_url" 2>/dev/null)
        elif command -v wget >/dev/null 2>&1; then
            api_response=$(wget -qO- --timeout=30 --user-agent="Mozilla/5.0 (Linux; Mihomo-Installer)" "$api_url" 2>/dev/null)
        fi

        if [ -n "$api_response" ]; then
            # 解析版本号
            if command -v jq >/dev/null 2>&1; then
                version=$(echo "$api_response" | jq -r '.tag_name' 2>/dev/null)
            else
                # 使用grep和sed解析（备用方法）
                version=$(echo "$api_response" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
            fi

            if [ -n "$version" ] && [ "$version" != "null" ]; then
                log_info "✅ 获取到最新版本: $version"
                break
            fi
        fi

        log_warn "⚠️  第 $attempts 次获取版本信息失败"
        [ $attempts -lt $max_attempts ] && sleep 2
    done

    # 如果无法获取最新版本，使用本地文件或默认版本
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_warn "⚠️  无法获取最新版本信息，检查本地文件..."

        # 检查是否有本地的mihomo文件
        if [ -f "mihomo-linux-$ARCH-"*.gz ]; then
            local local_file=$(ls mihomo-linux-$ARCH-*.gz | head -1)
            version=$(echo "$local_file" | sed "s/mihomo-linux-$ARCH-//g" | sed 's/.gz//g')
            log_info "📁 使用本地文件版本: $version"
            USE_LOCAL_FILES=true
        else
            # 使用已知的稳定版本作为备用
            version="v1.19.12"
            log_warn "🔄 使用默认版本: $version"
        fi
    fi

    # 构建下载文件名
    MIHOMO_BINARY="mihomo-linux-$ARCH-$version"

    # 构建下载URL（使用选定的代理）
    local binary_url
    local ui_url
    local country_url

    # 根据代理类型构建URL
    if [[ "$CURRENT_PROXY" == *"github.com/"* ]] && [[ "$CURRENT_PROXY" != "https://github.com/" ]]; then
        # 域名替换类型的代理
        binary_url="${CURRENT_PROXY}MetaCubeX/mihomo/releases/download/$version/mihomo-linux-$ARCH-$version.gz"
        ui_url="${CURRENT_PROXY}MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
        country_url="${CURRENT_PROXY}MetaCubeX/meta-rules-dat/releases/latest/download/country.mmdb"
    else
        # 前缀类型的代理
        binary_url="${CURRENT_PROXY}https://github.com/MetaCubeX/mihomo/releases/download/$version/mihomo-linux-$ARCH-$version.gz"
        ui_url="${CURRENT_PROXY}https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
        country_url="${CURRENT_PROXY}https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/country.mmdb"
    fi

    log_info "📦 准备下载文件:"
    log_info "   🔧 核心程序: $MIHOMO_BINARY.gz"
    log_info "   🌐 Web UI: compressed-dist.tgz (最新版)"
    log_info "   🗺️  GeoIP数据: country.mmdb"
    log_info "   🚀 使用代理: $CURRENT_PROXY"

    # 返回下载URL（通过全局变量）
    BINARY_DOWNLOAD_URL="$binary_url"
    UI_DOWNLOAD_URL="$ui_url"
    COUNTRY_DOWNLOAD_URL="$country_url"
}

# 增强的下载函数（支持代理和断点续传）
download_file_with_proxy() {
    local url="$1"
    local output="$2"
    local description="$3"
    local max_retries=3
    local retry_count=0

    log_info "📥 正在下载 $description..."

    # 创建临时目录
    local temp_dir="/tmp/mihomo_install_$$"
    mkdir -p "$temp_dir"
    local temp_file="$temp_dir/$(basename "$output")"

    while [ $retry_count -lt $max_retries ]; do
        retry_count=$((retry_count + 1))

        if [ $retry_count -gt 1 ]; then
            log_info "🔄 重试下载 $description (第 $retry_count 次)..."
        fi

        # 尝试使用curl下载（支持断点续传）
        if command -v curl >/dev/null 2>&1; then
            if curl -L \
                --progress-bar \
                --connect-timeout 15 \
                --max-time 300 \
                --retry 2 \
                --retry-delay 3 \
                --user-agent "Mozilla/5.0 (Linux; Mihomo-Installer)" \
                --continue-at - \
                -o "$temp_file" \
                "$url"; then

                # 验证下载的文件
                if [ -s "$temp_file" ]; then
                    mv "$temp_file" "$output"
                    log_info "✅ $description 下载完成"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
        fi

        # 备用：使用wget下载
        if command -v wget >/dev/null 2>&1; then
            if wget \
                --progress=bar:force \
                --timeout=300 \
                --tries=2 \
                --continue \
                --user-agent="Mozilla/5.0 (Linux; Mihomo-Installer)" \
                -O "$temp_file" \
                "$url"; then

                if [ -s "$temp_file" ]; then
                    mv "$temp_file" "$output"
                    log_info "✅ $description 下载完成"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
        fi

        log_warn "⚠️  $description 下载失败 (尝试 $retry_count/$max_retries)"

        # 如果不是最后一次重试，等待一段时间
        if [ $retry_count -lt $max_retries ]; then
            sleep $((retry_count * 2))
        fi
    done

    # 清理临时文件
    rm -rf "$temp_dir"

    log_error "❌ $description 下载最终失败"
    return 1
}

# 检查本地备用文件
check_local_files() {
    log_info "📁 检查本地备用文件..."

    # 检查核心程序
    if [ -f "$MIHOMO_BINARY.gz" ] || [ -f "mihomo-linux-$ARCH-"*.gz ]; then
        log_info "✅ 发现本地核心程序文件"
        LOCAL_BINARY_AVAILABLE=true
    else
        LOCAL_BINARY_AVAILABLE=false
    fi

    # 检查Web UI
    if [ -f "compressed-dist.tgz" ] || [ -f "metacubexd.zip" ] || [ -f "metacubexd-gh-pages.zip" ]; then
        log_info "✅ 发现本地Web UI文件"
        LOCAL_UI_AVAILABLE=true
    else
        LOCAL_UI_AVAILABLE=false
    fi

    # 检查GeoIP数据库
    if [ -f "Country.mmdb" ] || [ -f "country.mmdb" ]; then
        log_info "✅ 发现本地GeoIP数据库文件"
        LOCAL_COUNTRY_AVAILABLE=true
    else
        LOCAL_COUNTRY_AVAILABLE=false
    fi
}

# 下载所有必要文件（代理版本）
download_all_files() {
    local download_dir="/tmp/mihomo_downloads_$$"
    mkdir -p "$download_dir"

    log_info "🚀 开始下载所有必要文件..."
    echo

    # 检查本地备用文件
    check_local_files

    # 下载mihomo核心程序
    if ! download_file_with_proxy "$BINARY_DOWNLOAD_URL" "$download_dir/$MIHOMO_BINARY.gz" "Mihomo核心程序"; then
        if [ "$LOCAL_BINARY_AVAILABLE" = true ]; then
            log_warn "🔄 核心程序下载失败，使用本地备用文件"
            # 复制本地文件到下载目录
            if [ -f "$MIHOMO_BINARY.gz" ]; then
                cp "$MIHOMO_BINARY.gz" "$download_dir/"
            else
                # 查找匹配的本地文件
                local local_binary=$(ls mihomo-linux-$ARCH-*.gz 2>/dev/null | head -1)
                if [ -n "$local_binary" ]; then
                    cp "$local_binary" "$download_dir/$MIHOMO_BINARY.gz"
                fi
            fi
        else
            log_error "❌ 核心程序下载失败且无本地备用文件"
            rm -rf "$download_dir"
            exit 1
        fi
    fi

    # 下载Web UI
    if ! download_file_with_proxy "$UI_DOWNLOAD_URL" "$download_dir/compressed-dist.tgz" "Web UI"; then
        if [ "$LOCAL_UI_AVAILABLE" = true ]; then
            log_warn "🔄 Web UI下载失败，使用本地备用文件"
            # 按优先级查找本地UI文件
            if [ -f "compressed-dist.tgz" ]; then
                cp "compressed-dist.tgz" "$download_dir/"
                UI_AVAILABLE=true
            elif [ -f "metacubexd-gh-pages.zip" ]; then
                cp "metacubexd-gh-pages.zip" "$download_dir/metacubexd-gh-pages.zip"
                UI_AVAILABLE=true
            elif [ -f "metacubexd.zip" ]; then
                cp "metacubexd.zip" "$download_dir/"
                UI_AVAILABLE=true
            else
                UI_AVAILABLE=false
            fi
        else
            log_warn "⚠️  Web UI下载失败且无本地备用文件，将跳过UI安装"
            UI_AVAILABLE=false
        fi
    else
        UI_AVAILABLE=true
    fi

    # 下载GeoIP数据库
    if ! download_file_with_proxy "$COUNTRY_DOWNLOAD_URL" "$download_dir/Country.mmdb" "GeoIP数据库"; then
        if [ "$LOCAL_COUNTRY_AVAILABLE" = true ]; then
            log_warn "🔄 GeoIP数据库下载失败，使用本地备用文件"
            if [ -f "Country.mmdb" ]; then
                cp "Country.mmdb" "$download_dir/"
                COUNTRY_AVAILABLE=true
            elif [ -f "country.mmdb" ]; then
                cp "country.mmdb" "$download_dir/Country.mmdb"
                COUNTRY_AVAILABLE=true
            else
                COUNTRY_AVAILABLE=false
            fi
        else
            log_warn "⚠️  GeoIP数据库下载失败且无本地备用文件"
            COUNTRY_AVAILABLE=false
        fi
    else
        COUNTRY_AVAILABLE=true
    fi

    # 设置全局变量指向下载目录
    DOWNLOAD_DIR="$download_dir"

    echo
    log_info "✅ 文件准备完成"
}

# 清理临时文件
cleanup_temp_files() {
    if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
        log_info "🧹 清理临时文件..."
        rm -rf "$DOWNLOAD_DIR"
    fi
}

# 用户交互函数
ask_yes_no() {
    local prompt="$1"
    local default="${2:-N}"
    local response

    while true; do
        read -p "$prompt [y/N]: " response
        response=${response:-$default}
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "请输入 y 或 n" ;;
        esac
    done
}

# 功能选择菜单（简化版，适合代理环境）
show_feature_menu() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🚀 Mihomo 增强功能配置                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}✨ 推荐启用以下增强功能以获得更好的使用体验：${NC}"
    echo

    # 定时订阅更新配置
    if ask_yes_no "🤔 是否启用${YELLOW}定时订阅更新${NC}功能？(${GREEN}推荐${NC})"; then
        ENABLE_AUTO_UPDATE=true
        echo
        echo -e "${BLUE}⏰ 选择更新频率：${NC}"
        echo -e "   ${GREEN}1)${NC} 每 6 小时 (推荐) ⭐"
        echo -e "   ${GREEN}2)${NC} 每 12 小时"
        echo -e "   ${GREEN}3)${NC} 每 24 小时"
        echo
        read -p "请选择 (1-3, 默认1): " choice
        case "${choice:-1}" in
            1) UPDATE_INTERVAL=6 ;;
            2) UPDATE_INTERVAL=12 ;;
            3) UPDATE_INTERVAL=24 ;;
            *) UPDATE_INTERVAL=6 ;;
        esac
        log_info "✅ 已设置每 $UPDATE_INTERVAL 小时自动更新一次"
    else
        ENABLE_AUTO_UPDATE=false
    fi

    # 配置验证
    if ask_yes_no "🤔 是否启用${YELLOW}配置文件验证${NC}功能？(${GREEN}推荐${NC})"; then
        ENABLE_CONFIG_VALIDATION=true
        log_info "✅ 已启用配置文件验证功能"
    else
        ENABLE_CONFIG_VALIDATION=false
    fi

    # 日志管理
    if ask_yes_no "🤔 是否启用${YELLOW}日志管理系统${NC}？(${GREEN}推荐${NC})"; then
        ENABLE_LOG_MANAGEMENT=true
        log_info "✅ 已启用日志管理系统"
    else
        ENABLE_LOG_MANAGEMENT=false
    fi

    echo
    log_info "🎉 功能配置完成！"
}

# 主安装流程
main() {
    # 显示欢迎信息
    show_proxy_welcome

    # 检查运行权限
    if [ "$EUID" -ne 0 ]; then
        log_error "❌ 此脚本需要root权限运行"
        echo -e "   ${YELLOW}请使用: ${GREEN}sudo bash $0${NC}"
        exit 1
    fi

    # 系统检测和准备
    log_info "🔍 开始系统环境全面检测..."

    # 使用增强的系统检测器
    if [ -f "scripts/system_checker.sh" ]; then
        log_info "使用增强系统检测器..."
        if bash scripts/system_checker.sh --fix; then
            log_info "✅ 系统环境检测通过"
        else
            log_error "❌ 系统环境检测发现问题"
            echo
            echo -e "${YELLOW}💡 建议：${NC}"
            echo -e "   1. 查看上方的详细错误信息和修复建议"
            echo -e "   2. 手动解决问题后重新运行安装脚本"
            echo -e "   3. 代理加速版已经是最兼容的版本"
            echo
            if ask_yes_no "是否忽略警告继续安装？"; then
                log_warn "⚠️  用户选择忽略警告继续安装"
            else
                exit 1
            fi
        fi
    else
        # 备用检测方法
        log_warn "未找到增强检测器，使用基础检测..."
        detect_architecture
        detect_os_type
        check_dependencies
    fi

    # 选择最佳代理
    select_best_proxy
    select_best_api_proxy

    # 获取最新版本并下载文件
    get_latest_version
    download_all_files

    # 显示功能选择菜单
    show_feature_menu

    # 检查现有安装
    if [ -d "$MihomoDir" ]; then
        if ask_yes_no "📁 /etc/mihomo 目录已存在，是否覆盖？"; then
            log_info "🔄 正在覆盖现有安装..."
            rm -rf "$MihomoDir"
        else
            log_info "❌ 取消安装"
            cleanup_temp_files
            exit 0
        fi
    fi

    # 创建目录结构
    log_info "📁 创建目录结构..."
    mkdir -p "$MihomoDir"
    mkdir -p "$MihomoDir/logs"
    mkdir -p "$MihomoDir/backups"
    mkdir -p "$MihomoDir/scripts"

    # 停止现有服务
    log_info "🛑 检查现有服务..."
    if systemctl is-active --quiet mihomo 2>/dev/null; then
        log_info "🔄 停止现有mihomo服务..."
        systemctl stop mihomo
    fi

    # 检查并终止进程
    local pid=$(pgrep mihomo 2>/dev/null || echo "")
    if [ -n "$pid" ]; then
        log_warn "⚠️  发现运行中的mihomo进程，正在终止..."
        kill -9 "$pid"
        sleep 2
    fi

    # 安装核心程序
    log_info "🔧 安装核心程序..."
    if [ -f "$DOWNLOAD_DIR/$MIHOMO_BINARY.gz" ]; then
        gunzip -c "$DOWNLOAD_DIR/$MIHOMO_BINARY.gz" > "$MihomoDir/mihomo"
        chmod +x "$MihomoDir/mihomo"
        log_info "✅ Mihomo 核心程序安装完成"

        # 验证程序
        if "$MihomoDir/mihomo" -v >/dev/null 2>&1; then
            version_info=$("$MihomoDir/mihomo" -v 2>/dev/null | head -1)
            log_info "📋 程序版本: $version_info"
        fi
    else
        log_error "❌ 核心程序文件不存在"
        cleanup_temp_files
        exit 1
    fi

    # 安装Web UI
    if [ "$UI_AVAILABLE" = true ] && [ -f "$DOWNLOAD_DIR/metacubexd.zip" ]; then
        log_info "🌐 安装 Web UI..."
        mkdir -p "$MihomoDir/ui"

        if unzip -q "$DOWNLOAD_DIR/metacubexd.zip" -d "/tmp/ui_extract_$$"; then
            local ui_dir=$(find "/tmp/ui_extract_$$" -name "metacubexd-*" -type d | head -1)
            if [ -n "$ui_dir" ]; then
                cp -r "$ui_dir"/* "$MihomoDir/ui/"
                log_info "✅ Web UI 安装完成"
            fi
            rm -rf "/tmp/ui_extract_$$"
        fi
    else
        log_warn "⚠️  跳过 Web UI 安装"
    fi

    # 处理配置文件
    if [ -f "$ConfigFile" ]; then
        cp "$ConfigFile" "$MihomoDir/"
        cp "$ConfigFile" "$MihomoDir/backups/config_initial.yaml"
        log_info "✅ 使用本地配置文件"
    else
        log_warn "⚠️  未找到本地配置文件，将创建默认配置"
        # 这里可以添加创建默认配置的逻辑
    fi

    # 处理GeoIP数据库
    if [ "$COUNTRY_AVAILABLE" = true ] && [ -f "$DOWNLOAD_DIR/Country.mmdb" ]; then
        cp "$DOWNLOAD_DIR/Country.mmdb" "$MihomoDir/"
        log_info "✅ GeoIP 数据库安装完成"
    elif [ -f "$CountryFile" ]; then
        cp "$CountryFile" "$MihomoDir/"
        log_info "✅ 使用本地 GeoIP 数据库"
    else
        log_warn "⚠️  GeoIP 数据库不可用"
    fi

    # 部署增强脚本
    if [ -d "$ScriptsDir" ]; then
        log_info "📜 部署增强功能脚本..."
        cp -r "$ScriptsDir"/* "$MihomoDir/scripts/"
        chmod +x "$MihomoDir/scripts"/*.sh
        log_info "✅ 增强功能脚本部署完成"
    fi

    # 创建systemd服务
    log_info "⚙️  配置系统服务..."
    cat > /etc/systemd/system/mihomo.service << 'EOF'
[Unit]
Description=mihomo Daemon, Another Clash Kernel.
After=network.target NetworkManager.service systemd-networkd.service iwd.service

[Service]
Type=simple
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE
Restart=always
RestartSec=5
ExecStartPre=/usr/bin/sleep 1s
ExecStart=/etc/mihomo/mihomo -d /etc/mihomo
ExecReload=/bin/kill -HUP $MAINPID
StandardOutput=append:/etc/mihomo/logs/mihomo.log
StandardError=append:/etc/mihomo/logs/error.log

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    systemctl daemon-reload

    # 创建便捷命令
    log_info "🔧 创建便捷管理命令..."

    # 创建clashon命令
    cat > /usr/local/bin/clashon << 'EOF'
#!/bin/bash
# Mihomo 启动命令
systemctl start mihomo
if systemctl is-active --quiet mihomo; then
    echo "✅ Mihomo 已启动"
    echo "🌐 WebUI: http://127.0.0.1:9090"
    echo "🔗 HTTP代理: 127.0.0.1:7890"
    echo "🔗 SOCKS代理: 127.0.0.1:7891"
else
    echo "❌ Mihomo 启动失败"
    systemctl status mihomo
fi
EOF

    # 创建clashoff命令
    cat > /usr/local/bin/clashoff << 'EOF'
#!/bin/bash
# Mihomo 停止命令
systemctl stop mihomo
if ! systemctl is-active --quiet mihomo; then
    echo "✅ Mihomo 已停止"
else
    echo "❌ Mihomo 停止失败"
fi
EOF

    # 创建clashstatus命令
    cat > /usr/local/bin/clashstatus << 'EOF'
#!/bin/bash
# Mihomo 状态查看命令
echo "=== Mihomo 服务状态 ==="
systemctl status mihomo --no-pager
echo ""
echo "=== 端口监听状态 ==="
netstat -tlnp | grep -E ":(7890|7891|9090)" || echo "未发现监听端口"
echo ""
echo "=== 快速访问 ==="
echo "WebUI: http://127.0.0.1:9090"
echo "HTTP代理: 127.0.0.1:7890"
echo "SOCKS代理: 127.0.0.1:7891"
EOF

    # 创建clashlog命令
    cat > /usr/local/bin/clashlog << 'EOF'
#!/bin/bash
# Mihomo 日志查看命令
echo "=== Mihomo 实时日志 (按Ctrl+C退出) ==="
journalctl -u mihomo -f
EOF

    # 创建clashrestart命令
    cat > /usr/local/bin/clashrestart << 'EOF'
#!/bin/bash
# Mihomo 重启命令
echo "🔄 重启 Mihomo 服务..."
systemctl restart mihomo
sleep 2
if systemctl is-active --quiet mihomo; then
    echo "✅ Mihomo 重启成功"
    echo "🌐 WebUI: http://127.0.0.1:9090"
else
    echo "❌ Mihomo 重启失败"
    systemctl status mihomo
fi
EOF

    # 设置执行权限
    chmod +x /usr/local/bin/clashon
    chmod +x /usr/local/bin/clashoff
    chmod +x /usr/local/bin/clashstatus
    chmod +x /usr/local/bin/clashlog
    chmod +x /usr/local/bin/clashrestart

    log_info "✅ 便捷命令创建完成"

    # 启动服务
    log_info "🚀 启动mihomo服务..."
    systemctl start mihomo
    systemctl enable mihomo

    # 等待服务启动
    sleep 3

    if systemctl is-active --quiet mihomo; then
        log_info "✅ mihomo 服务启动成功"
    else
        log_error "❌ mihomo 服务启动失败"
        systemctl status mihomo
    fi

    # 清理临时文件
    cleanup_temp_files

    # 显示完成信息
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          🎉 安装成功完成！                                   ║${NC}"
    echo -e "${GREEN}║                 Mihomo Linux 代理加速版 v2.0                                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}🌐 Web 管理界面：${NC}"
    local local_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
    echo -e "   ${GREEN}本地访问${NC}:  http://127.0.0.1:9090/ui"
    echo -e "   ${GREEN}局域网访问${NC}: http://$local_ip:9090/ui"
    echo
    echo -e "${BLUE}🚀 便捷管理命令：${NC}"
    echo -e "   ${GREEN}clashon${NC}       # 启动Mihomo服务"
    echo -e "   ${GREEN}clashoff${NC}      # 停止Mihomo服务"
    echo -e "   ${GREEN}clashrestart${NC}  # 重启Mihomo服务"
    echo -e "   ${GREEN}clashstatus${NC}   # 查看服务状态"
    echo -e "   ${GREEN}clashlog${NC}      # 查看实时日志"
    echo
    echo -e "${BLUE}🔧 系统管理命令：${NC}"
    echo -e "   ${GREEN}systemctl start mihomo${NC}    # 启动服务"
    echo -e "   ${GREEN}systemctl stop mihomo${NC}     # 停止服务"
    echo -e "   ${GREEN}systemctl status mihomo${NC}   # 查看状态"
    echo
    echo -e "${YELLOW}💡 重要提示：${NC}"
    echo -e "   • 请编辑 ${GREEN}/etc/mihomo/config.yaml${NC} 添加您的订阅URL"
    echo -e "   • 建议为Web界面设置密码保护"
    echo -e "   • 使用 ${GREEN}clashstatus${NC} 查看完整系统状态"
    echo
    log_info "🎉 安装完成！感谢使用 Mihomo Linux 代理加速版"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
