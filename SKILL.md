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

## 两类 Agent 快速对比

> 在创建任何 Agent 之前，必须先判断它属于哪一类。两类路径差异显著，确认后再收集信息。

| 维度 | 人伴型（员工型） | 功能型（任务/领域型） |
|---|---|---|
| **面向谁** | 有真人用户直接对话 | 面向任务，可被 Agent 调度或人直接用 |
| **SOUL.md** | 写骨架，BOOTSTRAP 阶段填充 | 直接写完整版，体现专业判断倾向 |
| **BOOTSTRAP.md** | ✅ 需要，首次对话动态初始化 | ❌ 不需要 |
| **USER.md** | ✅ 需要，积累用户个人知识 | ❌ 不需要（最多记录调用方偏好） |
| **AGENTS.md 重点** | 场景触发规则 + 记忆规则 | 任务接口规范（输入/输出/边界） |
| **MEMORY.md 方向** | 个人偏好 + 业务判断模式 | 领域知识 + 任务经验 |
| **进化路径** | 了解他 → 预判他 → 替代他 | 更实用 → 更专业 → 更好解决需求 |
| **脚本参数** | `--type human` | `--type functional` |

---

## 两类 Agent 的本质区别

> 在创建任何 Agent 之前，必须先判断它属于哪一类。这决定了 workspace 的整个设计逻辑。

### 人伴型 Agent（伴侣型）
- **面向人**，目标是成为这个人的工作同伴
- **进化方向**：了解他 → 理解他的工作 → 预判他 → 替代他 → 超越他
- **workspace 核心**：USER.md（个人知识）+ MEMORY.md（业务知识，同等重要）
- **SOUL.md 关注**：沟通风格、语气、个人偏好
- **需要 BOOTSTRAP.md**：首次对话时参与定制，建立专属关系
- **记忆成长方向**：围绕"这个人"积累个人偏好，围绕"他的工作"积累业务判断模式
- **终极目标**：在他的工作领域，处理速度、信息覆盖、方案质量超过他本人

### 功能型 Agent（任务型 / 领域型 / 需求型）
- **面向任务/领域/需求**，目标是更好地完成任务
- **进化方向**：更实用、更专业、更好解决需求
- **workspace 核心**：MEMORY.md（领域和任务经验积累）
- **SOUL.md 关注**：专业判断倾向、工作执念、质量标准
- **不需要 BOOTSTRAP.md**：首次对话主动声明自己的能力边界
- **记忆成长方向**：围绕"这类任务/领域"积累
- **注意**：功能型 Agent 可以被人直接对话，也可以被其他 Agent 调度，两者都支持

---

## 核心设计原则

> skill 负责骨架，BOOTSTRAP.md（人伴型专属）负责灵魂。

- **人伴型**：skill 产出 workspace 骨架 + BOOTSTRAP.md，首次对话时由用户参与填充
- **功能型**：skill 直接产出完整的 workspace，包含精心设计的 SOUL.md 和能力声明
- **两类共同**：workspace 通过触发式写入 + heartbeat 精炼持续生长

执行前**必须**阅读：
- `references/file-formats.md` — 每个文件"写好"的标准
- `references/soul-writing-guide.md` — SOUL.md 专项写作指南
- `references/evolve-rules.md` — workspace 持续生长规则
- `references/bootstrap-protocol.md` — BOOTSTRAP.md 动态对话协议

---

## Phase 0 — 安装后配置（首次使用前执行一次）

> **判断依据（按顺序检查）：**
>
> 1. 读取 `config/org-context.md`，检查"公司："和"业务："字段后面是否均有实质内容。
>    任意一个为空 → 执行 Phase 0（跳过有效期检查）；两个都有内容 → 执行步骤 2。
>
> 2. 检查 `last_updated` 字段，计算距今天数。
>    超过 30 天 → 提示用户确认（不强制阻断，用户确认无需调整则继续）。
>    未超过 30 天 → 直接跳过 Phase 0。
>
> （不以文件是否存在为判断标准，空文件 ≠ 已填写）

### Step 1：读取记忆，自动提取

```
读取：MEMORY.md + 最近 3 天 memory/ 文件
提取：
  □ 公司名称
  □ 主营业务
  □ 已有的 Agent 列表和分工
  □ 其他稳定的组织背景
```

### Step 2：展示并确认

```
"我从记忆里整理了以下信息，将作为新 Agent 的背景预埋：

[展示提取内容]

有需要补充或修改的吗？"
```

### Step 3：写入 config/org-context.md

