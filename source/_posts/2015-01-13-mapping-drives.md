layout: post
date: 2015-01-13 12:00:00
title: "PowerShell 技能连载 - 映射驱动器"
description: PowerTip of the Day - Mapping Drives
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
_适用于 PowerShell 3.0 及以上版本_

要永久地映射一个网络驱动器，请使用 `New-PSDrive` 加上 `-Persist` 参数。这个参数使得驱动器在 PowerShell 之外可见。

要真正地创建一个永久的网络驱动器，请确保加上 `-Scope Global`。如果 `New-PSDrive` 在全局作用域范围之外运行（例如，在一个脚本中运行），该驱动器只会在脚本运行时出现在文件管理器中。

这个实例代码演示了如何映射一个网络驱动器：

    New-PSDrive -Name k -PSProvider FileSystem -Root \\storage2\vid -Persist -Scope Global

<!--more-->
本文国际来源：[Mapping Drives](http://community.idera.com/powershell/powertips/b/tips/posts/mapping-drives)
