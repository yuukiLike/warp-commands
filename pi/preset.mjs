import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

// 相对脚本定位模板，Warp 从其他目录启动时也能找到它。
export const templatePath = fileURLToPath(new URL("./settings.template.json", import.meta.url));
export const extensionPath = fileURLToPath(import.meta.url);
export const thinkingLevels = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
export const thinkingSuffix = new RegExp(`:(?:${thinkingLevels.join("|")})$`);
const openaiServiceTiers = ["auto", "default", "flex", "scale", "priority", "fast", "ultrafast"];

export function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function readJsonObject(file) {
  // 部分编辑器会写入 UTF-8 BOM，解析 JSON 前先去掉它。
  const content = readFileSync(file, "utf8").replace(/^\uFEFF/, "");
  let value;
  try {
    value = JSON.parse(content);
  } catch {
    throw new Error(`${file} 不是有效的 JSON。`);
  }
  if (!isObject(value)) throw new Error(`${file} 必须是 JSON 对象。`);
  return value;
}

// 模板使用精确的 provider/model ID。Pi 的常用模型列表还接受通配符和思考级别后缀。
function isModelId(value) {
  return typeof value === "string" && /^[\w-]+\/[^\s*?[\]]+$/.test(value) && !thinkingSuffix.test(value);
}

export function readPreset() {
  const {
    defaultModel, enabledModels, defaultThinkingLevel = "max", modelThinkingLevels = {}, serviceTiers = {},
  } = readJsonObject(templatePath);
  if (!isModelId(defaultModel) || !Array.isArray(enabledModels) || !enabledModels.every(isModelId)) {
    throw new Error(`${templatePath} 的 defaultModel 和 enabledModels 必须使用精确的 provider/model ID。`);
  }
  if (!thinkingLevels.includes(defaultThinkingLevel)) {
    throw new Error(`${templatePath} 的 defaultThinkingLevel 必须是 ${thinkingLevels.join("、")} 之一。`);
  }
  if (!isObject(modelThinkingLevels) || Object.entries(modelThinkingLevels).some(([id, level]) =>
    !isModelId(id) || !thinkingLevels.includes(level))) {
    throw new Error(`${templatePath} 的 modelThinkingLevels 必须使用精确的 provider/model ID 和有效的思考级别。`);
  }
  if (!isObject(serviceTiers) || Object.entries(serviceTiers).some(([id, tier]) =>
    !id.startsWith("openai/") || !isModelId(id) || !openaiServiceTiers.includes(tier))) {
    throw new Error(`${templatePath} 的 serviceTiers 必须将精确的 openai/model ID 映射到 ${openaiServiceTiers.join("、")} 之一。`);
  }
  return { defaultModel, enabledModels, defaultThinkingLevel, modelThinkingLevels, serviceTiers };
}

// Pi 调用这个默认导出注册扩展。钩子为匹配的 OpenAI Responses 请求补上 service_tier。
export default function registerServiceTiers(pi) {
  const { serviceTiers } = readPreset();
  pi.on("before_provider_request", ({ payload }, { model }) => {
    if (model?.provider !== "openai" || model.api !== "openai-responses" || payload?.model !== model.id) return;
    const tier = serviceTiers[`openai/${model.id}`];
    if (tier) return { ...payload, service_tier: tier };
  });
}