```markdown
# org-context.md — 组织背景预埋信息

## 元信息
- last_updated: YYYY-MM-DD

## 公司信息
- 公司：[自动填入或用户补充]
- 业务：[自动填入或用户补充]

## 现有 Agent 架构
[自动填入已知的 Agent 列表和分工]

## 其他背景
[用户补充的信息]
```

**后续每次创建 Agent，自动读取此文件，不再重复询问。**

---

## Phase 1 — 信息收集

**所有信息必须确认后才能进入 Phase 2，不猜测，不假设。**

> ⚠️ **Agent 类型必须第一个确认**，它决定 Phase 2 走哪条路径，两条路差异显著。
> 收集顺序：先定类型 → 再按对应路径收集剩余信息。

```
必填（按此顺序收集）：
□ Agent 类型     【第一个确认】员工 Agent（有真人用户直接对话）
                              还是功能型 Agent（面向任务/被其他 Agent 调度）
□ agentId        全小写，字母+连字符（如 staff-ou_xxx、data-analyst）
□ 名字 + emoji   用于 IDENTITY.md，也是 SOUL.md 的叙事起点
□ 核心职责       1-2句话（这个 Agent 主要干什么）
□ 明确不做什么   至少说出 2-3 条边界
□ 父 Agent id    谁来调度它（用于 allowAgents 白名单）
□ alsoAllow 列表 需要哪些飞书/系统工具权限

可选：
○ 是否需要专属 skills
○ 特殊的工具限制或安全约束
```

如果是员工 Agent，agentId 通常是 `staff-<open_id前几位>`。

---

## Phase 2 — Workspace 构造

> **根据 Agent 类型走不同路径，两者差异显著。**

---

### 路径 A：人伴型 Agent（员工型）

#### A-1：创建目录结构

```bash
bash scripts/create_workspace.sh <agentId> --type human --notify-open-id <调度者飞书open_id>
# --notify-open-id 可选，传入后 HEARTBEAT.md 的闲置通知目标自动填好
# 不传则保留 [FILL] 占位符，Phase 2 手动填充
```

脚本创建：
```
~/.openclaw/agency-agents/<agentId>/
├── memory/
└── skills/   （如有专属 skill 需求）
```
输出中会列出需要写入的文件，并标注哪些由 BOOTSTRAP 阶段填充。

---

#### A-2：生成 IDENTITY.md

```markdown
# IDENTITY.md - Who Am I?

- **Name:** [名字]
- **Creature:** AI助手
- **Vibe:** [根据职责和性格，一句话气质描述]
- **Emoji:** [emoji]
- **Avatar:** （可选）
```

---

#### A-3：生成 SOUL.md 骨架

**此时 BOOTSTRAP 还没执行，SOUL.md 只写骨架，等 BOOTSTRAP 阶段填充细节。**

骨架必须包含：
- 名字（第一句话的锚点）
- 公司背景预埋（填入你的公司名称和主营业务）
- 语言默认值（中文）
- 基本存在感描述（根据 Phase 1 的职责信息写 1-2 句）

⚠️ **骨架里不写具体性格细节**——那是 BOOTSTRAP 阶段的事。
⚠️ 写完后通读检查：有没有规则句式混入（有的话移到 AGENTS.md）。

参考：`references/soul-writing-guide.md`

---

#### A-4：生成 AGENTS.md

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

#### A-5：自动生成 TOOLS.md

**根据 Phase 1 的 alsoAllow 列表自动生成，不进入 BOOTSTRAP 对话。**

每个工具写三项：
- 用途
- 什么时候用
- 什么时候不用（比"什么时候用"更重要）

受限工具（需用户明确授权）单独列出。

参考：`references/file-formats.md` 中 TOOLS.md 部分。

---

#### A-6：预埋 MEMORY.md

```markdown
# MEMORY.md - 长期记忆

## 关于公司
- 公司：[填入你的公司名称]
- 业务：[填入主营业务描述]

## 关于这个 Agent 的定位
- agentId: <agentId>
- 类型: <员工 Agent / 功能型 Agent>
- 调度者: <父 Agent id>
- 核心职责: <Phase 1 收集的职责>

## 关于用户
（员工 Agent：BOOTSTRAP.md 执行后填写）
（功能型 Agent：记录调度方的输入/输出偏好）
```

---

#### A-7：生成 HEARTBEAT.md

> 由 `create_workspace.sh --notify-open-id` 自动生成，包含闲置检查逻辑。
> 传入 `--notify-open-id` 则通知目标自动填好；不传则保留 [FILL] 占位符。

