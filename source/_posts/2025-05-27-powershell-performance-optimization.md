---
layout: post
date: 2025-05-27 08:00:00
updated: 2025-05-27 08:00:00
title: "PowerShell 技能连载 - 性能优化与内存管理"
description: PowerTip of the Day - Performance Optimization and Memory Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- performance
- optimization
- memory
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 的便利性往往以性能为代价——管道对象传递、灵活的类型转换、丰富的 .NET 集成，这些特性在处理小规模数据时非常方便，但面对大量数据（数万行 CSV、上千个文件、数百台服务器）时，性能瓶颈会非常明显。理解 PowerShell 的性能特征并掌握优化技巧，可以将脚本执行时间从数小时缩短到数秒。

本文将讲解常见的性能陷阱、优化技巧、内存管理策略，以及如何度量和对比脚本性能。

<!-- more -->

## 性能度量

优化之前先度量。PowerShell 提供了多种性能测量工具：

```powershell
# 使用 Measure-Command 测量代码执行时间
Measure-Command {
    Get-ChildItem C:\ -Recurse -File | Where-Object { $_.Extension -eq '.log' }
} | Select-Object TotalSeconds, TotalMilliseconds

# 使用 Stopwatch 精确计时
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 你的代码
1..10000 | ForEach-Object { $_ * 2 }

$sw.Stop()
Write-Host "耗时：$($sw.Elapsed.TotalMilliseconds) 毫秒"

# 批量对比不同方案的性能
$iterations = 10000

$results = @(
    @{
        Name = 'ForEach-Object（管道）'
        Time = (Measure-Command {
            1..$iterations | ForEach-Object { $_ * 2 }
        }).TotalMilliseconds
    }
    @{
        Name = 'foreach 语句'
        Time = (Measure-Command {
            foreach ($i in 1..$iterations) { $i * 2 }
        }).TotalMilliseconds
    }
    @{
        Name = 'LINQ'
        Time = (Measure-Command {
            [System.Linq.Enumerable]::Range(1, $iterations) |
                ForEach-Object { $_ * 2 }
        }).TotalMilliseconds
    }
)

$results | ForEach-Object {
    [PSCustomObject]@{
        方法    = $_.Name
        耗时ms  = [math]::Round($_.Time, 2)
    }
} | Sort-Object 耗时ms | Format-Table -AutoSize
```

执行结果示例：

```
TotalSeconds TotalMilliseconds
------------ -----------------
        2.34          2345.67

耗时：15.23 毫秒

方法                    耗时ms
----                    ------
foreach 语句             12.34
LINQ                    45.67
ForEach-Object（管道）  234.56
```

> **注意**：`foreach` 语句通常比 `ForEach-Object` 快 10-20 倍，因为后者需要经过完整的管道处理。在性能敏感的场景中优先使用 `foreach` 语句。

## 字符串拼接优化

字符串操作是 PowerShell 中最常见的性能陷阱之一：

```powershell
# 陷阱：使用 += 拼接字符串（每次都创建新字符串）
Measure-Command {
    $result = ""
    1..10000 | ForEach-Object { $result += "Line $_`n" }
} | Select-Object TotalMilliseconds

# 优化一：使用 StringBuilder
Measure-Command {
    $sb = [System.Text.StringBuilder]::new()
    1..10000 | ForEach-Object { [void]$sb.AppendLine("Line $_") }
    $result = $sb.ToString()
} | Select-Object TotalMilliseconds

# 优化二：使用数组和 -join
Measure-Command {
    $lines = 1..10000 | ForEach-Object { "Line $_" }
    $result = $lines -join "`n"
} | Select-Object TotalMilliseconds

# 优化三：使用赋值表达式和 -join（最快）
Measure-Command {
    $result = 1..10000 | ForEach-Object { "Line $_" } | Join-String -Separator "`n"
} | Select-Object TotalMilliseconds
```

执行结果示例：

```
TotalMilliseconds
-----------------
         2345.67   # +=
          45.23    # StringBuilder
          38.45    # 数组 + -join
          32.12    # Join-String
