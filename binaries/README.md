# 二进制文件说明

本目录包含 Mihomo 的预编译二进制文件，支持离线安装。

## 文件说明

- `mihomo-linux-amd64-v1-*.gz`: x86_64 架构二进制文件
- `mihomo-linux-arm64-*.gz`: ARM64 架构二进制文件  
- `mihomo-linux-armv7-*.gz`: ARMv7 架构二进制文件
- `metacubexd.tgz`: WebUI 界面文件

## 使用方法

这些文件会被安装脚本自动使用，也可以手动解压使用：

```bash
# 解压二进制文件
gunzip mihomo-linux-amd64-v1-*.gz

# 解压 WebUI
tar -xzf metacubexd.tgz
```

## 自动更新

这些文件通过 GitHub Actions 自动更新，确保始终是最新版本。