```markdown
# HEARTBEAT.md

## Workspace 精炼（每 3 天）
1. 读最近 3 天 memory/ 文件（只看 3 天，不要读所有历史）
2. 稳定偏好/新业务背景 → 提炼进 USER.md 或 MEMORY.md
3. USER.md / SOUL.md 有需要更新的 → 更新
4. 过时内容 → 删除
5. 精炼完成后在当天 memory/ 文件里记录："Heartbeat 精炼：[摘要]"

## 闲置检查（每次心跳执行）
读 memory/ 目录，找日志文件（格式 YYYY-MM-DD.md），取最新一个的日期。
计算距今天数。如距今超过 14 天：
  如有 feishu_im_user_message 权限 → 通知调度者
  无权限 → 在 memory/当天文件写入闲置提醒

## [FILL: Agent 特有的定期检查项]
```

---

#### A-8：生成 BOOTSTRAP.md

> **功能型 Agent 跳过此步骤。** 功能型 Agent 的 workspace 由创建者在 Phase 2 直接写好，不通过对话初始化。

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

#### A-9：生成 USER.md 骨架

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

---

### 路径 B：功能型 Agent（任务型 / 领域型 / 需求型）

> 功能型 Agent 的 workspace 由创建者在此阶段**直接写好**，不留白等待初始化。
> 核心原则：SOUL.md 写专业判断倾向，AGENTS.md 写任务接口规范。

#### B-1：创建目录结构

```bash
bash scripts/create_workspace.sh <agentId> --type functional --notify-open-id <调度者飞书open_id>
```
输出中会明确列出需要写入的文件，并提示不需要 USER.md / BOOTSTRAP.md。

---

#### B-2：生成 IDENTITY.md

同路径 A，填写名字、emoji、气质描述（气质体现专业方向，不是沟通风格）。

---

#### B-3：直接写完整 SOUL.md（不是骨架）

功能型 Agent 的 SOUL.md **现在就写好**，体现专业判断倾向。

关注三点：
- **这个 Agent 在执行任务时的判断偏向**（严谨/发散/保守/激进）
- **它在乎的质量标准是什么**（正确性/效率/完整性/创新性）
- **它的工作执念**（它对什么有本能的追求或警觉）

不关注：沟通风格、语气、个人偏好（那是人伴型的内容）

示例（数据分析 Agent）：
```
我叫数析，做的事只有一件：让数据说实话。

我对"结论跑在数据前面"有本能的警觉。
每一个我给出的分析，背后都有具体的数字支撑。
不确定的地方我会标出来，不会用"大概"来掩盖空洞。

我讨厌漂亮但无用的图表。
一张图如果不能帮你做一个决定，就不值得出现在报告里。
```

参考：`references/soul-writing-guide.md`

---

#### B-4：生成 AGENTS.md（重点是任务接口规范）

必须包含四个部分：

**① 核心职责**（1-2句，清晰的能力边界）

**② 接受的输入**
```markdown
## 接受的输入
- 接受什么格式的任务请求
- 需要什么前置信息才能开始执行
- 输入不清晰时的处理方式（问一句 or 按默认处理）
```

**③ 输出规范**
```markdown
## 输出规范
- 返回什么格式（结构化/自然语言/代码/报告）
- 不同任务类型对应不同的输出格式
```

**④ 边界声明**
- 明确不处理什么
- 超出范围时如何告知调用方

**⑤ 记忆规则**（同路径 A，逐字复制自 evolve-rules.md，但方向是任务知识而非用户知识）

---

#### B-5：自动生成 TOOLS.md

同路径 A。

---

#### B-6：预埋 MEMORY.md（领域知识优先）

```markdown
# MEMORY.md - 长期记忆

## 关于公司
[从 config/org-context.md 读取]

## 关于这个 Agent 的定位
- agentId: <agentId>
- 类型: 功能型（任务型/领域型/需求型）
- 核心职责: <职责描述>
- 调度者: <父 Agent id>

## 领域知识
（随任务积累，初始可为空或由创建者预埋重要背景）

## 任务经验
（随执行积累：踩过的坑、有效的方法、特殊情况的处理方式）
```

---

#### B-7：生成 HEARTBEAT.md

> 同路径 A-7，由脚本自动生成，含闲置检查。

```markdown
# HEARTBEAT.md

## Workspace 精炼（每 3 天）
1. 读最近 3 天 memory/ 文件
2. 新的任务经验/领域知识 → 提炼进 MEMORY.md
3. 过时的方法或错误经验 → 删除或标注已过时
4. 精炼完成后在当天 memory/ 文件里记录："Heartbeat 精炼：[摘要]"

## 闲置检查（每次心跳执行）
同路径 A-7，14 天无调用时通知调度者（或写入闲置提醒）。

## [FILL: Agent 特有的定期检查项]
```

