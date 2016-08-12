layout: post
date: 2015-01-23 12:00:00
title: "PowerShell 技能连载 - 读取多行文本"
description: PowerTip of the Day - Reading Multiline Text
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

有些时候您偶然会见到类似这样的技巧：

    $FilePath = "$env:SystemRoot\WindowsUpdate.log"
    
    $ContentsWithLinebreaks = (Get-Content $FilePath) -join "`r`n" 

您能否出猜出它的用意？`Get-Content` 缺省情况下返回由一行一行组成的字符串数组，然后 `-join` 操作符将该数组转化为一个字符串。

从 PowerShell 3.0 开始，`Get-Content` 多了一个参数：`-Raw`。它比起刚才的方法高效的多，并且可以得到相同的结果：

    $FilePath = "$env:SystemRoot\WindowsUpdate.log"
    
    $ContentsWithLinebreaks = (Get-Content $FilePath) -join "`r`n"
    
    $ContentsWithLinebreaks2 = Get-Content $FilePath -Raw
    
    $ContentsWithLinebreaks -eq $ContentsWithLinebreaks2

当您使用这段代码时，会发现 `$ontentWithLinebreaks` 和 `$ContentWithLinebreaks2` 是不同的。唯一的区别是在 `$ContentsWithLinebreaks2` 尾部有一个换行符：

    PS> $ContentsWithLinebreaks -eq $ContentsWithLinebreaks2.TrimEnd("`r`n")
    True
    
    PS>

<!--more-->
本文国际来源：[Reading Multiline Text](http://powershell.com/cs/blogs/tips/archive/2015/01/23/reading-multiline-text.aspx)
