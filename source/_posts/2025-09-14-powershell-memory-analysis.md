---
layout: post
date: 2025-09-14 08:00:00
title: "PowerShell 技能连载 - 内存管理与性能分析"
description: PowerTip of the Day - Memory Management and Performance Analysis in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- memory
- performance
- diagnostics
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 脚本在处理大数据集、长时间运行的任务或复杂的对象管道时，内存消耗会快速增长。对象在管道中逐个传递，每个中间步骤都会产生新的 .NET 对象，而 .NET 的垃圾回收器（GC）并不总是能及时回收。理解 PowerShell 的内存模型和 GC 机制，对于编写高性能脚本至关重要。

本文将介绍内存诊断方法、GC 调优策略，以及减少内存占用的编码技巧。

## 内存诊断与监控

```powershell
# 当前进程内存信息
$proc = Get-Process -Id $PID
Write-Host "PowerShell 进程内存分析" -ForegroundColor Cyan
Write-Host "  工作集 (Working Set):    $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB"
Write-Host "  专用字节 (Private Bytes): $([math]::Round($proc.PrivateMemorySize64 / 1MB, 2)) MB"
Write-Host "  虚拟内存:                $([math]::Round($proc.VirtualMemorySize64 / 1MB, 2)) MB"
Write-Host "  句柄数:                  $($proc.HandleCount)"
Write-Host "  线程数:                  $($proc.Threads.Count)"

# .NET CLR 内存统计
$heap = [GC]::GetTotalMemory($false)
Write-Host "`n.NET 堆内存：$([math]::Round($heap / 1MB, 2)) MB" -ForegroundColor Yellow

# GC 代数统计
Write-Host "`nGC 代数回收次数：" -ForegroundColor Cyan
Write-Host "  Gen 0: $([GC]::CollectionCount(0))"
Write-Host "  Gen 1: $([GC]::CollectionCount(1))"
Write-Host "  Gen 2: $([GC]::CollectionCount(2))"

# 内存消耗函数
function Measure-ScriptMemory {
    param([scriptblock]$ScriptBlock, [string]$Label = "Test")

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    $before = [GC]::GetTotalMemory($true)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $sw.Stop()

    $after = [GC]::GetTotalMemory($false)
    $diff = $after - $before

    [PSCustomObject]@{
        Label     = $Label
        BeforeMB  = [math]::Round($before / 1MB, 2)
        AfterMB   = [math]::Round($after / 1MB, 2)
        DeltaMB   = [math]::Round($diff / 1MB, 2)
        TimeMs    = $sw.ElapsedMilliseconds
        Gen0      = [GC]::CollectionCount(0)
        Gen1      = [GC]::CollectionCount(1)
        Gen2      = [GC]::CollectionCount(2)
    }
}

# 对比不同方式的内存消耗
$result1 = Measure-ScriptMemory -Label "数组累加" -ScriptBlock {
    $arr = @()
    foreach ($i in 1..10000) { $arr += $i }
}

$result2 = Measure-ScriptMemory -Label "List 泛型" -ScriptBlock {
    $list = [System.Collections.Generic.List[int]]::new()
    foreach ($i in 1..10000) { $list.Add($i) }
}

$result3 = Measure-ScriptMemory -Label "赋值变量" -ScriptBlock {
    $result = foreach ($i in 1..10000) { $i }
}

"数组累加", "List 泛型", "赋值变量" | ForEach-Object {
    switch ($_) {
        "数组累加" { $result1 }
        "List 泛型" { $result2 }
        "赋值变量" { $result3 }
    }
} | Format-Table -AutoSize
```

执行结果示例：

```
PowerShell 进程内存分析
  工作集 (Working Set):    156.78 MB
  专用字节 (Private Bytes): 142.34 MB
  虚拟内存:                1024.56 MB
  句柄数:                  523
  线程数:                  12

.NET 堆内存：34.56 MB

GC 代数回收次数：
  Gen 0: 15
  Gen 1: 3
  Gen 2: 1

Label    BeforeMB AfterMB DeltaMB TimeMs Gen0 Gen1 Gen2
-----    -------- ------- ------- ------ ---- ---- ----
数组累加     34.56   42.31    7.75    234   18    3    1
List 泛型    42.31   42.34    0.03     12   18    3    1
赋值变量     42.34   42.35    0.01      8   18    3    1
```

## 垃圾回收与内存释放

```powershell
# 大对象堆（LOH）分析
# 超过 85,000 字节的对象存储在 LOH 中，LOH 的回收代价很高
function Get-LargeObjectStats {
    # 使用 GC 内存信息
    $totalMemory = [GC]::GetTotalMemory($false)
    $heapSize = [System.AppDomain]::CurrentDomain.MonitoringTotalAllocatedMemorySize

    Write-Host "总分配内存：$([math]::Round($heapSize / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host "当前存活内存：$([math]::Round($totalMemory / 1MB, 2)) MB" -ForegroundColor Yellow

    # 强制 GC 回收
    Write-Host "`n执行完整 GC 回收..." -ForegroundColor Yellow
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()  # 二次回收确保 Finalizer 队列的对象被回收

    $afterGC = [GC]::GetTotalMemory($true)
    $freed = $totalMemory - $afterGC
    Write-Host "回收后内存：$([math]::Round($afterGC / 1MB, 2)) MB（释放 $([math]::Round($freed / 1MB, 2)) MB）" -ForegroundColor Green
}

Get-LargeObjectStats

