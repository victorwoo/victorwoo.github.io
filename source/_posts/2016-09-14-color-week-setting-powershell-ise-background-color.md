layout: post
date: 2016-09-14 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 设置 PowerShell ISE 的背景色"
description: 'PowerTip of the Day - Color Week: Setting PowerShell ISE Background Color'
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

在前一个技能中我们介绍了如何设置 PowerShell ISE 控制台的前景色，以及通过 red、green 和 blue 值指定颜色。

PowerShell ISE 的控制台的背景色也可以用这种方法，不过会产生一些副作用，需要规避。

首先我们将 PowerShell ISE 控制台面板的颜色改为绿底浅灰字：

```powershell
PS C:\> $psise.Options.ConsolePaneForegroundColor =
[System.Windows.Media.Colors]::LightGray
 
PS C:\> $psise.Options.ConsolePaneBackgroundColor =
[System.Windows.Media.Colors]::DarkGreen

PS C:\>
PS C:\>"Hello"
Hello
 
PS C:\>
```


颜色改变了，但是提示符以及所有其它的输出还是原来的颜色。这是因为在 PowerShell ISE 中还有第三个设置，它决定了文字的背景色：

```powershell
PS C:\>$psise.Options.ConsolePaneTextBackgroundColor =
[System.Windows.Media.Colors]::DarkGreen
 
PS C:\> "Hello"
Hello
```

现在看起来一切完美了。

<!--more-->
本文国际来源：[Color Week: Setting PowerShell ISE Background Color](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-setting-powershell-ise-background-color)