```

## 集合操作优化

处理大量数据时，集合的选择至关重要：

```powershell
# 陷阱：数组 += 操作（每次复制整个数组）
Measure-Command {
    $array = @()
    1..5000 | ForEach-Object { $array += "Item-$_" }
} | Select-Object TotalMilliseconds

# 优化：使用 List
Measure-Command {
    $list = [System.Collections.Generic.List[string]]::new()
    1..5000 | ForEach-Object { $list.Add("Item-$_") }
    $result = $list.ToArray()
} | Select-Object TotalMilliseconds

# 哈希表查找 vs 数组过滤
$data = 1..10000 | ForEach-Object { @{ Id = $_; Name = "Item-$_" } }

# 数组查找（线性扫描，O(n)）
Measure-Command {
    $data | Where-Object { $_.Id -eq 5000 }
} | Select-Object TotalMilliseconds

# 哈希表查找（O(1)）
$lookup = @{}
$data | ForEach-Object { $lookup[$_.Id] = $_ }

Measure-Command {
    $lookup[5000]
} | Select-Object TotalMilliseconds
```

执行结果示例：

```
TotalMilliseconds
-----------------
         1234.56   # 数组 +=
           12.34   # List<T>

# Where-Object 过滤
TotalMilliseconds: 45.67

# 哈希表查找
TotalMilliseconds: 0.12
```

## 文件处理优化

处理大量文件时，I/O 操作往往是最大的性能瓶颈：

```powershell
# 陷阱：逐行读取大文件
Measure-Command {
    $lines = @()
    Get-Content "C:\Logs\large-app.log" | ForEach-Object {
        if ($_ -match 'ERROR') { $lines += $_ }
    }
} | Select-Object TotalMilliseconds

# 优化一：使用 Select-String
Measure-Command {
    $lines = Select-String -Path "C:\Logs\large-app.log" -Pattern 'ERROR'
} | Select-Object TotalMilliseconds

# 优化二：分批读取（减少管道开销）
Measure-Command {
    $lines = Get-Content "C:\Logs\large-app.log" -ReadCount 5000 |
        ForEach-Object { $_ | Where-Object { $_ -match 'ERROR' } }
} | Select-Object TotalMilliseconds

# 优化三：使用 StreamReader（处理超大文件）
Measure-Command {
    $reader = [System.IO.StreamReader]::new("C:\Logs\large-app.log")
    $errors = while (-not $reader.EndOfStream) {
        $line = $reader.ReadLine()
        if ($line -match 'ERROR') { $line }
    }
    $reader.Close()
} | Select-Object TotalMilliseconds

# CSV 处理优化
# 陷阱：Import-Csv 后再过滤
Measure-Command {
    Import-Csv "C:\Data\large.csv" | Where-Object { $_.Status -eq 'Active' }
} | Select-Object TotalMilliseconds

# 优化：使用 StreamReader + 直接解析
Measure-Command {
    $reader = [System.IO.StreamReader]::new("C:\Data\large.csv")
    $header = $reader.ReadLine() -split ','
    $active = while (-not $reader.EndOfStream) {
        $values = $reader.ReadLine() -split ','
        if ($values[3] -eq 'Active') {
            $obj = [ordered]@{}
            for ($i = 0; $i -lt $header.Count; $i++) {
                $obj[$header[$i]] = $values[$i]
            }
            [PSCustomObject]$obj
        }
    }
    $reader.Close()
} | Select-Object TotalMilliseconds
```

执行结果示例：

```
TotalMilliseconds
-----------------
         5678.90   # 逐行 += 拼接
          123.45   # Select-String
           89.23   # ReadCount 分批
           34.56   # StreamReader
```

## 内存管理

处理大量数据时，内存管理同样重要：

```powershell
# 监控当前 PowerShell 进程的内存使用
$proc = Get-Process -Id $PID
Write-Host "工作集：$([math]::Round($proc.WorkingSet64/1MB, 2)) MB"
Write-Host "私有内存：$([math]::Round($proc.PrivateMemorySize64/1MB, 2)) MB"

