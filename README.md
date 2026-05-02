# GitHub Connectivity Monitor

一个轻量级的 Windows 托盘工具，每 5 分钟检测 GitHub 是否可达，在恢复可访问时弹出通知提醒。最好搭配switchhosts，配置github520一起使用。

## 功能

- 🔍 每 5 分钟通过 HTTPS HEAD 请求检测 `github.com` 是否可达
- 🔔 当 GitHub 从不可访问恢复为可访问时，弹出系统通知
- 📋 日志记录所有检测结果，方便分析可用时间段
- 🖥️ 系统托盘运行，右键菜单支持"立即检测"和"退出"
- 🚀 支持开机自启（配合 `.vbs` 放入启动文件夹）
- 🐱 自定义托盘图标（黑色 GitHub Octocat）
- 🔒 单实例保护，不会重复启动

## 文件说明

| 文件 | 用途 |
|------|------|
| `github-monitor.ps1` | 主脚本，核心逻辑 |
| `start-monitor.bat` | 手动启动（有控制台窗口） |
| `start-monitor.vbs` | 静默启动（无窗口，适合开机自启） |
| `monitor.log` | 运行日志（自动清空前次记录） |
| `GitHub_Invertocat_Black.png` | 托盘图标 |

## 使用方式

### 手动运行

双击 `start-monitor.bat`，会在托盘出现图标并开始监控。

### 开机自启

1. `Win + R` → 输入 `shell:startup` → 回车
2. 将 `start-monitor.vbs` 拖入启动文件夹

### 查看日志

打开项目目录下的 `monitor.log` 即可查看历史检测记录。

## 依赖

- Windows 10 / 11
- PowerShell 7+（`pwsh.exe`）

> PowerShell 5.1（系统自带）可能因执行策略限制无法运行，推荐安装 [PowerShell 7](https://github.com/PowerShell/PowerShell)。

## 工作原理

```
┌─────────┐    每5分钟     ┌──────────┐
│  定时器  │ ───────────→ │ HEAD 请求 │
└─────────┘               │ github.com│
                          └─────┬─────┘
                                │
                     ┌──────────┴──────────┐
                     ▼                     ▼
                  可达 ✅               不可达 ❌
                     │                     │
           ┌────────┴────────┐    更新状态，继续等待
           ▼                 ▼
      首次启动？        之前不可达？
           │                 │
           ▼                 ▼
      简短通知           弹出"恢复"通知
```

## 配置

在 `github-monitor.ps1` 顶部可修改：

```powershell
$url = "https://github.com"   # 检测目标
$checkInterval = 300           # 检测间隔（秒）
$cooldownAfterNotify = 600    # 通知冷却时间（秒）
```
