# Warp Commands

[English](README.md) · 简体中文 · [日本語](README.ja.md)

**我自己在用的 Warp 命令，也许你也用得上。**

![Warp Commands — 本地优先的 YAML 工作流：搜索、填写、运行](assets/warp-cover.png)

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## 也许你需要

- **macOS Caps Lock 延迟** — [mac caps delay](mac/mac-caps-delay.yaml)：在我的 Mac 上，一条 `hidutil` 命令就解决了这个问题。
- **进入 iCloud Obsidian 笔记库** — [obsidian](mac/obsidian.yaml)：直接运行 `cd` 命令，也可以在每台 Mac [安装 `cnotes`](setup/)，之后用短命令进入。
- **用 eza 查看项目概览** — [projects](mac/projects.yaml)：[安装一次](setup/)，之后用 `projects` 一起查看项目名称、Git 分支和状态。默认 `~/codex`，也可以指定自己的项目目录。

## 怎么用

1. **克隆**

   ```sh
   git clone https://github.com/yuukiLike/warp-commands.git
   ```

2. **导入** — 打开 Warp Drive → 个人空间 **+ → Import**。进入克隆下来的 `warp-commands/`，选择需要的 `.yaml` 文件，也可以选择 `mac/`、`git/` 等命令分类文件夹。**不要直接选择整个仓库文件夹。**
3. **使用** — 搜索 `mac clipboard` 等命令，选中工作流，填写参数，然后运行。

`assets/` 放的是 README 配图，Markdown 文件和 `notes/` 是说明文档与参考笔记，**这些都不用导入**。`setup/` 中的 YAML 是安装工作流，按需导入。

![Warp Drive：个人空间的 + 菜单 → Import](assets/warp-import.png)

导入后会创建由 Warp Drive 同步的副本，仓库中的 YAML 仍作为源文件维护。[导入指南 →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## 挑你需要的

| 文件夹 | 内容 |
| --- | --- |
| [mac](mac/) | 剪贴板、DNS、Caps Lock、Zsh 配置、Obsidian、项目概览 |
| [setup](setup/) | 在 Warp 中安装一次：由 `.zshrc` 加载的 `cnotes` 和 eza 项目概览 `projects` |
| [git](git/) | Git 操作、忽略规则、SSH |
| [claude](claude/) | Claude Code 安装、API 切换、环境重置 |
| [ai](ai/) | Codex、Gemini 与 DeepSeek 驱动的 Claude Code、Codex |
| [browser](browser/) | Chrome 缓存、证书调试、Puppeteer |
| [dev](dev/) | npm、Whistle、Rust、Vue |
| [system](system/) | 公网 IP 与 Windows 实用工具 |
| [notes](notes/) | Git、SSH 与 Shell 参考笔记 |

Windows 工作流使用 PowerShell 或 Git Bash，请以各工作流的说明为准。

## 安装一次，后续直接使用

导入 `setup/` 中的 YAML。在每台 Mac 的 Warp 中搜索 **`setup obsidian`** 或 **`setup projects`**，选择并执行即可，不需要填写仓库路径。

工作流会将命令定义保存到 `~/.config/warp-commands/`，向 `.zshrc` 添加加载行，并让当前终端立即生效。`setup projects` 还会在缺少 `eza` 时通过 Homebrew 安装。之后用 `cnotes` 或 `projects "$HOME/explore"`；`projects` YAML 也调用这个安装好的函数。

更新时，先更新 Warp 中的对应工作流，再在各台 Mac 重新执行安装。已有 `.zshrc` 设置会保留，加载行不会重复添加。详细说明见 [setup](setup/)。

## 本地使用

也可以直接加载本地 YAML，将需要的工作流复制到：

| 系统 | 目录 |
| --- | --- |
| macOS | `$HOME/.warp/workflows/` |
| Windows（PowerShell） | `$env:APPDATA\warp\Warp\data\workflows\` |

在 Warp 的 Workflow Search 中搜索即可使用。源文件更新后，需同步更新本地副本。[YAML 工作流指南 →](https://docs.warp.dev/terminal/entry/yaml-workflows)