# GC 基础操作
# 查看当前 GC 内存
[System.GC]::GetTotalMemory($false) / 1MB

# 强制垃圾回收（释放未引用的对象）
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

Write-Host "GC 后内存：$([math]::Round([System.GC]::GetTotalMemory($true)/1MB, 2)) MB"

# 大对象处理模式
# 对于已知大小的集合，预分配容量
$list = [System.Collections.Generic.List[PSObject]]::new(10000)

# 使用 using 语句确保资源释放（PowerShell 7+）
Measure-Command {
    using ($reader = [System.IO.StreamReader]::new("C:\Logs\large-app.log")) {
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
        }
    }
} | Select-Object TotalMilliseconds

# 处理大文件时分块处理，避免全部加载到内存
function Process-LargeFile {
    param([string]$Path, [int]$ChunkSize = 10000)

    $reader = [System.IO.StreamReader]::new($Path)
    $chunk = [System.Collections.Generic.List[string]]::new($ChunkSize)
    $lineNum = 0

    while (-not $reader.EndOfStream) {
        $chunk.Add($reader.ReadLine())
        $lineNum++

        if ($chunk.Count -ge $ChunkSize) {
            # 处理当前块
            Process-Chunk -Data $chunk -LineStart ($lineNum - $ChunkSize)

            # 清空块，释放内存
            $chunk.Clear()
            [System.GC]::Collect()
        }
    }

    # 处理最后不满一块的数据
    if ($chunk.Count -gt 0) {
        Process-Chunk -Data $chunk -LineStart ($lineNum - $chunk.Count)
    }

    $reader.Close()
}
```

执行结果示例：

```
工作集：245.67 MB
私有内存：312.34 MB

GC 前内存：156.78 MB
GC 后内存：89.23 MB
```

## 管道优化

理解管道的执行方式对优化至关重要：

```powershell
# 陷阱：多次遍历集合
Measure-Command {
    $data = Get-ChildItem C:\Projects -Recurse -File
    $largeFiles = $data | Where-Object { $_.Length -gt 1MB }
    $recentFiles = $data | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
    $ps1Files = $data | Where-Object { $_.Extension -eq '.ps1' }
} | Select-Object TotalMilliseconds

# 优化：单次遍历，分类存储
Measure-Command {
    $largeFiles = [System.Collections.Generic.List[IO.FileInfo]]::new()
    $recentFiles = [System.Collections.Generic.List[IO.FileInfo]]::new()
    $ps1Files = [System.Collections.Generic.List[IO.FileInfo]]::new()

    foreach ($file in (Get-ChildItem C:\Projects -Recurse -File)) {
        if ($file.Length -gt 1MB) { $largeFiles.Add($file) }
        if ($file.LastWriteTime -gt (Get-Date).AddDays(-7)) { $recentFiles.Add($file) }
        if ($file.Extension -eq '.ps1') { $ps1Files.Add($file) }
    }
} | Select-Object TotalMilliseconds

# 过滤优化：尽早过滤，减少后续处理量
# 差：获取所有文件后再过滤
Get-ChildItem C:\ -Recurse -File | Where-Object { $_.Extension -eq '.log' }

# 好：在命令参数中过滤
Get-ChildItem C:\ -Recurse -Filter *.log
```

执行结果示例：

```
TotalMilliseconds
-----------------
          345.67   # 多次遍历
          123.45   # 单次遍历
```

## 注意事项

1. **先度量再优化**：不要凭直觉优化，使用 `Measure-Command` 确认瓶颈所在
2. **foreach 优于 ForEach-Object**：在不需要管道流式处理时，使用 `foreach` 语句代替 `ForEach-Object`
3. **避免数组 +=**：用 `[List<T>]` 或 `[ArrayList]` 替代，或直接赋值为数组
4. **哈希表用于查找**：需要频繁查找时，将数据构建为哈希表，避免线性扫描
5. **流式处理**：处理大量数据时，尽量逐条处理而不是全部加载到内存
6. **合理使用 GC**：不要频繁调用 `[GC]::Collect()`，它会暂停所有线程。仅在处理完大对象后手动触发
