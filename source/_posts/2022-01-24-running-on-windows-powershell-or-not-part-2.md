---
layout: post
date: 2022-01-24 00:00:00
title: "PowerShell 技能连载 - 是否在 Windows PowerShell 中运行（第 2 部分）"
description: "PowerTip of the Day - Running on Windows PowerShell – Or Not? (Part 2)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们介绍了一个向后兼容的单行代码，能够判断您的脚本是否运行在传统的 Windows PowerShell 环境中，还是运行在新的 PowerShell 7 便携版 shell 中。

如果您使用的是跨平台的 PowerShell 7，那么有一个名为 `[Management.Automation.platform]` 的新类型，能返回更多的平台信息。Windows PowerShell 尚未包含此类型，因此您可以使用此类型来确定您是否当前正在 Windows PowerShell 上运行。如果没有，则该类型提供了额外的平台信息：

```powershell
# testing whether type exists
$type = 'Management.Automation.Platform' -as [Type]
$isWPS = $type -eq $null

if ($isWPS)
{
  Write-Warning 'Windows PowerShell'
} else {
  # query all public properties
  $properties = $type.GetProperties().Name
  $properties | ForEach-Object -Begin { $hash = @{} } -Process {
    $hash[$_] = $type::$_
    } -End { $hash }
}
```

在 Windows PowerShell 上，脚本只会产生警告。 在 PowerShell 7 上，它返回一个哈希表，其中包含所有相关平台信息：

    Name                           Value
    ----                           -----
    IsStaSupported                 True
    IsLinux                        False
    IsCoreCLR                      True
    IsWindows                      True
    IsNanoServer                   False
    IsMacOS                        False
    IsWindowsDesktop               True
    IsIoT                          False

<!--本文国际来源：[Running on Windows PowerShell – Or Not? (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/running-on-windows-powershell-or-not-part-2)-->

