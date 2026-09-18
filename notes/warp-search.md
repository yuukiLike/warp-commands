# Warp 搜索

| 来源 | 检索什么 | 结果长什么样 |
| --- | --- | --- |
| Warp Drive / 本地 YAML 工作流 | YAML 里的 **`name:`**（command 内容也会匹配） | 工作流名 + Drive 路径 |

因此：

- `setup/` 的文件名用 `install-<主题>.yaml`，工作流名保持 `setup <主题>`。
- `claude-deepseek.yaml`（工作流 `ds-claude`）、`codex-deepseek.yaml`（工作流 `ds-codex`）—— 文件名与 `name:` 不一致是有意的，别改回去。
- 改 `name:` 后要在 Warp 里重新导入对应工作流才生效。

找命令用 Workflow Search（`Ctrl+Shift+R`），或 ⌘P 里的 `w:` / `drive:` 前缀。