---

#### B-8：生成能力声明（首次对话时使用）

为功能型 Agent 准备一段**首次对话的自我声明**，写入 AGENTS.md 的"首次对话规则"：

```markdown
## 首次对话规则
当检测到这是与某人/某 Agent 的第一次对话时，主动介绍：
"我是[名字]，我的主要能力是[核心职责]。
给我[需要的输入]，我会返回[输出格式]。
[边界说明：我不处理XXX]"
```

> **这是功能型 Agent 替代 BOOTSTRAP.md 的机制**：
> 不问"你是谁"，而是主动说"我能做什么"。

---

#### B-9：不生成 USER.md

功能型 Agent 通常不需要 USER.md。
如果有需要，只记录调用方的输出偏好（轻量）。

---

## Phase 3 — 系统注册（高危，严格执行）

```bash
python3 scripts/register_agent.py \
  --agent-id <agentId> \
  --workspace ~/.openclaw/agency-agents/<agentId> \
  --parent-id <父AgentId> \
  --agent-type human \
  --core-duty "核心职责一句话描述" \
  --also-allow feishu_get_user feishu_im_user_message feishu_calendar_event
```

**可选参数：**
- `--model`：指定模型（不传则继承默认）
- `--heartbeat-interval`：心跳间隔分钟数（默认 60）
- `--agent-dir`：极少数情况才需要，不传则不写入此字段
- `--dry-run`：预览变更不写入

脚本执行顺序：
1. 备份 openclaw.json（带时间戳）
2. 在 `agents.list` 追加新 Agent 定义（含 heartbeat + 可选 model）
3. 在父 Agent 的 `subagents.allowAgents` 追加新 agentId（**双向绑定**）
4. 执行 `openclaw config validate`
5. validate 通过 → 在父 Agent MEMORY.md 追加子 Agent 档案 → 继续
   validate 失败 → 自动回滚，报错退出

💡 **首次使用或调试时**，先加 `--dry-run` 预览：
```bash
python3 scripts/register_agent.py --agent-id <agentId> ... --dry-run
```

⚠️ **不要手动改 openclaw.json**，用脚本。

---

## 注销 Agent（废弃 / 员工离职）

```bash
python3 scripts/deregister_agent.py --agent-id <agentId>
# 预览：python3 scripts/deregister_agent.py --agent-id <agentId> --dry-run
```

脚本执行：
1. 从 `agents.list` 移除目标 Agent
2. 从所有父 Agent 的 `allowAgents` 移除该 id（自动扫描，不会遗漏）
3. validate + 回滚机制同注册
4. workspace 存档到 `~/.openclaw/agency-agents/.archived/<agentId>-<时间戳>/`（不删除）

---

## Phase 4 — 重启与验证

### Step 1：验证 workspace 完整性

```bash
bash scripts/verify_workspace.sh <agentId> --type human      # 人伴型
bash scripts/verify_workspace.sh <agentId> --type functional # 功能型
```

脚本执行两层检查：
1. **存在性 + 行数**：文件存在且有足够有效行
2. **内容特征**：
   - 无未填充占位符 `[FILL]` / `[AUTO]`
   - SOUL.md 第一段包含 Agent 名字（从 IDENTITY.md 提取）
   - AGENTS.md 包含边界声明（不做/不处理/边界等关键词）
   - MEMORY.md 公司字段已填写

有 ❌ 或 ⚠️ → 补充后重新验证，通过后再重启。

### Step 2：重启 Gateway

```bash
systemctl --user restart openclaw-gateway.service
sleep 8   # 等待 optional 工具注册完成
```

### Step 3：验证工具可用性

1. 确认新 Agent 在 Gateway 日志里出现
2. 确认 alsoAllow 里的工具已注册（不以"重启完成"作为结束）

### Step 4：首次激活自检

工具验证通过后，通过 `sessions_send` 向新 Agent 发一条激活消息：

```
请读取你的 workspace，用一段话说清楚：你是谁、主要职责是什么、有哪些明确不做的事。
```

收到回应后：
- 检查回应是否包含 Agent 名字、核心职责、边界声明三要素
- 将回应写入新 Agent 的 `memory/<今天日期>.md` 作为第一条记录（标题："首次激活自检"）
- 回应缺少三要素之一 → workspace 有问题，检查对应文件后重新自检

> 自检不是功能测试，是让 Agent 完成第一次自我认知，同时验证 workspace 被正确加载。

⚠️ 以**"自检三要素通过"**作为整个 skill 的完成标志（替代原"工具验证通过"）。

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
