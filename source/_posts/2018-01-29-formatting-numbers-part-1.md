---
layout: post
date: 2018-01-29 00:00:00
title: "PowerShell 技能连载 - 格式化数字（第 1 部分）"
description: PowerTip of the Day - Formatting Numbers (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下 `Get-DisplayFileSize` 函数接受任何字节数值，并且返回一个以 "MB"、"GB" 或 "PB" 为单位的，格式良好的大小值。

```powershell
function Get-DisplayFileSize
{
    param([Double]$Number)

    $newNumber = $Number

    $unit = ',KB,MB,GB,TB,PB,EB,ZB' -split ','
    $i = $null
    while ($newNumber -ge 1KB -and $i -lt $unit.Length)
    {
        $newNumber /= 1KB
        $i++
    }

    if ($i -eq $null) { return $number }
    $displayText = "'{0:N2} {1}'" -f $newNumber, $unit[$i]
    $Number = $Number | Add-Member -MemberType ScriptMethod -Name ToString -Value ([Scriptblock]::Create($displayText)) -Force -PassThru
    return $Number
}
```

以下是一些例子：

```powershell
PS> Get-DisplayFileSize -Number 800
800

PS> Get-DisplayFileSize -Number 678678674345
632,07 GB

PS> Get-DisplayFileSize -Number 6.23GB
6,23 GB
```

真正有趣的地方是这个函数返回的并不是字符串。它返回的是原始的数值，而只是覆盖了 `ToString()` 方法。您仍然可以对它进行排序、计算和对比：

```powershell
PS> $n = 1245646233213
PS> $formatted = Get-DisplayFileSize -Number $n
PS> $formatted
1,13 TB

PS> $formatted -eq $n
True

PS> $formatted * 2
2491292466426

PS> Get-DisplayFileSize ($formatted * 2)
2,27 TB
```

<!--本文国际来源：[Formatting Numbers (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/formatting-numbers-part-1)-->
