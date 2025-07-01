# Mihomo Linux 一键安装脚本 v2.0.0

🚀 **重构版本** - 支持多架构、智能下载、完善的错误处理

## ✨ v2.0.0 新特性

相比 v1.0.0 版本的重大改进：

### 🔧 技术重构
- **多架构支持**: 自动检测 x86_64、ARM64、ARMv7 架构
- **智能下载**: 多镜像源自动选择，提高下载成功率
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

## 开始使用

一键安装

```
git clone https://githubfast.com/tianyufeng925/mihomo-for-linux-install.git && cd mihomo-for-linux-install && sudo bash -c '. install.sh; exec bash'
```

上述脚本已使用[代理加速下载](https://githubfast.com)，如克隆失败请自行更换。

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
