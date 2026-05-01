#!/usr/bin/env python3
"""PowerTips 索引生成器

扫描 source/_posts/ 目录，筛选 PowerShell 技能连载文章，生成索引。

模式：
  full   — 重建总索引 2013-09-09-index.md
  annual — 生成年/季度索引文章（MVP 贡献周期：4月1日 到 次年3月31日）
"""

import argparse
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
POSTS_DIR = PROJECT_ROOT / "source" / "_posts"
INDEX_FILE = POSTS_DIR / "2013-09-09-index.md"

# front matter 中标题行的匹配
TITLE_RE = re.compile(r'^title:\s*"?PowerShell 技能连载 - (.+?)"?\s*$')
# 文件名中的日期和 slug
FILENAME_RE = re.compile(r'^(\d{4})-(\d{2})-(\d{2})-([\w-]+)\.md$')
# categories 行
CATEGORIES_RE = re.compile(r'^categories:', re.IGNORECASE)
CATEGORY_ITEM_RE = re.compile(r'^\s*-\s*(.+)$')


def parse_front_matter(filepath):
    """解析 Markdown 文件的 front matter，返回 (metadata_dict, body_str)"""
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # 找到 front matter 边界
    if not lines or lines[0].strip() != "---":
        return {}, ""

    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break

    if end is None:
        return {}, ""

    fm_lines = lines[1:end]
    body = "".join(lines[end + 1:])

    meta = {}
    current_key = None
    current_list = []

    for line in fm_lines:
        # 列表项
        m = CATEGORY_ITEM_RE.match(line)
        if m and current_key:
            current_list.append(m.group(1).strip())
            continue

        # key: value
        kv = re.match(r'^(\w+):\s*(.*)', line)
        if kv:
            # 保存上一个 key 的列表
            if current_key and current_list:
                meta[current_key] = current_list
                current_list = []
            current_key = kv.group(1)
            val = kv.group(2).strip().strip('"').strip("'")
            if val:
                meta[current_key] = val
                current_key = None
                current_list = []
            else:
                current_list = []
        else:
            # 续行或其他
            pass

    # 保存最后一个 key
    if current_key and current_list:
        meta[current_key] = current_list

    return meta, body


def collect_powertips():
    """收集所有 PowerTips 文章，返回列表 [{year, month, day, slug, title}, ...]"""
    articles = []

    for filename in os.listdir(POSTS_DIR):
        if not filename.endswith(".md"):
            continue

        m = FILENAME_RE.match(filename)
        if not m:
            continue

        year, month, day, slug = int(m.group(1)), int(m.group(2)), int(m.group(3)), m.group(4)

        # 跳过索引文件本身
        if filename == "2013-09-09-index.md":
            continue

        filepath = POSTS_DIR / filename
        meta, _ = parse_front_matter(filepath)

        # 筛选 categories 含 powershell 和 tip
        categories = meta.get("categories", [])
        if isinstance(categories, str):
            categories = [categories]
        if "powershell" not in categories or "tip" not in categories:
            continue

        # 提取中文标题
        title_line = meta.get("title", "")
        tm = re.match(r'^PowerShell 技能连载 - (.+)$', title_line)
        if tm:
            cn_title = tm.group(1).strip()
        else:
            cn_title = title_line.strip()

        articles.append({
            "year": year,
            "month": month,
            "day": day,
            "slug": slug,
            "title": cn_title,
            "date": f"{year:04d}-{month:02d}-{day:02d}",
        })

    # 按日期降序排序
    articles.sort(key=lambda a: a["date"], reverse=True)
    return articles


def generate_index_body(articles):
    """从文章列表生成索引 Markdown body"""
    if not articles:
        return ""

    lines = []
    current_year = None
    current_month = None

    for article in articles:
        y, m = article["year"], article["month"]

        if current_year != y:
            current_year = y
            current_month = None
            lines.append("")
            lines.append(f"## {y} 年")

        if current_month != m:
            current_month = m
            lines.append("")
            lines.append(f"### {y:04d} 年 {m:02d} 月")

        url = f"/{y:04d}/{m:02d}/{article['day']:02d}/{article['slug']}"
        lines.append(f"* [{article['date']} {article['title']}]({url})")

    return "\n".join(lines) + "\n"


