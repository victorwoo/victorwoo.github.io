# 博客索引生成

生成 PowerTips 文章索引，支持总索引和年度（MVP 贡献周期）索引。

## 参数

- $ARGUMENTS: 索引模式
  - 空 或 `full`：更新总索引 `2013-09-09-index.md`
  - `annual`：生成当年 MVP 周期索引（4月1日 ~ 次年3月31日）
  - `annual --year 2026`：生成指定年份的 MVP 周期索引
  - `annual --from 2025-04 --to 2026-04`：自定义日期范围

## 执行流程

### 1. 运行索引生成脚本

```bash
python3 util/generate-index.py --mode <模式> [--year YYYY | --from YYYY-MM --to YYYY-MM]
```

### 2. Lint 验证

```bash
markdownlint source/_posts/2013-09-09-index.md
```

年度索引还需验证对应文件：

```bash
markdownlint source/_posts/YYYY-MM-DD-blog-index.md
```

### 3. 展示统计

确认生成的文章数量和日期范围。

## MVP 贡献周期

每年 4月1日 到 次年3月31日为一个 MVP 贡献周期。例如：
- `--year 2026` 生成 2025-04-01 ~ 2026-03-31 的索引
- `--year 2025` 生成 2024-04-01 ~ 2025-03-31 的索引
