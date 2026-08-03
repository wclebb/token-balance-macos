# Contributing

感谢你改进 Token 余量。Bug 报告、兼容性修复、新 Provider 和文档改进都欢迎提交。

## 开始之前

- 搜索已有 Issue，避免重复。
- 涉及用户界面或数据源行为的较大改动，请先开 Issue 说明目标和方案。
- 不要在 Issue、日志或测试样本中提交账号令牌、会话文件或其他敏感信息。

## 本地开发

要求 macOS 14 或更高版本，以及 Apple Command Line Tools。

```bash
bash scripts/test.sh
bash scripts/build-app.sh
bash scripts/test-branding.sh
```

提交 Pull Request 前请确保以上命令全部通过。尽量让每个 PR 只解决一个主题，并清楚说明验证方式。

## 许可证

除非另有明确说明，你提交的贡献将按 Apache License 2.0 授权。
