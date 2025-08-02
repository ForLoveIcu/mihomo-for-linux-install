# 自动更新机制说明

本项目支持多种方式自动更新Mihomo核心程序和WebUI界面到最新版本。

## 🤖 GitHub Actions自动更新

### 配置文件
- `.github/workflows/update-binaries.yml` - 主要的自动更新工作流
- `.github/dependabot.yml` - Dependabot配置文件

### 工作原理
1. **定时检查**: 每天北京时间10:00自动检查更新
2. **版本比较**: 对比当前版本与GitHub最新Release版本
3. **自动下载**: 如有新版本，自动下载各架构的二进制文件
4. **文档更新**: 自动更新VERSION.md和README文件中的版本信息
5. **自动提交**: 提交更改并推送到主分支
6. **创建Release**: 为自动更新创建新的Release标签

### 触发方式
- **定时触发**: 每天UTC 02:00 (北京时间10:00)
- **手动触发**: 在GitHub Actions页面手动运行
- **Push触发**: 可以配置在特定条件下触发

### 更新内容
- Mihomo核心程序 (所有支持的架构)
- MetaCubeXD WebUI界面
- 版本文档和说明文件

## 🔧 Dependabot配置

### 功能
- 自动更新GitHub Actions依赖
- 每周一检查并创建PR
- 自动标记和分配审核者

### 配置选项
```yaml
schedule:
  interval: "weekly"  # 检查频率
  day: "monday"       # 检查日期
  time: "02:00"       # 检查时间
```

## 📋 手动更新脚本

### 使用方法
```bash
# 更新到最新版本
./scripts/update-binaries.sh

# 更新到指定版本
./scripts/update-binaries.sh v1.19.12 v1.188.1

# 只更新Mihomo，WebUI使用最新版
./scripts/update-binaries.sh v1.19.12
```

### 脚本功能
- 自动获取最新版本信息
- 下载指定架构的二进制文件
- 备份旧版本文件
- 更新文档版本信息
- 提供详细的操作日志

## 🔄 更新流程

### 自动更新流程
```
定时触发 → 检查版本 → 下载文件 → 更新文档 → 提交推送 → 创建Release
```

### 手动更新流程
```
运行脚本 → 下载文件 → 更新文档 → 手动提交 → 手动推送
```

## ⚙️ 配置选项

### 修改检查频率
编辑 `.github/workflows/update-binaries.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # 每天02:00
  # - cron: '0 2 * * 1'  # 每周一02:00
  # - cron: '0 2 1 * *'  # 每月1号02:00
```

### 添加通知
可以在工作流中添加通知步骤：
```yaml
- name: 发送通知
  if: steps.download-updates.outputs.has_updates == 'true'
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: '🤖 自动更新完成！新版本已发布。'
      })
```

## 🛡️ 安全考虑

### 权限设置
- 工作流使用 `GITHUB_TOKEN` 进行认证
- 只有仓库维护者可以手动触发更新
- 自动提交使用GitHub Actions身份

### 文件验证
- 下载后验证文件大小
- 检查文件类型和格式
- 备份旧版本以便回滚

## 📊 监控和日志

### 查看更新历史
- GitHub Actions页面查看运行历史
- Releases页面查看自动创建的版本
- 提交历史查看具体更改

### 故障排除
1. **下载失败**: 检查网络连接和GitHub API限制
2. **版本检测错误**: 验证API响应格式
3. **提交失败**: 检查权限和分支保护规则

## 🔧 自定义配置

### 添加新架构
在工作流中添加新的下载步骤：
```bash
curl -L -o "mihomo-linux-新架构-${latest_mihomo}.gz" \
  "https://github.com/MetaCubeX/mihomo/releases/download/${latest_mihomo}/mihomo-linux-新架构-${latest_mihomo}.gz"
```

### 修改更新策略
- 可以配置只在主要版本更新时触发
- 可以添加测试步骤验证新版本
- 可以配置更新前的备份策略

## 📝 注意事项

1. **网络依赖**: 需要稳定的网络连接到GitHub
2. **存储空间**: 多个架构的文件会占用较多空间
3. **API限制**: GitHub API有速率限制
4. **版本兼容**: 新版本可能有破坏性更改

## 🎯 最佳实践

1. **定期检查**: 监控自动更新的运行状态
2. **测试验证**: 在重要更新后进行功能测试
3. **备份策略**: 保留多个版本的备份
4. **文档同步**: 确保文档与实际版本一致
