#!/usr/bin/env python3
"""
文章复核脚本 - 检查生成的博客文章质量
用法: python3 util/review-article.py [--hexo] <article.md>
  --hexo: 同时运行 hexo render 验证单篇文章渲染
返回: JSON 格式的复核结果
"""
import json
import os
import re
import sys
import subprocess

def check_markdownlint(filepath):
    """运行 markdownlint 检查"""
    result = subprocess.run(
        ['markdownlint', filepath],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return [f"markdownlint 失败: {result.stdout.strip()}"]
    return []

def check_front_matter(content):
    """检查 front matter 完整性和基础 tags"""
    issues = []
    warnings = []

    if not content.startswith('---'):
        issues.append("缺少 front matter")
        return issues, warnings

    fm_end = content.find('---', 3)
    if fm_end == -1:
        issues.append("front matter 未正确关闭")
        return issues, warnings

    fm = content[3:fm_end]
    required = ['layout:', 'date:', 'title:', 'description:', 'categories:', 'tags:']
    for field in required:
        if field not in fm:
            issues.append(f"front matter 缺少字段: {field}")

    base_tags = ['powershell', 'tip', 'powertip', 'series']
    for tag in base_tags:
        if f'- {tag}' not in fm:
            warnings.append(f"缺少基础 tag: {tag}")

    return issues, warnings

def check_version_line(content):
    """检查版本说明行"""
    if not re.search(r'^_适用于', content, re.MULTILINE):
        return ["缺少版本说明行（如 _适用于 PowerShell 7.0_）"]
    return []

def check_code_block_safety(lines):
    """检查代码块内嵌三反引号"""
    issues = []
    in_code_block = False
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith('```') and not in_code_block:
            in_code_block = True
            continue
        if stripped == '```' and in_code_block:
            in_code_block = False
            continue
        if in_code_block and stripped == '```':
            issues.append(f"第 {i} 行: 代码块内嵌三反引号")
    return issues

def check_line_count(lines):
    """检查行数"""
    if len(lines) < 200:
        return [f"行数不足: {len(lines)} 行（要求 200+）"]
    return []

def check_code_blocks(content):
    """检查 powershell 代码块数量"""
    code_blocks = len(re.findall(r'^```powershell', content, re.MULTILINE))
    warnings = []
    if code_blocks < 3:
        warnings.append(f"powershell 代码块过少: {code_blocks} 个（建议 3+）")
    return warnings, code_blocks

def check_result_examples(content):
    """检查执行结果示例"""
    result_blocks = len(re.findall(r'^```\s*$', content, re.MULTILINE))
    if result_blocks < 2:
        return ["缺少执行结果示例（普通代码块）"]
    return []

def check_intro_length(content):
    """检查背景引入长度"""
    fm_end = content.find('---', 3)
    if fm_end == -1:
        return []

    after_fm = content[fm_end+3:].strip()
    first_para = []
    for line in after_fm.split('\n'):
        if line.strip().startswith('_') or line.strip().startswith('#'):
            continue
        if line.strip():
            first_para.append(line.strip())
        elif first_para:
            break

    intro_text = ''.join(first_para)
    if len(intro_text) < 50:
        return [f"背景引入过短: {len(intro_text)} 字（建议 50+）"]
    return []

def check_hexo_render(filepath):
    """运行 hexo render 验证单篇文章能否正确渲染"""
    issues = []
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(filepath)))

    result = subprocess.run(
        ['npx', 'hexo', 'render', filepath],
        capture_output=True, text=True,
        cwd=project_root,
        timeout=30
    )
    if result.returncode != 0:
        stderr = result.stderr.strip()
        issues.append(f"hexo render 失败: {stderr[-200:] if len(stderr) > 200 else stderr}")
    return issues

def review_article(filepath, run_hexo=False):
    issues = []
    warnings = []

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

    # 1. markdownlint
    issues.extend(check_markdownlint(filepath))

    # 2. Front matter
    fm_issues, fm_warnings = check_front_matter(content)
    issues.extend(fm_issues)
    warnings.extend(fm_warnings)

    # 3. 版本说明行
    issues.extend(check_version_line(content))

    # 4. 代码块安全
    issues.extend(check_code_block_safety(lines))

    # 5. 行数
    issues.extend(check_line_count(lines))

    # 6. 代码块数量
    code_warnings, code_blocks = check_code_blocks(content)
    warnings.extend(code_warnings)

    # 7. 执行结果示例
    warnings.extend(check_result_examples(content))

    # 8. 背景引入
    warnings.extend(check_intro_length(content))

    # 9. hexo render（可选）
    hexo_ok = True
    if run_hexo:
        hexo_issues = check_hexo_render(filepath)
        issues.extend(hexo_issues)
        if hexo_issues:
            hexo_ok = False

    # 判定结果
    if issues:
        result = 'fail'
    elif len(warnings) > 2:
        result = 'fail'
    elif warnings:
        result = 'pass_with_warnings'
    else:
        result = 'pass'

    output = {
        'result': result,
        'issues': issues,
        'warnings': warnings,
        'lines': len(lines),
        'code_blocks': code_blocks,
    }
    if run_hexo:
        output['hexo_render'] = 'ok' if hexo_ok else 'fail'

    return output

if __name__ == '__main__':
    run_hexo = '--hexo' in sys.argv
    args = [a for a in sys.argv[1:] if a != '--hexo']

    if not args:
        print("用法: python3 util/review-article.py [--hexo] <article.md>")
        print("  --hexo: 同时运行 hexo render 验证渲染")
        sys.exit(1)

    result = review_article(args[0], run_hexo=run_hexo)
    print(json.dumps(result, ensure_ascii=False, indent=2))

    if result['result'] == 'fail':
        sys.exit(1)
    else:
        sys.exit(0)
