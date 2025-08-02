#!/bin/bash

# Mihomo 二进制文件手动更新脚本
# 用法: ./scripts/update-binaries.sh [mihomo-version] [webui-version]

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 获取最新版本
get_latest_version() {
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    log_info "下载 $description..."
    if curl -L -o "$output" "$url" --retry 3 --retry-delay 5; then
        log_success "下载完成: $output"
    else
        log_error "下载失败: $url"
        return 1
    fi
}

main() {
    log_info "🚀 开始更新Mihomo二进制文件"
    
    # 获取版本参数或自动获取最新版本
    if [ $# -ge 1 ]; then
        MIHOMO_VERSION="$1"
        log_info "使用指定的Mihomo版本: $MIHOMO_VERSION"
    else
        log_info "获取Mihomo最新版本..."
        MIHOMO_VERSION=$(get_latest_version "MetaCubeX/mihomo")
        log_success "Mihomo最新版本: $MIHOMO_VERSION"
    fi
    
    if [ $# -ge 2 ]; then
        WEBUI_VERSION="$2"
        log_info "使用指定的WebUI版本: $WEBUI_VERSION"
    else
        log_info "获取WebUI最新版本..."
        WEBUI_VERSION=$(get_latest_version "MetaCubeX/metacubexd")
        log_success "WebUI最新版本: $WEBUI_VERSION"
    fi
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    log_info "临时目录: $TEMP_DIR"
    
    # 下载Mihomo各架构版本
    log_info "📦 下载Mihomo二进制文件..."
    
    architectures=("amd64-v1" "arm64" "armv7")
    for arch in "${architectures[@]}"; do
        filename="mihomo-linux-${arch}-${MIHOMO_VERSION}.gz"
        url="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/${filename}"
        download_file "$url" "$TEMP_DIR/$filename" "Mihomo $arch"
    done
    
    # 下载WebUI
    log_info "🎨 下载WebUI文件..."
    webui_url="https://github.com/MetaCubeX/metacubexd/releases/download/${WEBUI_VERSION}/compressed-dist.tgz"
    download_file "$webui_url" "$TEMP_DIR/metacubexd.tgz" "WebUI"
    
    # 备份旧文件
    log_info "💾 备份旧文件..."
    if [ -d "binaries" ]; then
        cp -r binaries "binaries.backup.$(date +%Y%m%d-%H%M%S)"
        log_success "已备份到 binaries.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # 创建目录并复制新文件
    log_info "📁 更新文件..."
    mkdir -p binaries
    
    # 删除旧文件
    rm -f mihomo-linux-*.gz compressed-dist.tgz
    rm -f binaries/mihomo-linux-*.gz binaries/metacubexd.tgz
    
    # 复制新文件
    cp "$TEMP_DIR"/mihomo-linux-*.gz binaries/
    cp "$TEMP_DIR"/mihomo-linux-*.gz .
    cp "$TEMP_DIR/metacubexd.tgz" binaries/
    cp "$TEMP_DIR/metacubexd.tgz" compressed-dist.tgz
    
    log_success "文件更新完成"
    
    # 更新文档
    log_info "📝 更新文档..."
    current_date=$(date '+%Y-%m-%d')
    
    # 更新VERSION.md
    if [ -f "VERSION.md" ]; then
        # 在开头添加新版本记录
        cat > temp_version.md << EOF
# Mihomo Linux 安装脚本版本历史

## v2.0.3 (手动更新版) - $current_date

### 🔄 手动更新
- **Mihomo核心**: 更新到 $MIHOMO_VERSION
- **WebUI界面**: 更新到 $WEBUI_VERSION
- **更新方式**: 手动执行更新脚本
- **更新时间**: $current_date

$(tail -n +3 VERSION.md)
EOF
        mv temp_version.md VERSION.md
        log_success "VERSION.md 已更新"
    fi
    
    # 更新binaries/README.md
    if [ -f "binaries/README.md" ]; then
        sed -i.bak "s/Mihomo 核心程序 (v[^)]*)/Mihomo 核心程序 ($MIHOMO_VERSION)/" binaries/README.md
        sed -i.bak "s/WebUI 界面 (v[^)]*)/WebUI 界面 ($WEBUI_VERSION)/" binaries/README.md
        sed -i.bak "s/\*\*Mihomo 版本\*\*: v[^(]*/\*\*Mihomo 版本\*\*: $MIHOMO_VERSION/" binaries/README.md
        sed -i.bak "s/\*\*WebUI 版本\*\*: v[^(]*/\*\*WebUI 版本\*\*: $WEBUI_VERSION/" binaries/README.md
        sed -i.bak "s/\*\*更新时间\*\*: [0-9-]*/\*\*更新时间\*\*: $current_date/" binaries/README.md
        rm -f binaries/README.md.bak
        log_success "binaries/README.md 已更新"
    fi
    
    # 显示文件信息
    log_info "📊 文件信息:"
    ls -lh mihomo-linux-*.gz compressed-dist.tgz 2>/dev/null || true
    ls -lh binaries/ 2>/dev/null || true
    
    log_success "🎉 更新完成！"
    echo
    echo "📋 更新摘要:"
    echo "  Mihomo: $MIHOMO_VERSION"
    echo "  WebUI: $WEBUI_VERSION"
    echo "  日期: $current_date"
    echo
    echo "🔄 下一步:"
    echo "  1. 检查文件是否正确"
    echo "  2. 提交更改: git add . && git commit -m '手动更新二进制文件'"
    echo "  3. 推送到远程: git push origin main"
}

# 检查依赖
if ! command -v curl >/dev/null 2>&1; then
    log_error "需要安装 curl"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    log_error "需要安装 jq"
    exit 1
fi

# 执行主函数
main "$@"
