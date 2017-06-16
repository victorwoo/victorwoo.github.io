---
layout: post
date: 2017-06-12 00:00:00
title: "PowerShell 技能连载 - 查看函数源码"
description: PowerTip of the Day - Spying on Function Source Code
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
以下是一种快速查看 PowerShell 函数源码的方法：

```powershell
${function:Clear-Host} | clip
```

这将会把 `Clear-Host` 的源代码复制到剪贴板中，并且当您粘贴它时，您可以看到 `Clear-Host` 是如何工作的：

```powershell
$RawUI = $Host.UI.RawUI
$RawUI.CursorPosition = @{X=0;Y=0}
$RawUI.SetBufferContents(
    @{Top = -1; Bottom = -1; Right = -1; Left = -1},
    @{Character = ' '; ForegroundColor = $rawui.ForegroundColor; BackgroundColor = $rawui.BackgroundColor})
```

通常可以从这里学到很多东西。如果您想用非空格的字符填充 PowerShell 控制台，例如绿底白字的 'X'，请试试这段代码：

```powershell
$host.UI.RawUI.SetBufferContents(
    @{Top = -1; Bottom = -1; Right = -1; Left = -1},
    @{Character = 'X'; ForegroundColor = 'Yellow'; BackgroundColor = 'Green'})
```

请注意这只能在真正的 PowerShell 控制台宿主中起作用。

<!--more-->
本文国际来源：[Spying on Function Source Code](http://community.idera.com/powershell/powertips/b/tips/posts/spying-on-function-source-code)
