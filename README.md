# create-agent

[OpenClaw](https://github.com/openclaw/openclaw) 的 Agent 创建标准流程。把"创建一个好 Agent"拆成四个 Phase，能自动化的自动化，必须判断的有明确引导。

```bash
clawhub install openclaw-create-agent
```

---

## 解决什么问题

在 OpenClaw 里注册一个 Agent 只需几行配置，但创建一个**好用的** Agent 需要正确处理：

- **workspace 结构**：7+ 个文件各有职责，漏写会影响行为
- **两类 Agent 差异**：人伴型和功能型的 workspace 结构完全不同
- **SOUL.md 质量**：写成通用模板 = 没有灵魂
- **系统注册安全**：改 openclaw.json 出错，所有 Agent 跟着挂
- **持续进化**：Agent 需要在使用中积累知识，不是创建完就定型

---

## 两类 Agent

| | 人伴型（员工型） | 功能型（任务/领域型） |
|---|---|---|
| **面向** | 有真人用户直接对话 | 面向任务，可被调度 |
| **SOUL.md** | 骨架 → BOOTSTRAP 首次对话填充 | 创建时直接写完整版 |
| **BOOTSTRAP.md** | ✅ 动态对话初始化 | ❌ |
| **USER.md** | ✅ 积累用户知识 | ❌ |
| **AGENTS.md 重点** | 场景触发规则 | 任务接口规范 |
| **记忆规则** | P0/P1 分层，偏好人为主 | P0/P1 分层，偏任务知识 |
| **脚本参数** | `--type human` | `--type functional` |

**核心设计**：skill 负责骨架，BOOTSTRAP.md（人伴型专属）负责灵魂。workspace 的质量由使用中的持续积累决定，不由创建时决定。

---

## 四 Phase 流程

### Phase 0 — 组织背景配置（一次性）

写入组织背景到 `~/.openclaw/workspace/agents-config/org-context.md`，含 30 天有效期提醒。后续创建 Agent 自动读取，不再重复询问。

### Phase 1 — 信息收集

**快速路径**（刚配对的员工，无额外要求）：只收集 3 项（agentId、open_id、工具权限），其余自动处理。

**详细收集**：先定类型（第一个确认），再按类型收集 agentId、名字、核心职责、边界、父 Agent、工具权限。功能型额外收集判断偏向、输入模糊处理、质量标准。

### Phase 2 — Workspace 构造

人伴型走 `references/human-path.md`（A-1 到 A-9），功能型走 `references/functional-path.md`（B-1 到 B-9）。

**人伴型关键步骤**：
- A-2：AI 根据飞书姓名生成名字和 SOUL.md 骨架
- A-5：AGENTS.md 字数控制（500 字上限），场景规则优先
- A-8：从 `bootstrap-protocol.md` 生成完整 BOOTSTRAP.md（覆盖占位符）

**功能型关键步骤**：
- B-3：SOUL.md 完整版（含判断偏向和工作执念）
- B-5：AGENTS.md 任务接口规范

### Phase 3 — 系统注册

```bash
python3 scripts/register_agent.py \
  --agent-id <agentId> \
  --workspace ~/.openclaw/agency-agents/<agentId> \
  --parent-id <父AgentId> \
  --agent-type human \
  --core-duty "核心职责" \
  --also-allow feishu_get_user feishu_im_user_message
```

脚本自动：备份 openclaw.json → 写入 agents.list → 双向绑定 allowAgents → validate → 失败自动回滚 → 通过则预埋父 Agent MEMORY.md 档案。

### Phase 4 — 重启验证

```bash
# 验证 workspace（按类型跳过合法占位）
bash scripts/verify_workspace.sh <agentId> --type human

# 重启 Gateway
# 验证工具可用性
# 首次激活自检（sessions_send 发测试消息）
# 边界场景行为验证
```

以"自检三要素通过 + 场景行为验证通过"作为完成标志。

---

## 记忆系统

### P0/P1 分层

| 优先级 | 触发条件 | 写入位置 |
|---|---|---|
| **P0 必须写入** | 用户说"记住这个"、纠正记录、重要决策 | 直接写 MEMORY.md 或 USER.md |
| **P1 观察积累** | 偏好、工作流、判断倾向、术语习惯 | 先写 memory/日记，Heartbeat 时决定是否提升 |

P1 提升条件：同类信息在不同日期出现 2 次以上，或用户后续行为验证了有效性。

### 记忆规则文件

记忆规则写入独立文件 `memory-rules.md`（~200 字符），AGENTS.md 只保留引用句。释放的 ~400 字空间留给场景规则使用。

### Heartbeat 精炼

每 3 天扫描最近 3 天日记，提炼稳定知识进 USER.md/MEMORY.md，清理过时内容。

---

## Workspace 成熟度

每 7 天评估一次（Heartbeat 中执行），三个维度：

| 维度 | 检查内容 | 权重 |
|---|---|---|
| 用户画像完整度 | 称呼、岗位、≥2偏好、≥1工作背景 | 30% |
| 业务知识积累度 | 公司背景、≥1客户/项目、≥1业务规则 | 40% |
| SOUL.md 个性度 | 具体厌恶点、行为描述、200-600字 | 30% |

成熟度 < 30 → 预警；30-70 → 正常；> 70 → 积累良好。评估结果写入 `memory/.health`。

---

## 进化里程碑

| 阶段 | 达成条件 | 成熟度参考 |
|---|---|---|
| 🌱 种子 | 创建完成，workspace 完整 | 0-20 |
| 📋 知道你是谁 | BOOTSTRAP 完成，有性格有偏好 | 20-40 |
| 🔍 理解你的工作 | 2-4 周，有业务判断积累 | 40-70 |
| 🎯 不用你说就知道 | 主动提供信息，无需重复解释 | 70+ |

---

## BOOTSTRAP（人伴型专属）

用户首次对话时自动触发。不是问卷，是自然对话：

1. 第一轮 3-4 个浅层问题（岗位、称呼、厌恶、语言）
2. 后续每次只问一个，动态选择最有价值的追问方向
3. 写入分两批：先结构化文件（IDENTITY/USER/AGENTS/MEMORY），再叙事文件（SOUL.md）
4. SOUL.md 写完后做共情验证（转述测试），不合格则重写
5. 全部通过后删除 BOOTSTRAP.md

支持断点续接（`memory/.bootstrap-progress.json`，含 write_stage 字段）。

---

## 脚本

| 脚本 | 用途 | 关键参数 |
|---|---|---|
| `create_workspace.sh` | 创建骨架文件 | `--type human\|functional` `--notify-open-id` |
| `register_agent.py` | 安全注册到 openclaw.json | `--dry-run` `--model` `--heartbeat-interval` |
| `deregister_agent.py` | 注销（workspace 存档） | `--dry-run` |
| `verify_workspace.sh` | 两层验证 | `--type human\|functional` |

---

## 文件结构

```
create-agent/
├── SKILL.md                          # 触发条件 + 四 Phase 流程
├── references/
│   ├── file-formats.md               # 每个 workspace 文件"写好"的标准
│   ├── soul-writing-guide.md         # SOUL.md 写作指南
│   ├── evolve-rules.md               # 持续生长规则（P0/P1 触发表）
│   ├── memory-rules.md               # 记忆规则精简模板
│   ├── human-path.md                 # 人伴型 Phase 2 步骤
│   ├── functional-path.md            # 功能型 Phase 2 步骤
│   └── bootstrap-protocol.md        # BOOTSTRAP 对话协议
└── scripts/
    ├── create_workspace.sh
    ├── register_agent.py
    ├── deregister_agent.py
    └── verify_workspace.sh
```

---

## 典型用法

### 快速创建员工 Agent

```
说："创建 agent，刚配对的员工，open_id 是 ou_xxx"
```

AI 自动走快速路径：收集 3 项 → 生成 workspace → 注册 → 验证 → 激活。

### 创建专业功能型 Agent

```
说："创建一个数据分析 Agent"
```

AI 走详细收集：类型确认 → 判断偏向 → 质量标准 → 完整 SOUL.md → 注册验证。

### 注销 Agent

```bash
python3 scripts/deregister_agent.py --agent-id <agentId> --dry-run
```

---

## 依赖

- OpenClaw >= 2026.3.0
- `openclaw` CLI（config validate）
- `systemctl --user`（Gateway 重启）
- Python 3.10+
