---
layout: post
date: 2025-04-10 08:00:00
title: "PowerShell 技能连载 - 理解对象模型"
description: PowerTip of the Day - Understanding the Object Model
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- object-model
- basics
- pipeline
---

_适用于 PowerShell 所有版本_

PowerShell 与传统 Shell（如 Bash、CMD）最大的区别在于：PowerShell 处理的是 .NET 对象，而不是纯文本。理解"一切皆对象"这个核心理念，是从入门走向精通 PowerShell 的关键一步。

在 Bash 中，命令输出是一串字符串，你需要用 `awk`、`sed`、`grep` 等工具来解析。而在 PowerShell 中，每条命令的输出都是结构化的对象，拥有属性和方法，可以直接访问和操作。这让自动化脚本更加健壮、可读且易于维护。

## 一切皆对象

让我们从一个简单的例子开始。获取正在运行的进程，看起来像表格，但实际上每个行都是一个 .NET 对象。

```powershell
# 获取进程信息
$process = Get-Process -Name "powershell" | Select-Object -First 1

# 查看 $process 的类型
$process.GetType().FullName
```

```
System.Diagnostics.Process
```

这个 `$process` 变量不是一个字符串，而是一个完整的 `System.Diagnostics.Process` 对象，它拥有丰富的属性和方法。

```powershell
# 直接访问对象的属性
Write-Host "进程 ID：$($process.Id)"
Write-Host "内存占用：$([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
Write-Host "启动时间：$($process.StartTime)"
Write-Host "CPU 时间：$($process.TotalProcessorTime)"
```

```
进程 ID：12345
内存占用：85.32 MB
启动时间：2025/4/10 8:30:15
CPU 时间：00:00:03.4567890
```

## Get-Member 探索对象

`Get-Member` 是 PowerShell 中最重要的工具之一。当你拿到一个对象却不知道它有哪些属性和方法时，`Get-Member` 就是你的"说明书"。

```powershell
# 查看 Get-Date 返回对象的所有成员
Get-Date | Get-Member -MemberType Properties
```

```
   TypeName: System.DateTime

Name        MemberType Definition
----        ---------- ----------
Date        Property   datetime Date {get;}
Day         Property   int Day {get;}
DayOfWeek   Property   System.DayOfWeek DayOfWeek {get;}
DayOfYear   Property   int DayOfYear {get;}
Hour        Property   int Hour {get;}
Kind        Property   System.DateTimeKind Kind {get;}
Millisecond Property   int Millisecond {get;}
Minute      Property   int Minute {get;}
Month       Property   int Month {get;}
Second      Property   int Second {get;}
Ticks       Property   long Ticks {get;}
TimeOfDay   Property   timespan TimeOfDay {get;}
Year        Property   int Year {get;}
```

可以按类型筛选成员，常用的 `MemberType` 包括：`Property`（属性）、`Method`（方法）、`Event`（事件）等。

```powershell
# 查看字符串对象的所有方法
"Hello, PowerShell" | Get-Member -MemberType Method
```

```
   TypeName: System.String

Name           MemberType Definition
----           ---------- ----------
Clone          Method     System.Object Clone()
CompareTo      Method     int CompareTo(string value), int CompareTo(obje...
Contains       Method     bool Contains(string value), bool Contains(stri...
EndsWith       Method     bool EndsWith(string value), bool EndsWith(stri...
Equals         Method     bool Equals(string value), bool Equals(object o...
IndexOf        Method     int IndexOf(string value), int IndexOf(char val...
Insert         Method     string Insert(int startIndex, string value)
PadLeft        Method     string PadLeft(int totalWidth), string PadLeft(...
Remove         Method     string Remove(int startIndex, int count), strin...
Replace        Method     string Replace(string oldValue, string newValue)...
Split          Method     string[] Split(string[] separator), string[] Sp...
Substring      Method     string Substring(int startIndex), string Substr...
ToLower        Method     string ToLower(), string ToLower(cultureInfo cu...
ToUpper        Method     string ToUpper(), string ToUpper(cultureInfo cu...
Trim           Method     string Trim(), string Trim(char[] trimChars)
```

## 类型系统与类型适配

PowerShell 的类型系统建立在 .NET 之上，但做了许多扩展和适配。

### 基本类型

```powershell
# PowerShell 中的常见类型
$int     = 42                    # System.Int32
$double  = 3.14                  # System.Double
$string  = "Hello"               # System.String
$bool    = $true                 # System.Boolean
$array   = @(1, 2, 3)           # System.Object[]
$hashtable = @{ Name = "Test" } # System.Collections.Hashtable
$null    = $null                 # null

# 查看每个变量的类型
@($int, $double, $string, $bool, $array, $hashtable) |
    ForEach-Object { $_.GetType().FullName }
```

```
System.Int32
System.Double
System.String
System.Boolean
System.Object[]
System.Collections.Hashtable
```

### 类型转换

PowerShell 会自动进行很多类型转换，但有时需要手动转换。

```powershell
# 显式类型转换
[string]$number = 42
[int]$text = "123"
[datetime]$dateStr = "2025-04-10"
[xml]$xmlStr = '<root><item>test</item></root>'

Write-Host "字符串数字：'$number'，类型：$($number.GetType().Name)"
Write-Host "文本转整数：$text，类型：$($text.GetType().Name)"
Write-Host "日期字符串：$dateStr，类型：$($dateStr.GetType().Name)"
Write-Host "XML 根节点：$($xmlStr.root.item)"
```

