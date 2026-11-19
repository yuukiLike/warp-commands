import { spawnSync } from "node:child_process";
import {
  chmodSync, lstatSync, mkdirSync, mkdtempSync, renameSync, rmSync, writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { extensionPath, isObject, readJsonObject, readPreset, templatePath, thinkingLevels, thinkingSuffix } from "./preset.mjs";

function agentDirectory() {
  const dir = process.env.PI_CODING_AGENT_DIR || "~/.pi/agent";
  if (dir.startsWith("file://")) return resolve(fileURLToPath(dir));
  return resolve(dir.replace(/^~(?=\/|$)/, () => homedir()));
}

function isStringArray(value) {
  return Array.isArray(value) && value.every(item => typeof item === "string");
}

function applyPreset(current, { defaultModel, defaultThinkingLevel, enabledModels, modelThinkingLevels }) {
  const { enabledModels: currentModels = [], modelThinkingLevels: currentLevels = {}, extensions = [] } = current;
  if (!isStringArray(currentModels)) {
    throw new Error("现有 settings.json 的 enabledModels 必须是字符串数组。");
  }
  if (!isObject(currentLevels)) {
    throw new Error("现有 settings.json 的 modelThinkingLevels 必须是对象。");
  }
  if (!isStringArray(extensions)) {
    throw new Error("现有 settings.json 的 extensions 必须是字符串数组。");
  }

  const models = [defaultModel, ...enabledModels];
  const presetIds = new Set(models.map(id => id.toLowerCase()));
  // 同步预设命中的模型级思考设置，并去掉用户列表中同模型的旧条目。
  for (const id of Object.keys(currentLevels)) {
    if (presetIds.has(id.toLowerCase())) currentLevels[id] = defaultThinkingLevel;
  }
  if (Object.keys(modelThinkingLevels).length > 0) {
    current.modelThinkingLevels = { ...currentLevels, ...modelThinkingLevels };
  }
  const otherPatterns = currentModels.filter(pattern => !presetIds.has(pattern.replace(thinkingSuffix, "").toLowerCase()));
  // Pi 的用户设置分开存提供方和模型，因此要拆开模板中的完整 ID。
  const separator = defaultModel.indexOf("/");
  // Pi 采用第一个匹配项，所以预设模型排在已有通配符前。
  return {
    ...current,
    defaultProvider: defaultModel.slice(0, separator),
    defaultModel: defaultModel.slice(separator + 1),
    defaultThinkingLevel,
    enabledModels: [...new Set([...models, ...otherPatterns])],
    // 写入扩展路径后，直接运行 pi 也会加载服务层级钩子。
    extensions: extensions.includes(extensionPath) ? extensions : [...extensions, extensionPath],
  };
}

function writeSettings(action) {
  const preset = readPreset();
  const dir = agentDirectory();
  const file = join(dir, "settings.json");
  if (lstatSync(dir, { throwIfNoEntry: false })?.isSymbolicLink()) {
    throw new Error(`拒绝写入符号链接：${dir}`);
  }
  const fileStat = lstatSync(file, { throwIfNoEntry: false });
  if (fileStat?.isSymbolicLink()) throw new Error(`拒绝写入符号链接：${file}`);
  if (fileStat && !fileStat.isFile()) throw new Error(`不是普通文件：${file}`);
  // 合并以原设置为起点，覆盖从空对象开始。
  const current = action === "merge" && fileStat ? readJsonObject(file) : {};
  const settings = applyPreset(current, preset);

  // 在目标目录下写好临时文件，再用 rename 一次性替换，避免留下只写了一半的设置。
  mkdirSync(dir, { recursive: true });
  const temporaryDir = mkdtempSync(join(dir, ".pi-write-"));
  const temporaryFile = join(temporaryDir, "content.json");
  try {
    writeFileSync(temporaryFile, JSON.stringify(settings, null, 2) + "\n", { mode: 0o600 });
    if (fileStat) chmodSync(temporaryFile, fileStat.mode & 0o777);
    renameSync(temporaryFile, file);
  } finally {
    rmSync(temporaryDir, { recursive: true, force: true });
  }
  console.log(`已${action === "merge" ? "合并" : "覆盖"} ${file}。默认模型为 ${preset.defaultModel}，思考级别为 ${preset.defaultThinkingLevel}。`);
}

function runInteractive(command, args) {
  // 把终端交给 Pi 或 vi，并把子进程的退出结果传回 Warp。
  const result = spawnSync(command, args, { stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.signal) process.kill(process.pid, result.signal);
  else process.exitCode = result.status;
}

function start(modelArg, thinkingArg) {
  const { defaultModel, defaultThinkingLevel, modelThinkingLevels } = readPreset();
  const selection = modelArg?.trim();
  const level = thinkingArg?.trim();
  const model = !selection || selection === "preset" ? defaultModel : selection;
  const presetLevel = Object.hasOwn(modelThinkingLevels, model) ? modelThinkingLevels[model] : defaultThinkingLevel;
  const thinking = !level || level === "preset" ? presetLevel : level;
  if (!thinkingLevels.includes(thinking)) throw new Error(`无效的思考级别 ${thinking}。`);
  runInteractive("pi", ["--model", model, "--thinking", thinking, "--extension", extensionPath]);
}

// 跳过 Node 和脚本路径，读取 Warp 传入的动作和参数。
const [, , action, model, thinking] = process.argv;
try {
  if (action === "start") start(model, thinking);
  else if (action === "edit") runInteractive("vi", [templatePath]);
  else if (action === "merge" || action === "overwrite") writeSettings(action);
  else throw new Error("用法为 node pi/warp.mjs start [model] [thinking]、edit、merge 或 overwrite。");
} catch (error) {
  console.error(`pi: ${error.message}`);
  process.exitCode = 1;
}
