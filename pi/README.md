# Pi 工作流

在 Warp 中导入需要的 YAML。新版命令名需要重新导入一次。脚本使用 Node.js，支持 Bash 和 Zsh，默认从 `~/codex/warp-commands` 加载。其他路径可用 `WARP_COMMANDS_DIR` 指定。

运行 `pi model edit` 编辑仓库预设。`pi start` 每次启动都读取该文件。 [settings.template.json](settings.template.json)

- `defaultModel` 填精确的 `provider/model` ID。`enabledModels` 填其余常用模型的 ID，默认模型会自动加入列表。
- `defaultThinkingLevel` 默认是 `max`，Pi 会按模型支持的级别调整。
- `modelThinkingLevels` 按模型设置思考级别，优先于全局默认。GPT‑6.2 Astra 的预设是 `max`。
- `serviceTiers` 按模型配置 OpenAI Responses API 的 `service_tier`。默认对 `openai/gpt-6.2-sol` 发送 `ultrafast`。需要标准层级时填 `default`，也可删除模型条目来取消该模型的模板层级。Ultrafast 的可用性和用量限制取决于 OpenAI 项目。 [OpenAI Ultrafast 文档](https://developers.openai.com/api/docs/guides/ultrafast-mode)

在 Pi 输入框用 `/login openai` 或 `/login deepseek` 配置凭据，也可分别设置 `OPENAI_API_KEY`、`DEEPSEEK_API_KEY`。OpenAI API 项目可以通过 `pi auth login openai --api-key` 选择 API Key 登录。

## 命令

| Warp 命令 | 作用 |
| --- | --- |
| [pi start](pi-start.yaml) | 按预设启动，可临时指定模型或思考级别。 |
| [pi model edit](pi-model-edit.yaml) | 用 `vi` 编辑模型预设。 |
| [pi settings edit](pi-settings-edit.yaml) | 用 `vi` 打开用户设置，不应用模型预设。 |
| [pi merge](pi-merge.yaml) | 合并预设，保留其他用户设置。 |
| [pi overwrite](pi-overwrite.yaml) | 覆盖用户设置，旧设置无备份。 |
| [pi models](pi-models.yaml) | 按关键词搜索模型。 |
| [pi refresh](pi-refresh.yaml) | 刷新模型目录。 |

用户设置文件默认是 `~/.pi/agent/settings.json`，支持 `PI_CODING_AGENT_DIR`。用 `pi settings edit` 保存后，可回到 Pi 运行 `/reload`。

直接运行 `pi` 时也想使用预设，先退出 Pi，再运行 `pi merge` 或 `pi overwrite`。Pi 启动时会通过扩展读取预设里的服务层级。项目设置、命令行参数或恢复的会话可以覆盖用户默认值。

## 新模型发布后

用 `pi models` 查找模型 ID，目录缺少新模型时先运行 `pi refresh`。修改预设后运行 `pi start`，也可用 `pi merge` 同步到用户设置。

更多选项见 [Pi Settings](https://pi.dev/docs/latest/settings)。