```
字符串数字：'42'，类型：String
文本转整数：123，类型：Int32
日期字符串：2025/4/10 0:00:00，类型：DateTime
XML 根节点：test
```

## 属性和方法的使用

对象不仅有属性（数据），还有方法（行为）。掌握属性和方法的调用是高效使用 PowerShell 的基础。

```powershell
# 操作 DateTime 对象
$now = Get-Date

# 属性访问
Write-Host "当前年份：$($now.Year)"
Write-Host "当前月份：$($now.Month)"
Write-Host "是否闰年：$([datetime]::IsLeapYear($now.Year))"

# 方法调用
Write-Host "明天此时：$($now.AddDays(1))"
Write-Host "上月今天：$($now.AddMonths(-1))"
Write-Host "格式化输出：$($now.ToString('yyyy年MM月dd日 HH:mm:ss'))"
```

```
当前年份：2025
当前月份：4
是否闰年：False
明天此时：2025/4/11 9:30:15
上月今天：2025/3/10 9:30:15
格式化输出：2025年04月10日 09:30:15
```

### 调用静态方法

.NET 类型还有静态方法，通过 `[TypeName]::MethodName()` 调用。

```powershell
# 常用的静态方法
Write-Host "数学运算：[Math]::Round(3.14159, 2) = $([math]::Round(3.14159, 2))"
Write-Host "最大值：[Math]::Max(10, 20) = $([math]::Max(10, 20))"
Write-Host "GUID：$([guid]::NewGuid())"
Write-Host "当前目录：$([Environment]::CurrentDirectory)"
Write-Host "机器名：$([Environment]::MachineName)"
```

```
数学运算：[Math]::Round(3.14159, 2) = 3.14
最大值：[Math]::Max(10, 20) = 20
GUID：a1b2c3d4-e5f6-7890-abcd-ef1234567890
当前目录：C:\Users\Admin
机器名：DESKTOP-WIN2025
```

## 自定义对象

在实际脚本开发中，经常需要创建自定义对象来组织和传递数据。PowerShell 提供了多种创建自定义对象的方式。

### 使用 [PSCustomObject]（推荐）

```powershell
# 使用 [PSCustomObject] 创建自定义对象
$serverInfo = [PSCustomObject]@{
    ComputerName = "SRV-PROD-01"
    IPAddress    = "192.168.1.10"
    OS           = "Windows Server 2022"
    CPU          = 8
    MemoryGB     = 32
    Status       = "运行中"
}

# 访问属性
Write-Host "服务器名：$($serverInfo.ComputerName)"
Write-Host "内存：$($serverInfo.MemoryGB) GB"

# 动态添加属性和成员
$serverInfo | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
    "$($this.ComputerName) ($($this.IPAddress)) - $($this.Status)"
}

Write-Host $serverInfo.ToString()
```

```
服务器名：SRV-PROD-01
内存：32 GB
SRV-PROD-01 (192.168.1.10) - 运行中
```

### 批量创建对象

```powershell
# 从 CSV 数据批量创建对象
$csvData = @(
    "名称,部门,邮箱"
    "张三,运维部,zhangsan@vichamp.com"
    "李四,开发部,lisi@vichamp.com"
    "王五,安全部,wangwu@vichamp.com"
)

$employees = $csvData | ConvertFrom-Csv
$employees | Format-Table -AutoSize
```

```
名称 部门  邮箱
---- ----  ----
张三 运维部 zhangsan@vichamp.com
李四 开发部 lisi@vichamp.com
王五 安全部 wangwu@vichamp.com
```

## 管道中的对象传递

PowerShell 管道的强大之处在于它传递的是完整对象，而非字符串。这意味着下游命令可以精确访问上游输出的属性。

```powershell
# 管道传递对象示例
Get-Process |
    Where-Object { $_.WorkingSet64 -gt 100MB } |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 5 Name,
        @{N='内存(MB)';E={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
        @{N='CPU(秒)';E={[math]::Round($_.TotalProcessorTime.TotalSeconds, 1)}} |
    Format-Table -AutoSize
```

```
Name              内存(MB) CPU(秒)
----              -------- -------
chrome              245.6   127.3
devenv              189.2    85.7
powershell           95.4    12.1
ServiceHub.SettingsHost 52.3     3.8
MSBuild              48.1    15.6
```

管道中的每个环节接收到的都是完整的对象，`Where-Object` 可以精确比较数值大小，`Sort-Object` 可以按任何属性排序，`Select-Object` 可以自由选择和计算输出列。

## 注意事项

- 始终用 `Get-Member` 来探索陌生对象的成员，这是理解 PowerShell 对象的关键
- 注意区分属性（存储数据）和方法（执行操作），方法调用需要加括号
- 使用 `[PSCustomObject]` 创建自定义对象时，哈希表中的键会变成属性名
- 管道中传递的是对象引用，在循环中修改对象属性会影响原始数据
- 字符串在 PowerShell 中也是对象，拥有 `Length`、`Substring`、`Replace` 等丰富成员
- 当输出看似"空"时，检查对象的类型和属性名是否正确，可能只是默认显示格式问题
