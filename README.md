# Warp Commands

English · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

**Local-first YAML workflows for Warp.**

![Warp Commands — Local-first YAML workflows. Search. Fill. Run.](assets/warp-cover.png)

Searchable shortcuts for Git, macOS, Windows, Claude Code, and everyday development. Short English command names; Chinese descriptions and comments.

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## You might need these

- **Fix macOS Caps Lock delay** — [mac caps delay](mac/mac-caps-delay.yaml): a one-line `hidutil` fix, verified on the author's Mac.
- **See your projects at a glance with eza** — [projects](mac/projects.yaml): project names, Git branches, and status in one table. Requires `eza`; defaults to `~/codex`, which you can change.

## Quick start

1. **Import** — In Warp Drive, click your personal workspace's **+ → Import**. Select YAML files or a category folder such as `mac/`.
2. **Search** — Find a command in Warp, such as `mac clipboard` or `npm registry`.
3. **Run** — Select the workflow, fill in its arguments, and run it.

![Warp Drive: personal workspace + menu → Import](assets/warp-import.png)

Warp Drive imports a synced copy. Keep the repository YAML as your source. [Import guide →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## Commands

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
