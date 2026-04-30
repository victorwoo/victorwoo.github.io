#!/bin/bash
# Agent 进度监控脚本
# 每 15 秒扫描 .claude/agent-meta/ 下的 .meta.json 文件，输出进度面板
# 用法: bash util/monitor-agents.sh

META_DIR="/Users/wubo/Code/home.vichamp.com/.claude/agent-meta"

while true; do
    jsons=$(ls "$META_DIR"/*.meta.json 2>/dev/null)
    if [ -z "$jsons" ]; then
        sleep 15
        continue
    fi

    # 用单个 python3 调用批量处理所有 meta 文件
    python3 -c "
import json, os, sys
from datetime import datetime

meta_dir = '$META_DIR'
icons = {'pending': '⏳', 'running': '🔄', 'completed': '✅', 'done': '✅', 'failed': '❌', 'reviewing': '🔍', 'revising': '✏️'}

results = []
for fname in sorted(os.listdir(meta_dir)):
    if not fname.endswith('.meta.json'):
        continue
    path = os.path.join(meta_dir, fname)
    try:
        with open(path) as f:
            d = json.load(f)
    except:
        continue

    task = d.get('task', '?')
    status = d.get('status', '?')
    start = d.get('start_time', '')
    stage = d.get('current_stage', '')
    md_file = d.get('output_file', '')
    error = d.get('error') or ''
    review = d.get('review_result', '')

    lines = 0
    if md_file:
        try:
            with open(md_file) as f:
                lines = sum(1 for _ in f)
        except:
            pass

    elapsed = ''
    if start:
        try:
            s = datetime.fromisoformat(start.replace('Z', '+00:00'))
            e = datetime.now(s.tzinfo)
            d_sec = (e - s).total_seconds()
            if abs(d_sec) < 60: elapsed = f'{abs(d_sec):.0f}s'
            elif abs(d_sec) < 3600: elapsed = f'{abs(d_sec)/60:.1f}min'
            else: elapsed = f'{abs(d_sec)/3600:.1f}h'
        except:
            elapsed = '?'

    icon = icons.get(status, '❓')
    line = f'{icon} {task} | {stage} | {elapsed} | {lines}行'
    if error:
        line += f' | ⚠️ {error}'
    if review:
        line += f' | 复核: {review}'
    results.append(line)

if results:
    print(f'Agent 进度 $(date '+\"%H:%M:%S\"')')
    for r in results:
        print(f'  {r}')
" 2>/dev/null

    sleep 15
done
