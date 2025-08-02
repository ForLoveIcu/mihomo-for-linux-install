# Linux 一键安装 mihomo (新版clash、Clash Meta） 支持订阅

Linux 一键安装 mihomo (新版clash、Clash Meta）

一键安装Clash

一键安装Clash Meta

一键安装mihomo

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
