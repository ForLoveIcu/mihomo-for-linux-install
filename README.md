# Mihomo Linux 一键安装脚本 v2.0.0

🚀 **重构版本** - 支持多架构、智能下载、完善的错误处理

## ✨ v2.0.0 新特性

相比 v1.0.0 版本的重大改进：

### 🔧 技术重构
- **多架构支持**: 自动检测 x86_64、ARM64、ARMv7 架构
- **智能下载**: 集成多个 GitHub 镜像加速服务，显著提升下载成功率
  - 🚀 **镜像加速**: 集成多个稳定的 GitHub 文件加速服务
  - 🔄 **智能切换**: 多层备用下载策略，确保高可用性
  - 📡 **自动优选**: 智能镜像自动切换机制，优化下载体验
- **错误处理**: 完善的错误处理和用户提示
- **系统兼容**: 支持更多 Linux 发行版

### 📦 安装方式升级
- **在线安装**: 自动下载最新版本
- **离线安装**: 支持本地文件安装
- **重试机制**: 下载失败自动重试

clash-verge/Clash Meta 等linux 使用的都是mihomo 内核 我这里使用的是[mihomo](https://github.com/MetaCubeX/mihomo/releases) +[metacubexd](https://github.com/MetaCubeX/metacubexd/releases)

## 环境要求

需要 root 或 sudo 权限。

具备 bash 和 systemd 的系统环境。

已适配：CentOS 7.x Rocky linux ,Debian和Ubuntu 稍微改动一下bashrc路径即可

## 🚀 快速开始

### 在线安装 (推荐)

```bash
curl -fsSL https://raw.githubusercontent.com/ForLoveIcu/mihomo-for-linux-install/main/quick_install.sh | bash
```

### 离线安装

```bash
git clone https://github.com/ForLoveIcu/mihomo-for-linux-install.git
cd mihomo-for-linux-install
sudo bash install.sh
```

### 🎮 便捷命令

安装完成后，您可以使用以下命令：

```bash
clashon        # 启动服务
clashoff       # 停止服务 + 清理系统代理
clashstatus    # 查看服务状态
clashlog       # 查看实时日志
clashrestart   # 重启服务
```

## 命令

- 启动代理环境: clashon
- 关闭代理环境: clashoff

## 添加订阅

替换 /etc/mihomo/config.yaml 里面的订阅即可

```
vi /etc/mihomo/config.yaml
```

重启clash即可

```
systemctl restart mihomo
```

## 进入面板

输入 服务器ip+9090/ui

点击添加即可

## 🚀 GitHub 镜像加速

本项目集成了智能镜像加速系统，确保在任何网络环境下都能稳定快速地完成安装：

### 🌟 核心特性
- **多镜像支持**: 集成多个稳定的 GitHub 文件加速服务
  - ✅ 完全免费，无需额外配置
  - ✅ 支持 Release 文件、Archive 文件、Raw 文件
  - ✅ 实时可用性检测，确保服务稳定
  - ✅ 多层备用策略，保障下载成功

### 🔄 智能切换机制
- **自动优选**: 智能选择最优镜像服务
- **故障转移**: 主镜像不可用时自动切换备用服务
- **重试机制**: 多次重试确保下载成功
- **降级保护**: 最终回退到原始 GitHub 地址

### 📡 用户体验优化
安装脚本会自动：
1. 智能检测并选择最佳镜像服务
2. 实时显示下载进度和镜像切换状态
3. 自动处理网络异常和服务不可用情况
4. 确保在网络受限环境下也能成功安装

这套机制显著提升了安装成功率，特别是在网络环境不佳的情况下表现优异。

## Thanks

[@nelvko](https://github.com/nelvko)

[clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install)

## 引用

[metacubexd](https://github.com/MetaCubeX/metacubexd/releases)

[mihomo](https://github.com/MetaCubeX/mihomo/releases)

[clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install)

## 特别声明

1. 编写本项目主要目的为学习和研究 `Shell` 编程，不得将本项目中任何内容用于违反国家/地区/组织等的法律法规或相关规定的其他用途。
2. 本项目保留随时对免责声明进行补充或更改的权利，直接或间接使用本项目内容的个人或组织，视为接受本项目的特别声明。