# 处理大文件时的内存优化
function Get-LargeFileHashBatch {
    param(
        [string]$Path,
        [int]$BatchSize = 100
    )

    $files = [System.IO.Directory]::EnumerateFiles($Path, "*", [System.IO.SearchOption]::AllDirectories)
    $batch = @()
    $totalProcessed = 0

    foreach ($file in $files) {
        $info = [System.IO.FileInfo]::new($file)
        $hash = (Get-FileHash $file -Algorithm SHA256).Hash

        $batch += [PSCustomObject]@{
            File   = $info.Name
            SizeKB = [math]::Round($info.Length / 1KB, 2)
            Hash   = $hash.Substring(0, 16) + "..."
        }

        $totalProcessed++

        if ($batch.Count -ge $BatchSize) {
            # 输出批次结果并释放引用
            $batch
            $batch = @()

            if ($totalProcessed % 500 -eq 0) {
                [GC]::Collect()
                $mem = [math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
                Write-Host "  已处理 $totalProcessed 个文件，内存：$mem MB" -ForegroundColor DarkGray
            }
        }
    }

    # 输出最后一批
    if ($batch) { $batch }
    Write-Host "`n总计处理：$totalProcessed 个文件" -ForegroundColor Green
}

# 使用流式处理替代一次性加载
function Read-LargeCsvStreaming {
    param(
        [string]$Path,
        [int]$TopN = 10
    )

    $reader = [System.IO.StreamReader]::new($Path)
    $header = $reader.ReadLine()
    $columns = $header -split ','

    $count = 0
    while ($null -ne ($line = $reader.ReadLine()) -and $count -lt $TopN) {
        $values = $line -split ','
        $obj = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $obj[$columns[$i].Trim('"')] = $values[$i].Trim('"')
        }
        [PSCustomObject]$obj
        $count++
    }

    $reader.Close()
    $reader.Dispose()
}

Write-Host "`n流式处理避免了将整个文件加载到内存" -ForegroundColor Green
```

执行结果示例：

```
总分配内存：256.78 MB
当前存活内存：42.31 MB

执行完整 GC 回收...
回收后内存：18.45 MB（释放 23.86 MB）
  已处理 500 个文件，内存：24.56 MB
  已处理 1000 个文件，内存：22.34 MB
总计处理：1234 个文件
流式处理避免了将整个文件加载到内存
```

## 性能分析实战

```powershell
# 脚本性能分析器
function Measure-ScriptPerformance {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$Iterations = 3
    )

    $results = @()

    # 预热（排除 JIT 编译影响）
    Write-Host "预热中..." -ForegroundColor DarkGray
    & $ScriptBlock | Out-Null

    for ($i = 1; $i -le $Iterations; $i++) {
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        $memBefore = [GC]::GetTotalMemory($true)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        & $ScriptBlock | Out-Null

        $sw.Stop()
        $memAfter = [GC]::GetTotalMemory($false)

        $results += [PSCustomObject]@{
            Iteration = $i
            TimeMs    = $sw.ElapsedMilliseconds
            MemoryKB  = [math]::Round(($memAfter - $memBefore) / 1KB, 2)
            Gen0      = [GC]::CollectionCount(0)
        }

        Write-Host "  第 $i 次：$($sw.ElapsedMilliseconds) ms" -ForegroundColor DarkGray
    }

    $avg = ($results | Measure-Object TimeMs -Average).Average
    $min = ($results | Measure-Object TimeMs -Minimum).Minimum
    $max = ($results | Measure-Object TimeMs -Maximum).Maximum

    Write-Host "`n性能统计：" -ForegroundColor Cyan
    Write-Host "  平均：$([math]::Round($avg, 2)) ms"
    Write-Host "  最快：$min ms"
    Write-Host "  最慢：$max ms"

    return $results
}

# 对比字符串拼接方式
Write-Host "=== 字符串拼接对比 ===" -ForegroundColor Yellow

Measure-ScriptPerformance -Iterations 3 -ScriptBlock {
    $s = ""
    foreach ($i in 1..1000) { $s += "Line $i`n" }
} | Out-Null

Measure-ScriptPerformance -Iterations 3 -ScriptBlock {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($i in 1..1000) { $sb.AppendLine("Line $i") | Out-Null }
    $sb.ToString()
} | Out-Null
```

执行结果示例：

```
预热中...
  第 1 次：45 ms
  第 2 次：42 ms
  第 3 次：40 ms

性能统计：
  平均：42.33 ms
  最快：40 ms
  最慢：45 ms
```

## 注意事项

1. **数组 += 陷阱**：PowerShell 中 `$arr += $item` 每次都创建新数组，复杂度 O(n^2)，大数据集必须用 `List` 泛型
2. **GC 非万能**：显式调用 `[GC]::Collect()` 有其代价，不应过度使用，主要依赖 GC 的自动回收
3. **大对象处理**：超过 85KB 的对象进入 LOH，LOH 的碎片化是内存泄漏的常见原因
4. **流式处理**：处理大文件时使用 `StreamReader`/`EnumerateFiles` 代替 `Get-Content`/`Get-ChildItem`，避免一次性加载
5. **对象释放**：使用 `IDisposable` 对象（如 Stream、Connection）后务必调用 `Dispose()` 或使用 `using` 语句
6. **32 位限制**：Windows PowerShell 5.1（32 位）进程有 2GB 内存上限，处理大数据时应使用 64 位 PowerShell
