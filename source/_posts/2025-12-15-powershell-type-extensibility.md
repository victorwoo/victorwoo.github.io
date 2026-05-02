---
layout: post
date: 2025-12-15 08:00:00
updated: 2025-12-15 08:00:00
title: "PowerShell 技能连载 - 类型扩展与格式化"
description: PowerTip of the Day - Type Extension and Formatting in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- types
- format-data
- extended-type-system
- customization
---

_适用于 PowerShell 5.1 及以上版本_

## 背景

PowerShell 的扩展类型系统（Extended Type System，简称 ETS）是它区别于传统 .NET 宿主的核心特性之一。当你对一个 `FileInfo` 对象调用 `.Length` 并看到它以 KB、MB 的友好格式输出时，或者当你对 `DateTime` 对象调用 `.DayOfWeek` 得到中文星期名时，背后都是 ETS 在起作用。ETS 允许你在不修改原始 .NET 类型定义的前提下，为任何对象动态添加属性和方法，甚至自定义它的显示格式。

这种"无侵入式扩展"在实际运维中非常有用。比如你可能希望每个进程对象额外携带一个"内存占用评分"属性，或者让所有服务器连接对象都自带一个 `Test-Port` 方法。这些需求如果靠继承或封装来实现会非常繁琐，而 ETS 可以用几行配置就搞定。同时，PowerShell 的格式化系统（Formatting System）与 ETS 紧密配合，决定了对象在控制台上以表格、列表还是宽格式显示，以及显示哪些列、列宽多少、对齐方式如何。

本文将从 `Update-TypeData` 动态添加属性和方法开始，接着介绍 `Update-FormatData` 自定义显示格式，最后展示如何将类型扩展和格式化配置持久化为 XML 文件，方便在模块中分发。

## 基础：使用 Update-TypeData 添加脚本属性

`Update-TypeData` cmdlet 可以为已存在的 .NET 类型动态注入脚本属性（ScriptProperty）和脚本方法（ScriptMethod）。脚本属性本质上是一段在访问时执行的 PowerShell 脚本，可以基于现有属性计算出新值。下面我们为 `System.IO.FileInfo` 类型添加一个 `SizeCategory` 属性，根据文件大小自动归类。

```powershell
# 为 FileInfo 添加 SizeCategory 脚本属性
Update-TypeData -TypeName System.IO.FileInfo -MemberType ScriptProperty `
    -MemberName SizeCategory -Value {
    $len = $this.Length
    if ($len -lt 1KB) {
        "微型"
    }
    elseif ($len -lt 1MB) {
        "小型"
    }
    elseif ($len -lt 100MB) {
        "中型"
    }
    elseif ($len -lt 1GB) {
        "大型"
    }
    else {
        "超大"
    }
}

# 验证新属性是否生效
$testFiles = @(
    "/tmp/mini-note.txt"
    "/tmp/report-q1.xlsx"
    "/tmp/database-backup.bak"
    "/tmp/archive.tar.gz"
)

# 创建测试文件（不同大小）
$testSizes = @(128, 524288, 52428800, 2147483648)
$index = 0

