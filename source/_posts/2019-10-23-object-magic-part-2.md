---
layout: post
date: 2019-10-23 00:00:00
title: "PowerShell 技能连载 - 对象的魔法（第 2 部分）"
description: PowerTip of the Day - Object Magic (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过隐藏的 "`PSObject`" 属性，您可以获取对象成员的详细信息。例如，如果您希望知道哪个属性可以被改变，请试试这段代码：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$object.PSObject.Properties.Where{$_.IsSettable}.Name
```

结果是进程对象的可以被赋值的属性列表：

    MaxWorkingSet
    MinWorkingSet
    PriorityBoostEnabled
    PriorityClass
    ProcessorAffinity
    StartInfo
    SynchronizingObject
    EnableRaisingEvents
    Site

类似地，您可以轻松地找出所有当前没有值（为空）的属性：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$object.PSObject.Properties.Where{$null -eq $_.Value}.Name
```

<!--本文国际来源：[Object Magic (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/object-magic-part-2)-->

