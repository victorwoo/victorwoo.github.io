---
layout: post
date: 2017-07-12 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 缺省变量（第三部分）"
description: PowerTip of the Day - Finding PowerShell Default Variables (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用类似如下的方法来查找内置的 PowerShell 变量：

```powershell
$ps = [PowerShell]::Create()
$null = $ps.AddScript('$null=$host;Get-Variable')
$ps.Invoke()
$ps.Runspace.Close()
$ps.Dispose()
```

显然，这段代码还是漏了一些不是由 PowerShell 核心引擎创建的变量，而是由具体宿主加入的变量，例如 powershell.exe，或者 ISE。这些缺失的变量需要手工添加。幸好不是很多：

```powershell
$ps = [PowerShell]::Create()
$null = $ps.AddScript('$null=$host;Get-Variable')
[System.Collections.ArrayList]$result = $ps.Invoke() |
    Select-Object -ExpandProperty Name
$ps.Runspace.Close()
$ps.Dispose()

# add host-specific variables
$special = 'ps','psise','psunsupportedconsoleapplications', 'foreach', 'profile'
$result.AddRange($special)
```

现在这段代码能够获取包含所有保留 PowerShell 变量的列表，并且如果我们还缺少了某些变量，只需要将它们添加到 `$special` 列表即可。

顺便说一下，这段代码完美地演示了如何用 `[System.Collections.ArrayList]` 来创建一个更好的数组。跟常规的 `[Object[]]` 数组相比，`ArrayList` 对象拥有例如 `AddRange()`，能快速批量加入多个元素，等其它方法。

<!--本文国际来源：[Finding PowerShell Default Variables (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-default-variables-part-3)-->
