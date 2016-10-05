layout: post
date: 2016-02-18 05:00:00
title: "PowerShell 技能连载 - 不要混合不同的对象"
description: PowerTip of the Day - Do Not Mix Different Objects!
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
如果您连续输出完全不同的对象，您可能丢失信息。请看这个例子：

    #requires -Version 2

    $hash = @{
    Name = 'PowerShell Conference EU'
    Date = 'April 20, 2016'
    City = 'Hannover'
    URL = 'www.psconf.eu'
    }
    New-Object -TypeName PSObject -Property $hash
    
    $b = Get-Process -Id $pid
    $b

当您运行这段代码时，您将得到这样的结果：

    Date           URL           Name                     City    
    ----           ---           ----                     ----    
    April 20, 2016 www.psconf.eu PowerShell Conference EU Hannover
                                 powershell_ise

看起来 `$b` (process) 的几乎所有属性都丢失了。原因是 PowerShell 是实时输出对象的，而且首次提交的对象决定了在表格中显示哪些属性。所有接下来的对象都将纳入这张表格中。

如果您必须要输出不同的对象，请将它们用管道输出到 `Out-Host`。每次您输出到 `Out-Host`，PowerShell 都将创建一个具有新的表格标题的输出。

<!--more-->
本文国际来源：[Do Not Mix Different Objects!](http://community.idera.com/powershell/powertips/b/tips/posts/do-not-mix-different-objects)
