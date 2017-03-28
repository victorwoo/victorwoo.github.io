layout: post
date: 2016-12-21 00:00:00
title: "PowerShell 技能连载 - 捕获 Linux 输出"
description: PowerTip of the Day - Capturing Linux Output
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
如果您在 Linux 上运行 PowerShell，您可以混合使用 Linux 命令和 PowerShell 命令。要将 Linux 命令的输出赋值给 PowerShell 变量，请像这样写：

```powershell
$content = (ls)
```
请注意“`ls`”在 Windows 系统上是一个别名，但在 Linux 系统上指向的是原始的 ls 命令。

<!--more-->
本文国际来源：[Capturing Linux Output](http://community.idera.com/powershell/powertips/b/tips/posts/capturing-linux-output)
