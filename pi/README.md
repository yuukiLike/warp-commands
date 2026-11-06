# Pi 配置与速查

默认使用 **Sol + max**，按用途切换其他模型。Pi 操作按 `1.5.0` 核对，OpenAI 模型资料核对日期为 **2026-11-05**。

[默认配置模板](settings.json) · [模型怎么选](#按用途选择模型) · [快捷键速查](#快捷键速查)

## 设置默认模型与常用集合

在 **Pi 输入框**操作即可保存相关配置，通常无需手动合并模板。

1. **默认模型**：输入 `/model`，搜索并选中 `openai/gpt-6.1-sol`，按 `Ctrl+S` 保存。下次直接运行 `pi` 开始新会话时使用 Sol。
2. **常用集合**：输入 `/scoped-models`。想从零选择时，先清空搜索词，按 `Ctrl+X` 取消全选；逐个搜索模型，用方向键定位、`Enter` 勾选，最后按 `Ctrl+S` 保存、`Escape` 返回。至少保留一个可用模型，并把默认的 Sol 留在集合中。
3. **默认思考级别**：输入 `/thinking`，选中 `max` 后按 `Ctrl+S` 保存。已有 `modelThinkingLevels` 时，对应模型的单独设置优先。

之后临时切到 Terra，在 `/model` 中按 `Enter` 即可；按 `Ctrl+P` 也可在常用集合里循环切换。这些操作只改变当前会话，下次新启动仍用 Sol；在 Terra 上按 `Ctrl+S` 才会把它保存为新的默认模型。选择与保存规则见 [Pi Models](https://pi.dev/docs/latest/models#select-a-model)。

`pi -c`、`pi -r` 会恢复历史会话记录的模型与思考级别。如果直接运行 `pi` 仍未使用 Sol，检查项目 `.pi/settings.json` 是否覆盖了默认值、启动命令是否指定了 `--model`，以及 Sol 是否在常用集合中且认证可用。

## 编辑配置

需要调整界面之外的选项时，再编辑对应文件：

| 文件 | 配置内容 |
| --- | --- |
| `~/.pi/agent/settings.json` | 默认模型、常用模型范围、思考级别与使用偏好 |
| `项目目录/.pi/settings.json` | 当前项目的设置；项目受信任后加载，并可覆盖用户设置 |
| `~/.pi/agent/keybindings.json` | 自定义快捷键 |
| `~/.pi/agent/models.json` | 自定义 API 地址、模型及模型参数覆盖 |
| `~/.pi/agent/auth.json` | 保存的 API Key / OAuth 凭据，通常通过 `/login`、`/logout` 管理 |

以下命令在 **系统终端**执行，用 `vi` 编辑用户配置；目录不存在时先创建。设置了 `PI_CODING_AGENT_DIR` 时，使用该目录，默认是 `~/.pi/agent`。

```sh
mkdir -p "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" && vi "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/settings.json"
```

按 `i` 进入编辑；改完按 `Esc`，输入 `:wq` 后回车保存退出；放弃修改用 `Esc` → `:q!` → 回车。保存后在 Pi 输入 `/reload` 重载配置；验证启动默认模型时，退出后直接运行 `pi`。

只对当前项目生效时，在项目目录执行 `mkdir -p .pi && vi .pi/settings.json`。项目受信任后，项目设置覆盖同名用户设置；在 Pi 中保存全局默认模型后，仍需留意项目覆盖。位置与作用域见 [Pi Configuration](https://pi.dev/docs/latest/configuration)。

### 使用模板与处理同名配置

仓库的 [settings.json](settings.json) 是模板，Pi 不会自动加载它。配置文件不存在时可粘贴完整模板；已有配置时，按下表修改原字段，保留其他设置。每个键只出现一次，整个文件保留一个 JSON 对象，避免注释和末尾逗号。

| 字段 | 模板内容与合并规则 |
| --- | --- |
| `defaultProvider` + `defaultModel` | 固定 Sol 时，将原值分别改为 `openai`、`gpt-6.1-sol` |
| `enabledModels` | 常用集合，每项为 `供应商/模型ID`；采用模板的四个模型，或保留需要的旧模型并添加新模型，避免重复 |
| `defaultThinkingLevel` | 默认级别改为 `max` |
| `modelThinkingLevels` | 按 `供应商/模型ID` 逐项合并；采用模板时将四个同名模型的级别改为 `max`，保留其他模型条目 |
| `defaultTools` | 在原数组追加一次 `+codemode`，保留原有工具；启用脚本调用及 Pi 支持的图片模型入口 |

`modelThinkingLevels` 优先于 `defaultThinkingLevel`。例如原来 Luna 单独设置为 `low`，仅将全局默认改为 `max` 不会覆盖它，需要同步修改 Luna 的条目。字段说明见 [Pi Settings](https://pi.dev/docs/latest/settings#model-and-thinking)。

常用集合未设置或为 `[]` 时回退到全部模型；`/model` 中可按 `Tab` 在常用与全部之间切换。目录中有某个模型，不代表当前账号已有调用权限。

继续使用 DeepSeek 时，可将 `deepseek/deepseek-v4-pro`、`deepseek/deepseek-flash` 加入 `enabledModels`；改用它作为默认模型时，再修改 `defaultProvider` 与 `defaultModel`。认证由已保存的凭据或环境变量提供。

`max` 优先考虑推理深度；简单任务可临时切到 `low` 或 `medium`。Sol、Astra 支持 `low` 到 `max`，Terra、Luna 还支持 `off`（对应 API 的 `none`）；具体选项以 `/thinking` 为准。

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
| [pi settings](pi-settings.yaml) | 用 `vi` 编辑用户配置，完整命令见[编辑配置](#编辑配置) |
| [pi model](pi-model.yaml) | `pi --provider <供应商> --model <模型> --thinking <级别>` |
| [pi models](pi-models.yaml) | `pi --list-models <关键词>` |
| [pi models refresh](pi-models-refresh.yaml) | `pi update --models` |

`pi model` 的表单默认是 `gpt-6.1-sol` + `max`，会覆盖本次启动设置。平时直接运行 `pi`，即可使用配置文件中的默认模型与级别。

Warp 导入的是副本；更新 YAML 后需重新导入。

## 会话内常用命令

以下命令在 **Pi 输入框**执行；`/settings` 打开偏好界面，Warp 的 `pi settings` 工作流则打开配置文件。

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

## 快捷键速查

macOS / 普通 Linux 默认键位；当前设置看 `/hotkeys`，选择器内看底部提示。完整键位见 [Pi Keybindings](https://pi.dev/docs/latest/keybindings)。

| 按键 | 主输入框操作 |
| --- | --- |
| `Ctrl+L` | 选择模型 |
| `Ctrl+P` / `Ctrl+Shift+P` | 常用集合中的下一个 / 上一个模型 |
| `Shift+Tab` | 切换思考级别 |
| `Escape` | 中止当前运行 |
| `Shift+Enter` | 换行（需终端支持） |
| `Alt+Enter` | 追加请求，等当前工作结束后执行 |
| `Ctrl+V` | 粘贴文本或图片 |
| `Ctrl+O` | 折叠 / 展开工具输出 |
| `Ctrl+T` | 折叠 / 展开思考内容 |
| `Ctrl+C` | 清空输入 |
| `Ctrl+D` | 输入为空时退出 |

| 界面 | 按键 | 操作 |
| --- | --- | --- |
| `/model` | 输入关键词 | 搜索模型或供应商 |
| `/model` | `Enter` / `Ctrl+S` | 仅当前会话切换 / 切换并保存为默认模型 |
| `/model` | `Tab` | 常用 / 全部（已设置常用范围时） |
| `/thinking` | `Enter` / `Ctrl+S` | 仅当前会话应用 / 应用并保存默认级别 |
| `/scoped-models` | `Ctrl+X` | 取消全选；有搜索词时只取消搜索结果 |
| `/scoped-models` | `Enter` | 勾选 / 取消当前模型 |
| `/scoped-models` | `Ctrl+S` | 保存常用集合；未保存仅对当前会话有效 |
| 以上界面 | `Escape` | 返回 |
