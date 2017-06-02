---
layout: post
date: 2016-12-26 00:00:00
title: "PowerShell 技能连载 - 复制着色过的代码"
description: PowerTip of the Day - Copy Color-Coded Code
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
当您在 PowerShell ISE 中选中一段代码并复制到剪贴板时，它是以 RTF 格式复制的并且保留了所有颜色代码和字体信息。您可以将它粘贴到支持 RTF 的应用程序，例如 Word 中，就可以看到格式化并着色好的 PowerShell 代码。

要调节字体大小，您不能用 PowerShell ISE 右下角的滑块。这个滑块只是改变 PowerShell ISE 中的字体大小，并不会影响复制的代码字体大小。

正确的方法是，在 PowerShell ISE 中，选择工具/选项，然后在选项对话框中调节字体大小。

<!--more-->
本文国际来源：[Copy Color-Coded Code](http://community.idera.com/powershell/powertips/b/tips/posts/copy-color-coded-code)
