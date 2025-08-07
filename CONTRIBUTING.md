# 贡献指南

感谢您对 Mihomo Linux 安装脚本项目的关注和贡献意愿。

## 贡献原则

### 项目定位
本项目专注于为技术学习和研究提供便利的自动化安装工具。所有贡献都应符合这一核心定位。

### 贡献类型
我们欢迎以下类型的贡献：
- Bug 修复和问题报告
- 文档改进和翻译
- 代码优化和性能提升
- 新的 Linux 发行版支持
- 镜像服务的测试和验证

## 开发环境

### 系统要求
- Linux 系统（推荐 Ubuntu 20.04+ 或 Debian 11+）
- Bash 4.0+
- Git 2.20+
- 基本的系统管理权限

### 开发工具
- 文本编辑器（推荐 VS Code 或 Vim）
- ShellCheck（用于脚本静态分析）
- 虚拟机或容器环境（用于测试）

## 代码规范

### Shell 脚本规范
- 使用 4 空格缩进
- 函数名使用下划线分隔（snake_case）
- 变量名使用大写字母和下划线
- 添加适当的注释说明复杂逻辑
- 使用 `set -euo pipefail` 确保脚本安全性

### 提交信息规范
使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### 类型说明
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

#### 示例
```
feat(install): 添加 Rocky Linux 9 支持

- 新增 Rocky Linux 9 的包管理器检测
- 更新系统兼容性列表
- 添加相关测试用例

Closes #123
```

## 提交流程

### 1. Fork 项目
在 GitHub 上 Fork 本项目到您的账户。

### 2. 创建分支
```bash
git checkout -b feature/your-feature-name
```

### 3. 开发和测试
- 编写代码并确保通过所有测试
- 使用 ShellCheck 检查脚本质量
- 在多个 Linux 发行版上测试（如可能）

### 4. 提交更改
```bash
git add .
git commit -m "feat: 添加新功能描述"
```

### 5. 推送分支
```bash
git push origin feature/your-feature-name
```

### 6. 创建 Pull Request
在 GitHub 上创建 Pull Request，详细描述您的更改。

## 测试指南

### 基本测试
在提交前，请确保：
- 脚本在目标系统上能正常执行
- 所有功能按预期工作
- 没有引入新的错误或警告

### 测试环境
推荐在以下环境中测试：
- Ubuntu 20.04/22.04
- Debian 11/12
- CentOS 7/8
- Rocky Linux 8/9

### 测试脚本
```bash
# 基本安装测试
./quick_install.sh

# 卸载测试
./uninstall.sh

# 镜像测试
./test_github_mirrors.sh
```

## 问题报告

### Bug 报告
使用 GitHub Issues 报告 Bug，请包含：
- 操作系统和版本
- 错误信息的完整输出
- 复现步骤
- 预期行为和实际行为

### 功能请求
提交功能请求时，请说明：
- 功能的具体需求
- 使用场景和必要性
- 可能的实现方案

## 代码审查

### 审查标准
- 代码质量和可读性
- 功能完整性和正确性
- 文档的完整性
- 测试覆盖率
- 安全性考虑

### 审查流程
1. 自动化检查（ShellCheck、语法检查）
2. 人工代码审查
3. 功能测试验证
4. 文档审查
5. 最终批准和合并

## 社区准则

### 行为准则
- 保持友善和专业的交流态度
- 尊重不同的观点和经验水平
- 专注于技术讨论，避免无关话题
- 遵守开源社区的基本礼仪

### 沟通渠道
- GitHub Issues: 问题报告和功能讨论
- GitHub Discussions: 一般性讨论和问答
- Pull Request: 代码审查和技术讨论

## 许可证

通过向本项目贡献代码，您同意您的贡献将在 MIT 许可证下发布。

## 联系方式

如有任何疑问，请通过 GitHub Issues 联系项目维护者。

---

感谢您的贡献！
