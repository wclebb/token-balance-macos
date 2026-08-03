# Token 余量（Token Balance）

<p align="center">
  <strong>简体中文</strong> · <a href="README.md">English</a>
</p>

<p align="center">
  <img src="Resources/AppIconConcepts/token-balance-concept-a-v1-transparent.png" width="160" alt="Token Balance icon">
</p>

<p align="center">
  一款本机运行的 macOS 菜单栏工具，用于查看 ChatGPT 订阅额度。<br>
  A local-first macOS menu bar utility for monitoring ChatGPT subscription usage.
</p>

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Release](https://img.shields.io/badge/release-v1.0.0-blue)
![License](https://img.shields.io/badge/license-Apache--2.0-green)

## 功能

- 显示 Weekly 剩余额度百分比和自然重置倒计时。
- 显示当前可用的额外 Reset 数量及临近到期提醒。
- 每 60 秒自动刷新，也可从菜单立即刷新。
- 使用 macOS 原生分层菜单，菜单栏文字跟随系统前景色。
- 自动复用本机 ChatGPT/Codex 登录状态，不要求选择文件或重新登录。
- 通过轻量后台组件随 ChatGPT 启动和退出。
- 使用统一 Provider 模型，为未来接入其他 AI 平台保留扩展空间。

常态菜单栏格式：

```text
65% · R×2 · 6d
```

| 字段 | 含义 |
| --- | --- |
| `65%` | Weekly 剩余额度 |
| `R×2` | 还有 2 次可用的额外 Reset |
| `6d` | 距离 Weekly 自然重置还有 6 天 |

额外 Reset 临近过期时，尾部会临时切换为最近一次到期倒计时。若上游不提供 Weekly 精确调用次数，应用显示 `W—`，不会用百分比伪造次数。

## 系统要求

- Apple Silicon Mac（当前 Release 为 arm64）
- macOS 14 Sonoma 或更高版本
- 已安装并登录 ChatGPT/Codex 桌面应用

## 安装

1. 从 [Releases](../../releases/latest) 下载 `Token-Balance-macOS.zip`。
2. 解压并将 `Token Balance.app` 拖入“应用程序”。系统显示名为“Token 余量”。
3. 当前 Release 使用 ad-hoc 签名，未经过 Apple Developer ID 公证。若 Gatekeeper 阻止首次启动，请在 Finder 中右键应用并选择“打开”。

首次运行会安装名为 `Token Balance Watcher` 的用户级后台组件。之后 ChatGPT 启动时 Token 余量自动启动，ChatGPT 退出时 Token 余量自动退出。用户手动退出后，本轮 ChatGPT 会话内不会被重新拉起。

后台组件位置：

```text
~/Library/Application Support/Token Balance/Token Balance Watcher
~/Library/LaunchAgents/com.tokenbalance.watcher.plist
```

升级自早期 TokenBar 版本时，应用会自动停用并移除旧 Watcher 和旧 LaunchAgent。

## 数据与隐私

Token 余量调用本机 ChatGPT/Codex 桌面应用自带的 `app-server`，读取当前账户提供的额度窗口：

- Weekly 已使用比例与自然重置时间；
- 可用额外 Reset 数量及过期时间；
- 当前订阅计划与额度窗口。

应用不读取、复制、上传或保存 ChatGPT 登录令牌，也不运行自有云端服务。通知和偏好设置仅保存在本机。

> 本项目依赖未承诺长期稳定的本机 app-server 协议。ChatGPT/Codex 桌面应用升级后，可能需要同步适配。

## 从源码构建

无需完整 Xcode，安装 Apple Command Line Tools 后执行：

```bash
bash scripts/test.sh
bash scripts/build-app.sh
bash scripts/test-branding.sh
```

生成产物：

```text
outputs/Token Balance.app
outputs/Token-Balance-macOS.zip
```

## 项目结构

```text
Sources/TokenBarCore/       额度模型、格式化、提醒和 Provider
Sources/TokenBarApp/        AppKit 菜单栏应用与 Watcher 安装器
Sources/TokenBarWatcher/    ChatGPT 生命周期监听后台组件
Resources/                  Info.plist 与 App Icon
Tests/                      核心行为测试
scripts/                    构建和验证脚本
```

内部类名、可执行文件名和 Bundle ID 中保留部分 `TokenBar` 标识，用于兼容早期版本；它们不是当前产品显示名称。

## 卸载

退出 Token 余量后，可删除应用，并执行：

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.tokenbalance.watcher.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.tokenbalance.watcher.plist"
rm -rf "$HOME/Library/Application Support/Token Balance"
```

## 开发方式：AI 辅助 / Vibe Coding

本仓库采用 AI 辅助的 Vibe Coding 工作流完成设计与实现。披露这一点是为了说明开发过程，而不是替代工程质量保证；可执行行为仍以源代码、自动化测试和 Release 验证结果为准。欢迎审查、修改和重新分发。

## 贡献与安全

提交改进前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题请按 [SECURITY.md](SECURITY.md) 私密报告，不要在公开 Issue 中提交令牌或个人数据。

## 许可证

本项目按 [Apache License 2.0](LICENSE) 开源。你可以使用、修改和再分发本项目，包括商业用途，但须遵守许可证中的版权、许可证副本、修改声明和专利条款。

## 商标声明

ChatGPT、OpenAI、Codex 和 Apple 是其各自权利人的商标。本项目是独立开源项目，与 OpenAI 或 Apple 无隶属、赞助或认可关系。
