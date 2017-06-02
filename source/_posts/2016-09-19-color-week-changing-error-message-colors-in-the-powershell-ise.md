---
layout: post
date: 2016-09-19 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 改变 PowerShell ISE 中的错误信息颜色"
description: 'PowerTip of the Day - Color Week: Changing Error Message Colors in the PowerShell ISE'
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

在前一个技能中我们介绍了如何改变 PowerShell 预设的颜色，例如错误信息颜色。

在 PowerShell ISE 中，您可将这些颜色设置为指定的 16 种控制台颜色之一：

```powershell
$host.PrivateData.ErrorBackgroundColor="White"
$host.PrivateData.ErrorForegroundColor=
```

而且，PowerShell ISE  也接受自定义的 WPF 颜色。以下代码将设置错误信息为透明底橙色：

```powershell
$host.PrivateData.ErrorBackgroundColor="#00000000"
$host.PrivateData.ErrorForegroundColor=[System.Windows.Media.Colors]::OrangeRed
```

<!--more-->
本文国际来源：[Color Week: Changing Error Message Colors in the PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-changing-error-message-colors-in-the-powershell-ise)
