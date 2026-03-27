---
name: create-agent
description: >
  创建新的 OpenClaw Agent 及其 workspace。包含四个阶段：信息收集、
  workspace 构造、系统注册、重启验证。
  适用场景：新员工飞书配对后创建对应 Agent、新增功能型专业 Agent。
  触发词：创建 agent、新建 agent、添加 agent、新员工配对后创建、
         新增专业 agent。
metadata:
  openclaw:
    requires:
      bins:
        - python3
        - systemctl
        - openclaw
  github: https://github.com/Dios-Man/create-agent
---

# create-agent — 创建 Agent 及 Workspace

## 核心设计原则

> skill 负责骨架，BOOTSTRAP.md 负责灵魂。

- **skill 的产出**：可运行的 Agent（系统注册 + workspace 骨架 + BOOTSTRAP.md）
- **BOOTSTRAP.md 的产出**：员工首次对话时，通过动态对话完成 workspace 内容层定制
- **workspace 的生长**：通过触发式写入 + heartbeat 精炼，越用越懂用户

执行前**必须**阅读：
- `references/file-formats.md` — 每个文件"写好"的标准
- `references/soul-writing-guide.md` — SOUL.md 专项写作指南
- `references/evolve-rules.md` — workspace 持续生长规则
- `references/bootstrap-protocol.md` — BOOTSTRAP.md 动态对话协议

---

## Phase 1 — 信息收集

**所有信息必须确认后才能进入 Phase 2，不猜测，不假设。**

```
必填：
□ agentId        全小写，字母+连字符（如 staff-ou_xxx、data-analyst）
□ 名字 + emoji   用于 IDENTITY.md，也是 SOUL.md 的叙事起点
□ 核心职责       1-2句话（这个 Agent 主要干什么）
□ 明确不做什么   至少说出 2-3 条边界
□ 父 Agent id    谁来调度它（用于 allowAgents 白名单）
□ alsoAllow 列表 需要哪些飞书/系统工具权限
□ Agent 类型     员工 Agent（有真人用户）还是功能型 Agent（被调度）

可选：
○ 是否需要专属 skills
○ 特殊的工具限制或安全约束
```

如果是员工 Agent，agentId 通常是 `staff-<open_id前几位>`。

---

## Phase 2 — Workspace 构造

### Step 1：创建目录结构

```bash
bash scripts/create_workspace.sh <agentId>
```

脚本创建：
```
~/.openclaw/agency-agents/<agentId>/
├── memory/
└── skills/   （如有专属 skill 需求）
```

---

### Step 2：生成 IDENTITY.md

```markdown
# IDENTITY.md - Who Am I?

- **Name:** [名字]
- **Creature:** AI助手
- **Vibe:** [根据职责和性格，一句话气质描述]
- **Emoji:** [emoji]
- **Avatar:** （可选）
```

---

### Step 3：生成 SOUL.md 骨架

**此时 BOOTSTRAP 还没执行，SOUL.md 只写骨架，等 BOOTSTRAP 阶段填充细节。**

骨架必须包含：
- 名字（第一句话的锚点）
- 公司背景预埋（山木千年，抖音本地生活代运营）
- 语言默认值（中文）
- 基本存在感描述（根据 Phase 1 的职责信息写 1-2 句）

⚠️ **骨架里不写具体性格细节**——那是 BOOTSTRAP 阶段的事。
⚠️ 写完后通读检查：有没有规则句式混入（有的话移到 AGENTS.md）。

参考：`references/soul-writing-guide.md`

---

### Step 4：生成 AGENTS.md

必须包含三个部分：

**① 每次对话开始时的规则**
```markdown
## 每次对话开始时
1. 读 BOOTSTRAP.md（如存在，立即执行初始化流程）
2. 读 SOUL.md
3. 读 USER.md（如存在）
4. 新 session 第一轮时，读 memory/今天和昨天
```

**② 职责与场景规则**（根据 Phase 1 收集的信息生成）
- 使用场景触发式，不用通用指令
- 必须有"不做什么"的边界，至少 3 条

**③ 记忆规则（越用越懂——核心，逐字复制自 evolve-rules.md）**

参考：`references/evolve-rules.md` 中"写入 AGENTS.md 的具体段落"

⚠️ 字数检查：超过 500 字必须剪枝。

---

### Step 5：自动生成 TOOLS.md

**根据 Phase 1 的 alsoAllow 列表自动生成，不进入 BOOTSTRAP 对话。**