foreach ($filePath in $testFiles) {
    $dir = Split-Path -Parent $filePath
    if (-not (Test-Path -Path $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    $size = $testSizes[$index]
    $content = [byte[]]::new([math]::Min($size, 1024))
    [System.IO.File]::WriteAllBytes($filePath, $content)

    # 对于需要更大尺寸的文件，用 Stream 扩展
    if ($size -gt 1024) {
        $stream = [System.IO.File]::OpenWrite($filePath)
        $stream.SetLength($size)
        $stream.Close()
    }

    $index++
}

# 输出结果
foreach ($filePath in $testFiles) {
    $file = Get-Item -Path $filePath -ErrorAction SilentlyContinue
    if ($file) {
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        Write-Output "$($file.Name) | 大小: ${sizeKB} KB | 分类: $($file.SizeCategory)"
    }
}

# 清理测试文件
foreach ($filePath in $testFiles) {
    Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
}
```

执行结果示例：

```text
mini-note.txt | 大小: 0.13 KB | 分类: 微型
report-q1.xlsx | 大小: 512 KB | 分类: 小型
database-backup.bak | 大小: 51200 KB | 分类: 中型
archive.tar.gz | 大小: 2097152 KB | 分类: 超大
```

这段代码的关键在于 `Update-TypeData` 的 `-Value` 参数。它接收一段脚本块，在脚本块内通过 `$this` 访问当前对象实例。每次访问 `.SizeCategory` 属性时，PowerShell 都会执行这段脚本并返回结果。注意 `-TypeName` 必须是完全限定的 .NET 类型名称（包含命名空间），不能使用别名。另外，如果同一个属性已经存在，需要加 `-Force` 参数才能覆盖，否则会报错。

## 进阶：添加脚本方法与 CodeMethod

除了属性，ETS 还支持添加脚本方法（ScriptMethod）和代码方法（CodeMethod）。脚本方法与脚本属性类似，用脚本块实现；代码方法则直接引用已编译 .NET 类型中的静态方法，性能更高。下面我们为 `System.Diagnostics.Process` 添加一个 `GetUpTime` 脚本方法和一个 `SafeKill` 方法。

```powershell
# 为 Process 类型添加 GetUpTime 脚本方法
Update-TypeData -TypeName System.Diagnostics.Process `
    -MemberType ScriptMethod `
    -MemberName GetUpTime -Value {
    $startTime = $this.StartTime
    $uptime = (Get-Date) - $startTime
    $hours = [math]::Floor($uptime.TotalHours)
    $minutes = $uptime.Minutes
    return "${hours}小时${minutes}分钟"
}

# 为 Process 类型添加 SafeKill 脚本方法（安全关闭）
Update-TypeData -TypeName System.Diagnostics.Process `
    -MemberType ScriptMethod `
    -MemberName SafeKill -Value {
    param(
        [int]$GracePeriodSeconds = 5
    )

    try {
        $this.CloseMainWindow()
        $this.WaitForExit($GracePeriodSeconds * 1000)

        if (-not $this.HasExited) {
            $this.Kill()
            return "强制终止"
        }
        return "优雅关闭"
    }
    catch {
        return "操作失败: $($_.Exception.Message)"
    }
}

# 演示：获取当前 PowerShell 进程的运行时间
$procs = Get-Process -Id $PID
$uptime = $procs.GetUpTime()
Write-Output "当前进程 (PID: $PID) 已运行: $uptime"

# 演示：获取一组进程的运行时长
$targetNames = @("code", "Terminal", "Finder")
Write-Output ""
Write-Output "进程运行时长统计:"
Write-Output ("-" * 55)

foreach ($name in $targetNames) {
    $found = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($found) {
        foreach ($p in $found) {
            try {
                $up = $p.GetUpTime()
                $memMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
                Write-Output ("{0,-20} PID:{1,-8} 内存:{2,8} MB  运行:{3}" -f `
                    $p.ProcessName, $p.Id, $memMB, $up)
            }
            catch {
                Write-Output ("{0,-20} PID:{1,-8} (无法获取运行时间)" -f `
                    $p.ProcessName, $p.Id)
            }
        }
    }
    else {
        Write-Output ("{0,-20} (未运行)" -f $name)
    }
}
```

执行结果示例：

```text
当前进程 (PID: 48923) 已运行: 2小时34分钟

进程运行时长统计:
-------------------------------------------------------
code                 PID:31245    内存:   412.3 MB  运行:8小时12分钟
code                 PID:31246    内存:    38.7 MB  运行:8小时12分钟
Terminal             PID:1024     内存:   156.2 MB  运行:48小时5分钟
Finder               PID:245      内存:   289.1 MB  运行:120小时0分钟
```

这段代码演示了 `ScriptMethod` 的用法。与 `ScriptProperty` 不同，`ScriptMethod` 的脚本块可以接收 `param` 参数，通过 `$this` 访问当前对象。`SafeKill` 方法展示了在脚本方法中调用对象自身的其他方法（如 `CloseMainWindow`、`Kill`）来构建复合操作。值得注意的是，`try/catch` 在脚本方法中同样有效，可以用来处理进程已退出、权限不足等异常情况。在 Windows 系统上获取进程的 `StartTime` 需要管理员权限，部分系统进程可能会抛出"拒绝访问"异常。

## 实战：自定义格式化视图并持久化

类型扩展让你的对象拥有了新属性，但默认情况下 PowerShell 并不知道该如何展示它们。`Update-FormatData` 可以自定义对象的默认显示格式，而将类型定义和格式定义保存为 XML 文件则能实现跨会话持久化。下面我们创建一个自定义的 `ServerStatus` 对象类型，为它添加格式化视图，并将所有配置保存为可复用的模块文件。

```powershell
# 定义自定义对象类型名称
$TypeName = "MyTools.ServerStatus"

# 创建带类型名的自定义对象
function New-ServerStatus {
    param(
        [string]$Name,
        [string]$IPAddress,
        [string]$Status,
        [int]$ResponseMs,
        [string]$OS
    )

    $obj = [PSCustomObject]@{
        Name       = $Name
        IPAddress  = $IPAddress
        Status     = $Status
        ResponseMs = $ResponseMs
        OS         = $OS
        CheckedAt  = Get-Date
    }

    $obj.PSTypeNames.Insert(0, $TypeName)
    return $obj
}

# 使用 Update-TypeData 为自定义类型添加脚本属性
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty `
    -MemberName UptimeLabel -Value {
    $ts = (Get-Date) - $this.CheckedAt
    return "上次检查于 {0:N0} 秒前" -f $ts.TotalSeconds
} -Force

# 创建测试数据
$servers = @(
    New-ServerStatus -Name "WEB-01" -IPAddress "10.0.1.10" `
        -Status "在线" -ResponseMs 12 -OS "Windows Server 2022"
    New-ServerStatus -Name "WEB-02" -IPAddress "10.0.1.11" `
        -Status "在线" -ResponseMs 18 -OS "Windows Server 2022"
    New-ServerStatus -Name "DB-01" -IPAddress "10.0.2.20" `
        -Status "告警" -ResponseMs 245 -OS "Ubuntu 22.04"
    New-ServerStatus -Name "CACHE-01" -IPAddress "10.0.3.30" `
        -Status "离线" -ResponseMs -1 -OS "CentOS 7"
    New-ServerStatus -Name "API-01" -IPAddress "10.0.4.40" `
        -Status "在线" -ResponseMs 8 -OS "Windows Server 2025"
)

# 默认输出（无格式化，属性多时显示为列表）
Write-Output "=== 默认输出（List 格式）==="
$servers | Select-Object -First 1 | Format-List

# 使用 Format-Table 手动选择列
Write-Output ""
Write-Output "=== 自定义表格输出 ==="
$tableOutput = foreach ($svr in $servers) {
    $color = switch ($svr.Status) {
        "在线" { "Green" }
        "告警" { "Yellow" }
        "离线" { "Red" }
        default { "White" }
    }

    [PSCustomObject]@{
        名称     = $svr.Name
        地址     = $svr.IPAddress
        状态     = $svr.Status
        响应时间 = if ($svr.ResponseMs -ge 0) { "$($svr.ResponseMs) ms" } else { "N/A" }
        操作系统 = $svr.OS
    }
}
$tableOutput | Format-Table -AutoSize

# 演示脚本属性
Write-Output ""
Write-Output "=== 脚本属性 UptimeLabel ==="
foreach ($svr in $servers) {
    Write-Output "  $($svr.Name): $($svr.UptimeLabel)"
}

# 导出类型定义到 XML（供模块加载使用）
$typeXmlPath = "/tmp/MyTools.Types.ps1xml"
$formatXmlPath = "/tmp/MyTools.Format.ps1xml"

# 生成类型 XML
$typeXmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Types>
  <Type>
    <Name>MyTools.ServerStatus</Name>
    <Members>
      <ScriptProperty>
        <Name>UptimeLabel</Name>
        <GetScriptBlock>
          `$ts = (Get-Date) - `$this.CheckedAt
          "上次检查于 {0:N0} 秒前" -f `$ts.TotalSeconds
        </GetScriptBlock>
      </ScriptProperty>
      <ScriptProperty>
        <Name>ResponseGrade</Name>
        <GetScriptBlock>
          `$ms = `$this.ResponseMs
          if (`$ms -lt 0) { return "不可达" }
          if (`$ms -lt 50) { return "优秀" }
          if (`$ms -lt 200) { return "良好" }
          return "缓慢"
        </GetScriptBlock>
      </ScriptProperty>
    </Members>
  </Type>
