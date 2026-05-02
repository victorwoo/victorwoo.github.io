---
layout: post
date: 2025-07-03 08:00:00
updated: 2025-07-03 08:00:00
title: "PowerShell 技能连载 - 类型加速器与 .NET 互操作"
description: PowerTip of the Day - Type Accelerators and .NET Interop in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dotnet
- type-accelerator
- interop
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 构建在 .NET 之上，这意味着你可以直接使用 .NET 的全部类库——从文件操作到加密算法，从网络编程到并行处理。但很多用户不知道的是，PowerShell 提供了大量"类型加速器"（Type Accelerator），让你可以用简短的名称代替冗长的命名空间路径。比如 `[xml]` 实际上是 `[System.Xml.XmlDocument]`，`[mailaddress]` 是 `[System.Net.Mail.MailAddress]`。

本文将讲解常用的类型加速器、.NET 类的直接调用，以及一些通过 .NET 互操作实现的高级功能。

## 内置类型加速器

```powershell
# 查看所有内置类型加速器
[System.Management.Automation.PSObject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)::Get | Sort-Object Key | ForEach-Object {
    [PSCustomObject]@{
        Shortcut = $_.Key
        FullType = $_.Value.FullName
    }
} | Format-Table -AutoSize | Out-String -Width 120 | Write-Host

# 常用加速器示例
# [xml] => System.Xml.XmlDocument
[xml]$doc = '<config><server>prod-db01</server><port>5432</port></config>'
Write-Host "XML 服务器：$($doc.config.server)"

# [regex] => System.Text.RegularExpressions.Regex
$matches = [regex]::Matches("版本 1.2.3 和 2.0.1", '\d+\.\d+\.\d+')
$matches | ForEach-Object { Write-Host "匹配：$($_.Value)" }

# [guid] => System.Guid
$guid = [guid]::NewGuid()
Write-Host "新 GUID：$guid"

# [datetime] => System.DateTime
$dt = [datetime]::ParseExact("2025-07-03 08:30", "yyyy-MM-dd HH:mm", $null)
Write-Host "解析日期：$($dt.ToString('yyyy年M月d日 HH:mm'))"

# [timespan] => System.TimeSpan
$ts = [timespan]::FromHours(2.5)
Write-Host "时间跨度：$($ts.ToString('hh\:mm\:ss'))"

# [math] => System.Math
Write-Host "PI：$([math]::PI)"
Write-Host "四舍五入：$([math]::Round(3.14159, 2))"
Write-Host "最大值：$([math]::Max(10, 20))"
```

执行结果示例：

```
Shortcut   FullType
--------   --------
adsi       System.DirectoryServices.DirectoryEntry
adsisearcher System.DirectoryServices.DirectorySearcher
bool       System.Boolean
byte       System.Byte
char       System.Char
datetime   System.DateTime
decimal    System.Decimal
double     System.Double
float      System.Single
guid       System.Guid
hashtable  System.Collections.Hashtable
int        System.Int32
long       System.Int64
mailaddress System.Net.Mail.MailAddress
regex      System.Text.RegularExpressions.Regex
scriptblock System.Management.Automation.ScriptBlock
string     System.String
timespan   System.TimeSpan
uri        System.Uri
version    System.Version
xml        System.Xml.XmlDocument

XML 服务器：prod-db01
匹配：1.2.3
匹配：2.0.1
新 GUID：a1b2c3d4-e5f6-7890-abcd-ef1234567890
解析日期：2025年7月3日 08:30
时间跨度：02:30:00
PI：3.14159265358979
四舍五入：3.14
最大值：20
```

## 常用 .NET 类直接调用

```powershell
# System.IO —— 文件操作（比 cmdlet 更快的批量操作）
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 快速读取所有行
$lines = [System.IO.File]::ReadAllLines("C:\Logs\app.log")
Write-Host "读取 $($lines.Count) 行，耗时：$($sw.ElapsedMilliseconds)ms"

# 快速写入
[System.IO.File]::WriteAllLines("C:\Temp\output.txt", $lines)

$sw.Stop()

# System.Text.StringBuilder —— 高效字符串拼接
$sb = [System.Text.StringBuilder]::new()
$sb.AppendLine("服务器巡检报告") | Out-Null
$sb.AppendLine("生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
$sb.AppendLine("") | Out-Null

@("SRV01", "SRV02", "SRV03") | ForEach-Object {
    $sb.AppendLine("  $_ : 在线") | Out-Null
}

Write-Host $sb.ToString()

# System.Net —— DNS 查询
$dnsResult = [System.Net.Dns]::GetHostAddresses("www.microsoft.com")
$dnsResult | ForEach-Object { Write-Host "IP：$($_.IPAddressFamily) $($_.ToString())" }

# System.Security.Cryptography —— 计算文件哈希
function Get-FileHashFast {
    param([string]$Path, [string]$Algorithm = "SHA256")

    $hashAlg = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hashBytes = $hashAlg.ComputeHash($stream)
        $hashHex = [BitConverter]::ToString($hashBytes) -replace '-', ''
        return $hashHex.ToLower()
    } finally {
        $stream.Close()
    }
}

$hash = Get-FileHashFast -Path "C:\Windows\notepad.exe"
Write-Host "SHA256：$($hash.Substring(0, 16))..."
```

