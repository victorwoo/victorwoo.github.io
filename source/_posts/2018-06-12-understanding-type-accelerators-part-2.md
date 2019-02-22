---
layout: post
date: 2018-06-12 00:00:00
title: "PowerShell 技能连载 - 理解类型加速器（第 2 部分）"
description: PowerTip of the Day - Understanding Type Accelerators (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 带来了一系列硬编码的类型加速器，它们的效果就像通常使用的 .NET 类型，而且由于它们比原始数据类型名称短很多，所以它们“加快了打字速度”。

一个很少人知道的事实是类型加速器列表是可以扩展的。以下代码添加一个新的名为 "SuperArray" 的类型加速器，它指向 "System.Collections.ArrayList"。


您现在可以创建一个新的“超级数组”（它用起来像普通的数组，但是拥有一系列额外的方法来向指定的位置增删元素，而且附加数组元素也比普通的数组快得多）：

```powershell
[PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Add('SuperArray', [System.Collections.ArrayList])

$a = [superarray]::new()
```

您还可以将一个普通数组转换成“超级数组”：

```powershell
PS> $a = [superarray](1,2,3)

PS> $a.RemoveAt(1)

PS> $a
1
3
```

请注意虽然不用类型加速器也可以完成这项任务。但是得敲这么长的代码：

```powershell
PS> $a = [System.Collections.ArrayList](1,2,3)

PS> $a.RemoveAt(1)

PS> $a
1
3
```

<!--本文国际来源：[Understanding Type Accelerators (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-type-accelerators-part-2)-->