def write_full_index(articles):
    """重建总索引文件"""
    front_matter = """\
---
layout: post
title: "PowerShell 技能连载 - 汇总索引"
date: 2013-09-09 00:00:00
description: Index of PowerTip of the Day
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---"""

    body = generate_index_body(articles)
    content = front_matter + "\n" + body

    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"总索引已更新：{INDEX_FILE}")
    print(f"共 {len(articles)} 篇文章")


def write_annual_index(articles, date_from, date_to, year_label):
    """生成年度索引文章"""
    # 筛选日期范围内的文章
    from_str = date_from.strftime("%Y-%m-%d")
    to_str = date_to.strftime("%Y-%m-%d")
    filtered = [a for a in articles if from_str <= a["date"] <= to_str]

    if not filtered:
        print(f"日期范围 {from_str} ~ {to_str} 内没有文章")
        return

    # 按日期升序排列（年度索引从新到旧）
    filtered.sort(key=lambda a: a["date"], reverse=True)

    # 确定发布日期（取范围的最后一天）
    publish_date = date_to.strftime("%Y-%m-%d")
    filename = f"{publish_date}-blog-index.md"
    filepath = POSTS_DIR / filename

    front_matter = f"""\
---
layout: post
title: "PowerShell 博客文章汇总 ({date_from.strftime('%Y-%m')} ~ {date_to.strftime('%Y-%m')})"
date: {publish_date} 00:00:00
description: PowerShell blog post collection ({date_from.strftime('%Y-%m')} ~ {date_to.strftime('%Y-%m')})
categories:
- powershell
tags:
- powershell
- tip
- powertip
- series
---"""

    body = generate_index_body(filtered)
    content = front_matter + "\n" + body

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"年度索引已生成：{filepath}")
    print(f"日期范围：{from_str} ~ {to_str}")
    print(f"共 {len(filtered)} 篇文章")


def parse_year_month(s):
    """解析 YYYY-MM 格式"""
    m = re.match(r'^(\d{4})-(\d{2})$', s)
    if not m:
        raise ValueError(f"无效的日期格式：{s}，应为 YYYY-MM")
    return int(m.group(1)), int(m.group(2))


def mvp_period(year):
    """计算 MVP 贡献周期：(year-1)年4月1日 ~ year年3月31日"""
    from datetime import date
    return date(year - 1, 4, 1), date(year, 3, 31)


def main():
    parser = argparse.ArgumentParser(description="PowerTips 索引生成器")
    parser.add_argument("--mode", choices=["full", "annual"], default="full",
                        help="生成模式：full=总索引，annual=年度索引")
    parser.add_argument("--year", type=int, default=None,
                        help="年度索引的目标年份（MVP周期：前一年4月 ~ 当年3月）")
    parser.add_argument("--from", dest="date_from", default=None,
                        help="年度索引起始月份 (YYYY-MM)")
    parser.add_argument("--to", dest="date_to", default=None,
                        help="年度索引结束月份 (YYYY-MM)")

    args = parser.parse_args()

    articles = collect_powertips()
    if not articles:
        print("未找到任何 PowerTips 文章")
        sys.exit(1)

    if args.mode == "full":
        write_full_index(articles)

    elif args.mode == "annual":
        from datetime import date

        if args.date_from and args.date_to:
            fy, fm = parse_year_month(args.date_from)
            ty, tm = parse_year_month(args.date_to)
            d_from = date(fy, fm, 1)
            # 结束月份的最后一天
            if tm == 12:
                d_to = date(ty, 12, 31)
            else:
                d_to = date(ty, tm + 1, 1)
                d_to = date(d_to.year, d_to.month, 1)
                from datetime import timedelta
                d_to = d_to - timedelta(days=1)
            label = str(ty)
        elif args.year:
            d_from, d_to = mvp_period(args.year)
            label = str(args.year)
        else:
            # 默认使用当前年份
            current_year = datetime.now().year
            d_from, d_to = mvp_period(current_year)
            label = str(current_year)

        write_annual_index(articles, d_from, d_to, label)


if __name__ == "__main__":
    main()
