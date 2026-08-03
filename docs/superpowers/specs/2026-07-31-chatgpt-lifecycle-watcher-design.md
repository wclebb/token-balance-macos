# TokenBar ChatGPT 生命周期联动设计

## 目标

通过用户级 LaunchAgent 运行一个无界面的轻量 Watcher，使 TokenBar 随 ChatGPT/Codex 桌面应用启动和退出。无需管理员权限，不修改 ChatGPT.app。

## 行为

- Watcher 登录后静默运行，通过 `NSWorkspace` 监听 `com.openai.codex`。
- ChatGPT 启动且 TokenBar 未运行时，Watcher 启动当前 TokenBar.app。
- ChatGPT 退出且 TokenBar 正在运行时，Watcher 终止 TokenBar。
- 用户在 ChatGPT 仍运行时手动选择“退出”，Watcher 在本轮 ChatGPT 会话中不重启 TokenBar；ChatGPT 下次启动时恢复联动。
- TokenBar 启动时将 Watcher 复制到 `~/Library/Application Support/TokenBar/`，写入用户级 LaunchAgent 并加载。

## 失败处理

Watcher 安装失败不影响 TokenBar 查看额度。TokenBar 不弹出阻塞对话框；安装错误仅写入系统日志。移动 TokenBar.app 后，用户手动启动一次即可更新 Watcher 的目标路径。

## 验证

用纯状态机测试覆盖初始启动、ChatGPT 启停、用户手动退出抑制和下一次会话恢复；构建后验证 Watcher 随应用打包、LaunchAgent 可加载以及 TokenBar 仍通过现有测试。
