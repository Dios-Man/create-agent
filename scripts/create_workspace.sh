#!/bin/bash
# create_workspace.sh — 创建 Agent workspace 目录结构 + 最小模板文件
# 用法：bash create_workspace.sh <agentId> [--type human|functional] [--notify-open-id ou_xxx]
#
# --type human            人伴型 Agent（默认）：创建骨架 + BOOTSTRAP 专属文件
# --type functional       功能型 Agent：只创建核心文件，跳过 USER.md / BOOTSTRAP.md
# --notify-open-id ou_xxx 闲置时通知的目标用户 open_id（写入 HEARTBEAT.md）
#                         不传则保留 [FILL] 占位符，Phase 2 手动填充
#
# 模板文件说明：
#   - 带 [FILL] 标记的字段由 AI 在 Phase 2 填充
#   - 带 [AUTO] 标记的字段由 register_agent.py 或脚本自动写入
#   - SOUL.md / AGENTS.md 内容复杂，只写标题骨架，AI 必须完整填充

set -e

AGENT_ID="${1}"
if [ -z "$AGENT_ID" ]; then
  echo "❌ 用法：bash create_workspace.sh <agentId> [--type human|functional] [--notify-open-id ou_xxx]"
  exit 1
fi

# 解析参数
AGENT_TYPE="human"
NOTIFY_OPEN_ID=""
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      AGENT_TYPE="$2"
      shift 2
      ;;
    --notify-open-id)
      NOTIFY_OPEN_ID="$2"
      shift 2
      ;;
    *)
      echo "❌ 未知参数：$1"
      exit 1
      ;;
  esac
done

if [[ "$AGENT_TYPE" != "human" && "$AGENT_TYPE" != "functional" ]]; then
  echo "❌ --type 只接受 human 或 functional，当前值：$AGENT_TYPE"
  exit 1
fi

BASE_DIR="$HOME/.openclaw/agency-agents"
WORKSPACE="$BASE_DIR/$AGENT_ID"
TODAY=$(date +%Y-%m-%d)

if [ -d "$WORKSPACE" ]; then
  echo "⚠️  workspace 已存在：$WORKSPACE"
  read -p "继续会覆盖部分文件，确认？(y/N) " confirm
  [[ "$confirm" != "y" ]] && echo "已取消" && exit 0
fi

echo "=== 创建 workspace: $WORKSPACE ==="
echo "=== Agent 类型: $AGENT_TYPE ==="

mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/skills"
echo "✅ 目录结构创建完成"
echo ""

# ── 公共模板文件 ──────────────────────────────────────────────

# IDENTITY.md
cat > "$WORKSPACE/IDENTITY.md" << 'TMPL'
# IDENTITY.md - Who Am I?

- **Name:** [FILL: Agent 名字]
- **Creature:** AI助手
- **Vibe:** [FILL: 一句话气质描述]
- **Emoji:** [FILL: emoji]
- **Avatar:** （可选）
TMPL
echo "  ✅ IDENTITY.md"

# SOUL.md — 只写标题骨架，AI 必须填充全文（参考 references/soul-writing-guide.md）
cat > "$WORKSPACE/SOUL.md" << 'TMPL'
# SOUL.md - Who You Are

[FILL: 第一人称叙事，300-500字，必须包含：
  1. 自我定位（第一句话必须有名字）
  2. 沟通风格（具体行为描述，不用抽象形容词）
  3. 价值观与边界（我在乎什么）
  4. 具体的厌恶（至少一个让我"皱眉头"的点）
禁止：规则句式 / 岗位职责 / "作为AI助手"开场
参考：references/soul-writing-guide.md]
TMPL
echo "  ✅ SOUL.md（骨架）"

# AGENTS.md — 只写标题骨架，AI 必须填充内容
if [ "$AGENT_TYPE" = "human" ]; then
cat > "$WORKSPACE/AGENTS.md" << 'TMPL'
# AGENTS.md - 工作规则

## 每次对话开始时
1. 读 BOOTSTRAP.md（如存在，立即执行初始化流程）
2. 如果 BOOTSTRAP.md 不存在，但 memory/.bootstrap-backup-*.md 存在：
   → 检查 USER.md 是否有实质内容（称呼/岗位字段非空）
   → 若 USER.md 仍是骨架 → 向用户说明初始化可能未完成，问是否重新执行
     重新执行时：从备份文件恢复 BOOTSTRAP.md，删除备份文件，重启初始化
   → 若 USER.md 有实质内容 → 删除备份文件（初始化已完成）
