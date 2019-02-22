---
layout: post
date: 2015-08-10 11:00:00
title: "PowerShell 技能连载 - 避免使用重定向符"
description: PowerTip of the Day - Avoid Using Redirection
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您还在使用旧的重定向操作符来将命令的结果输出到一个文件，那么您可以使用新的 PowerShell cmdlet 来代替。以下是原因：

    #requires -Version 2
    
    $OutPath = "$env:temp\report.txt"
    
    Get-EventLog -LogName System -EntryType Error, Warning -Newest 10 > $OutPath
    
    notepad.exe $OutPath

这将产生一个文本文件，内容和控制台中显示的精确一致，但不会包含任何对象的特性。

下一个例子确保输出的文本一点也不会被截断，并且输出使用 UTF8 编码——这些参数都是简易重定向所不包含的：

    #requires -Version 2
    
    $OutPath = "$env:temp\report.txt"
    
    Get-EventLog -LogName System -EntryType Error, Warning -Newest 10 |
    Format-Table -AutoSize -Wrap |
    Out-File -FilePath $OutPath -Width 100
    
    notepad.exe $OutPath

<!--本文国际来源：[Avoid Using Redirection](http://community.idera.com/powershell/powertips/b/tips/posts/avoid-using-redirection)-->
