---
layout: post
date: 2016-09-16 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 改变错误信息颜色"
description: 'PowerTip of the Day - Color Week: Changing Error Message Colors'
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

PowerShell 使用预定义的颜色来显示错误信息、警告信息、详细信息，以及其他输出信息。这些颜色也可以更改。

这段代码将把错误信息改为白底红字。这个颜色更好阅读，特别在演示的时候：

```powershell
$host.PrivateData.ErrorBackgroundColor="White"
$host.PrivateData.ErrorForegroundColor='Red'
```

<!--more-->
本文国际来源：[Color Week: Changing Error Message Colors](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-changing-error-message-colors)