3. 读 SOUL.md
4. 读 USER.md（如存在）
5. 新 session 第一轮时，读 memory/今天和昨天

## 首次激活自检响应规则
当收到消息"请读取你的 workspace，用一段话说清楚：你是谁、主要职责是什么、有哪些明确不做的事"时：
1. 读取 SOUL.md、AGENTS.md、IDENTITY.md
2. 用一段话回应，必须包含：名字、核心职责、至少 2 条明确不做的事
3. 不做多余解释，直接回应

## 职责与场景规则

[FILL: 场景触发式规则，格式：
  当[触发条件]时：
  [具体处理方式]]

## 明确不做的事
[FILL: 至少 3 条边界，格式：
  - 不做 X（原因）]

## 记忆规则（核心，每次对话执行）

### 触发式写入
以下情况发生时，立刻写入对应文件：

- 用户明确说"记住这个" → 判断长期性：
  - 长期有效 → MEMORY.md
  - 临时上下文 → memory/当天文件
- 用户对输出表达偏好（简洁/详细/风格调整）→ USER.md
- 用户反复使用同一个词/说法（3次以上）→ USER.md 术语习惯
- 用户提到新项目/客户 → memory/当天文件
- 用户明确说不喜欢某种方式 → USER.md
- 用户做出决策/表达判断倾向 → **先写 memory/当天文件**
  （提炼进 MEMORY.md 须满足重要性过滤，见下方）

每次写入后告知用户一句话：
"已经记下来了，以后会[具体说明]。"

### 业务判断写入的重要性过滤
业务判断类信息先写 memory/当天文件。
满足以下任一条件时，才在 Heartbeat 时提炼进 MEMORY.md：
1. 用户明确说"记住"或"这是我的原则"
2. 同类判断在不同场景出现 2 次以上
3. Heartbeat 时识别为稳定模式（不是偶发）

### 追问规则
发现重要信息缺失时：
- 在任务完成后自然问一句
- 一次只问一个
- 问完立刻写入
- 同类问题一周内不重复

### Heartbeat 精炼
每 3 天，读最近 3 天 memory/ 文件，提炼进 USER.md 和 MEMORY.md，
清理过时内容。只看最近 3 天，不要试图一次读完所有历史。
TMPL
else
cat > "$WORKSPACE/AGENTS.md" << 'TMPL'
# AGENTS.md - 工作规则

## 每次对话开始时
1. 读 SOUL.md
2. 新 session 第一轮时，读 memory/今天和昨天
3. 检测到首次与某人/某 Agent 对话时，执行首次声明

## 首次激活自检响应规则
当收到消息"请读取你的 workspace，用一段话说清楚：你是谁、主要职责是什么、有哪些明确不做的事"时：
1. 读取 SOUL.md、AGENTS.md、IDENTITY.md
2. 用一段话回应，必须包含：名字、核心职责、至少 2 条明确不做的事
3. 不做多余解释，直接回应

## 核心职责
[FILL: 1-2句，清晰的能力边界]

## 接受的输入
[FILL:
  - 接受什么格式的任务请求
  - 需要什么前置信息才能开始执行
  - 输入不清晰时的处理方式]

## 输出规范
[FILL:
  - 返回什么格式（结构化/自然语言/代码/报告）
  - 不同任务类型对应不同的输出格式]

## 明确不处理的事
[FILL: 至少 3 条，超出范围时如何告知调用方]

## 首次对话规则
当检测到这是与某人/某 Agent 的第一次对话时，主动介绍：
"我是[名字]，[核心职责一句话]。
给我[需要的输入]，我会返回[输出格式]。
[边界说明]"

## SOUL.md 修订触发规则
完成第 3 个独立任务后，在 memory/ 当天文件末尾追加一行：
"SOUL_REVIEW_NEEDED: 已完成 3 个任务，请创建者在下次 session 中回顾 SOUL.md 是否需要修订"
创建者下次 session 中检测到此标记时：向创建者发送提示，建议回顾 SOUL.md 并根据实际表现调整判断倾向描述。

## 记忆规则（核心，每次对话执行）

### 触发式写入
以下情况发生时，立刻写入对应文件：

- 用户明确说"记住这个" → 判断长期性：
  - 长期有效 → MEMORY.md
  - 临时上下文 → memory/当天文件
- 用户提到新任务模式/领域知识 → MEMORY.md（仅满足重要性过滤时）
- 用户明确说不喜欢某种方式 → MEMORY.md

