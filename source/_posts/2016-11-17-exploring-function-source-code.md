layout: post
date: 2016-11-16 16:00:00
title: "PowerShell 技能连载 - 探索函数源码"
description: PowerTip of the Day - Exploring Function Source Code
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
在 PowerShell 中，cmdlet 和 function 的唯一根本区别是它们是怎么编程的：函数用的是纯粹的 PowerShell 代码，这也是查看它们的源代码，并学习新东西的有趣之处。

这行代码列出所有当前从 module 中加载的所有 PowerShell function：

```powershell
Get-Module | ForEach-Object { Get-Command -Module $_.Name -CommandType Function }
```

一旦您知道了内存中某个函数的名字，可以用这种方法快捷查看它的源代码。在这些例子中，我们将探索 `Format-Hex` 函数。只需要将这个名字替换成内存中存在的其它函数名即可：

```powershell
${function:Format-Hex} | clip.exe
```

这行代码将源代码存入剪贴板，您可以将它粘贴到您喜欢的编辑器中。另外，您也可以用这种方式运行：

```powershell
Get-Command -Name Format-Hex -CommandType Function |
  Select-Object -ExpandProperty Definition |
  clip.exe
```

<!--more-->
本文国际来源：[Exploring Function Source Code](http://community.idera.com/powershell/powertips/b/tips/posts/exploring-function-source-code)
