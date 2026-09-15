# Changelog

## Unreleased

- Add independent 5-hour remaining percentage and reset time alongside Weekly.
- Identify app-server windows by 300/10080-minute durations regardless of slot order; missing windows remain unknown.
- Show `5H … · W … · R×…` in the menu bar, with reset times, expiry details and any Weekly use count in the native menu.
- Preserve banked reset counts, expiry alerts and stale-data markers; expand parser and formatter regression coverage.


本项目遵循语义化版本号。

## 1.0.0 — 2026-08-03

- 首个公开版本。
- 显示 ChatGPT Weekly 剩余额度、自然重置倒计时和额外 Reset 数量。
- 提供 Reset 到期提醒与本机通知设置。
- 每 60 秒自动刷新，并支持手动立即刷新。
- 通过本机 ChatGPT/Codex app-server 自动复用登录状态，不保存登录令牌。
- 提供随 ChatGPT 启停的 `Token Balance Watcher`。
- 采用 macOS 原生分层菜单和系统菜单栏文字颜色。
