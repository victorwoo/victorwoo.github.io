---
layout: post
date: 2019-06-19 00:00:00
title: "PowerShell 技能连载 - Left Side of Comparison"
description: PowerTip of the Day - Left Side of Comparison
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当使用比较运算符时，请确保明确的部分放在左边。这是因为 PowerShell 查找运算符的左边并且可能会自动改变右侧的数据类型。并且，当左侧是数组类型时，比较运算符可以作为过滤器使用。

请查看差异：

```powershell
$array = @()

'-'* 80
$array -eq $null
'-'* 80
$null -eq $array
'-'* 80
```

由于要比较数组，比较操作符的工作原理类似于过滤器，在第一个比较中不返回任何内容。而当您交换操作数，结果会返回 `$false`，这才是正确的答案：一个数组，甚至是一个空的数组，不等于 null。

<!--本文国际来源：[Left Side of Comparison](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/left-side-of-comparison)-->

