---
layout: post
date: 2025-11-24 08:00:00
updated: 2025-11-24 08:00:00
title: "PowerShell 技能连载 - Obsidian 笔记自动化"
description: PowerTip of the Day - Obsidian Note Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- obsidian
- notes
- markdown
- productivity
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

## 背景

Obsidian 是近年来最受欢迎的本地知识管理工具之一，所有笔记以 Markdown 格式存储在本地文件夹中。这种"文件即数据库"的设计理念使得 Obsidian 天然适合与脚本工具集成。而 PowerShell 作为跨平台的自动化利器，正好可以在 Obsidian 的 vault 目录中高效地批量创建、检索和管理笔记。

在日常使用 Obsidian 的过程中，我们经常面临一些重复性操作：批量整理标签、根据模板创建日记、统计笔记数量、提取待办事项等。手动处理这些任务既耗时又容易出错。借助 PowerShell 脚本，我们可以将这些操作自动化，大幅提升知识管理的效率。

本文将介绍如何使用 PowerShell 与 Obsidian vault 进行交互，涵盖笔记批量创建、内容检索、元数据管理等常见场景，帮助你构建一套自动化的笔记工作流。

## 基础：连接 Obsidian Vault

首先，我们需要定位 Obsidian vault 的路径，并封装一些基础函数以便后续复用。下面的代码定义了 vault 根路径和常用的辅助函数。

```powershell
# 定义 Obsidian vault 路径
$VaultPath = "/Users/wubo/Obsidian/MyVault"

# 检查 vault 是否存在并包含 .obsidian 目录
function Test-Vault {
    param([string]$Path)
    $obsidianDir = Join-Path -Path $Path -ChildPath ".obsidian"
    if ((Test-Path -Path $Path) -and (Test-Path -Path $obsidianDir)) {
        return $true
    }
    return $false
}

# 获取 vault 中所有 Markdown 文件
function Get-VaultNotes {
    param([string]$Path)
    $mdFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -File
    return $mdFiles
}

# 调用示例
if (Test-Vault -Path $VaultPath) {
    $notes = Get-VaultNotes -Path $VaultPath
    Write-Output "Vault 中共有 $($notes.Count) 篇笔记"
    $notes | Select-Object -First 5 | Format-Table Name, Length, LastWriteTime
} else {
    Write-Output "指定的路径不是一个有效的 Obsidian vault"
}
```

执行结果示例：

```text
Vault 中共有 1283 篇笔记

Name                 Length LastWriteTime
----                 ------ -------------
Daily Note 模板.md      482 2025-11-20 09:15:00
MOC - 编程.md          1205 2025-11-22 14:30:00
项目计划.md             876 2025-11-23 10:00:00
读书笔记 - 深度学习.md  2340 2025-11-23 16:45:00
周报 2025-W47.md        650 2025-11-24 08:00:00
```

这段代码的核心思路是利用 `.obsidian` 目录来判断一个文件夹是否为有效的 Obsidian vault，然后递归扫描其中所有的 `.md` 文件。`Get-ChildItem` 配合 `-Recurse` 参数可以遍历所有子文件夹，确保不会遗漏任何笔记。

## 批量创建笔记

当我们需要根据固定模板批量创建笔记时，手动操作既繁琐又容易格式不一致。PowerShell 可以通过字符串模板和文件写入操作，快速生成大量结构化的笔记文件。下面展示如何根据日期范围批量创建日记笔记。

```powershell
# 定义日记模板
$DailyTemplate = @'
---
date: {DATE}
updated: {DATE}
tags:
  - daily-note
  - journal
---

# {DATE} 日记

## 今日计划

-

## 今日完成

-

## 随想

-

## 明日计划

-
'@

# 批量创建指定日期范围的日记
function New-DailyNotes {
    param(
        [Parameter(Mandatory)]
        [string]$VaultPath,
        [Parameter(Mandatory)]
        [DateTime]$StartDate,
        [Parameter(Mandatory)]
        [DateTime]$EndDate
    )

    $dailyDir = Join-Path -Path $VaultPath -ChildPath "Daily Notes"
    if (-not (Test-Path -Path $dailyDir)) {
        New-Item -Path $dailyDir -ItemType Directory | Out-Null
        Write-Output "已创建 Daily Notes 目录"
    }

    $current = $StartDate
    $created = 0

    foreach ($day in @(while ($current -le $EndDate) { $current; $current = $current.AddDays(1) })) {
        $dateStr = $day.ToString("yyyy-MM-dd")
        $fileName = "{0}.md" -f $dateStr
        $filePath = Join-Path -Path $dailyDir -ChildPath $fileName

        if (Test-Path -Path $filePath) {
            Write-Output "跳过已存在: $fileName"
            continue
        }

        $content = $DailyTemplate -replace '\{DATE\}', $dateStr
        Set-Content -Path $filePath -Value $content -Encoding UTF8
        $created++
        Write-Output "已创建: $fileName"
    }

    Write-Output "`n总计创建 $created 篇日记"
}

