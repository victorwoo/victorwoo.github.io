#!/usr/bin/env python3
"""批量在贡献周期文章中插入 <!-- more --> 标签。

规则：
- 技能连载文章：在引言段落后、第一个 ## 标题之前插入
- 特殊文章（index、community-growth-status）：跳过
- 已包含 <!-- more --> 的文章：跳过
"""

import os
import re
import sys

POSTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'source', '_posts')

# 贡献周期：2025-04 ~ 2026-03
CONTRIBUTION_PREFIXES = ('2025-04', '2025-05', '2025-06', '2025-07', '2025-08',
                         '2025-09', '2025-10', '2025-11', '2025-12',
                         '2026-01', '2026-02', '2026-03')

# 跳过的特殊文章
SKIP_PATTERNS = ('blog-index', 'community-growth-status')


def is_special_article(filename):
    return any(pattern in filename for pattern in SKIP_PATTERNS)


def is_contribution_article(filename):
    return any(filename.startswith(prefix) for prefix in CONTRIBUTION_PREFIXES)


def process_article(filepath):
    """处理单篇文章，返回 (是否修改, 原因)。"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 已有 <!-- more --> 则跳过
    if '<!-- more -->' in content:
        return False, '已有 more 标签'

    # 分离 front matter 和正文
    match = re.match(r'^---\n.*?\n---\n', content, re.DOTALL)
    if not match:
        return False, '无 front matter'

    front_matter = match.group(0)
    body = content[len(front_matter):]

    # 查找第一个 ## 标题的位置
    heading_match = re.search(r'^## ', body, re.MULTILINE)
    if not heading_match:
        return False, '无二级标题'

    # 在第一个 ## 标题前插入
    # 截取标题前的内容，去掉末尾空行
    before_heading = body[:heading_match.start()].rstrip('\n')
    after_heading = body[heading_match.start():]

    # 重组
    new_content = front_matter + before_heading + '\n\n<!-- more -->\n\n' + after_heading

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return True, 'OK'


def main():
    dry_run = '--dry-run' in sys.argv

    files = sorted(os.listdir(POSTS_DIR))
    contribution_files = [f for f in files if f.endswith('.md') and is_contribution_article(f)]

    skipped_special = 0
    skipped_existing = 0
    modified = 0
    errors = 0

    for filename in contribution_files:
        filepath = os.path.join(POSTS_DIR, filename)

        if is_special_article(filename):
            skipped_special += 1
            continue

        with open(filepath, 'r', encoding='utf-8') as f:
            if '<!-- more -->' in f.read():
                skipped_existing += 1
                continue

        if dry_run:
            print(f'[DRY-RUN] {filename}')
            modified += 1
        else:
            changed, reason = process_article(filepath)
            if changed:
                modified += 1
                print(f'[OK] {filename}')
            else:
                errors += 1
                print(f'[SKIP] {filename}: {reason}')

    print(f'\n统计: 修改={modified}, 跳过(特殊)={skipped_special}, '
          f'跳过(已有)={skipped_existing}, 跳过(其他)={errors}')


if __name__ == '__main__':
    main()
