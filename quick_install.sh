#!/bin/bash

# {{CHENGQI:
# Action: Created
# Timestamp: 2025-08-01 17:30:00 +08:00
# Reason: Create quick installation selector for users to choose appropriate version
# Principle_Applied: KISS - Simple version selection logic
# Optimization: Automatic network detection and version recommendation
# Architectural_Note (AR): User-friendly installation selector
# Documentation_Note (DW): Quick installation selector script
# }}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    Mihomo Linux 快速安装选择器                              ║
# ║                              版本: v1.0                                     ║
# ║                          更新时间: 2025-08-01                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 作者: tianyufeng925
# 项目地址: https://github.com/tianyufeng925/mihomo-for-linux-install
# 许可证: MIT License
#
# 功能: 自动检测网络环境并推荐合适的安装版本
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
#
# 如有疑问，请咨询专业法律人士意见。
#
# ╔══════════════════════════════════════════════════════════════════════════════╗

# 移除 set -e 避免在网络测试时意外退出

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 显示欢迎界面
show_welcome() {
    clear
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          🚀 Mihomo Linux 安装器                             ║${NC}"
    echo -e "${BLUE}║                            快速版本选择器                                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}欢迎使用 Mihomo Linux 增强版安装器！${NC}"
    echo
    echo -e "${YELLOW}我们提供两个版本的安装脚本：${NC}"
    echo
    echo -e "${CYAN}📡 标准版${NC} - 适合网络环境良好的用户"
    echo -e "   ${GREEN}→${NC} 直连GitHub，速度快"
    echo -e "   ${GREEN}→${NC} 安装过程简洁高效"
    echo -e "   ${GREEN}→${NC} 推荐给网络无限制的用户"
    echo
    echo -e "${PURPLE}🌐 代理加速版${NC} - 适合网络受限的用户"
    echo -e "   ${GREEN}→${NC} 12个代理镜像智能选择"
    echo -e "   ${GREEN}→${NC} 自动选择最快的下载源"
    echo -e "   ${GREEN}→${NC} 推荐给网络受限的用户"
    echo
}

# 测试GitHub连接
test_github_connection() {
    echo -e "${BLUE}🔍 正在检测您的网络环境...${NC}"
    echo

    local github_accessible=false
    local api_accessible=false
    local download_speed=""

    # 测试GitHub主站
    echo -n "   测试GitHub主站连接... "
    if curl -s --connect-timeout 3 --max-time 5 "https://github.com" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 可访问${NC}"
        github_accessible=true
    else
        echo -e "${RED}✗ 不可访问${NC}"
    fi

    # 测试GitHub API
    echo -n "   测试GitHub API连接... "
    if curl -s --connect-timeout 3 --max-time 5 "https://api.github.com" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 可访问${NC}"
        api_accessible=true
    else
        echo -e "${RED}✗ 不可访问${NC}"
    fi

    # 测试下载速度
    if [ "$github_accessible" = true ]; then
        echo -n "   测试下载速度... "
        local test_url="https://github.com/MetaCubeX/mihomo"
        local start_time=$(date +%s)

        if curl -s --connect-timeout 3 --max-time 5 --head "$test_url" >/dev/null 2>&1; then
            local end_time=$(date +%s)
            local response_time=$((end_time - start_time))

            if [ "$response_time" -lt 3 ]; then
                echo -e "${GREEN}✓ 快速 (${response_time}s)${NC}"
                download_speed="fast"
            elif [ "$response_time" -lt 6 ]; then
                echo -e "${YELLOW}△ 一般 (${response_time}s)${NC}"
                download_speed="normal"
            else
                echo -e "${RED}✗ 较慢 (${response_time}s)${NC}"
                download_speed="slow"
            fi
        else
            echo -e "${RED}✗ 超时${NC}"
            download_speed="timeout"
        fi
    fi

    echo

    # 返回检测结果（只返回结果，不输出到stdout）
    if [ "$github_accessible" = true ] && [ "$api_accessible" = true ] && [ "$download_speed" = "fast" ]; then
        return 0  # excellent
    elif [ "$github_accessible" = true ] && [ "$api_accessible" = true ]; then
        return 1  # good
    elif [ "$github_accessible" = true ] || [ "$api_accessible" = true ]; then
        return 2  # limited
    else
        return 3  # poor
    fi
}

