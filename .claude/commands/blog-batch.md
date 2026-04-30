# 批量博客创作

批量生成多篇 PowerShell 技能连载博客，使用后台 Agent 并行执行，配合元数据追踪、进度监控和自动复核。

## 参数

- $ARGUMENTS: 自然语言日期范围（如 "2025-04-01 至今的所有工作日"、"最后一篇文章至今"、"4月"、"本月剩余工作日"）

## 执行流程

### 1. 解析日期范围

将自然语言转为具体日期列表：

- "至今" → 用当前日期
- "最后一篇文章至今" → 扫描 `source/_posts/` 找最新文件名中的日期，计算到今天
- "4月" / "2025-04" → 该月所有工作日
- "本月剩余工作日" → 今天到月末的工作日
- 具体日期范围如 "2025-04-01 至 2025-04-30"

排除周末（周六、周日），只保留工作日。

### 2. 去重

扫描已有文章，排除已有对应日期的：
```bash
ls source/_posts/YYYY-MM-DD-*.md
```

输出待生成清单，包括日期和建议主题。

### 3. 确认

向用户展示待生成清单（日期 + 主题），确认后开始。如果用户想调整主题，在此步修改。

### 4. 启动监控

```bash
# 通过 Monitor 工具启动（persistent 模式）
bash util/monitor-agents.sh
```

### 5. 批量生成

每批 4 个 Agent 并行启动，每个 Agent 遵循以下规范：

**元数据**：在 `.claude/agent-meta/` 创建 `YYYY-MM-DD-xxx.meta.json`，每阶段更新：
- 阶段：init → planning → writing_content → linting → verifying → done
- `start_time` 必须是实际时间（ISO 8601 带时区）
- 遇到错误设 status=failed，error 填错误信息

**文章**：用 Write 工具创建，遵循 CLAUDE.md 写作规范（front matter、tags、版本说明、背景引入、代码块+说明、执行结果、注意事项，不少于 200 行）

**验证**：Agent 内部运行 `markdownlint` 检查

### 6. 复核

每篇 Agent 完成后，运行复核：
```bash
python3 util/review-article.py --hexo source/_posts/YYYY-MM-DD-xxx.md
```

如果 fail，将问题清单注入修复 Agent 重新生成，最多重试 2 次。仍 fail 则标记为需人工介入。

### 7. 汇总报告

输出最终结果：
- ✅ 通过的文章列表（路径 + 行数）
- ❌ 失败的文章列表 + 问题
- 总计生成数量

### 8. 引导最终验证

提醒用户运行：
```bash
npx hexo clean && npx hexo generate
```

不要自动执行 `hexo deploy`。
