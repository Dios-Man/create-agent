# create-agent

> 基于 [OpenClaw](https://github.com/openclaw/openclaw) 的 AgentSkill

OpenClaw skill：创建 Agent 及 Workspace 的完整流程工具。

## 功能

自动化完成新 Agent 的全套创建流程：

- **Phase 0** — 安装后配置（一次性，写入组织背景到 `config/org-context.md`）
- **Phase 1** — 信息收集（Agent 类型【第一确认】/ agentId / 工具权限 / 父 Agent）
- **Phase 2** — Workspace 构造（SOUL.md / AGENTS.md / BOOTSTRAP.md 等全套文件，按类型走不同路径）
- **Phase 3** — 系统注册（安全修改 openclaw.json，备份 + 双向绑定 + validate + 回滚；支持 --dry-run）
- **Phase 4** — 重启验证（workspace 文件完整性验证 + 工具可用性验证）

## 核心设计理念

> **skill 负责骨架，BOOTSTRAP.md 负责灵魂。**

### 两类 Agent

| 维度 | 人伴型（员工型） | 功能型（任务/领域型） |
|---|---|---|
| **面向谁** | 有真人用户直接对话 | 面向任务，可被 Agent 调度或人直接用 |
| **SOUL.md** | 写骨架，BOOTSTRAP 阶段填充 | 直接写完整版，体现专业判断倾向 |
| **BOOTSTRAP.md** | ✅ 需要 | ❌ 不需要 |
| **USER.md** | ✅ 需要 | ❌ 不需要 |
| **脚本参数** | `--type human` | `--type functional` |

- skill 产出可运行的 Agent（系统层 + workspace 骨架）
- BOOTSTRAP.md 通过动态对话（支持断点续接）完成 workspace 内容层定制
- workspace 从真实使用中持续生长（触发式写入 + heartbeat 精炼）

## 文件结构

```
create-agent/
├── SKILL.md                          # 触发条件 + 四 Phase 执行流程
├── config/
│   └── org-context.md               # 组织背景预埋（Phase 0 生成，不推送到 repo）
├── references/
│   ├── file-formats.md               # 每个 workspace 文件"写好"的标准
│   ├── soul-writing-guide.md         # SOUL.md 素材→叙事的组织方法
│   ├── evolve-rules.md               # workspace 持续生长规则
│   └── bootstrap-protocol.md        # BOOTSTRAP.md 动态对话协议蓝本（含断点续接）
└── scripts/
    ├── create_workspace.sh           # 创建目录结构（支持 --type human|functional）
    ├── register_agent.py             # 安全注册（备份+双向绑定+validate+回滚+dry-run）
    └── verify_workspace.sh           # workspace 完整性验证（Phase 4 使用）
```

## 安装

需要先安装 [OpenClaw](https://github.com/openclaw/openclaw)。

```bash
clawhub install openclaw-create-agent
```

或手动克隆到 `~/.openclaw/skills/create-agent/`。

## 触发

在 OpenClaw 对话中说：
- "创建 agent"
- "新建 agent"
- "新员工配对后创建 agent"
- "新增专业 agent"

## 依赖

- OpenClaw >= 2026.3.0
- `openclaw` CLI（用于 config validate）
- `systemctl --user`（用于 Gateway 重启）