# 显示推荐结果
show_recommendation() {
    local network_status="$1"
    
    echo -e "${BLUE}📊 网络环境评估结果：${NC}"
    echo
    
    case "$network_status" in
        "excellent")
            echo -e "${GREEN}🎉 您的网络环境${YELLOW}优秀${GREEN}！${NC}"
            echo -e "${GREEN}   GitHub访问速度快，连接稳定${NC}"
            echo
            echo -e "${CYAN}💡 推荐使用：${YELLOW}标准版 (install.sh)${NC}"
            echo -e "   ${GREEN}→${NC} 直连GitHub，安装速度最快"
            echo -e "   ${GREEN}→${NC} 过程简洁，体验最佳"
            return 0
            ;;
        "good")
            echo -e "${GREEN}👍 您的网络环境${YELLOW}良好${GREEN}！${NC}"
            echo -e "${GREEN}   GitHub可以正常访问${NC}"
            echo
            echo -e "${CYAN}💡 推荐使用：${YELLOW}标准版 (install.sh)${NC}"
            echo -e "   ${GREEN}→${NC} 可以正常使用直连方式"
            echo -e "   ${YELLOW}→${NC} 如果下载较慢，可尝试代理加速版"
            return 0
            ;;
        "limited")
            echo -e "${YELLOW}⚠️  您的网络环境${YELLOW}受限${NC}"
            echo -e "${YELLOW}   GitHub访问不稳定或速度较慢${NC}"
            echo
            echo -e "${PURPLE}💡 推荐使用：${YELLOW}代理加速版 (install_proxy.sh)${NC}"
            echo -e "   ${GREEN}→${NC} 12个代理镜像智能选择"
            echo -e "   ${GREEN}→${NC} 自动选择最快的下载源"
            return 1
            ;;
        "poor")
            echo -e "${RED}❌您的网络环境${YELLOW}较差${NC}"
            echo -e "${RED}   无法正常访问GitHub${NC}"
            echo
            echo -e "${PURPLE}💡 强烈推荐：${YELLOW}代理加速版 (install_proxy.sh)${NC}"
            echo -e "   ${GREEN}→${NC} 专为网络受限环境优化"
            echo -e "   ${GREEN}→${NC} 多重代理确保下载成功"
            return 1
            ;;
    esac
}

# 用户选择
user_choice() {
    local recommended_version="$1"
    
    echo
    echo -e "${BLUE}请选择安装版本：${NC}"
    echo
    echo -e "${CYAN}1)${NC} 标准版 (install.sh) - 直连GitHub"
    echo -e "${PURPLE}2)${NC} 代理加速版 (install_proxy.sh) - 镜像加速"
    echo -e "${YELLOW}3)${NC} 查看详细对比"
    echo -e "${RED}4)${NC} 退出"
    echo
    
    while true; do
        read -p "请输入选择 (1-4): " choice
        case "$choice" in
            1)
                echo
                echo -e "${CYAN}✅ 您选择了标准版${NC}"
                return 1
                ;;
            2)
                echo
                echo -e "${PURPLE}✅ 您选择了代理加速版${NC}"
                return 2
                ;;
            3)
                show_detailed_comparison
                echo
                echo -e "${BLUE}请重新选择：${NC}"
                ;;
            4)
                echo
                echo -e "${YELLOW}👋 感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，请输入 1-4${NC}"
                ;;
        esac
    done
}

