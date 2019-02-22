---
layout: post
date: 2017-04-03 00:00:00
title: "PowerShell 技能连载 - 检查变量是否为 $NULL"
description: PowerTip of the Day - Comparing Against $NULL
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想检查一个变量是否为 `$Null`（空），请记住始终将 `$null` 放在比较运算符的左边。大多数情况下，顺序不重要：

```powershell
PS C:\> $a = $null

PS C:\> $b = 12

PS C:\> $a -eq $null
True

PS C:\> $b -eq $null
False
```

然而，如果一个变量为一个数组，则将数组放在对比操作符左边的行为类似过滤器。这时候顺序变得很关键：

```powershell
# this all produces inconsistent and fishy results
    
$a = $null
$a -eq $null  # works: returns $true
    
$a = 1,2,3
$a -eq $null  # fails: returns $null
    
$a = 1,2,$null,3,4
$a -eq $null  # fails: returns $null
    
$a = 1,2,$null,3,4,$null,5
$a -eq $null  # fails: returns array of 2x $null
($a -eq $null).Count
```

如果您将变量放在左侧，PowerShell 将检测数组内部的 `$null` 值，并且返回这些值。如果没有 `$null` 值，则返回 `$null`。

如果您将变量放在右侧，PowerShell 将检查变量是否为 `$null`。

```powershell
# by reversing the operands, all is FINE:
    
$a = $null
$null -eq $a  # works: $true
    
$a = 1,2,3
$null -eq $a  # works: $false
    
$a = 1,2,$null,3,4
$null -eq $a  # works: $false
    
$a = 1,2,$null,3,4,$null,5
$null -eq $a  # works: $false
```

可以将 `$null` 放在比较运算符的左侧而不是右侧，来消除这个问题。

<!--本文国际来源：[Comparing Against $NULL](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-against-null)-->
