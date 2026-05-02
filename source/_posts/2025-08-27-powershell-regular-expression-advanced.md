---
layout: post
date: 2025-08-27 08:00:00
updated: 2025-08-27 08:00:00
title: "PowerShell 技能连载 - 正则表达式高级技巧"
description: PowerTip of the Day - Advanced Regular Expression Techniques in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- regex
- regular-expression
- pattern-matching
---

_适用于 PowerShell 5.1 及以上版本_

正则表达式是文本处理的瑞士军刀，PowerShell 通过 `-match`、`-replace` 运算符和 `[regex]` 类提供了丰富的正则支持。日常运维中，日志解析、数据提取、配置校验、文件重命名等场景都离不开正则。掌握高级正则技巧，可以让原本需要多步处理的文本操作浓缩到一条表达式中。

本文将介绍命名捕获组、零宽断言、正则表达式编译优化，以及实用的文本处理模式。

## 命名捕获组与匹配结果

```powershell
# 使用命名捕获组提取结构化数据
$logLine = '2025-08-27 14:30:15 [ERROR] [SRV01] Connection timeout to db.prod.local:5432'

$pattern = '^(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>\d{2}:\d{2}:\d{2})\s+\[(?<Level>\w+)\]\s+\[(?<Server>\w+)\]\s+(?<Message>.+)$'

if ($logLine -match $pattern) {
    $Matches.Date
    $Matches.Time
    $Matches.Level
    $Matches.Server
    $Matches.Message

    # 转为自定义对象
    $logEntry = [PSCustomObject]@{
        Date    = $Matches.Date
        Time    = $Matches.Time
        Level   = $Matches.Level
        Server  = $Matches.Server
        Message = $Matches.Message
    }
    $logEntry | Format-List
}

# 批量解析日志文件
$logContent = @'
2025-08-27 14:30:15 [ERROR] [SRV01] Connection timeout to db.prod.local:5432
2025-08-27 14:31:02 [WARN]  [SRV02] Disk usage at 85%
2025-08-27 14:32:10 [INFO]  [SRV01] Backup completed successfully
2025-08-27 14:33:45 [ERROR] [SRV03] Service IIS crashed
2025-08-27 14:35:00 [INFO]  [SRV02] User login: admin
'@

$pattern = '^(?<Date>\S+)\s+(?<Time>\S+)\s+\[(?<Level>\w+)\]\s+\[(?<Server>\w+)\]\s+(?<Message>.+)$'

$entries = $logContent -split "`n" | ForEach-Object {
    if ($_ -match $pattern) {
        [PSCustomObject]@{
            Date    = $Matches.Date
            Time    = $Matches.Time
            Level   = $Matches.Level
            Server  = $Matches.Server
            Message = $Matches.Message.Trim()
        }
    }
}

$entries | Where-Object { $_.Level -eq 'ERROR' } | Format-Table -AutoSize
```

执行结果示例：

```
Date       Time
----       ----
2025-08-27 14:30:15

Date    : 2025-08-27
Time    : 14:30:15
Level   : ERROR
Server  : SRV01
Message : Connection timeout to db.prod.local:5432

Date       Time     Level Server Message
----       ----     ----- ------ -------
2025-08-27 14:30:15 ERROR SRV01  Connection timeout to db.prod.local:5432
2025-08-27 14:33:45 ERROR SRV03  Service IIS crashed
```

## 零宽断言与精确提取

```powershell
# 正向先行断言 (?=...)：匹配后面跟着特定内容的位
# 提取 URL 中的域名
$url = 'https://blog.vichamp.com/2025/08/powershell-tips/'
if ($url -match 'https?://(?<Domain>[^/]+)') {
    Write-Host "域名：$($Matches.Domain)"
}

# 正向后行断言 (?<=...)：匹配前面是特定内容的位
# 提取 JSON 字符串中的键值
$jsonText = '{"name":"MyApp","version":"3.2.1","port":8080}'
 keyValuePairs = [regex]::Matches($jsonText, '(?<=")(\w+)":\s*"?([^",{}]+)"?')
foreach ($match in $keyValuePairs) {
    Write-Host "键：$($match.Groups[1].Value)  值：$($match.Groups[2].Value)"
}

# 负向断言：匹配不以特定内容开头的行
$lines = @(
    '# 这是注释'
    'server = prod-db01'
    '# 另一条注释'
    'port = 5432'
    'timeout = 30'
)