执行结果示例：

```
读取 54230 行，耗时：45ms

服务器巡检报告
生成时间：2025-07-03 08:30:15

  SRV01 : 在线
  SRV02 : 在线
  SRV03 : 在线

IP：InterNetwork 20.190.159.2
IP：InterNetworkV6 2603:1030:20...
SHA256：a1b2c3d4e5f67890...
```

## 自定义类型加速器

```powershell
# 注册自定义类型加速器
$accel = [System.Management.Automation.PSObject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)

# 添加自定义加速器
$accel::Add("ws", [System.Net.WebSockets.ClientWebSocket])
$accel::Add("http", [System.Net.Http.HttpClient])

# 验证
Write-Host "ws => $($accel::Get['ws'].FullName)"
Write-Host "http => $($accel::Get['http'].FullName)"

# 实际使用：用 [http] 代替完整类型名
$client = [http]::new()
$client.Timeout = [timespan]::FromSeconds(30)
Write-Host "HTTP 客户端超时：$($client.Timeout)"

# 添加常用 .NET 缩写
$mappings = @{
    "sb"     = [System.Text.StringBuilder]
    "stopw"  = [System.Diagnostics.Stopwatch]
    "zip"    = [System.IO.Compression.ZipArchive]
    "json"   = [System.Text.Json.JsonSerializer]
    "crypto" = [System.Security.Cryptography.Aes]
}

foreach ($key in $mappings.Keys) {
    $accel::Add($key, $mappings[$key])
    Write-Host "已注册：$key => $($mappings[$key].FullName)" -ForegroundColor Green
}
```

执行结果示例：

```
ws => System.Net.WebSockets.ClientWebSocket
http => System.Net.Http.HttpClient
HTTP 客户端超时：00:00:30
已注册：sb => System.Text.StringBuilder
已注册：stopw => System.Diagnostics.Stopwatch
已注册：zip => System.IO.Compression.ZipArchive
已注册：json => System.Text.Json.JsonSerializer
已注册：crypto => System.Security.Cryptography.Aes
```

## 使用 .NET 泛型集合

```powershell
# List<T> —— 动态数组
$list = [System.Collections.Generic.List[string]]::new()
$list.AddRange(@("apple", "banana", "cherry"))
$list.Add("date")
Write-Host "列表内容：$($list -join ', ')"
Write-Host "数量：$($list.Count)"

$list.Remove("banana")
$list.Sort()
Write-Host "排序后：$($list -join ', ')"

# Dictionary<TKey, TValue> —— 强类型字典
$dict = [System.Collections.Generic.Dictionary[string, int]]::new()
$dict["apple"] = 5
$dict["banana"] = 3
$dict["cherry"] = 7

Write-Host "苹果数量：$($dict['apple'])"

# 遍历强类型字典
foreach ($entry in $dict) {
    Write-Host "  $($entry.Key)：$($entry.Value) 个"
}

# HashSet<T> —— 去重集合
$set = [System.Collections.Generic.HashSet[string]]::new()
$items = @("server01", "server02", "server01", "server03", "server02")
foreach ($item in $items) {
    $added = $set.Add($item)
    if (-not $added) {
        Write-Host "重复项：$item" -ForegroundColor Yellow
    }
}
Write-Host "去重后：$($set -join ', ')"

# Queue<T> —— 先进先出队列
$queue = [System.Collections.Generic.Queue[string]]::new()
"task1", "task2", "task3" | ForEach-Object { $queue.Enqueue($_) }

while ($queue.Count -gt 0) {
    $task = $queue.Dequeue()
    Write-Host "处理：$task"
}
```

执行结果示例：

```
列表内容：apple, banana, cherry, date
数量：4
排序后：apple, cherry, date
苹果数量：5
  apple：5 个
  banana：3 个
  cherry：7 个
重复项：server01
重复项：server02
去重后：server01, server02, server03
处理：task1
处理：task2
处理：task3
```

## 注意事项

1. **类型加速器作用域**：自定义类型加速器只在当前会话中生效，放入 `$PROFILE` 中可持久化
2. **性能差异**：批量操作（大量文件读写、字符串拼接）使用 .NET 类比 cmdlet 快 10-100 倍
3. **内存管理**：`IDisposable` 对象（如 `Stream`、`HttpClient`）应使用 `using` 语句或 `try/finally` 释放
4. **泛型语法**：PowerShell 中泛型用方括号表示 `[List[string]]`，不能使用 C# 的 `List<string>` 语法
5. **平台兼容**：部分 .NET 类仅在 Windows 上可用（如 `System.Drawing`），跨平台脚本注意检查
6. **加载程序集**：使用 `Add-Type -AssemblyName` 加载非默认引用的程序集