# 创建本周（周一到周五）的工作日记
$monday = (Get-Date).Date
while ($monday.DayOfWeek -ne [System.DayOfWeek]::Monday) {
    $monday = $monday.AddDays(-1)
}
$friday = $monday.AddDays(4)

New-DailyNotes -VaultPath $VaultPath -StartDate $monday -EndDate $friday
```

执行结果示例：

```text
已创建: 2025-11-24.md
已创建: 2025-11-25.md
已创建: 2025-11-26.md
已创建: 2025-11-27.md
已创建: 2025-11-28.md

总计创建 5 篇日记
```

这段代码使用字符串模板配合 `-replace` 操作符来生成笔记内容。`foreach` 循环遍历日期范围内的每一天，检查文件是否已存在以避免覆盖。模板中的 `{DATE}` 占位符会被实际日期替换。注意 `Set-Content` 使用 UTF8 编码，确保 Obsidian 能正确读取中文内容。

## 笔记内容检索与统计

随着 vault 中笔记数量增长到数百甚至上千篇，手动查找特定内容变得困难。PowerShell 的文本处理能力可以帮我们快速检索笔记内容、提取元数据并生成统计报告。下面是一个综合的笔记分析工具。

```powershell
# 分析 Obsidian vault 中的笔记标签使用情况
function Get-VaultTagStats {
    param(
        [Parameter(Mandatory)]
        [string]$VaultPath
    )

    $notes = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File
    $tagMap = @{}
    $totalTags = 0

    foreach ($note in $notes) {
        $content = Get-Content -Path $note.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }

        # 提取 front matter 中的 tags
        if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
            $frontMatter = $Matches[1]
            $tagLines = $frontMatter -split "`n" | Where-Object { $_ -match '^\s*-\s+' }

            foreach ($line in $tagLines) {
                $tag = ($line -replace '^\s*-\s+', '').Trim()
                if ($tag -and $tag -notmatch '^\s*$') {
                    $totalTags++
                    if ($tagMap.ContainsKey($tag)) {
                        $tagMap[$tag]++
                    } else {
                        $tagMap[$tag] = 1
                    }
                }
            }
        }
    }

    # 按使用次数排序输出
    $results = $tagMap.GetEnumerator() |
        Sort-Object -Property Value -Descending |
        Select-Object -First 20

    Write-Output "=== Vault 标签统计 ==="
    Write-Output "笔记总数: $($notes.Count)"
    Write-Output "标签总数: $totalTags"
    Write-Output "去重标签: $($tagMap.Count)"
    Write-Output ""
    Write-Output "Top 20 标签:"
    Write-Output ("{0,-25} {1,8}" -f "标签", "出现次数")
    Write-Output ("{0,-25} {1,8}" -f "----", "--------")

    foreach ($item in $results) {
        Write-Output ("{0,-25} {1,8}" -f $item.Key, $item.Value)
    }
}

Get-VaultTagStats -VaultPath $VaultPath
```

执行结果示例：

```text
=== Vault 标签统计 ===
笔记总数: 1283
标签总数: 4856
去重标签: 187