# 非注释的配置行
$configLines = $lines | Where-Object { $_ -match '^(?!\s*#)(?<Key>\w+)\s*=\s*(?<Value>.+)$' }
foreach ($line in $configLines) {
    if ($line -match '^(?!\s*#)(?<Key>\w+)\s*=\s*(?<Value>.+)$') {
        Write-Host "$($Matches.Key) => $($Matches.Value.Trim())"
    }
}

# 使用 [regex] 类进行精确替换
$template = 'Hello {name}, your order {orderId} has been shipped to {city}.'

$replacements = @{
    name    = '张三'
    orderId = 'ORD-20250827-001'
    city    = '北京'
}

# 使用 MatchEvaluator 动态替换
$result = [regex]::Replace($template, '\{(\w+)\}', {
    param($match)
    $key = $match.Groups[1].Value
    if ($replacements.ContainsKey($key)) {
        $replacements[$key]
    } else {
        $match.Value
    }
})

Write-Host $result
```

执行结果示例：

```
域名：blog.vichamp.com
键：name  值：MyApp
键：version  值：3.2.1
键：port  值：8080
server => prod-db01
port => 5432
timeout => 30
Hello 张三, your order ORD-20250827-001 has been shipped to 北京.
```

## 正则表达式编译与性能优化

```powershell
# 编译正则表达式提升重复匹配性能
$patterns = @{
    IPv4     = '^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$'
    Email    = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    DateTime = '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2})?(\.\d+)?$'
    URL      = '^https?://[^\s/$.?#].[^\s]*$'
    GUID     = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
}

# 预编译所有正则
$compiled = @{}
foreach ($entry in $patterns.GetEnumerator()) {
    $compiled[$entry.Key] = [regex]::new($entry.Value, 'Compiled, IgnoreCase')
}

# 验证函数
function Test-Format {
    param(
        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4', 'Email', 'DateTime', 'URL', 'GUID')]
        [string]$Format
    )

    $regex = $compiled[$Format]
    return $regex.IsMatch($Value)
}

# 批量验证测试
$testCases = @(
    @{ Value = '192.168.1.100';      Format = 'IPv4' }
    @{ Value = '999.999.999.999';     Format = 'IPv4' }
    @{ Value = 'admin@example.com';   Format = 'Email' }
    @{ Value = 'not-an-email';        Format = 'Email' }
    @{ Value = '2025-08-27T14:30:00'; Format = 'DateTime' }
    @{ Value = 'https://blog.vichamp.com'; Format = 'URL' }
    @{ Value = 'a3e1f2b4-5c6d-7e8f-9a0b-1c2d3e4f5a6b'; Format = 'GUID' }
    @{ Value = 'not-a-guid';          Format = 'GUID' }
)

foreach ($case in $testCases) {
    $isValid = Test-Format -Value $case.Value -Format $case.Format
    $status = if ($isValid) { "有效" } else { "无效" }
    Write-Host ("{0,-40} [{1}] {2}" -f $case.Value, $case.Format, $status)
}

# 性能对比：编译 vs 非编译
$sampleText = "User admin (admin@example.com) logged in from 192.168.1.100 at 2025-08-27T14:30:00"
$emailPattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'

# 非编译模式
$sw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt 10000; $i++) {
    $sampleText -match $emailPattern | Out-Null
}
$sw.Stop()
Write-Host "`n非编译模式 10000 次：$($sw.ElapsedMilliseconds) ms"

# 编译模式
$compiledRegex = [regex]::new($emailPattern, 'Compiled')
$sw.Restart()
for ($i = 0; $i -lt 10000; $i++) {
    $compiledRegex.IsMatch($sampleText) | Out-Null
}
$sw.Stop()
Write-Host "编译模式 10000 次：$($sw.ElapsedMilliseconds) ms"
```

执行结果示例：

```
192.168.1.100                            [IPv4] 有效
999.999.999.999                          [IPv4] 无效
admin@example.com                        [Email] 有效
not-an-email                             [Email] 无效
2025-08-27T14:30:00                      [DateTime] 有效
https://blog.vichamp.com                 [URL] 有效
a3e1f2b4-5c6d-7e8f-9a0b-1c2d3e4f5a6b    [GUID] 有效
not-a-guid                               [GUID] 无效

非编译模式 10000 次：128 ms
编译模式 10000 次：34 ms
```

## 实用文本处理模式

```powershell
# 1. 提取 CSV 中的引号字段（处理内嵌逗号）
$csvLine = '张三,"工程部,高级工程师",北京,100001'
$fields = [regex]::Matches($csvLine, '(?<=^|,)(?:"(?<q>[^"]*)"|(?<n>[^,]*))')

