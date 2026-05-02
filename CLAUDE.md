# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Hexo 静态博客，域名 blog.vichamp.com，通过 GitHub Pages 托管。
线上网站：https://blog.vichamp.com/ — 这是需要确保正确无误的最终产出。

## 部署架构

```
source/_posts/*.md  →  hexo generate  →  public/  →  hexo deploy  →  victorwoo.github.io (master)
                                                                      ↓
                                                              blog.vichamp.com (CNAME)
```

- **仓库**: `victorwoo/victorwoo.github.io`
- **source 分支**: Hexo 源码（Markdown、主题、配置），开发工作在此分支
- **master 分支**: `hexo deploy` 产出的静态网站，GitHub Pages 直接托管
- **DNS**: `blog.vichamp.com` → CNAME → `victorwoo.github.io`

## 常用命令

```bash
npm install            # 安装依赖
npx hexo server        # 本地预览 http://localhost:4000
npx hexo generate      # 生成静态文件到 public/
npx hexo deploy        # 部署到 master 分支
npx hexo clean         # 清除缓存和生成文件
npx hexo new post "标题"  # 新建文章

markdownlint source/_posts/YYYY-MM-DD-*.md  # Lint 单篇文章
```

## 关键配置

- **主题**: icarus (`hexo-theme-icarus`)
- **语言**: zh-CN
- **文章命名**: `_config.yml` 中 `new_post_name: ':year-:month-:day-:title.md'`
- **永久链接格式**: `:year/:month/:day/:title/`
- **部署目标**: `git@github.com:victorwoo/victorwoo.github.io.git` → master 分支

## 主题定制（patch-package）

icarus 主题通过 npm 安装，自定义修改存放在 `node_modules/` 中，使用 `patch-package` 管理。`npm install` 后会自动执行 `postinstall` 脚本应用补丁。

### 当前补丁

| 补丁文件 | 修改内容 |
|----------|----------|
| `patches/hexo-theme-icarus+6.1.1.patch` | 新增 `qq-group` widget，在侧边栏展示 QQ 群二维码 |

### QQ 群 widget 配置

在 `_config.icarus.yml` 的 `widgets` 中添加：

```yaml
- position: left
  type: qq-group
  img_url: /img/qr-qq-group.png
  link_url: https://qm.qq.com/q/BMzkmLNUD6
  title: PowerShell 技术 QQ 群
```

### 主题升级流程

1. 修改 `package.json` 中 `hexo-theme-icarus` 的版本号
2. 运行 `npm install`
3. 检查 `patches/` 下的补丁是否仍然适用：
   - 如果 patch 应用成功 → 无需操作
   - 如果 patch 冲突 → 删除旧 patch，手动将自定义修改重新应用到新版 `node_modules`，然后运行 `npx patch-package hexo-theme-icarus` 重新生成 patch
4. 运行 `hexo generate` 验证渲染正常

## 目录结构要点

```
source/_posts/     ← 博客文章 Markdown 文件（约 2184 篇）
source/_drafts/    ← 草稿
scaffolds/         ← 文章模板
themes/            ← Hexo 主题
util/              ← PowerShell/Bash 工具脚本
_config.yml        ← Hexo 主配置
```

## 写作规范（必须遵循）

### Markdown Lint

每篇文章必须通过 `markdownlint` 检查。项目根目录有 `.markdownlint.json` 配置文件。

### Hexo 编译验证

每完成一批文章（约 5-10 篇）后，必须运行以下命令验证生成无错误：

```bash
npx hexo clean && npx hexo generate
```

注意：主题本身会产生大量 ERROR（sidebar widget 问题），这是已知问题，非新文章引起。验证时关注是否有新增的 ERROR 类型。

**验证原则**：Hexo 全量生成耗时较长（约 2-5 分钟），验证时应尽量局部验证（单篇文章 `markdownlint`、检查生成后的单个 HTML 文件），降低迭代成本。待局部验证无误后再全量 `hexo generate`。

### 代码块安全

