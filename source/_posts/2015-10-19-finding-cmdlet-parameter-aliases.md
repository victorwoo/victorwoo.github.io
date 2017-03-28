layout: post
date: 2015-10-19 11:00:00
title: "PowerShell 技能连载 - 查找 cmdlet 参数别名"
description: PowerTip of the Day - Finding Cmdlet Parameter Aliases
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
PowerShell cmdlet 和函数可以带有参数，并且这些参数可以有（更短的）别名。一个典型的例子是 `-ErrorAction` 通用参数，它也可以通过 `-ea` 别名访问。

参数别名不是自动完成的。您需要预先知道它们。以下这个脚本可以提取任意 PowerShell 函数或 cmdlet 的参数别名：

    #requires -Version 3
    
    $command = 'Get-Process'
    
    (Get-Command $command).Parameters.Values |
      Select-Object -Property Name, Aliases

<!--more-->
本文国际来源：[Finding Cmdlet Parameter Aliases](http://community.idera.com/powershell/powertips/b/tips/posts/finding-cmdlet-parameter-aliases)