Top 20 标签:
标签                       出现次数
----                       --------
powershell                     142
daily-note                     135
project                        98
reading                        87
programming                    76
ai                             65
linux                          54
docker                         43
python                         39
meeting                        36
review                         32
security                       28
network                        25
devops                         23
database                       21
cloud                          19
architecture                   17
book                           15
tip                            14
learning                       12
```

这段代码通过正则表达式提取 Markdown 文件中 YAML front matter 里的标签列表。`$content -match '(?s)^---\r?\n(.*?)\r?\n---'` 这条正则用于匹配 front matter 区域，然后逐行解析其中的标签项。最终使用哈希表进行计数，并按频率排序输出。这种统计方式可以帮助你发现 vault 中的热门主题，以及哪些标签可能需要合并或清理。

## 自动提取待办事项

Obsidian 的待办事项通常以 `- [ ]` 和 `- [x]` 的形式散落在各篇笔记中。手动翻阅所有笔记来汇总待办事项效率极低。PowerShell 可以快速扫描整个 vault，提取未完成的任务并按优先级或文件分组展示。

```powershell
# 从 vault 中提取所有未完成的待办事项
function Get-VaultTodoItems {
    param(
        [Parameter(Mandatory)]
        [string]$VaultPath,
        [switch]$IncludeCompleted
    )

    $notes = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File
    $todoItems = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($note in $notes) {
        $lines = Get-Content -Path $note.FullName -ErrorAction SilentlyContinue
        if ($null -eq $lines) { continue }

        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++

            if ($IncludeCompleted) {
                # 匹配已完成和未完成的待办
                if ($line -match '^\s*-\s+\[([ xX])\]\s+(.+)') {
                    $done = $Matches[1] -match '[xX]'
                    $todoItems += [PSCustomObject]@{
                        File     = $note.Name
                        Line     = $lineNum
                        Done     = $done
                        Task     = $Matches[2].Trim()
                        Relative = $note.FullName.Replace($VaultPath, "").TrimStart("/", "\")
                    }
                }
            } else {
                # 只匹配未完成的待办
                if ($line -match '^\s*-\s+\[\s\]\s+(.+)') {
                    $todoItems += [PSCustomObject]@{
                        File     = $note.Name
                        Line     = $lineNum
                        Task     = $Matches[1].Trim()
                        Relative = $note.FullName.Replace($VaultPath, "").TrimStart("/", "\")
                    }
                }
            }
        }
    }

    return $todoItems
}

# 查找所有未完成的待办事项
$todos = Get-VaultTodoItems -VaultPath $VaultPath

Write-Output "=== 未完成待办事项 ($($todos.Count) 项) ==="
Write-Output ""

$grouped = $todos | Group-Object -Property File |
    Sort-Object -Property Count -Descending |
    Select-Object -First 10

foreach ($group in $grouped) {
    Write-Output "--- $($group.Name) ($($group.Count) 项) ---"
    foreach ($item in $group.Group) {
        Write-Output "  [ ] $($item.Task)"
    }
    Write-Output ""
}
```

执行结果示例：

```text
=== 未完成待办事项 (47 项) ===

--- 项目计划.md (8 项) ---
  [ ] 完成接口文档编写
  [ ] 更新部署脚本
  [ ] 联系运维确认服务器规格
  [ ] 编写单元测试
  [ ] 代码评审反馈修改
  [ ] 性能测试报告
  [ ] 准备周会演示
  [ ] 整理技术方案

--- 读书笔记 - 深度学习.md (5 项) ---
  [ ] 完成第五章习题
  [ ] 复习反向传播算法
  [ ] 实现 CNN 模型
  [ ] 阅读补充材料
  [ ] 整理笔记发布到博客

--- Weekly/周报 2025-W47.md (3 项) ---
  [ ] 提交周报
  [ ] 跟进客户反馈
  [ ] 整理会议纪要
```

这段代码的核心是正则表达式 `^\s*-\s+\[\s\]\s+(.+)`，它匹配 Markdown 中标准的未完成待办格式。通过 `Group-Object` 按文件分组后，可以直观地看到每篇笔记中积压的任务数量。结合 `-IncludeCompleted` 开关，还可以对比已完成和未完成任务的比率，评估自己的执行效率。

## 注意事项

1. **编码问题**：Obsidian 默认使用 UTF-8 编码保存笔记。使用 `Set-Content` 写入文件时务必指定 `-Encoding UTF8`（PowerShell 7 中默认是 UTF8，但显式声明更安全）。如果在 Windows 上遇到中文乱码，检查文件是否被保存为 UTF-8 with BOM。

2. **文件锁定**：当 Obsidian 正在运行时，它会监控 vault 目录的文件变化。PowerShell 写入文件后，Obsidian 通常会在几秒内自动检测到变更。但如果频繁大量写入，建议先关闭 Obsidian 或使用其 URI 协议（`obsidian://`）进行操作，避免索引冲突。

3. **Front Matter 格式**：Obsidian 依赖 YAML front matter 来管理元数据（标签、别名、日期等）。自动生成笔记时要确保 YAML 语法正确，特别是冒号后的空格和列表缩进。建议使用 `ConvertTo-Yaml` 模块或手动拼接字符串，避免格式错误导致 Obsidian 无法解析。

4. **路径分隔符**：PowerShell 7 虽然跨平台，但在处理路径时仍需注意操作系统差异。使用 `Join-Path` 和 `Split-Path` 代替手动拼接路径字符串，确保脚本在 Windows、macOS 和 Linux 上都能正常运行。

5. **备份策略**：在执行批量修改操作前，务必先备份 vault。可以使用 Git 进行版本控制，或者用 PowerShell 创建 zip 备份。批量操作脚本中应加入 `-WhatIf` 支持，先预览将要修改的文件列表，确认无误后再实际执行。

6. **性能考量**：当 vault 中有数千篇笔记时，逐个读取文件内容会比较慢。对于纯文件名或路径相关的操作，优先使用 `Get-ChildItem` 返回的文件信息对象，避免不必要的 `Get-Content` 调用。如果需要全文搜索，考虑先构建索引或使用 `Select-String` 进行流式匹配，而不是将所有文件内容加载到内存中。
