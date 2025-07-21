# 贡献指南

感谢您考虑为 TraeChatDemo 项目做出贡献！以下是一些指导方针，帮助您更有效地参与项目开发。

## 行为准则

请尊重所有项目参与者，保持专业和友好的交流环境。

## 如何贡献

### 报告问题

如果您发现了问题或有功能建议，请通过以下步骤提交：

1. 检查现有的问题列表，避免重复提交
2. 使用清晰的标题和详细描述创建新问题
3. 包含重现步骤、预期行为和实际行为
4. 如果可能，添加屏幕截图或错误日志

### 提交代码

1. Fork 仓库到您的 GitHub 账户
2. 克隆您的 fork 到本地：
   ```bash
   git clone https://github.com/您的用户名/TraeChatDemo.git
   cd TraeChatDemo
   ```
3. 创建新的功能分支：
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. 进行必要的代码更改
5. 确保代码符合项目的代码风格和质量标准
6. 提交您的更改：
   ```bash
   git commit -m "Add feature: your feature description"
   ```
7. 推送到您的 fork：
   ```bash
   git push origin feature/your-feature-name
   ```
8. 创建 Pull Request 到主仓库的 main 分支

## 开发指南

### 前端开发

1. 遵循 Flutter 官方推荐的代码风格
2. 使用 Provider/Bloc 进行状态管理
3. 确保 UI 组件可重用且符合设计规范
4. 添加适当的注释和文档

### 后端开发

1. 遵循 Go 官方推荐的代码风格
2. 使用依赖注入模式组织代码
3. 编写单元测试和集成测试
4. 确保 API 文档保持最新

## 代码审查流程

所有提交的代码都将经过审查。请注意以下几点：

1. 代码必须通过所有自动化测试
2. 代码必须符合项目的代码风格和质量标准
3. 代码必须包含适当的测试覆盖
4. 代码必须解决特定问题或实现特定功能

## 版本控制

我们使用语义化版本控制（[SemVer](https://semver.org/lang/zh-CN/)）。

## 许可证

通过贡献代码，您同意您的贡献将在 MIT 许可证下发布。