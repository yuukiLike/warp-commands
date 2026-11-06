# Pi 配置

默认启动 **OpenAI `gpt-6.1-sol` + `max`**，常用模型只配置 OpenAI 和 DeepSeek。

## 1. 连接 provider

在 **Pi 输入框**中登录需要的供应商，或通过环境变量提供 API Key：

| Provider ID | Pi 登录命令 | API Key 环境变量 |
| --- | --- | --- |
| `openai` | `/login openai` | `OPENAI_API_KEY` |
| `deepseek`（DS） | `/login deepseek` | `DEEPSEEK_API_KEY` |

这两家是内置 provider，使用官方接口不需要配置 `models.json`。凭据在每台电脑单独配置，不写进工作流。

## 2. 默认配置

[settings.json](settings.json) 的内容如下，对应用户文件 `~/.pi/agent/settings.json`：

```json
{
  "defaultProvider": "openai",
  "defaultModel": "gpt-6.1-sol",
  "defaultThinkingLevel": "max",
  "enabledModels": [
    "openai/gpt-6.1-sol",
    "openai/gpt-6-astra",
    "openai/gpt-6.1-terra",
    "openai/gpt-6-luna",
    "deepseek/deepseek-v4-pro",
    "deepseek/deepseek-flash"
  ]
}
```

`max` 优先推理深度，可能增加延迟与费用。临时换模型用 `/model`，调整思考级别用 `/thinking`；按 `Enter` 仅当前会话使用，按 `Ctrl+S` 保存默认值。

模型 ID 按 Pi `1.5.0` 内置目录核对，DeepSeek Flash 使用 `deepseek-flash`。实际可用项以认证后的 `/model` 为准。

## 3. Warp 一键写入

导入需要的 YAML，在 Warp 搜索命令名直接执行，**不需要填写参数，也不生成备份**：

| Warp 命令 | 作用 |
| --- | --- |
| [pi settings overwrite](pi-settings-overwrite.yaml) | **整份覆盖**成上面的配置，旧设置全部替换 |
| [pi settings merge](pi-settings-merge.yaml) | **增量更新**默认模型和 `max`，追加常用模型并去重；保留原有模型、主题、包、扩展等设置 |

增量命令也会将这些常用模型已有的单独思考级别改为 `max`，避免旧值覆盖全局默认；JSON 解析失败或相关字段格式有误时停止，不覆盖原文件。配置文件不存在时，两条命令都可直接创建。

**先退出 Pi，执行其中一条命令，再直接运行 `pi`。** 不用 `pi -c` 或 `pi -r` 验证默认值，它们会恢复历史会话设置。

两条命令适用于 Bash / Zsh，需要 Node.js。配置内容已内置，换电脑导入同一工作流即可，不依赖仓库路径或联网下载。设置了 `PI_CODING_AGENT_DIR` 时写入该目录，否则写入 `~/.pi/agent`；均不修改登录凭据或项目配置。

若新会话仍未使用上述默认值，检查项目 `.pi/settings.json` 或启动参数是否覆盖。仓库更新后，Warp 中的副本需要重新导入。

手动编辑配置仍可用 [pi settings](pi-settings.yaml)。更多选项见 [Pi Settings](https://pi.dev/docs/latest/settings)。