</Types>
"@

Set-Content -Path $typeXmlPath -Value $typeXmlContent -Encoding UTF8
Write-Output ""
Write-Output "类型定义已导出: $typeXmlPath"
Write-Output "在模块中使用: Update-TypeData -AppendPath `"$typeXmlPath`""
```

执行结果示例：

```text
=== 默认输出（List 格式）===

Name       : WEB-01
IPAddress  : 10.0.1.10
Status     : 在线
ResponseMs : 12
OS         : Windows Server 2022
CheckedAt  : 2025/12/15 10:30:45

=== 自定义表格输出 ===

名称     地址        状态  响应时间  操作系统
----     ----        ----  --------  --------
WEB-01   10.0.1.10   在线  12 ms     Windows Server 2022
WEB-02   10.0.1.11   在线  18 ms     Windows Server 2022
DB-01    10.0.2.20   告警  245 ms    Ubuntu 22.04
CACHE-01 10.0.3.30   离线  N/A       CentOS 7
API-01   10.0.4.40   在线  8 ms      Windows Server 2025

=== 脚本属性 UptimeLabel ===
  WEB-01: 上次检查于 2 秒前
  WEB-02: 上次检查于 2 秒前
  DB-01: 上次检查于 2 秒前
  CACHE-01: 上次检查于 2 秒前
  API-01: 上次检查于 2 秒前

类型定义已导出: /tmp/MyTools.Types.ps1xml
在模块中使用: Update-TypeData -AppendPath "/tmp/MyTools.Types.ps1xml"
```

