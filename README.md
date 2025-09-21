# Mihomo Linux 安装脚本

一个用于在 Linux 系统上自动化安装和配置 Mihomo 代理软件的部署工具。

## 项目概述

本项目提供了一套完整的 Mihomo 安装解决方案，支持多架构 Linux 系统的自动化部署。通过集成多个 GitHub 镜像加速服务，确保在各种网络环境下都能稳定完成安装。

### 核心特性

- **多架构支持**: 自动检测并支持 x86_64、ARM64、ARMv7 架构
- **镜像加速**: 集成多个 GitHub 文件加速服务，提升下载成功率
- **智能切换**: 自动故障转移机制，确保安装可靠性
- **系统集成**: 完整的 systemd 服务配置和管理
- **多前端支持**: 支持 MetaCubeXD 和 Zashboard 两种 Web 管理界面
- **便捷管理**: 提供简化的命令行工具

### 技术实现

- **下载优化**: 多镜像源智能选择，支持文件格式验证
- **错误处理**: 完善的异常处理和用户反馈机制
- **系统兼容**: 支持主流 Linux 发行版（Debian、Ubuntu、CentOS、Rocky Linux）

## 系统要求

### 支持的操作系统
- Debian 9+ / Ubuntu 18.04+
- CentOS 7+ / Rocky Linux 8+
- 其他基于 systemd 的 Linux 发行版

### 硬件架构
- x86_64 (AMD64)
- ARM64 (AArch64)
- ARMv7

### 系统权限
- 需要 root 权限执行安装

## 快速开始

### 在线安装

```bash
curl -fsSL https://raw.githubusercontent.com/ForLoveIcu/mihomo-for-linux-install/main/quick_install.sh | bash
```

### 离线安装

1. 下载项目文件
```bash
git clone https://github.com/ForLoveIcu/mihomo-for-linux-install.git
cd mihomo-for-linux-install
```

2. 执行安装脚本
```bash
chmod +x install.sh
./install.sh
```

## 服务管理

安装完成后，系统将提供以下管理命令：

### 基础命令
- `clashon` - 启动 Mihomo 服务
- `clashoff` - 停止 Mihomo 服务
- `clashstatus` - 查看服务状态
- `clashlog` - 查看服务日志
- `clashrestart` - 重启服务
- `clashfrontend` - 前端界面管理
- `clashuninstall` - 完整卸载

### 系统服务
```bash
# 使用 systemctl 管理
systemctl start mihomo
systemctl stop mihomo
systemctl status mihomo
systemctl enable mihomo
systemctl disable mihomo
```

## 配置说明

### 默认配置
- **HTTP 代理端口**: 7890
- **SOCKS5 代理端口**: 7891
- **管理界面端口**: 9090
- **DNS 服务端口**: 53

### 配置文件位置
- 主配置文件: `/etc/mihomo/config.yaml`
- 安装目录: `/opt/mihomo/`
- 服务文件: `/etc/systemd/system/mihomo.service`

### Web 管理界面
安装完成后，可通过以下地址访问管理界面：
```
http://服务器IP:9090
```

#### 多前端支持
项目支持两种前端界面，可根据需求选择：

**MetaCubeXD (默认)**
- 官方维护，功能完整
- 稳定可靠，兼容性好
- 适合生产环境使用

**Zashboard**
- 现代化设计，界面美观
- 移动端友好，响应式布局
- 基于 Vue 3，性能优秀

#### 前端管理命令
```bash
# 查看当前前端信息
clashfrontend info

# 切换到 MetaCubeXD
clashfrontend switch metacubexd

# 切换到 Zashboard
clashfrontend switch zashboard

# 交互式前端选择
clashfrontend
```

## 技术架构

### 组件说明
- **Mihomo**: 核心代理引擎，基于 Clash Meta
- **前端界面**: 支持 MetaCubeXD 和 Zashboard 两种选择
- **安装脚本**: 自动化部署工具
- **前端管理器**: 支持前端切换和管理

### 镜像加速机制
项目集成了多个 GitHub 镜像服务，按优先级自动选择：
1. 主要镜像服务
2. 备用镜像服务
3. 原始 GitHub 地址（最后备选）

### 文件验证
- 文件格式检查：确保下载的是正确的二进制文件
- 文件大小验证：防止下载不完整的文件
- 自动重试机制：下载失败时自动切换镜像

## 故障排除

### 常见问题

**安装失败**
- 检查网络连接
- 确认系统权限（需要 root）
- 查看错误日志

**服务无法启动**
```bash
# 查看服务状态
systemctl status mihomo

# 查看详细日志
journalctl -u mihomo -f
```

**端口冲突**
- 检查端口占用情况
- 修改配置文件中的端口设置

### 卸载方法

**方法一：使用便捷命令（推荐）**
```bash
clashuninstall
```

**方法二：直接运行卸载脚本**
```bash
# 在线卸载
curl -fsSL https://github.com/ForLoveIcu/mihomo-for-linux-install/raw/master/uninstall.sh | sudo bash

# 本地卸载（如果已下载）
sudo bash uninstall.sh
```

**方法三：手动卸载**
```bash
# 停止并禁用服务
sudo systemctl stop mihomo
sudo systemctl disable mihomo

# 删除文件和目录
sudo rm -rf /etc/mihomo
sudo rm -f /etc/systemd/system/mihomo.service
sudo rm -f /usr/local/bin/clash*

# 清理配置
sudo sed -i '/clash_control\.sh/d' /etc/bashrc
sudo systemctl daemon-reload
```

**注意事项：**
- 卸载前会要求确认，避免误操作
- 自动清理所有相关文件和配置
- 卸载后需要重启终端以清理环境变量

## 法律声明

### 使用条款
- 本项目仅供技术学习和研究目的使用
- 用户必须遵守所在国家和地区的相关法律法规
- 禁止用于任何违法违规活动

### 免责声明
- 软件按"现状"提供，不提供任何保证
- 用户使用风险自担
- 详细条款请参阅 [DISCLAIMER.md](DISCLAIMER.md)

## 开源协议

本项目采用 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目。

### 开发环境
- Bash 4.0+
- Git
- 基本的 Linux 系统管理知识

### 提交规范
- 使用清晰的提交信息
- 遵循现有的代码风格
- 添加必要的测试和文档

## 版本历史

- **v2.2.0** - 镜像加速优化，提升下载稳定性
- **v2.1.0** - 功能增强，完善便捷命令
- **v2.0.0** - 重构版本，多架构支持

详细更新日志请参阅 [CHANGELOG.md](CHANGELOG.md)

## 相关项目

- [Mihomo](https://github.com/MetaCubeX/mihomo) - 核心代理引擎
- [MetaCubeXD](https://github.com/MetaCubeX/metacubexd) - Web 管理界面 (默认)
- [Zashboard](https://github.com/Zephyruso/zashboard) - 现代化 Web 管理界面

---

**注意**: 请确保在合法合规的前提下使用本项目。
