# 在 Warp 中安装，之后直接使用

这里的 YAML 是**安装工作流**。在每台 Mac 的 Warp 中运行一次，之后直接输入短命令。

## 从 Warp 安装

1. 在 Warp Drive → 个人空间 **+ → Import** 中，按需选择本目录的 `install-obsidian.yaml`、`install-projects.yaml` 或 `install-projects-pull.yaml`。`README.md` 是说明文档，不需要导入。
2. 在 Warp 的工作流搜索中搜索下面的安装名称，选择并执行。
3. 看到安装成功提示后，当前终端立即可用，新开的终端也会自动加载。

文件名以 `install-` 开头：Warp 搜索按命中位置排序，越靠前排名越高。这样输入 `obsidian`、`projects` 时，命令文件（如 `mac/obsidian.yaml`）排在安装文件之前，两者不会互相抢位；想找安装文件时搜索 `install` 或 `setup`。

| 在 Warp 中搜索 | 安装内容 | 安装后使用 |
| --- | --- | --- |
| [`setup obsidian`](install-obsidian.yaml) | Obsidian 笔记库入口 | `cnotes` |
| [`setup projects`](install-projects.yaml) | eza 与项目概览命令 | `projects` |
| [`setup projects pull`](install-projects-pull.yaml) | 批量更新各项目的本地 `main` | `projects-pull` |

这些工作流可以独立安装，不需要填写仓库路径或切换到源码目录。`setup projects` 先检测 `eza`：已有时提示跳过；缺少时先显示将执行 `brew install eza`，再通过 Homebrew 安装。如果 `brew` 也没有，会提示先安装 Homebrew 并停止。依赖安装方式参考 [eza 官方说明](https://eza.rocks/#installation)。`setup projects pull` 只需要 Git 和 Zsh，不依赖 `eza` 或 `projects`。

## 命令保存在什么位置

| 文件 | 内容 |
| --- | --- |
| `~/.config/warp-commands/obsidian.zsh` | `cnotes` 的函数定义 |
| `~/.config/warp-commands/projects.zsh` | `projects` 的函数定义 |
| `~/.config/warp-commands/projects-pull.zsh` | `projects-pull` 的函数定义 |
| `~/.zshrc` | 每个工具一行 `source`，让新终端加载函数 |

设置了 `ZDOTDIR` 时，加载行写入该目录下的 `.zshrc`。已有配置会保留；再次执行安装工作流会更新本工具的命令文件，不会重复添加相同的加载行。

## 日常使用

| 命令 | 用途 |
| --- | --- |
| `cnotes` | 进入 iCloud Obsidian 中的 `notes` 笔记库 |
| `cnotes "工作笔记"` | 进入指定名称的 iCloud Obsidian 笔记库 |
| `projects` | 查看 `~/codex` 下各项目的名称、Git 分支和状态 |
| `projects "$HOME/explore"` | 查看指定父目录下的项目 |
| `projects-pull` | 从 `origin/main` 更新 `~/codex` 各项目的本地 `main`，保留当前分支 |
| `projects-pull "$HOME/explore"` | 更新指定父目录下各项目的本地 `main` |

`cnotes` 使用每台 Mac 自己的 `$HOME`。先在该 Mac 开启 iCloud Drive，并确认 `iCloud 云盘 → Obsidian` 下已经同步好对应笔记库。

`projects` 排除 `node_modules`，支持目录名中的空格，并遵循 `NO_COLOR` 设置。安装后，也可以通过 [projects 工作流](../mac/projects.yaml) 填写目录并调用。

## 批量更新 main

在 Warp 中运行 [`setup projects pull`](install-projects-pull.yaml) 后，输入 `projects-pull`；也可以导入 [projects pull 工作流](../mac/projects-pull.yaml) 后填写项目父目录。

命令只扫描父目录的直接子目录，排除 `node_modules`、隐藏目录和目录符号链接，不递归进入嵌套项目。每个项目固定从 `origin` 抓取 `main`，只更新远端跟踪引用 `origin/main` 和本地 `main`。

| 项目情况 | 处理方式 |
| --- | --- |
| 当前在其他分支或 detached HEAD | 只快进本地 `main` 引用，保留当前 HEAD、暂存区和未提交改动 |
| 当前在 `main`，工作区干净 | 快进 `main` 并更新工作区；即使配置了 rebase 或自动 stash，也不执行它们 |
| 当前在 `main`，有暂存、未暂存或未跟踪文件 | 跳过并显示原因 |
| 本地没有 `main` | 从远端版本创建本地 `main`，保留当前分支；不修改 upstream 配置 |
| 本地 `main` 有远端未包含的提交，包括领先或分叉 | 保留本地提交，跳过并显示原因 |
| `main` 被其他 worktree 使用 | 跳过，避免另一个工作区与分支引用不一致 |
| 任一 worktree 正在 merge、rebase、cherry-pick、revert 或 bisect | 跳过，保留进行中的操作 |
| 没有 `origin` | 跳过并显示原因 |
| 普通目录 | 标记为非 Git 目录并忽略 |
| 远端没有 `main`、认证失败或网络错误 | 显示失败与 Git 错误，继续处理其他项目 |

命令逐个执行，结束时汇总更新、已是最新、跳过、失败和非 Git 目录的数量。全部 Git 项目处理成功时退出码为 `0`；有跳过或失败时为 `1`，表示存在需要单独处理的项目。普通目录被忽略不影响成功状态。

实现按“读取当前分支 → 抓取 `origin/main` → 检查工作区和祖先关系 → 快进更新”的顺序执行。检查会使用抓取后的工作区状态；如果期间切换了分支，会跳过。其他分支上的项目用带旧值检查的 `git update-ref` 更新 `main`，如果抓取期间 `main` 被另一个进程修改，会拒绝覆盖。已经在 `main` 上的项目使用 `git merge --ff-only`。抓取明确关闭 prune、标签和子模块递归，避免已有 Git 配置扩大操作范围。跳过项目时，已抓取的 `origin/main` 仍可能更新，本地 `main` 和工作区保持原状。

## 两种 Obsidian 入口

- **安装后用短命令**：在 Warp 中运行 [`setup obsidian`](install-obsidian.yaml)，之后输入 `cnotes`。命令定义由 `.zshrc` 加载。
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

验证批量更新命令时，在仓库根目录运行 `ruby tests/projects_pull_test.rb`。测试仅使用 macOS 自带的 Ruby 标准库、Git 和 Zsh，在临时目录中安装命令并创建本地 Git 仓库，不访问网络或修改实际的 Shell 配置。