这段代码涵盖了 ETS 的完整工作流。首先通过 `$obj.PSTypeNames.Insert(0, $TypeName)` 将自定义类型名插入到对象的类型层次链头部，这样 PowerShell 就能识别并应用对应的类型扩展。`Update-TypeData` 为该类型添加了 `UptimeLabel` 脚本属性。最后展示了如何将类型定义导出为 `.ps1xml` 文件——这种 XML 格式是 PowerShell 模块分发类型扩展的标准方式，模块清单（`.psd1`）中的 `TypesToProcess` 字段可以声明这些文件，模块加载时自动注册。

## 注意事项

1. **`Update-TypeData` 在修改类型后对已存在的对象不一定立即生效**。某些情况下需要重新创建对象实例或重新获取对象（例如再次调用 `Get-Process`）才能看到新添加的成员。如果发现新属性不可见，可以尝试先用 `Remove-TypeData` 清除再重新添加。

2. **`.ps1xml` 文件不会自动加载，必须显式注册**。独立脚本中使用 `Update-TypeData -AppendPath` 加载，模块中则通过 `.psd1` 清单文件的 `TypesToProcess` 和 `FormatsToProcess` 字段声明。如果模块有嵌套模块，确保 `.ps1xml` 文件路径正确——推荐使用相对于模块根目录的相对路径。

3. **脚本属性和方法中的 `$this` 指向当前对象实例**，但脚本块在独立的闭包中执行，无法直接访问外层作用域的变量。如果需要传入外部数据，可以使用 `GetNewClosure()` 方法捕获变量，或者将数据存储在对象本身的 NoteProperty 中再在脚本块内通过 `$this` 访问。

4. **`PSTypeNames` 的顺序决定类型解析优先级**。`Insert(0, ...)` 将自定义类型名放在最前面，PowerShell 会优先匹配第一个类型名对应的类型扩展和格式定义。如果多个模块为同一 .NET 类型注册了不同的扩展，后加载的模块可能覆盖先前的定义，建议为自定义类型使用带命名空间前缀的唯一名称（如 `MyCompany.MyModule.MyType`）。

5. **格式化 XML 中不要嵌入复杂的条件逻辑**。`.Format.ps1xml` 支持通过 `<Condition>` 和 `<ScriptBlock>` 实现条件显示，但调试困难且性能较差。复杂的格式化需求建议在脚本中用 `Format-Table`/`Format-List` 配合计算属性（`@{Name=...; Expression=...}`）来实现，既灵活又易于排错。

6. **`Update-TypeData -Force` 会静默覆盖已有成员**。在生产环境使用前务必确认不会与 PowerShell 内置类型扩展或其他模块的扩展产生冲突。可以用 `Get-TypeData -TypeName <名称>` 先查看当前已注册的类型扩展，检查是否存在同名成员。
