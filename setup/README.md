# 在 Warp 中安装，之后直接使用

这里的 YAML 是**安装工作流**。在每台 Mac 的 Warp 中运行一次，之后直接输入短命令。

## 从 Warp 安装

1. 在 Warp Drive → 个人空间 **+ → Import** 中，选择本目录的 `obsidian.yaml` 和 `projects.yaml`。`README.md` 是说明文档，不需要导入。
2. 在 Warp 的工作流搜索中搜索下面的安装名称，选择并执行。
3. 看到安装成功提示后，当前终端立即可用，新开的终端也会自动加载。

| 在 Warp 中搜索 | 安装内容 | 安装后使用 |
| --- | --- | --- |
| [`setup obsidian`](obsidian.yaml) | Obsidian 笔记库入口 | `cnotes` |
| [`setup projects`](projects.yaml) | eza 与项目概览命令 | `projects` |

两个工作流可以独立安装，不需要填写仓库路径或切换到源码目录。`setup projects` 先检测 `eza`：已有时提示跳过；缺少时先显示将执行 `brew install eza`，再通过 Homebrew 安装。如果 `brew` 也没有，会提示先安装 Homebrew 并停止。依赖安装方式参考 [eza 官方说明](https://eza.rocks/#installation)。

## 命令保存在什么位置

| 文件 | 内容 |
| --- | --- |
| `~/.config/warp-commands/obsidian.zsh` | `cnotes` 的函数定义 |
| `~/.config/warp-commands/projects.zsh` | `projects` 的函数定义 |
| `~/.zshrc` | 每个工具一行 `source`，让新终端加载函数 |

设置了 `ZDOTDIR` 时，加载行写入该目录下的 `.zshrc`。已有配置会保留；再次执行安装工作流会更新本工具的命令文件，不会重复添加相同的加载行。

## 日常使用

| 命令 | 用途 |
| --- | --- |
| `cnotes` | 进入 iCloud Obsidian 中的 `notes` 笔记库 |
| `cnotes "工作笔记"` | 进入指定名称的 iCloud Obsidian 笔记库 |
| `projects` | 查看 `~/codex` 下各项目的名称、Git 分支和状态 |
| `projects "$HOME/explore"` | 查看指定父目录下的项目 |

`cnotes` 使用每台 Mac 自己的 `$HOME`。先在该 Mac 开启 iCloud Drive，并确认 `iCloud 云盘 → Obsidian` 下已经同步好对应笔记库。

`projects` 排除 `node_modules`，支持目录名中的空格，并遵循 `NO_COLOR` 设置。安装后，也可以通过 [projects 工作流](../mac/projects.yaml) 填写目录并调用。

## 两种 Obsidian 入口

- **安装后用短命令**：在 Warp 中运行 [`setup obsidian`](obsidian.yaml)，之后输入 `cnotes`。命令定义由 `.zshrc` 加载。
- **直接运行命令**：导入 [obsidian 工作流](../mac/obsidian.yaml)。YAML 中直接保存 `cd` 命令，填写笔记库名称即可运行，也可以复制其中的命令到终端。

## 多台 Mac 与更新

每台 Mac 获得同一份安装工作流后，在自己的 Warp 中运行一次。工作流使用当前用户的 `$HOME`，安装位置不依赖仓库放在哪里。

仓库里的 YAML 是源文件，Warp 导入的是副本。修改 YAML 后，先更新 Warp 中的对应工作流，再在各台 Mac 上重新执行安装，新的命令定义才会写入该机器。

卸载某个快捷命令时，从 `.zshrc` 删除该工具的 `# Warp Commands:` 注释及下一行 `source`，然后新开终端。`eza` 软件仍保留。

## 如何阅读与修改代码

每个安装工作流完整保存在一个 YAML 中，`command` 按编号从上到下执行：

1. **检查配置与依赖**：先处理无法写入配置、找不到 eza 等情况。
2. **保存日常命令**：`<<'ZSH'` 与下一行独立的 `ZSH` 之间，是将来运行的函数定义。这里的 `$HOME` 和参数会保留到调用函数时再展开。
3. **注册自动加载**：向 `.zshrc` 追加 `source`，相同的行只添加一次。
4. **当前终端生效**：安装成功后，在当前 Warp Shell 中加载刚保存的函数。

安装过程使用子 Shell 隔离临时变量。每个关键写入步骤用 `|| exit` 明确表示失败就停止；写命令时先生成临时文件，通过 Zsh 语法检查后再替换旧文件。

`projects` 的数据流是“eza 读取项目状态 → awk 输出表格”。状态符号与文字、颜色分别用映射表表示；项目名、分支、状态和颜色前后缀都有独立名称，便于逐步阅读和修改。
