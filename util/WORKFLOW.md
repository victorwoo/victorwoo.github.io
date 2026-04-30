# 批量生成工作流详细文档

## 概述

使用后台 Agent 并行生成博客文章，配合元数据追踪、自动复核和修复循环，确保文章质量。

## 流程图

```
启动 → 生成 Agent（并行）→ 复核脚本 → pass? → done
                                    ↓ fail
                              修复 Agent（带问题清单）
                                    ↓
                              复核脚本 → pass? → done
                                    ↓ fail
                              人工介入
```

## 1. 生成阶段

### 启动 Agent

主线程为每篇文章创建 TaskCreate 任务，然后启动后台 Agent。每批建议 4 个，避免 API 限流。

### 元数据文件

每个 Agent 必须在 `.claude/agent-meta/` 目录下创建 `.meta.json` 文件。

**为什么放在 `.claude/agent-meta/`：**
- `source/_posts/` 下的非 `.md` 文件会被 hexo 当作静态资源复制到 `public/`
- `.claude/` 已在 `.gitignore` 中，不污染版本控制
- 语义上属于 Claude Code 的运行时数据

**文件名格式：** `<markdown-filename>.meta.json`

如 `2025-04-16-powershell-firewall-management.meta.json`

**字段定义：**

```json
{
  "task": "04-16 防火墙规则管理",
  "output_file": "/Users/wubo/Code/home.vichamp.com/source/_posts/2025-04-16-powershell-firewall-management.md",
  "status": "running",
  "start_time": "2026-04-30T17:32:00+08:00",
  "current_stage": "writing_content",
  "stages_completed": ["init", "planning"],
  "error": null,
  "lines": 0,
  "review_result": null,
  "review_issues": [],
  "review_warnings": [],
  "revision_count": 0
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `task` | string | 简短任务描述 |
| `output_file` | string | 目标 Markdown 文件绝对路径 |
| `status` | string | `pending` / `running` / `done` / `failed` / `reviewing` / `revising` |
| `start_time` | string | 实际启动时间（ISO 8601 带时区），**不得用占位时间** |
| `current_stage` | string | 当前阶段名 |
| `stages_completed` | string[] | 已完成阶段列表 |
| `error` | string\|null | 错误信息 |
| `lines` | int | 当前文件行数（verifying 阶段更新） |
| `review_result` | string\|null | 复核结果：`pass` / `pass_with_warnings` / `fail` |
| `review_issues` | string[] | 复核发现的问题 |
| `review_warnings` | string[] | 复核警告 |
| `revision_count` | int | 修复次数 |

### 阶段定义

| 阶段 | 说明 | meta.json 更新要点 |
|------|------|-------------------|
| `init` | 初始化，创建 meta.json | status=running, start_time=当前时间 |
| `planning` | 规划文章结构 | current_stage=planning |
| `writing_content` | 写文章主体 | current_stage=writing_content |
| `linting` | 运行 markdownlint | current_stage=linting |
| `verifying` | 验证行数和格式 | current_stage=verifying, lines=行数 |
| `reviewing` | 复核中（由主线程设置） | status=reviewing |
| `revising` | 修复中（由主线程设置） | status=revising, revision_count++ |
| `done` | 完成 | status=done |

**每次切换阶段必须更新 meta.json。** 遇到错误设 status=failed，error 填错误信息。

### Agent 注意事项

- **必须用 Write 工具**写文件，不要用 Bash heredoc（PowerShell 代码中的 `@{}` 会触发 zsh 安全检查 "expansion obfuscation"）
- **start_time 必须是实际时间**
- 批量启动时每批 4 个 Agent
- Agent 完成后由主线程更新 TaskCreate 状态

## 2. 复核阶段

复核分两层：**脚本复核**（确定性、快速）和 **AI 复核**（质量判断、深度审查）。

### 脚本复核

```bash
# 基础检查（lint、front matter、行数等）
python3 util/review-article.py source/_posts/YYYY-MM-DD-xxx.md

# 同时验证 hexo 渲染
python3 util/review-article.py --hexo source/_posts/YYYY-MM-DD-xxx.md
```

脚本检查维度：

| 检查项 | 级别 | 说明 |
|--------|------|------|
| markdownlint | error | 必须通过，否则 fail |
| front matter 完整性 | error | 缺少 layout/date/title/description/categories/tags 则 fail |
| 基础 tags | error | 缺少 powershell/tip/powertip/series 则 fail |
| 版本说明行 | error | 必须有 `_适用于...` 开头 |
| 代码块内嵌三反引号 | error | 发现则 fail |
| 行数 | error | 不足 200 行则 fail |
| hexo render | error | `--hexo` 时，渲染失败则 fail |
| powershell 代码块数量 | warning | 少于 3 个则警告 |
| 执行结果示例 | warning | 缺少则警告 |
| 背景引入长度 | warning | 不足 50 字则警告 |

### AI 复核

脚本 pass 后，由复核 Agent 做 AI 判断。复核 Agent 应调用脚本获取结果，再追加以下检查：

| 检查项 | 说明 |
|--------|------|
| 内容深度 | 是否只有代码没有说明，背景引入是否有实质内容 |
| 技术准确性 | 代码逻辑是否有明显 bug，API 用法是否正确 |
| 重复度 | 与已有文章的角度是否有所区别 |
| 风格一致性 | 是否符合系列文章的写作风格 |
| 示例质量 | 执行结果示例是否合理，不是随意编造的数字 |

复核 Agent prompt 模板要点：
1. 先运行 `python3 util/review-article.py --hexo <file>` 获取脚本结果
2. 如果脚本报 fail，直接返回 fail + 脚本问题清单
3. 如果脚本报 pass，再读取文章内容做 AI 质量审查
4. 输出 JSON：`{ "result": "pass/fail", "ai_issues": [...], "script_result": {...} }`

### 判定逻辑

脚本判定：
- 有 issues → `fail`
- warnings > 2 → `fail`
- 有 warnings ≤ 2 → `pass_with_warnings`
- 无问题 → `pass`

最终判定：脚本 fail → 直接 fail；脚本 pass → AI 复核决定

### 输出格式

```json
{
  "result": "pass",
  "issues": [],
  "warnings": ["背景引入过短: 38 字"],
  "lines": 321,
  "code_blocks": 5,
  "hexo_render": "ok"
}
```

## 3. 修复阶段

复核 `fail` 的文章：

1. 将 `review_issues` 写入 meta.json
2. 启动修复 Agent，prompt 中包含：
   - 原始文章内容
   - `review_issues` 列表
   - 要求逐一修复
3. 修复完成后重新复核
4. `revision_count` 超过 2 次仍 fail → 人工介入

## 4. 验证阶段

单篇验证在复核阶段通过 `--hexo` 参数完成。全部文章复核通过后，引导用户运行一次完整的 `hexo generate` 做最终批量验证：

```bash
npx hexo clean && npx hexo generate
```

注意：不要自动执行 `hexo deploy`，需要用户确认后再部署。

## 5. 监控脚本

```bash
bash util/monitor-agents.sh
```

- 每 15 秒扫描 `.claude/agent-meta/*.meta.json`
- 输出：图标 + 任务名 | 阶段 | 时长 | 行数
- 通过 Monitor 工具启动（persistent 模式）

### 状态图标

| 图标 | 状态 |
|------|------|
| ⏳ | pending |
| 🔄 | running |
| 🔍 | reviewing |
| ✏️ | revising |
| ✅ | done |
| ❌ | failed |