$values = foreach ($f in $fields) {
    if ($f.Groups['q'].Success) { $f.Groups['q'].Value }
    else { $f.Groups['n'].Value }
}
Write-Host "CSV 字段：$($values -join ' | ')"

# 2. 清理多余空白
$messy = '  Hello    World   this   is   a   test  '
$clean = $messy -replace '\s+', ' ' -replace '^\s+|\s+$', ''
Write-Host "清理前：[$messy]"
Write-Host "清理后：[$clean]"

# 3. 文件名安全化
$unsafeNames = @(
    'Report: Q3/2025 <Final>.xlsx'
    'Notes (draft #2).txt'
    'Data | Backup & Archive.csv'
    '配置文件 - 生产环境.json'
)

$safeNames = $unsafeNames | ForEach-Object {
    $safe = $_ -replace '[\\/:*?"<>|]', '_'
    $safe = $safe -replace '\s+', ' '
    $safe = $safe.Trim()
    [PSCustomObject]@{
        Original = $_
        Safe     = $safe
    }
}
$safeNames | Format-Table -AutoSize

# 4. 批量重命名文件（基于正则提取）
function Invoke-RegexRename {
    param(
        [string]$Path = ".",
        [string]$Pattern,
        [string]$Replace,
        [switch]$WhatIf
    )

    $files = Get-ChildItem $Path -File
    $renamed = 0

    foreach ($file in $files) {
        $newName = $file.Name -replace $Pattern, $Replace
        if ($newName -ne $file.Name) {
            Write-Host "$($file.Name) -> $newName"
            if (-not $WhatIf) {
                Rename-Item $file.FullName -NewName $newName
            }
            $renamed++
        }
    }

    Write-Host "`n共处理 $renamed 个文件" -ForegroundColor Green
}

# 示例：将 IMG_20250827_143015.jpg 重命名为 2025-08-27_14-30-15.jpg
# Invoke-RegexRename -Pattern 'IMG_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})' `
#     -Replace '$1-$2-$3_$4-$5-$6' -WhatIf

# 5. 日志时间范围过滤
function Select-LogByTimeRange {
    param(
        [string]$LogPath,
        [datetime]$Start,
        [datetime]$End,
        [string]$TimePattern = '(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})'
    )

    $regex = [regex]::new($TimePattern, 'Compiled')
    $lines = Get-Content $LogPath

    $filtered = foreach ($line in $lines) {
        $match = $regex.Match($line)
        if ($match.Success) {
            $timestamp = [datetime]::ParseExact($match.Groups[1].Value, 'yyyy-MM-dd HH:mm:ss', $null)
            if ($timestamp -ge $Start -and $timestamp -le $End) {
                $line
            }
        }
    }

    Write-Host "时间范围 $Start ~ $End：共 $($filtered.Count) 条" -ForegroundColor Cyan
    return $filtered
}
```

执行结果示例：

```
CSV 字段：张三 | 工程部,高级工程师 | 北京 | 100001
清理前：[  Hello    World   this   is   a   test  ]
清理后：[Hello World this is a test]
Original                              Safe
--------                              ----
Report: Q3/2025 <Final>.xlsx          Report_ Q3_2025 _Final_.xlsx
Notes (draft #2).txt                  Notes (draft #2).txt
Data | Backup & Archive.csv           Data _ Backup & Archive.csv
配置文件 - 生产环境.json               配置文件 - 生产环境.json
```

## 注意事项

1. **贪婪 vs 非贪婪**：默认量词（`*`、`+`）是贪婪的，会匹配尽可能多的字符，使用 `*?` 和 `+?` 切换为非贪婪模式
2. **性能陷阱**：复杂的嵌套量词可能导致灾难性回溯，对大文本使用 `(?=` 断言）或预编译正则
3. **字符转义**：在 PowerShell 字符串中，反斜杠需要双写或使用单引号字符串避免转义冲突
4. **Unicode 支持**：`\w` 在 .NET 中匹配 Unicode 字符（包括中文），如果只匹配 ASCII 请使用 `[a-zA-Z0-9_]`
5. **RegexOptions**：常用的有 `IgnoreCase`（忽略大小写）、`Multiline`（`^$` 匹配行首行尾）、`Singleline`（`.` 匹配换行）
6. **测试工具**：推荐使用 regex101.com 在线测试正则表达式，支持 .NET 风格语法高亮
