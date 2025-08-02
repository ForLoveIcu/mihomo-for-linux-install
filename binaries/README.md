# Mihomo 二进制文件

本目录包含最新版本的 Mihomo 核心程序和 WebUI 文件，用于离线安装环境。

## 📦 文件列表

### Mihomo 核心程序 (v1.19.12)
- `mihomo-linux-amd64-v1-v1.19.12.gz` - x86_64 架构 (Intel/AMD 64位)
- `mihomo-linux-arm64-v1.19.12.gz` - ARM64 架构 (ARMv8 64位)
- `mihomo-linux-armv7-v1.19.12.gz` - ARMv7 架构 (ARM 32位)

### WebUI 界面 (v1.188.1)
- `metacubexd.tgz` - MetaCubeX Dashboard Web界面

## 🔧 使用方法

### 离线安装
1. 将对应架构的文件复制到目标服务器
2. 解压缩文件：
   ```bash
   gunzip mihomo-linux-amd64-v1-v1.19.12.gz
   tar -xzf metacubexd.tgz
   ```
3. 设置执行权限：
   ```bash
   chmod +x mihomo-linux-amd64-v1
   ```

### 架构选择
- **x86_64 服务器**: 使用 `mihomo-linux-amd64-v1-v1.19.12.gz`
- **ARM64 设备** (如树莓派4): 使用 `mihomo-linux-arm64-v1.19.12.gz`
- **ARMv7 设备** (如树莓派3): 使用 `mihomo-linux-armv7-v1.19.12.gz`

## 📋 版本信息

- **Mihomo 版本**: v1.19.12 (2025-07-27)
- **WebUI 版本**: v1.188.1 (2025-07-18)
- **更新时间**: 2025-08-01

## 🔄 更新说明

这些文件会定期更新到最新版本。如需手动更新：

1. 访问 [Mihomo Releases](https://github.com/MetaCubeX/mihomo/releases)
2. 访问 [MetaCubeXD Releases](https://github.com/MetaCubeX/metacubexd/releases)
3. 下载对应架构的最新版本文件

## ⚠️ 注意事项

1. **架构匹配**: 确保下载的文件与目标设备架构匹配
2. **权限设置**: 解压后需要设置可执行权限
3. **文件完整性**: 建议验证文件大小和MD5值
4. **版本兼容**: 配置文件格式可能在版本间有变化

## 📝 文件大小

- amd64-v1: ~11.8MB (压缩后)
- arm64: ~10.9MB (压缩后)  
- armv7: ~11.1MB (压缩后)
- WebUI: ~1.6MB (压缩后)
