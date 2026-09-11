# Warp Commands

[English](README.md) · [简体中文](README.zh-CN.md) · 日本語

**普段使っている Warp コマンド。あなたにも役立つものがあれば。**

![Warp Commands — ローカルファーストの YAML ワークフロー：検索、入力、実行](assets/warp-cover.png)

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## こんなときに

- **macOS の Caps Lock 遅延** — [mac caps delay](mac/mac-caps-delay.yaml)：私の Mac では、この `hidutil` コマンドで解消できました。
- **eza でプロジェクトを一覧表示** — [projects](mac/projects.yaml)：プロジェクト名、Git ブランチ、状態をまとめて見るために使っています。先に `eza` をインストールし、`~/codex` を自分のプロジェクト用ディレクトリに変更してください。

## 使ってみる

1. **クローン**

   ```sh
   git clone https://github.com/yuukiLike/warp-commands.git
   ```

2. **インポート** — Warp Drive → 個人用ワークスペースの **+ → Import** を開きます。クローンした `warp-commands/` の中から、必要な `.yaml` ファイルか `mac/`、`git/` などのコマンド用フォルダを選びます。**リポジトリ全体のフォルダは選ばないでください。**
3. **実行** — `mac clipboard` などを検索し、ワークフローを選んで引数を入力し、実行します。

`assets/` は README 用の画像、`README*.md` と `notes/` は説明や参考ノートです。**これらのインポートは不要です。**

![Warp Drive：個人用ワークスペースの + メニュー → Import](assets/warp-import.png)

インポートすると、Warp Drive で同期されるコピーが作成されます。元の YAML はリポジトリで管理してください。[インポートガイド →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## 必要なものを選ぶ

| フォルダ | 内容 |
| --- | --- |
| [mac](mac/) | クリップボード、DNS、Caps Lock、Zsh 設定、プロジェクト一覧 |
| [git](git/) | Git 操作、除外ルール、SSH |
| [claude](claude/) | Claude Code のインストール、API 切り替え、環境のリセット |
| [ai](ai/) | Codex と Gemini |
| [browser](browser/) | Chrome キャッシュ、証明書のデバッグ、Puppeteer |
| [dev](dev/) | npm、Whistle、Rust、Vue |
| [system](system/) | グローバル IP と Windows ユーティリティ |
| [notes](notes/) | Git、SSH、シェルの参考ノート |

Windows のワークフローは PowerShell または Git Bash を使います。各ワークフローの説明を確認してください。

## ローカルファイルから使う

ローカルの YAML を直接読み込む場合は、必要なワークフローを次の場所にコピーします。

| OS | ディレクトリ |
| --- | --- |
| macOS | `$HOME/.warp/workflows/` |
| Windows（PowerShell） | `$env:APPDATA\warp\Warp\data\workflows\` |

Warp の Workflow Search から利用できます。元のファイルを更新したら、コピーも更新してください。[YAML ワークフローガイド →](https://docs.warp.dev/terminal/entry/yaml-workflows)
