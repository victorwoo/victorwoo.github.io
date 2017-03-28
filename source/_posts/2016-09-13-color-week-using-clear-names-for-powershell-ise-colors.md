layout: post
date: 2016-09-13 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 为 PowerShell ISE 指定命名的颜色"
description: 'PowerTip of the Day - Color Week: Using Clear Names for PowerShell ISE Colors'
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
本周我们将关注如何改变 PowerShell 控制台和 PowerShell ISE 的颜色，以便设置您的 PowerShell 环境。

在前一个技能中我们将 PowerShell ISE 控制台的前景色改为任意的自定义 RGB 颜色。您也可以从预定义的颜色种选一个：

```powershell
PS> $psise.Options.ConsolePaneForegroundColor = [System.Windows.Media.Colors]::Azure

PS> $psise.Options.ConsolePaneForegroundColor = [System.Windows.Media.Colors]::White
```

在 PowerShell 控制台面板中键入这些代码时，当按下两个冒号后，智能提示将打开一个清单，列出所有预定义的颜色名。这对查找已有的名字十分有用。如果知道一个颜色名，您也可以这样写：

```powershell
PS C:\> $psise.Options.ConsolePaneForegroundColor = 'Azure'

PS C:\> $psise.Options.ConsolePaneForegroundColor = 'DarkGray'

PS C:\> $psise.Options.ConsolePaneForegroundColor = 'White'
```

<!--more-->
本文国际来源：[Color Week: Using Clear Names for PowerShell ISE Colors](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-using-clear-names-for-powershell-ise-colors)