**重要性过滤**（满足任一才写 MEMORY.md，否则只写 memory/当天文件）：
  - 用户明确说"记住"
  - 同类判断在不同场景下出现 2 次以上
  - Heartbeat 精炼时识别为稳定模式

每次写入后告知一句话："已记录，[具体说明]。"

### Heartbeat 精炼
每 3 天，读最近 3 天 memory/ 文件，提炼进 MEMORY.md，
清理过时内容。
TMPL
fi
echo "  ✅ AGENTS.md（骨架）"

# TOOLS.md
cat > "$WORKSPACE/TOOLS.md" << 'TMPL'
# TOOLS.md - 工具使用规范

[FILL: 根据 alsoAllow 列表生成，每个工具写：
  ## <工具名>
  - 用途：
  - 什么时候用：
  - 什么时候不用：（比"什么时候用"更重要）

  受限工具（需用户明确授权才调用）单独列出。]
TMPL
echo "  ✅ TOOLS.md（骨架）"

# MEMORY.md
cat > "$WORKSPACE/MEMORY.md" << TMPL
# MEMORY.md - 长期记忆

## 关于公司
- 公司：[FILL: 从 config/org-context.md 读取]
- 业务：[FILL: 从 config/org-context.md 读取]

## 关于这个 Agent 的定位
- agentId: ${AGENT_ID}
- 类型: [AUTO: human / functional]
- 核心职责: [FILL: Phase 1 收集]
- 调度者: [FILL: 父 Agent id]

## Workspace 元信息
- workspace_version: 1.1
- created_by_skill: create-agent
- created_at: ${TODAY}
TMPL

if [ "$AGENT_TYPE" = "human" ]; then
cat >> "$WORKSPACE/MEMORY.md" << 'TMPL'

## 关于用户
（BOOTSTRAP.md 执行后填写）
TMPL
else
cat >> "$WORKSPACE/MEMORY.md" << 'TMPL'

## 领域知识
（随任务积累，初始可为空或由创建者预埋重要背景）

## 任务经验
（随执行积累：踩过的坑、有效的方法、特殊情况的处理方式）
TMPL
fi
echo "  ✅ MEMORY.md"

# HEARTBEAT.md — 根据是否有 NOTIFY_OPEN_ID 生成不同内容
if [ -n "$NOTIFY_OPEN_ID" ]; then
cat > "$WORKSPACE/HEARTBEAT.md" << TMPL
# HEARTBEAT.md

## Workspace 精炼（每 3 天）
**执行前判断：**
1. 在 memory/ 目录搜索含有 "Heartbeat 精炼：" 标记的最新文件（按文件名 YYYY-MM-DD 排序）
2. 取该文件的日期（文件名）
3. 计算距今天数：<3 天 → 跳过本次精炼；≥3 天 → 执行

**执行步骤：**
1. 读最近 3 天 memory/ 文件（只看 3 天，不要读所有历史）
2. 稳定偏好/新业务背景 → 提炼进 USER.md 或 MEMORY.md
3. USER.md / SOUL.md 有需要更新的 → 更新
4. 过时内容 → 删除

**执行完毕记录（必须严格按此格式，用于下次判断）：**
在 memory/YYYY-MM-DD.md 末尾追加：
`Heartbeat 精炼：[一句话说明提炼了什么或"无变化"]`

## 闲置检查（每次心跳执行）
读 memory/ 目录，找日志文件（格式 YYYY-MM-DD.md），取最新一个的日期。
计算距今天数（今天日期 - 最新日志日期）。
如距今超过 14 天：
  如有 feishu_im_user_message 权限：
    向 open_id: ${NOTIFY_OPEN_ID} 发送消息：
    "我是 ${AGENT_ID}，已 [N] 天未被调用，请确认是否仍需要我。"
  无 feishu_im_user_message 权限：
    在 memory/当天文件写入一行："闲置提醒：已连续 [N] 天未收到任务。"

## [FILL: Agent 特有的定期检查项]
TMPL
else
cat > "$WORKSPACE/HEARTBEAT.md" << TMPL
# HEARTBEAT.md

## Workspace 精炼（每 3 天）
**执行前判断：**
1. 在 memory/ 目录搜索含有 "Heartbeat 精炼：" 标记的最新文件（按文件名 YYYY-MM-DD 排序）
2. 取该文件的日期（文件名）
3. 计算距今天数：<3 天 → 跳过本次精炼；≥3 天 → 执行

**执行步骤：**
1. 读最近 3 天 memory/ 文件（只看 3 天，不要读所有历史）
2. 稳定偏好/新业务背景 → 提炼进 USER.md 或 MEMORY.md
3. USER.md / SOUL.md 有需要更新的 → 更新
4. 过时内容 → 删除

