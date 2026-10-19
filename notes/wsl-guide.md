# WSL 实用指南

适用于已经安装 WSL2 与 Ubuntu、准备在 Windows Warp 中开发的场景。[返回仓库说明](../README.zh-CN.md)

## 先分清命令在哪里运行

| 终端环境 | 负责什么 | 常见命令 |
| --- | --- | --- |
| **Windows PowerShell** | 进入、查看、更新和管理 WSL | `wsl`、`Get-ChildItem` |
| **Ubuntu 的 Bash** | 开发项目、安装 Linux 软件、使用 Git | `pwd`、`cd`、`sudo apt`、`git` |

WSL2 在 Windows 管理的轻量虚拟机中运行 Linux 内核。每次进入同一发行版，都会继续使用已有的软件和文件；新终端不会创建一套空白 Ubuntu。[微软：WSL 架构](https://learn.microsoft.com/en-us/windows/wsl/about)

下文的 `Ubuntu` 是发行版名称示例。如果你的名称是 `Ubuntu-24.04`，使用命令时应替换成这个完整名称。

## 日常进入、退出和查看版本

**在 Windows PowerShell 中：**

| 要做什么 | 命令 |
| --- | --- |
| 进入默认发行版的主目录 | `wsl ~` |
| 进入指定 Ubuntu 的主目录 | `wsl -d Ubuntu --cd ~` |
| 查看已安装发行版、运行状态和 WSL1／2 | `wsl -l -v` |
| 查看 WSL 软件及组件版本 | `wsl --version` |
| 查看默认发行版、内核等配置 | `wsl --status` |
| 查看当前版本支持的管理命令 | `wsl --help` |

**在 Ubuntu 的 Bash 中：**

| 要做什么 | 命令 |
| --- | --- |
| 查看 Ubuntu 发行版版本 | `cat /etc/os-release` |
| 查看当前目录 | `pwd` |
| 查看目录内容 | `ls` |
| 回到用户主目录 | `cd ~` |
| 回到上一级 | `cd ..` |
| 退出当前 Bash | `exit` |

`wsl -l -v` 的 `VERSION` 为 `2`，表示使用 WSL2；Ubuntu 的 `24.04` 等版本号要在 `/etc/os-release` 中查看。

`exit` 只退出当前 Shell。需要停止全部 WSL 发行版及后台程序时，先保存工作，再在 **PowerShell** 执行 `wsl --shutdown`；平时无需每次退出都关闭整套 WSL。[微软：WSL 基本命令](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)

## 项目文件在哪里

| Ubuntu 中的路径 | 文件所在的位置 |
| --- | --- |
| `/home/你的用户名`、`~` | 当前 Linux 用户的主目录 |
| `~/code/项目` | Ubuntu 的 Linux 文件系统 |
| `/mnt/c/Users/...` | Windows 的 C 盘 |
| `/mnt/d/code/...` | Windows 的 D 盘 |

例如，`pwd` 输出 `/home/administrator` 只说明当前位置是这个 Linux 用户的主目录，无法据此判断底层占用 C 盘还是 D 盘。Ubuntu 的文件系统保存在 Windows 硬盘上的虚拟磁盘中，实际位置按下面的 `BasePath` 查询结果判断。

使用 Ubuntu 里的 Git、Node、Python 等工具时，建议把项目放在 `~/code`，减少跨 Windows／Linux 文件系统访问的开销。[微软：跨文件系统工作](https://learn.microsoft.com/en-us/windows/wsl/filesystems)

在 **Ubuntu 的 Bash** 中建立并进入项目总目录：

```bash
mkdir -p ~/code
cd ~/code
```

需要从 Windows 浏览当前目录，在 **Ubuntu 的 Bash** 中执行：

```bash
explorer.exe .
```

也可以在 Windows 资源管理器地址栏输入 `\\wsl$\Ubuntu\home`，再打开自己的用户目录。这里访问的是同一份 Linux 文件；实际发行版名称需与 `wsl -l -v` 一致。

## 安装和更新 Ubuntu 软件

以下命令都在 **Ubuntu 的 Bash** 中按需执行：

| 操作 | 命令 | 含义 |
| --- | --- | --- |
| 更新软件包索引 | `sudo apt update` | 刷新软件源中可用的软件版本信息 |
| 安装 Git 和 curl | `sudo apt install git curl` | 安装这些 Linux 软件及所需依赖 |
| 更新已安装的软件包 | `sudo apt upgrade` | 查看待升级内容，确认后升级 |
| 确认 Git 已安装 | `git --version` | 显示当前 Git 版本 |

先完成 `sudo apt update`，再执行安装或升级。`apt` 管理 Ubuntu 软件包；Windows 上的软件、WSL 本身，以及通过其他安装器安装的软件，需要各自的更新方式。[Ubuntu：软件包管理](https://documentation.ubuntu.com/server/how-to/software/package-management/)

Codex 安装沿用已有的 [codex install](../ai/codex-install.yaml)，在 Ubuntu 的 Bash 中使用；Git 操作参考 [git 命令目录](../git/)，并按各工作流标注的 Shell 选择。

## 在 Windows Warp 中使用

Windows Warp 支持 WSL2。在它的 PowerShell 标签页运行 `wsl -d Ubuntu --cd ~`，进入的就是已经安装的那套 Ubuntu。

想让新会话直接进入 Ubuntu，可在 **Settings → Features → Session → Startup shell for new sessions** 中选择对应的 WSL 发行版，然后新开标签页；设置只影响新会话。[Warp：支持的 Shell](https://docs.warp.dev/getting-started/supported-shells)

在 Windows 版 Warp 中打开 Ubuntu 会话时，本地 YAML 仍放在 Windows 的 `$env:APPDATA\warp\Warp\data\workflows\`。也可以按仓库 README 把 `wsl/` 导入 Warp Drive；导入的是副本，更新 GitHub 仓库后需要同步更新这些工作流。[Warp：本地 YAML 工作流](https://docs.warp.dev/terminal/entry/yaml-workflows)

## 安全边界

WSL 与 Windows 默认可以互通：Ubuntu 可访问挂载的 Windows 目录并调用 `.exe`，访问权限受启动它的 Windows 账户约束，同一账户也能访问自己的 Ubuntu 文件。
WSL 发行版不构成与宿主 Windows 之间的安全边界；如果宿主账户被控制，不能认为 Ubuntu 内的代码和凭据仍受隔离保护。
保持 Windows 与 Ubuntu 更新，并在执行项目脚本前确认来源与用途。[微软：WSL 安全模型](https://github.com/microsoft/WSL/blob/master/doc/docs/technical-documentation/security.md)

## 迁移 Ubuntu 到 D 盘

这会改变发行版虚拟磁盘在 Windows 上的位置，之后仍可在 `~/code` 中开发。下面的步骤需在自己电脑上执行，完成后通过 `BasePath` 核对实际位置。

### 1. 查看准确名称和当前存储位置

**在 Windows PowerShell 中：**

```powershell
wsl -l -v
```

记录要迁移的完整名称，并确认其 `VERSION` 是 `2`。然后执行下面的只读查询：

```powershell
Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' |
    Get-ItemProperty |
    Format-List DistributionName, BasePath
```

找到对应的 `DistributionName`，检查其 `BasePath`。`C:\...` 表示在 C 盘，`D:\...` 表示在 D 盘；如果带有 `\\?\` 前缀，看后面的盘符。[微软：定位虚拟磁盘](https://learn.microsoft.com/en-us/windows/wsl/disk-space#how-to-locate-the-vhdx-file-and-disk-path-for-your-linux-distribution)

### 2. 准备迁移并更新 WSL

保存文件并结束开发任务，关闭连接 Ubuntu 的终端、编辑器和其他应用。已有重要文件时，先把它们备份到迁移目录以外；确认 D 盘有足够空间容纳当前虚拟磁盘。

以下示例选用新的专用目录 `D:\WSL\Ubuntu`。如果那里已有其他内容，换一个新的目标目录。**以下各条管理命令均在 PowerShell 中逐条执行，成功后再继续。**

```powershell
wsl --update --web-download
```

等待更新成功；如提示重启，先重启电脑，再继续。用 `wsl --help` 确认当前版本提供 `--manage` 下的 `--move`；若仍不支持，保留版本和报错信息，暂不继续迁移。

### 3. 创建父目录、关闭 WSL、迁移

创建用于存放发行版的父目录：

```powershell
New-Item -ItemType Directory -Path 'D:\WSL' -Force
```

再次确认工作已保存。下面会停止**所有 WSL 发行版及其后台任务**，包括依赖 WSL 的其他应用：

```powershell
wsl --shutdown
```

把下面的 `Ubuntu` 替换成第 1 步查到的准确名称，再执行迁移并等待完成：

```powershell
wsl --manage Ubuntu --move 'D:\WSL\Ubuntu'
```

这是 WSL 提供的迁移选项；具体支持情况以本机 `wsl --help` 为准。[微软：WSL 命令行帮助源文件](https://github.com/microsoft/WSL/blob/master/localization/strings/en-US/Resources.resw)

### 4. 验证新位置与项目

在 **PowerShell** 重新执行第 1 步的 `BasePath` 查询，确认目标发行版已指向 `D:\WSL\Ubuntu`，然后进入它：

```powershell
wsl -d Ubuntu --cd ~
```

在 **Ubuntu 的 Bash** 中检查：

```bash
pwd
ls
```

`pwd` 仍然显示 `/home/你的用户名` 是正常的。检查已有文件和开发工具，之后继续使用 `~/code`；这些文件会存放在 D 盘承载的 Linux 虚拟磁盘中。

迁移的是该发行版的虚拟磁盘，WSL 平台组件和交换文件等仍可能占用 C 盘。[微软：WSL 交换文件配置](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconfig)

任何一步报错，都先保留完整输出并停在该步骤，确认原因后再继续。

## 对应的 Warp 工作流

按 [仓库导入步骤](../README.zh-CN.md#怎么用) 选择需要的 YAML。`notes/` 是说明文档，不用导入。

| Warp 中搜索 | 在哪里运行 | 用途 |
| --- | --- | --- |
| [wsl enter](../wsl/wsl-enter.yaml) | Windows PowerShell | 进入默认发行版的主目录 |
| [wsl info](../wsl/wsl-info.yaml) | Windows PowerShell | 查看 WSL 版本、状态和发行版 |
| [wsl storage](../wsl/wsl-storage.yaml) | Windows PowerShell | 查询发行版在 Windows 中的存储位置 |
| [wsl update](../wsl/wsl-update.yaml) | Windows PowerShell | 更新 WSL 平台 |
| [wsl shutdown](../wsl/wsl-shutdown.yaml) | Windows PowerShell | 停止全部 WSL，需要先保存工作 |
| [wsl projects](../wsl/wsl-projects.yaml) | Ubuntu Bash | 进入 Linux 项目总目录 |
| [wsl path](../wsl/wsl-path.yaml) | Ubuntu Bash | 查看当前路径、文件系统类型和可用空间 |
| [wsl explorer](../wsl/wsl-explorer.yaml) | Ubuntu Bash | 用 Windows 资源管理器打开当前目录 |
| [wsl apt install](../wsl/wsl-apt-install.yaml) | Ubuntu Bash | 运行后输入一个包名，例如 `git` 或 `curl` |
| [wsl apt upgrade](../wsl/wsl-apt-upgrade.yaml) | Ubuntu Bash | 更新索引并升级 Ubuntu 软件包 |

迁移按上面的步骤逐条执行，以便在更新、关闭和移动前分别检查状态。
