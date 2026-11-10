# 在 Warp 中安装，之后直接使用

这里的 YAML 是**安装工作流**，用于安装常用 Shell 命令或应用配置。在每台 Mac 的 Warp 中运行对应工作流，之后按下表使用。

## 从 Warp 安装

1. 在 Warp Drive → 个人空间 **+ → Import** 中，按需选择下表对应的 YAML。`README.md` 是说明文档，不需要导入。
2. 在 Warp 的工作流搜索中搜索下面的安装名称，选择并执行。
3. 看到安装成功提示后，使用下表中的命令或快捷键。Shell 短命令在当前终端立即可用，新开的终端也会自动加载。

文件名以 `install-` 开头：Warp 搜索按命中位置排序，越靠前排名越高。这样输入 `obsidian`、`projects` 时，命令文件（如 `mac/obsidian.yaml`）排在安装文件之前，两者不会互相抢位；想找安装文件时搜索 `install` 或 `setup`。

| 在 Warp 中搜索 | 安装内容 | 安装后使用 |
| --- | --- | --- |
| [`setup obsidian`](install-obsidian.yaml) | Obsidian 笔记库入口 | `cnotes` |
| [`setup projects`](install-projects.yaml) | eza 与项目概览命令 | `projects` |
| [`setup projects pull`](install-projects-pull.yaml) | 批量更新各项目的本地 `main` | `projects-pull` |
| [`setup zed`](install-zed.yaml) | Zed 通用任务与快捷键，当前提供 HTML 浏览器任务 | 在 Zed 的 HTML 文件中按 `⌘⌃B` |

这些工作流可以独立安装，不需要填写仓库路径或切换到源码目录。`setup projects` 先检测 `eza`：已有时提示跳过；缺少时先显示将执行 `brew install eza`，再通过 Homebrew 安装。如果 `brew` 也没有，会提示先安装 Homebrew 并停止。依赖安装方式参考 [eza 官方说明](https://eza.rocks/#installation)。`setup projects pull` 只需要 Git 和 Zsh，不依赖 `eza` 或 `projects`。

`setup zed` 使用已安装的 Node.js 和 macOS 自带的 `plutil`，将内置配置写入 Zed，无需下载脚本。

安装器按工具集中维护通用配置。项目的 `dev`、`check`、`test`、`build` 等命令由各项目的 `package.json` 定义，项目专用的 Zed 入口放在该项目的 `.zed/` 中。

## 命令和配置保存在什么位置

| 文件 | 内容 |
| --- | --- |
| `~/.config/warp-commands/obsidian.zsh` | `cnotes` 的函数定义 |
| `~/.config/warp-commands/projects.zsh` | `projects` 的函数定义 |
| `~/.config/warp-commands/projects-pull.zsh` | `projects-pull` 的函数定义 |
| `~/.zshrc` | 每个 Shell 工具一行 `source`，让新终端加载函数 |
| `~/.config/zed/tasks.json` | Zed 全局任务 |
| `~/.config/zed/keymap.json` | Zed 用户快捷键 |

Shell 工具设置了 `ZDOTDIR` 时，加载行写入该目录下的 `.zshrc`。已有配置会保留；再次执行安装工作流会更新本工具的命令文件，不会重复添加相同的加载行。

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

## Zed 通用配置

导入并运行 [`setup zed`](install-zed.yaml)，安装 `Open HTML in Browser` 任务及 **Command + Control + B** 快捷键。任务先保存当前文件，再使用 macOS 的 `open` 打开 HTML，终端面板不弹出；快捷键只在 `.html`、`.htm` 编辑器中生效。

使用前，在 Zed 按 **Command + O** 打开 HTML 所在的**文件夹**，再进入 HTML 文件。部分 Zed 版本在仅打开单文件时无法提供 `$ZED_FILE`，任务不会出现。

安装过程会：

- 按 `label` 更新同名任务，保留其他任务与快捷键。
- 在配置不存在时创建文件；两份配置均校验通过后才写入，格式错误时停止。
- 将有修改的文件整理为标准 JSON，并将含注释的原文件备份到配置目录中的 `.warp-html-*` 文件夹。备份文件名为 `tasks.json.before` / `keymap.json.before`，运行结果会显示路径。
- 在配置已一致时跳过写入，不重复添加配置或备份。

`open` 遵循 HTML 文件的默认应用关联。若 HTML 默认由编辑器打开，可将 YAML 中 `task.args` 改成 `["-a", "Google Chrome", "$ZED_FILE"]` 后重新分发。页面自动刷新需另外使用 Live Server。

使用自定义 Zed 配置目录时，执行前设置 `WARP_ZED_CONFIG_DIR`；它只决定安装器的写入位置，不改变 Zed 的启动配置。

运行 `ruby tests/zed_setup_test.rb` 可在临时目录验证安装、JSONC 合并、重复执行及写入失败后的回退，不修改本机 Zed 配置。参考：[Zed Tasks](https://zed.dev/docs/tasks)、[Zed 快捷键](https://zed.dev/docs/key-bindings)。

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

将安装工作流导入 Warp Drive 的个人空间后，其他 Mac 登录同一账号、联网获取工作流，再在每台 Mac 上运行一次。安装位置不依赖仓库放在哪里。

仓库里的 YAML 是源文件，Warp 导入的是副本。修改 YAML 后，先更新 Warp 中的对应工作流，再在各台 Mac 上重新执行安装，新的命令定义或应用配置才会写入该机器。Warp Drive 同步工作流内容；Zed 本地配置的修改不会自动回写到工作流或仓库。参见 [Warp Drive 同步机制](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/)。

卸载某个 Shell 快捷命令时，从 `.zshrc` 删除该工具的 `# Warp Commands:` 注释及下一行 `source`，然后新开终端。`eza` 软件仍保留。

## 如何阅读与修改代码

每个安装工作流完整保存在一个 YAML 中。Shell 快捷命令安装器的 `command` 按编号从上到下执行：

1. **检查配置与依赖**：先处理无法写入配置、找不到 eza 等情况。
2. **保存日常命令**：`<<'ZSH'` 与下一行独立的 `ZSH` 之间，是将来运行的函数定义。这里的 `$HOME` 和参数会保留到调用函数时再展开。
3. **注册自动加载**：向 `.zshrc` 追加 `source`，相同的行只添加一次。
4. **当前终端生效**：安装成功后，在当前 Warp Shell 中加载刚保存的函数。

安装过程使用子 Shell 隔离临时变量。每个关键写入步骤用 `|| exit` 明确表示失败就停止；写命令时先生成临时文件，通过 Zsh 语法检查后再替换旧文件。

`projects` 的数据流是“eza 读取项目状态 → awk 输出表格”。状态符号与文字、颜色分别用映射表表示；项目名、分支、状态和颜色前后缀都有独立名称，便于逐步阅读和修改。

验证批量更新命令时，在仓库根目录运行 `ruby tests/projects_pull_test.rb`。测试仅使用 macOS 自带的 Ruby 标准库、Git 和 Zsh，在临时目录中安装命令并创建本地 Git 仓库，不访问网络或修改实际的 Shell 配置。
