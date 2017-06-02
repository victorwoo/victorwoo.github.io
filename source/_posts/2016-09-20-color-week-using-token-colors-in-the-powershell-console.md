---
layout: post
date: 2016-09-20 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 为 PowerShell 控制台中的符号着色"
description: 'PowerTip of the Day - Color Week: Using Token Colors in the PowerShell Console'
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
*支持 PowerShell 3 以上版本*

本周我们将关注如何改变 PowerShell 控制台和 PowerShell ISE 的颜色，以便设置您的 PowerShell 环境。

当您在 PowerShell ISE 输入命令的时候符号会被着色，而 PowerShell 控制台并不会。如果您喜欢着色的符号，可以试试 PSReadline 这个很棒的模块。以下是下载和安装的方法：

```powershell
PS C:\> Install-Module -Name PSReadLine -Scope CurrentUser -Force
```

如果不支持 "`Install-Module`" 命令，那么请到 [www.powershellgallery.com](http://www.powershellgallery.com) 下载 "PowerShellGet" MSI 安装包。它为非 PowerShell 5 的环境添加了一系列操作 Microsoft PowerShell Gallery 的功能。

安装好该模块以后，您需要加载它（在 PowerShell 控制台中，而不是在 PowerShell ISE 中）：

```powershell
PS C:\> Import-Module -Name PSReadLine
```

当它加载完成后，PowerShell 控制台就可以显示彩色的符号。

<!--more-->
本文国际来源：[Color Week: Using Token Colors in the PowerShell Console](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-using-token-colors-in-the-powershell-console)
