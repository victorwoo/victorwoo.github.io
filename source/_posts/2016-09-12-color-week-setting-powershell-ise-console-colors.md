layout: post
date: 2016-09-12 00:00:00
title: "PowerShell 技能连载 - 颜色之周: 设置 PowerShell ISE 控制台的颜色"
description: 'PowerTip of the Day - Color Week: Setting PowerShell ISE Console Colors'
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

您可以通过 `$host` 对象改变 PowerShell ISE 控制台的背景色和前景色，这种方式提供了 16 中预设的颜色可选择：

```powershell
PS> $host.UI.RawUI.ForegroundColor = 'Red'

PS> $host.UI.RawUI.ForegroundColor = 'White'

PS>
```

这些命令将前景色先改为红色，然后改回白色。

在 PowerShell ISE 中，您也可以通过 `$psISE` 变量修改这些颜色。在这里可以用 RGB 值构成您自己的背景色和前景色。让我们把 PowerShell ISE 控制台的前景色改为一些别的：

```powershell
PS> $psise.Options.ConsolePaneForegroundColor = '#FFDD98'

PS> $psise.Options.ConsolePaneForegroundColor = '#FFFFFF'
```

第一行将前景色改为微带青色的颜色，下一行将颜色改为白色。

颜色可以用三个十六进制值构成，分别由红色、绿色和蓝色分量组成。

<!--more-->
本文国际来源：[Color Week: Setting PowerShell ISE Console Colors](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-setting-powershell-ise-console-colors)
