---
layout: post
date: 2021-01-07 00:00:00
title: "PowerShell 技能连载 - 查找未使用（或使用过的）驱动器号"
description: PowerTip of the Day - Finding Unused (or Used) Drive Letters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过连接类型转换的结果，您可以轻松创建字母列表：

```powershell
PS> [Char[]](65..90)
A
B
C
D
...
```

从此列表中，您可以生成正在使用的驱动器号的列表：

```powershell
PS> [Char[]](65..90) | Where-Object { Test-Path "${_}:\" }
C
D
```

同样，要查找空闲的（未使用的）驱动器号，请尝试以下操作：

```powershell
PS> [Char[]](65..90) | Where-Object { (Test-Path "${_}:\") -eq $false }
A
B
E
F
...
```

<!--本文国际来源：[Finding Unused (or Used) Drive Letters](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-unused-or-used-drive-letters)-->

