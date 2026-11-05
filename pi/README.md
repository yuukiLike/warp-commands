# Pi 配置与速查

常用模型、思考级别和快捷键集中放在这里。默认使用 **Sol + max**，聊天、看图、图片生成、TTS 和语音转写按用途选择。Pi 操作按 `1.5.0` 核对，OpenAI 模型资料核对日期为 **2026-11-05**。

[默认配置模板](settings.json) · [模型怎么选](#按用途选择模型) · [快捷键速查](shortcuts.md)

## 配置文件在哪里

| 文件 | 配置内容 |
| --- | --- |
| `~/.pi/agent/settings.json` | 默认模型、常用模型范围、思考级别与使用偏好 |
| `项目目录/.pi/settings.json` | 当前项目的设置；项目受信任后加载，并可覆盖用户设置 |
| `~/.pi/agent/keybindings.json` | 自定义快捷键 |
| `~/.pi/agent/models.json` | 自定义 API 地址、模型及模型参数覆盖 |
| `~/.pi/agent/auth.json` | 保存的 API Key / OAuth 凭据，通常通过 `/login`、`/logout` 管理 |

精简模型列表与调整思考级别，编辑 **`settings.json`**。设置了 `PI_CODING_AGENT_DIR` 时，用户配置目录以这个环境变量为准；`pi settings` 工作流会使用它。位置与作用域见 [Pi Configuration](https://pi.dev/docs/latest/configuration)。

## 默认配置

仓库的 [settings.json](settings.json) 是可复用模板，Pi 不会自动加载 `pi/settings.json`。将以下字段合并到用户配置 `~/.pi/agent/settings.json`；只想对某个项目生效时，合并到该项目的 `.pi/settings.json`，信任项目后加载。保留其他设置，保存后重启 Pi 开始新会话。

已有 `defaultTools` 时，把 `+codemode` 追加到原数组；合并 `modelThinkingLevels` 时保留其他模型的条目。

思考级别统一为 `max`，与当前常用的 Codex 配置一致。默认启动模型沿用 `gpt-6.1-sol`。

```json
{
  "$schema": "https://pi.dev/schemas/settings.schema.json",
  "defaultProvider": "openai",
  "defaultModel": "gpt-6.1-sol",
  "defaultThinkingLevel": "max",
  "enabledModels": [
    "openai/gpt-6.1-sol",
    "openai/gpt-6-astra",
    "openai/gpt-6.1-terra",
    "openai/gpt-6-luna"
  ],
  "modelThinkingLevels": {
    "openai/gpt-6.1-sol": "max",
    "openai/gpt-6-astra": "max",
    "openai/gpt-6.1-terra": "max",
    "openai/gpt-6-luna": "max"
  },
  "defaultTools": ["+codemode"]
}
```

| 字段 | 含义 |
| --- | --- |
| `defaultProvider` + `defaultModel` | 新会话的默认供应商与模型 |
| `enabledModels` | `/model` 默认展示及 `Ctrl+P` 循环切换的常用范围，每项写成 `供应商/模型ID` |
| `defaultThinkingLevel` | 未单独指定模型思考级别时的默认值 |
| `modelThinkingLevels` | 按模型设置思考级别，优先于全局默认值 |
| `defaultTools` | `+codemode` 在现有工具上增加脚本调用能力，可调用 Pi 支持的图片模型 |

四个常用聊天模型都显式设为 `max`，合并配置时也会替换旧示例中 Luna 的 `low`。恢复历史会话仍会恢复该会话记录的模型与思考级别；需要改当前会话时用 `/thinking`。字段说明见 [Pi Settings](https://pi.dev/docs/latest/settings#model-and-thinking)。

`max` 优先考虑推理深度；简单任务需要更快响应时，临时切到 `low` 或 `medium`。图片、TTS 等专用模型有各自的调用入口，见下方选型表。

继续使用 DeepSeek 时，可以把 `deepseek/deepseek-v4-pro`、`deepseek/deepseek-flash` 加入 `enabledModels`；需要以 DeepSeek 启动，再将 `defaultProvider` 与 `defaultModel` 改成对应值。认证仍由已保存的凭据或环境变量提供。

### low、high、max 支持哪些

| 模型 | Pi 中可选级别 |
| --- | --- |
| `gpt-6.1-sol`、`gpt-6-astra` | `low`、`medium`、`high`、`xhigh`、`max` |
| `gpt-6.1-terra`、`gpt-6-luna` | `off`、`low`、`medium`、`high`、`xhigh`、`max` |

Pi 会根据当前模型显示支持的级别。`off` 在上述支持关闭推理的 OpenAI 模型上对应 API 的 `none`；这些模型没有 `minimal` 档。范围以当前 `/thinking` 为准，单独运行时也可以指定：

```sh
pi --provider openai --model gpt-6.1-sol --thinking max
```

### 用界面从零勾选

1. 在 Pi 输入 `/scoped-models`。
2. 搜索框留空，按 `Ctrl+X` 取消全选。
3. 搜索模型，用方向键定位，按 `Enter` 勾选；清空搜索词后选择其他模型。
4. 至少保留一个当前可用模型，按 `Ctrl+S` 保存，再按 `Escape` 返回。

之后 `/model` 默认进入 `scoped`，只显示常用范围；按 `Tab` 可切到 `all` 查看全部。只勾选而不保存，修改仅对当前会话有效。

Pi `1.5.0` 首次默认全选，没有“首次默认空选”的设置。`enabledModels` 留空或设为 `[]` 会回退到全部模型。Pi 仍会读取完整目录供选择；目录中有某个模型，不代表当前 Key 已有调用权限。目录与模型选择见 [Pi Models](https://pi.dev/docs/latest/models)。

## 按用途选择模型

| 用途 | 默认选择 | 在 Pi 中使用 |
| --- | --- | --- |
| 日常编程 | `gpt-6.1-sol` · `max` | 默认启动模型 |
| 复杂推理、困难任务 | `gpt-6-astra` · `max` | `/model` 切换 |
| UI 截图、视觉分析、写作 | `gpt-6.1-terra` · `max` | `/model` 切换，已加入常用范围 |
| 轻量任务 | `gpt-6-luna` · `max` | `/model` 切换；追求速度时临时降低思考级别 |
| 图片生成、精细编辑 | [gpt-image-2.6-sunburst](https://developers.openai.com/api/docs/models/gpt-image-2.6-sunburst) | Image API，需要工具、扩展或 MCP 接入 |
| 图片快速迭代 | [gpt-image-2.6-flare](https://developers.openai.com/api/docs/models/gpt-image-2.6-flare) | Image API，需要工具、扩展或 MCP 接入 |
| Pi 内置图片调用 | `openrouter/google/gemini-2.5-flash-image` | 登录 OpenRouter 后由 `codemode` 调用 |
| TTS、文字转语音（新接入） | [gpt-realtime-2.1-mini](https://developers.openai.com/api/docs/models/gpt-realtime-2.1-mini) | Realtime API，需要语音工具、扩展或 MCP 接入 |
| TTS（兼容已有接口） | `gpt-4o-mini-tts` | `/v1/audio/speech`，已弃用，见下方停用日期 |
| 录音转文字 | [gpt-transcribe](https://developers.openai.com/api/docs/models/gpt-transcribe) | Transcription API，需要工具接入 |
| 自然实时语音对话 | [gpt-live-1](https://developers.openai.com/api/docs/models/gpt-live-1) | Live API，需要实时语音接入 |

四个聊天模型都支持图片输入，定位见 [OpenAI 模型目录](https://developers.openai.com/api/docs/models)。图片生成与语音模型使用独立接口，**不填进 `enabledModels`，也不通过 `/model` 切换**；这里列出的专用模型是选型建议，加入表格不会自动安装工具。

### 图片调用入口

默认模板已启用 `codemode`。Pi `1.5.0` 原生支持 OpenRouter 图片模型，使用 OpenRouter 的 `/login` 凭据或 `OPENROUTER_API_KEY`。可直接让 Pi：“列出当前可用的图片模型，再用我选的模型生成图片。”

Pi 在 `codemode` 中查询 `models.getAvailableOfType("image")`，通过 `models.generateImages(...)` 调用，再用 `image(...)` 展示结果。OpenAI Image API 的 Sunburst、Flare 需要另接工具。详见 [Pi 图片模型](https://pi.dev/docs/latest/models#use-image-models)与 [Codemode 图片调用](https://pi.dev/docs/latest/codemode#generate-images)。

### TTS 与语音调用入口

Pi `1.5.0` 没有原生 TTS 模型选择器或 `defaultTtsModel` 设置；接入语音工具后，在工具自己的配置中选择上表模型。

新接入优先使用 `gpt-realtime-2.1-mini` 的 Realtime 工作流。已有 Speech API 接入可暂用 `gpt-4o-mini-tts`，或 `tts-1` / `tts-1-hd`；它们已弃用，计划 **2027-01-06 停用**。`gpt-realtime-2.1-mini` 不能直接替换进 `/v1/audio/speech` 请求。见 [OpenAI TTS 说明](https://developers.openai.com/api/docs/guides/text-to-speech)。

图片质量、音色与语速等参数在对应工具中设置，不共用聊天模型的 `max` 思考级别。实际可用模型与接口以供应商及账号权限为准。

## Warp 工作流与终端命令

导入需要的 YAML，在 Warp 中按左列名称搜索；直接使用终端时，执行右列命令并替换占位符。工作流适用于 Bash / Zsh。

| Warp 搜索名 | 实际终端命令 |
| --- | --- |
| [pi settings](pi-settings.yaml) | `nano ~/.pi/agent/settings.json`（默认路径） |
| [pi model](pi-model.yaml) | `pi --provider <供应商> --model <模型> --thinking <级别>` |
| [pi models](pi-models.yaml) | `pi --list-models <关键词>` |
| [pi models refresh](pi-models-refresh.yaml) | `pi update --models` |

`pi model` 的表单默认是 `gpt-6.1-sol` + `max`，会覆盖本次启动设置。平时直接运行 `pi`，即可使用配置文件中的默认模型与级别。

Warp 导入的是副本；更新 YAML 后需重新导入。

## 会话内常用命令

以下命令在 **Pi 输入框**执行。

| 命令 | 用途 |
| --- | --- |
| `/login` / `/logout` | 管理供应商认证 |
| `/model` | 选择模型 |
| `/scoped-models` | 设置常用模型范围 |
| `/thinking` | 选择思考级别 |
| `/settings` | 修改主题、消息投递等偏好 |
| `/session` | 查看会话、用量和费用 |
| `/new` / `/resume` | 开始新会话 / 选择历史会话 |
| `/compact [说明]` | 总结旧上下文 |
| `/reload` | 重载设置、快捷键和资源 |
| `/hotkeys` | 查看当前快捷键 |
| `/quit` | 退出 Pi |

在系统终端继续最近会话用 `pi -c`，选择历史会话用 `pi -r`。完整命令见 [Pi Slash Commands](https://pi.dev/docs/latest/slash-commands)。
