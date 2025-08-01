#!/bin/bash

# Mihomo 资源更新脚本
# 用于更新项目中的二进制文件和配置

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

# 加载配置
source resources.conf

# 创建资源目录
create_directories() {
    log_info "创建资源目录..."
    mkdir -p binaries
    mkdir -p configs
    mkdir -p docs
}

# 下载 Mihomo 二进制文件
download_mihomo() {
    log_info "下载 Mihomo 二进制文件..."
    
    local architectures=("x86_64" "aarch64" "armv7l")
    
    for arch in "${architectures[@]}"; do
        local file_var="ARCH_${arch}_MIHOMO"
        local filename="${!file_var}"
        
        if [ -n "$filename" ]; then
            local url="${MIHOMO_BASE_URL}/${filename}"
            local output="binaries/${filename}"
            
            log_info "下载 $arch: $filename"
            
            if curl -L --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
                log_success "下载成功: $output"
            else
                log_error "下载失败: $filename"
            fi
        fi
    done
}

# 下载 WebUI
download_webui() {
    log_info "下载 WebUI..."
    
    local output="binaries/metacubexd.tgz"
    
    if curl -L --connect-timeout 30 --max-time 300 -o "$output" "$WEBUI_DOWNLOAD_URL"; then
        log_success "WebUI 下载成功: $output"
    else
        log_error "WebUI 下载失败"
    fi
}

# 下载 GeoIP 数据库
download_geoip() {
    log_info "下载 GeoIP 数据库..."
    
    local output="binaries/Country.mmdb"
    
    if curl -L --connect-timeout 30 --max-time 300 -o "$output" "$GEOIP_DOWNLOAD_URL"; then
        log_success "GeoIP 数据库下载成功: $output"
    else
        log_error "GeoIP 数据库下载失败"
    fi
}

# 验证下载的文件
verify_files() {
    log_info "验证下载的文件..."
    
    local files=(
        "binaries/mihomo-linux-amd64-v1-v1.19.12.gz"
        "binaries/mihomo-linux-arm64-v1.19.12.gz"
        "binaries/mihomo-linux-armv7-v1.19.12.gz"
        "binaries/metacubexd.tgz"
        "binaries/Country.mmdb"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            if [ "$size" -gt 1000 ]; then
                log_success "✓ $file (${size} bytes)"
            else
                log_warn "⚠ $file 文件太小 (${size} bytes)"
            fi
        else
            log_error "✗ $file 不存在"
        fi
    done
}

# 更新版本信息
update_version_info() {
    log_info "更新版本信息..."
    
    # 获取最新版本信息
    local latest_version=$(curl -s "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    
    if [ -n "$latest_version" ]; then
        log_info "检测到最新版本: $latest_version"
        log_info "当前配置版本: $MIHOMO_VERSION"
        
        if [ "$latest_version" != "$MIHOMO_VERSION" ]; then
            log_warn "发现新版本，建议更新配置文件"
            log_info "请手动更新 resources.conf 中的版本信息"
        else
            log_success "版本信息已是最新"
        fi
    else
        log_warn "无法获取最新版本信息"
    fi
}

# 生成资源清单
generate_manifest() {
    log_info "生成资源清单..."
    
    cat > binaries/MANIFEST.md << EOF
# Mihomo 资源清单

## 版本信息
- **Mihomo 版本**: $MIHOMO_VERSION
- **WebUI 版本**: $WEBUI_VERSION
- **更新时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 文件列表

### Mihomo 核心文件
- \`mihomo-linux-amd64-v1-v1.19.12.gz\` - x86_64 架构
- \`mihomo-linux-arm64-v1.19.12.gz\` - ARM64 架构  
- \`mihomo-linux-armv7-v1.19.12.gz\` - ARMv7 架构

### WebUI 界面
- \`metacubexd.tgz\` - Web 管理界面

### 数据库文件
- \`Country.mmdb\` - GeoIP 数据库

## 使用说明

这些文件用于离线安装模式，当网络环境无法访问 GitHub 时，
安装脚本会自动使用这些预置的二进制文件。

## 更新说明

使用 \`update_resources.sh\` 脚本可以自动更新所有资源文件。

EOF

    log_success "资源清单已生成: binaries/MANIFEST.md"
}

# 主函数
main() {
    log_info "开始更新 Mihomo 资源..."
    
    create_directories
    download_mihomo
    download_webui
    download_geoip
    verify_files
    update_version_info
    generate_manifest
    
    log_success "资源更新完成！"
    log_info "请检查 binaries/ 目录中的文件"
}

# 执行主函数
main "$@"