# 显示详细对比
show_detailed_comparison() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        版本详细对比                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    printf "%-20s %-25s %-25s\n" "特性" "标准版" "代理加速版"
    printf "%-20s %-25s %-25s\n" "----" "----" "--------"
    printf "%-20s %-25s %-25s\n" "适用环境" "网络环境良好" "网络受限/较慢"
    printf "%-20s %-25s %-25s\n" "下载源" "GitHub直连" "12个代理镜像"
    printf "%-20s %-25s %-25s\n" "连接测试" "基础连接测试" "智能代理选择"
    printf "%-20s %-25s %-25s\n" "下载速度" "取决于网络" "自动选择最快镜像"
    printf "%-20s %-25s %-25s\n" "稳定性" "高（直连）" "高（多重备用）"
    printf "%-20s %-25s %-25s\n" "功能完整性" "✅ 完整" "✅ 完整"
    echo
}

# 执行安装
run_installation() {
    local version="$1"

    echo -e "${BLUE}🚀 开始安装...${NC}"
    echo

    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ 需要root权限运行安装脚本${NC}"
        echo -e "${YELLOW}请使用: ${GREEN}sudo bash $0${NC}"
        exit 1
    fi

    # 直接下载并执行对应的安装脚本
    if [ "$version" = "1" ]; then
        echo -e "${CYAN}🔧 执行标准版安装...${NC}"
        echo -e "${BLUE}正在下载标准版安装脚本...${NC}"

        # 使用重试机制
        download_success=false
        for i in {1..3}; do
            echo -e "${BLUE}尝试第 $i 次下载...${NC}"
            if timeout 60 curl -sSL https://raw.githubusercontent.com/tianyufeng925/mihomo-for-linux-install/main/install.sh | bash; then
                echo -e "${GREEN}✅ 标准版安装完成${NC}"
                download_success=true
                break
            else
                echo -e "${YELLOW}⚠️ 第 $i 次尝试失败${NC}"
                if [ $i -lt 3 ]; then
                    echo -e "${BLUE}等待10秒后重试...${NC}"
                    sleep 10
                fi
            fi
        done

        if [ "$download_success" = false ]; then
            echo -e "${RED}❌ 标准版安装失败${NC}"
            echo -e "${YELLOW}💡 建议手动下载安装：${NC}"
            echo "wget https://raw.githubusercontent.com/tianyufeng925/mihomo-for-linux-install/main/install.sh"
            echo "sudo bash install.sh"
            exit 1
        fi
    else
        echo -e "${PURPLE}🔧 执行代理加速版安装...${NC}"
        echo -e "${BLUE}正在下载代理加速版安装脚本...${NC}"

        # 尝试多个下载源
        download_success=false
        sources=(
            "https://raw.githubusercontent.com/tianyufeng925/mihomo-for-linux-install/main/install_proxy.sh"
            "https://raw.githubusercontent.com/tianyufeng925/mihomo-for-linux-install/main/install.sh"
        )

        for source in "${sources[@]}"; do
            echo -e "${BLUE}尝试下载源: $source${NC}"
            if timeout 60 curl -sSL "$source" | bash; then
                echo -e "${GREEN}✅ 代理加速版安装完成${NC}"
                download_success=true
                break
            else
                echo -e "${YELLOW}⚠️ 此下载源失败，尝试下一个...${NC}"
            fi
        done

        if [ "$download_success" = false ]; then
            echo -e "${RED}❌ 所有下载源都失败了${NC}"
            echo -e "${YELLOW}💡 建议手动下载安装：${NC}"
            echo "wget https://raw.githubusercontent.com/tianyufeng925/mihomo-for-linux-install/main/install.sh"
            echo "sudo bash install.sh"
            exit 1
        fi
    fi
}

# 主函数
main() {
    # 显示欢迎界面
    show_welcome
    
    # 检测网络环境
    test_github_connection
    local network_result=$?

    # 根据返回码确定网络状态
    local network_status
    case $network_result in
        0) network_status="excellent" ;;
        1) network_status="good" ;;
        2) network_status="limited" ;;
        3) network_status="poor" ;;
        *) network_status="poor" ;;
    esac

    # 显示推荐
    local recommended_version
    if show_recommendation "$network_status"; then
        recommended_version=1
    else
        recommended_version=2
    fi
    
    # 用户选择
    user_choice "$recommended_version"
    local user_version=$?
    
    # 执行安装
    run_installation "$user_version"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
    main "$@"
fi