Markdown 代码块内的 PowerShell here-string（`@"..."@`）中**不得**嵌入三反引号（` ``` `），否则会被 Markdown 解析器误认为代码围栏结束，导致渲染断裂。应改用数组拼接等方式。

### 文章格式

```yaml
---
layout: post
date: YYYY-MM-DD 08:00:00
updated: YYYY-MM-DD 08:00:00
title: "PowerShell 技能连载 - 中文标题"
description: PowerTip of the Day - English Title
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- <content-specific-tags>
---
```

- 文件名格式：`YYYY-MM-DD-english-slug.md`
- 每个工作日一篇
- 内容以 PowerShell 技术为主，适当结合当时互联网热点（AIGC、LLM、Browser Using、容器化、DevOps 等）
- 代码块使用标准 Markdown 围栏语法

### Tags 规范

每篇文章必须包含基础 tags，再根据文章内容添加主题相关的 tags，使用 **kebab-case** 格式：

- **基础 tags**（每篇必有）：`powershell`、`tip`、`powertip`、`series`
- **内容 tags**（按文章主题添加），示例：
  - AI 相关：`ai`、`llm`、`openai`、`ollama`、`local-llm`
  - 浏览器相关：`browser-automation`、`selenium`、`playwright`
  - 安全相关：`security`、`audit`、`baseline`
  - 容器相关：`docker`、`container`、`devops`
  - 配置相关：`json`、`yaml`、`config-management`
  - 网络相关：`network`、`api`、`rest-api`

### 文章内容规范

每篇文章必须包含以下结构，不得只贴代码：

1. **开头**：一行适用版本说明（如 `_适用于 PowerShell 7.0 及以上版本_`）
2. **背景引入**：1-3 段文字，说明主题的背景和为什么需要这个技术
3. **正文**：每个代码块前后都要有文字说明，解释代码做什么、为什么这样写
4. **执行结果示例**：每个主要代码块后附上模拟的执行输出（用普通代码块，不加 `powershell` 标记），让读者知道运行结果长什么样
5. **注意事项**：文末总结使用要点和坑点

### 摘要截断（`<!-- more -->`）

列表页只显示文章摘要，点击"阅读更多"进入详情页查看全文。通过在文章中插入 `<!-- more -->` 标签实现：

- **技能连载文章**：在引言段落之后、第一个 `## ` 标题之前插入
- **特殊文章**（索引、社区成长等）：不插入，保持全文显示
- **新文章**：写作时即应包含 `<!-- more -->` 标签

批量插入工具：`python3 util/add-more-tag.py`

## 数据源说明

| 数据源 | 状态 |
|--------|------|
| **victorwoo.github.io** (当前仓库) | **权威来源**，source 分支有完整 2184 篇文章 |
| 旧本地目录 `/Users/wubo/blog.vichamp.com` | 已确认与当前仓库内容一致，可不再关注 |
| `blog.vichamp.com` GitHub 仓库 | **已淘汰**，缺少 2017-2025 年的文章 |

### 内容去重

写新文章时，先用 `grep` 快速扫描 `source/_posts/` 目录，避免与已有文章主题高度重复。如果不可避免有部分重叠，可以接受，但角度或示例应有所区别。

### 进度可视化

生成批量文章时，使用 TaskCreate 跟踪每篇文章的状态，每完成一篇立即标记 completed，让用户随时了解进度。

## 批量生成工作流

详细流程见 `util/WORKFLOW.md`，以下为核心规则：

### 流程：生成 → 复核 → 修复 → 验证

1. **生成**：后台 Agent 并行写文章，每阶段更新 `.claude/agent-meta/*.meta.json`
2. **复核**：生成完成后运行 `python3 util/review-article.py <file>`，检查 lint、front matter、tags、行数、代码块安全等
3. **修复**：复核 fail 的文章，将问题清单注入新 Agent 重新生成
4. **验证**：全部 pass 后统一 `hexo generate`

### 元数据

- 路径：`.claude/agent-meta/<filename>.meta.json`（不放 source/_posts，避免影响 hexo）
- 阶段：init → planning → writing_content → linting → verifying → reviewing → done
- 每次切换阶段必须更新 meta.json，`start_time` 必须是实际时间
- 复核结果写入 `review_result` 字段：`pass` / `pass_with_warnings` / `fail`

### 监控

```bash
bash util/monitor-agents.sh    # 通过 Monitor 工具启动（persistent 模式）
```

### Agent 约束

- **必须用 Write 工具**写文件，不要用 Bash heredoc（`@{}` 触发 zsh 安全检查）
- 每批 4 个 Agent，避免 API 限流
- Agent 完成后由主线程更新 TaskCreate 状态

## 工作流程

1. 在 `source/_posts/` 编写或修改 Markdown 文章
2. `markdownlint` 检查格式
3. `hexo generate` 验证生成（每批 5-10 篇验证一次）
4. `hexo server` 本地预览
5. `hexo deploy` 推送到 master → GitHub Pages

## 验证原则

- **局部验证优先**：修改后先检查具体影响的文件（如 `public/` 中对应的 HTML），确认无误后再全量 `hexo generate`
- **全量生成耗时**：2470 篇文章全量生成约需 2 分钟，应减少全量生成次数
