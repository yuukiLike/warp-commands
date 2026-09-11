# Warp Commands

[English](README.md) · [简体中文](README.zh-CN.md) · 日本語

**Warp 向けのローカルファーストな YAML コマンド集。**

![Warp Commands — ローカルファーストの YAML ワークフロー：検索、入力、実行](assets/warp-cover.png)

Git、macOS、Windows、Claude Code、日々の開発に使うコマンドをまとめています。コマンド名は短い英語、説明とコメントは中国語です。

[local-first](https://github.com/topics/local-first) · [warp](https://github.com/topics/warp) · [yaml](https://github.com/topics/yaml)

## こんなときに

- **macOS の Caps Lock 遅延を解消** — [mac caps delay](mac/mac-caps-delay.yaml)：`hidutil` の1行で設定。作者の Mac で動作確認済みです。
- **eza でプロジェクトをひと目で確認** — [projects](mac/projects.yaml)：プロジェクト名、Git ブランチ、状態を一覧表示。`eza` が必要です。対象ディレクトリはデフォルトで `~/codex` ですが、変更できます。

## 使い方

1. **インポート** — Warp Drive で個人用ワークスペースの **+ → Import** を開き、YAML ファイルか `mac/` などのカテゴリフォルダを選びます。
2. **検索** — Warp で `mac clipboard` や `npm registry` などのコマンドを検索します。
3. **実行** — ワークフローを選び、引数を入力して実行します。

![Warp Drive：個人用ワークスペースの + メニュー → Import](assets/warp-import.png)

インポートすると、Warp Drive で同期されるコピーが作成されます。元の YAML はリポジトリで管理してください。[インポートガイド →](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/#importing-files-into-warp-drive)

## コマンド一覧

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