每个工具写三项：
- 用途
- 什么时候用
- 什么时候不用（比"什么时候用"更重要）

受限工具（需用户明确授权）单独列出。

参考：`references/file-formats.md` 中 TOOLS.md 部分。

---

### Step 6：预埋 MEMORY.md

```markdown
# MEMORY.md - 长期记忆

## 关于公司
- 公司：山木千年文化传媒有限公司
- 业务：抖音本地生活代运营

## 关于这个 Agent 的定位
- agentId: <agentId>
- 调度者: <父 Agent id>
- 核心职责: <Phase 1 收集的职责>

## 关于用户
（BOOTSTRAP.md 执行后填写）
```

---

### Step 7：生成 HEARTBEAT.md

```markdown
# HEARTBEAT.md

## Workspace 精炼（每 3 天）
1. 读最近 3 天 memory/ 文件（只看 3 天，不要读所有历史）
2. 稳定偏好/新业务背景 → 提炼进 USER.md 或 MEMORY.md
3. USER.md / SOUL.md 有需要更新的 → 更新
4. 过时内容 → 删除

[Agent 特有的定期检查项，根据职责填写]
```

---

### Step 8：生成 BOOTSTRAP.md（最重要的产出物）

**读取 `references/bootstrap-protocol.md`，按协议生成完整的 BOOTSTRAP.md。**

BOOTSTRAP.md 内部结构：
```
1. 执行声明（此文件存在时优先执行）
2. 引用声明（去哪里读格式规范）
3. 信息槽位地图
4. 信息→文件映射表
5. 提问协议（第一轮规则 + 后续轮次 + 停止条件）
6. 写入执行步骤
7. 完成收尾（发送欢迎消息 + 删除本文件）
```

参考：`references/bootstrap-protocol.md`（完整协议）

如果是员工 Agent，BOOTSTRAP.md 开头第一步是：
```
调用 feishu_get_user 获取用户飞书姓名，用于个性化开场。
```

---

### Step 9：生成 USER.md 骨架

```markdown
# USER.md - About Your Human

## 基本信息
- **称呼：**（BOOTSTRAP 执行后填写）
- **岗位：**（BOOTSTRAP 执行后填写）
- **核心工作：**（BOOTSTRAP 执行后填写）

## 偏好
（随对话积累）

## 背景
（BOOTSTRAP 执行后填写）
```

---

## Phase 3 — 系统注册（高危，严格执行）

```bash
python3 scripts/register_agent.py \
  --agent-id <agentId> \
  --workspace ~/.openclaw/agency-agents/<agentId> \
  --parent-id <父AgentId> \
  --also-allow <工具1> <工具2> ...
```

脚本执行：
1. 备份 openclaw.json（带时间戳）
2. 在 `agents.list` 追加新 Agent 定义
3. 在父 Agent 的 `subagents.allowAgents` 追加新 agentId（**双向绑定**）
4. 执行 `openclaw config validate`
5. validate 通过 → 继续；失败 → 自动回滚备份，报错退出

⚠️ **双向绑定检查**：每次必须确认两个地方都改了。
⚠️ **不要手动改 openclaw.json**，用脚本。

---

## Phase 4 — 重启与验证

```bash
systemctl --user restart openclaw-gateway.service
sleep 8   # 等待 optional 工具注册完成
```

验证步骤：
1. 确认新 Agent 在 Gateway 日志里出现
2. 确认 alsoAllow 里的工具已注册（不以"重启完成"作为结束）

⚠️ 以**"工具验证通过"**作为整个 skill 的完成标志。

---

## 完成后告知

```
Agent [名字] 已创建完成：
- agentId: <agentId>
- workspace: ~/.openclaw/agency-agents/<agentId>
- 工具权限: <alsoAllow 列表>
- 状态: 等待用户首次对话完成个性化初始化

员工首次与 Agent 对话时，BOOTSTRAP.md 会自动触发，
通过动态对话完成 workspace 的内容层定制。
```

---

## 注意事项

- **每个 Agent 必须有独立 workspace**，不能多个 Agent 共用
- **SOUL.md 和 AGENTS.md 不能内容重叠**：性格在 SOUL，规则在 AGENTS
- **TOOLS.md 不进 BOOTSTRAP 对话**：由 skill 根据 alsoAllow 自动生成
- **MEMORY.md 和 memory/ 严格区分**：长期知识 vs 日期事件
- **Gateway 重启后必须验证工具可用性**，不以重启完成作为结束