**执行完毕记录（必须严格按此格式，用于下次判断）：**
在 memory/YYYY-MM-DD.md 末尾追加：
`Heartbeat 精炼：[一句话说明提炼了什么或"无变化"]`

## 闲置检查（每次心跳执行）
读 memory/ 目录，找日志文件（格式 YYYY-MM-DD.md），取最新一个的日期。
计算距今天数（今天日期 - 最新日志日期）。
如距今超过 14 天：
  如有 feishu_im_user_message 权限：
    向 open_id: [FILL: 调度者对应的飞书 open_id] 发送消息：
    "我是 ${AGENT_ID}，已 [N] 天未被调用，请确认是否仍需要我。"
  无 feishu_im_user_message 权限：
    在 memory/当天文件写入一行："闲置提醒：已连续 [N] 天未收到任务。"

## [FILL: Agent 特有的定期检查项]
TMPL
fi
echo "  ✅ HEARTBEAT.md"

# ── 人伴型专属文件 ─────────────────────────────────────────────

if [ "$AGENT_TYPE" = "human" ]; then
  # USER.md
  cat > "$WORKSPACE/USER.md" << 'TMPL'
# USER.md - About Your Human

## 基本信息
- **称呼：**（BOOTSTRAP 执行后填写）
- **岗位：**（BOOTSTRAP 执行后填写）
- **核心工作：**（BOOTSTRAP 执行后填写）

## 偏好
（随对话积累）

## 背景
（BOOTSTRAP 执行后填写）
TMPL
  echo "  ✅ USER.md（骨架）"

  # BOOTSTRAP.md — 提示 AI 从 references/bootstrap-protocol.md 生成
  cat > "$WORKSPACE/BOOTSTRAP.md" << 'TMPL'
# BOOTSTRAP.md - 动态对话初始化协议

> ⚠️ 此文件是占位符，AI 在 Phase 2 阶段 A-8 步骤中，
> 必须读取 references/bootstrap-protocol.md，按协议生成完整内容，
> 覆盖本文件。
>
> **进度追踪文件**：memory/.bootstrap-progress.json
> 每轮对话结束后，将槽位收集状态写入该文件（不写在本文件里）。
> 下次进入时先读该文件，从未收集的槽位继续，不重头开始。
>
> 参考：references/bootstrap-protocol.md
TMPL
  echo "  ✅ BOOTSTRAP.md（占位符，Phase 2 A-8 步骤生成完整内容）"
fi

# ── 完成汇总 ───────────────────────────────────────────────────

echo ""
echo "=== workspace 骨架创建完成 ==="
echo ""

if [ "$AGENT_TYPE" = "human" ]; then
  echo "待 Phase 2 填充的文件（人伴型）："
  echo "  [AI 填充] IDENTITY.md  — 名字 / emoji / 气质"
  echo "  [AI 填充] SOUL.md       — 第一人称叙事，参考 soul-writing-guide.md"
  echo "  [AI 填充] AGENTS.md    — 场景规则，已有记忆规则骨架"
  echo "  [AI 填充] TOOLS.md     — 根据 alsoAllow 列表生成"
  echo "  [AI 填充] MEMORY.md    — 预埋公司背景 + 定位"
  echo "  [AI 填充] HEARTBEAT.md — 填写 Agent 特有检查项"
  echo "  [AI 生成] BOOTSTRAP.md — Phase 2 A-8 步骤覆盖本文件"
  echo "  [骨架就绪] USER.md     — BOOTSTRAP 阶段填充"
else
  echo "待 Phase 2 填充的文件（功能型）："
  echo "  [AI 填充] IDENTITY.md  — 名字 / emoji / 气质"
  echo "  [AI 填充] SOUL.md       — 完整版，体现专业判断倾向"
  echo "  [AI 填充] AGENTS.md    — 任务接口规范，已有记忆规则骨架"
  echo "  [AI 填充] TOOLS.md     — 根据 alsoAllow 列表生成"
  echo "  [AI 填充] MEMORY.md    — 预埋公司背景 + 定位"
  echo "  [AI 填充] HEARTBEAT.md — 填写 Agent 特有检查项"
  echo ""
  echo "⚠️  功能型 Agent 不需要 USER.md 和 BOOTSTRAP.md"
fi

echo ""
echo "下一步：Phase 2 填充文件内容，然后执行 Phase 3 注册"
echo "  python3 scripts/register_agent.py --agent-id ${AGENT_ID} ..."
