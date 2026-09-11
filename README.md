# Warp Commands

English · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

**Commands I use in Warp. Maybe you'll find them useful too.**

![Warp Commands — Local-first YAML workflows. Search. Fill. Run.](assets/warp-cover.png)

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## You might need these

- **macOS Caps Lock delay** — [mac caps delay](mac/mac-caps-delay.yaml): one `hidutil` command fixed this on my Mac.
- **A project overview with eza** — [projects](mac/projects.yaml): I use this to see project names, Git branches, and status together. Install `eza` first; change `~/codex` to your own projects directory.

## Try them

1. **Download** — [Download the ZIP](https://github.com/yuukiLike/warp-commands/archive/refs/heads/main.zip) and extract it.
2. **Import** — Open Warp Drive → personal workspace **+ → Import**. Select the `.yaml` files you want, or a command folder such as `mac/` or `git/` inside the extracted repository. **Do not select the repository's top-level folder.**
3. **Use** — Search for a command such as `mac clipboard`, select it, fill in the arguments, and run.

`assets/` contains README images; `README*.md` and `notes/` are documentation. **Leave these out of the import.**

![Warp Drive: personal workspace + menu → Import](assets/warp-import.png)

Warp Drive imports a synced copy. Keep the repository YAML as your source. [Import guide →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## Pick what you need

| Folder | Contents |
| --- | --- |
| [mac](mac/) | Clipboard, DNS, Caps Lock, Zsh config, project overview |
| [git](git/) | Git operations, ignore rules, SSH |
| [claude](claude/) | Claude Code installation, API switching, environment reset |
| [ai](ai/) | Codex and Gemini |
| [browser](browser/) | Chrome cache, certificate debugging, Puppeteer |
| [dev](dev/) | npm, Whistle, Rust, Vue |
| [system](system/) | Public IP and Windows utilities |
| [notes](notes/) | Git, SSH, and shell references |

Windows workflows use PowerShell or Git Bash; check each workflow's description.

## Local use

To load YAML directly from local files, copy the workflows you need into:

| Platform | Directory |
| --- | --- |
| macOS | `$HOME/.warp/workflows/` |
| Windows (PowerShell) | `$env:APPDATA\warp\Warp\data\workflows\` |

Open Workflow Search in Warp to find them. Update your copies when the source changes. [YAML workflow guide →](https://docs.warp.dev/terminal/entry/yaml-workflows)
