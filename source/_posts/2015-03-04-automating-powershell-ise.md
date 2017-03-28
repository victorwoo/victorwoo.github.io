layout: post
date: 2015-03-04 12:00:00
title: "PowerShell 技能连载 - PowerShell ISE 自动化"
description: PowerTip of the Day - Automating PowerShell ISE
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

PowerShell ISE 是可以通过 `$psISE` 脚本化编程的。这个变量只在 PowerShell ISE 环境中有效。

要获得当前可见的脚本内容，请试试以下代码：

    PS> $psise.CurrentFile.Editor.Text 

这段代码可以实现一个简单的重命名方法，将 PowerShell ISE 当前打开的脚本中的 所有 "testserver" 替换成 "productionserver"（前提是在您当前的脚本代码中有一系列 "testserver" 字眼出现）：

    $psise.CurrentFile.Editor.Text = $psise.CurrentFile.Editor.Text -replace 'testserver', 'ProductionServer'

<!--more-->
本文国际来源：[Automating PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/automating-powershell-ise)
