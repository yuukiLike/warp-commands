# Warp Commands

[English](README.md) · [简体中文](README.zh-CN.md) · 日本語

普段使っている Warp の YAML ワークフロー。必要なものをどうぞ。

![Warp Commands](assets/warp-cover.png)

## 使い方

```sh
git clone https://github.com/yuukiLike/warp-commands.git
```

1. Warp Drive → 個人用ワークスペースの **+ → Import** で、必要な YAML やコマンド用フォルダを選択。リポジトリ全体は選ばないでください。
2. 検索して引数を入力し、実行。実行環境は各ワークフローの説明を確認してください。

インポートされるのはコピーです。元の更新時にはコピーも更新してください。`cnotes`、`projects`、`projects-pull` のインストールと更新は [setup](setup/) を参照。

[インポート画面](assets/warp-import.png) · [ローカル YAML の使い方](https://docs.warp.dev/terminal/entry/yaml-workflows)

## フォルダ

| フォルダ | 内容 |
| --- | --- |
| [mac](mac/) | macOS ツール、Obsidian、プロジェクト一覧と main の一括更新 |
| [wsl](wsl/) | Windows / Ubuntu ツール · [ガイド（中国語）](notes/wsl-guide.md) |
| [setup](setup/) | `cnotes`、`projects`、`projects-pull` のインストール |
| [git](git/) | Git と SSH |
| [claude](claude/) | Claude Code のインストールと設定 |
| [ai](ai/) | Codex、Gemini、DeepSeek |
| [browser](browser/) | Chrome と Puppeteer |
| [dev](dev/) | npm、Whistle、Rust、Vue |
| [system](system/) | グローバル IP と Windows ツール |
| [notes](notes/) | 参考ノート |
