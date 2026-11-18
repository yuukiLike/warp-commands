# Pi 工作流

在 Warp 中导入需要的 YAML 即可。预设和设置工作流需要 Node.js，适用于 Bash / Zsh，不依赖仓库路径或额外环境变量。

第一次按预设启动或应用预设时，会自动创建 **`~/.config/warp-commands/pi/settings.template.json`**。之后这些工作流直接读取这份本地模板，不会覆盖它。只改模板就能换预设，不用重导入 YAML。

`defaultModel` 填 `provider/model`，`enabledModels` 填其余常用模型的 ID；默认模型会自动加入列表，不必写两次。模板不使用通配符或 `:low` 等后缀。预设默认请求 `max`，Pi 会按模型实际支持的级别调整。

在 Pi 输入框用 `/login openai` 或 `/login deepseek` 配置凭据，也可分别设置 `OPENAI_API_KEY`、`DEEPSEEK_API_KEY`。凭据不写入模板。

## 命令

| Warp 命令 | 作用 |
| --- | --- |
| [pi model search](pi-model-search.yaml) | 按关键词搜索 Pi 当前能列出的模型，不受常用列表限制。 |
| [pi model catalog refresh](pi-model-catalog-refresh.yaml) | 刷新模型目录，不更新 Pi 本身，也不更改模型偏好。 |
| [pi model start](pi-model-start.yaml) | 直接按模板默认模型和 `max` 启动，可临时指定模型或思考级别，不修改设置。 |
| [pi settings edit](pi-settings-edit.yaml) | 用 `vi` 手动编辑当前用户的 Pi 设置；它和本地模板是两份文件。 |
| [pi settings merge](pi-settings-merge.yaml) | **应用模板默认模型和 `max`**，将模板模型排在常用列表最前面，保留其他模式的相对顺序，以及其他模型的单独思考级别、主题、包和扩展等设置。 |
| [pi settings overwrite](pi-settings-overwrite.yaml) | **用模板覆盖整个用户设置**，不保留旧设置。 |

应用模板时先退出 Pi，再执行 `merge` 或 `overwrite`，然后直接运行 `pi` 开始新会话。两条命令都不留备份，不修改凭据或项目设置；模板无效时均停止，现有设置无效时 `merge` 也会停止。默认写入 `~/.pi/agent/settings.json`，支持 `PI_CODING_AGENT_DIR`。项目设置、命令行参数或恢复的会话仍可能覆盖用户默认值。

## 新模型发布后

发布新模型或刷新目录都不会替换当前默认值。只想临时试用新模型，可在 Pi 的 `/model` 中按 `Tab` 切到全部模型并选用；按 `Ctrl+S` 可保存为当前用户的默认。想升级**预设**，改本地模板中的模型 ID，再执行 `pi settings merge`；否则重跑 `merge` 时，默认值仍会设回模板里的模型。

## 维护仓库中的工作流

[settings.template.json](settings.template.json) 是首次创建本地模板时使用的初始值；[warp.mjs](warp.mjs) 是共用的 Node 源码。改动任一文件后运行 `node pi/build-workflows.mjs` 重新生成 YAML 的 `command`。更新 Warp 中已导入的命令需要重新导入 YAML，不会覆盖已创建的本地模板。

更多选项见 [Pi Settings](https://pi.dev/docs/latest/settings)。
