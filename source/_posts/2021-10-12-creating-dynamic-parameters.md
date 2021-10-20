---
layout: post
date: 2021-10-12 00:00:00
title: "PowerShell 技能连载 - 创建动态参数"
description: PowerTip of the Day - Creating Dynamic Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
动态参数是一种特殊的参数，可以根据运行时条件显示或隐藏。 您的 PowerShell 函数可以例如具有一个参数，并基于用户选择的操作，将显示其他参数。或者，只有在用户具有管理员权限时才能显示参数。

不幸的是，组合动态参数并不是一件轻松的事。借助称为 "dynpar" 的模块，使用动态参数变得同样简单，就像使用“普通”静态参数一样简单，然后您可以简单地使用名为 `[Dynamic()]` 的新属性指定动态参数，该属性告诉 PowerShell 需要满足以哪些条件以显示参数：

```powershell
param
(
    # regular static parameter
    [string]
    $Normal,

    # show -Lunch only at 11 a.m. or later
    [Dynamic({(Get-Date).Hour -ge 11})]
    [switch]
    $Lunch,

    # show -Mount only when -Path refers to a local path (and not a UNC path)
    [string]
    $Path,

    [Dynamic({$PSBoundParameters['Path'] -match '^[a-z]:'})]
    [switch]
    $Mount
)
```

您可以在此处找到一份详细的操作指南：https://github.com/tobiaspsp/modules.dynpar

<!--本文国际来源：[Creating Dynamic Parameters](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-dynamic-parameters)-->

