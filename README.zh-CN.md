# Warp Commands

[English](README.md) · 简体中文 · [日本語](README.ja.md)

**面向 Warp 的本地优先 YAML 命令集合。**

![Warp Commands — 本地优先的 YAML 工作流：搜索、填写、运行](assets/warp-cover.png)

收录 Git、macOS、Windows、Claude Code 和日常开发快捷命令。使用简短的英文命令名，搭配中文说明与注释。

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## 也许你需要

- **修复 macOS Caps Lock 延迟** — [mac caps delay](mac/mac-caps-delay.yaml)：一条 `hidutil` 命令，已在作者的 Mac 上验证有效。
- **用 eza 一眼查看项目概览** — [projects](mac/projects.yaml)：在一张表中查看项目名称、Git 分支和状态。需先安装 `eza`，默认查看 `~/codex`，可改成自己的项目目录。

## 快速开始

1. **导入** — 打开 Warp Drive，点击个人空间的 **+ → Import**，选择 YAML 文件或 `mac/` 等分类文件夹。
2. **搜索** — 在 Warp 中查找命令，例如 `mac clipboard` 或 `npm registry`。
3. **运行** — 选中工作流，填写参数，然后运行。

![Warp Drive：个人空间的 + 菜单 → Import](assets/warp-import.png)

导入后会创建由 Warp Drive 同步的副本，仓库中的 YAML 仍作为源文件维护。[导入指南 →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## 命令分类

| 文件夹 | 内容 |
| --- | --- |
| [mac](mac/) | 剪贴板、DNS、Caps Lock、Zsh 配置、项目概览 |
| [git](git/) | Git 操作、忽略规则、SSH |
| [claude](claude/) | Claude Code 安装、API 切换、环境重置 |
| [ai](ai/) | Codex 与 Gemini |
| [browser](browser/) | Chrome 缓存、证书调试、Puppeteer |
| [dev](dev/) | npm、Whistle、Rust、Vue |
| [system](system/) | 公网 IP 与 Windows 实用工具 |
| [notes](notes/) | Git、SSH 与 Shell 参考笔记 |

Windows 工作流使用 PowerShell 或 Git Bash，请以各工作流的说明为准。

## 本地使用

也可以直接加载本地 YAML，将需要的工作流复制到：

| 系统 | 目录 |
| --- | --- |
| macOS | `$HOME/.warp/workflows/` |
| Windows（PowerShell） | `$env:APPDATA\warp\Warp\data\workflows\` |

在 Warp 的 Workflow Search 中搜索即可使用。源文件更新后，需同步更新本地副本。[YAML 工作流指南 →](https://docs.warp.dev/terminal/entry/yaml-workflows)
