layout: post
date: 2015-11-18 12:00:00
title: "PowerShell 技能连载 - 以不同的格式输出文件大小"
description: PowerTip of the Day - Outputting File Sizes in Different Formats
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
当您将一个数值赋给一个变量时，您也许希望按不同的单位显示该数字。字节的方式很清晰，但是有些时候以 KB 或 MB 的方式显示更合适。

以下是一个聪明的技巧，它用一个更多样化的版本覆盖了内置的 ToString() 方法。该方法包括了单位，您希望的位数，以及后缀文字。通过这种方式，您可以根据需要按各种格式显示数字。

变量的内容并没有被改变，所以变量仍然存储着 Integer 数值。您可以安全地用于排序及和其它值比较：

    #requires -Version 1
    
    
    $a = 1257657656
    $a = $a | Add-Member -MemberType ScriptMethod -Name tostring -Force -Value { param($Unit = 1MB, $Digits=1, $Suffix=' MB') "{0:n$Digits}$Suffix" -f ($this/($Unit)) } -PassThru

以下是多种使用 `$a` 的例子：

    PS> $a
    1.199,4 MB
    
    PS> $a.ToString(1GB, 0, ' GB')
    1 GB
    
    PS> $a.ToString(1KB, 2, ' KB')
    1.228.181,30 KB
    
    PS> $a -eq 1257657656
    True
    
    PS> $a -eq 1257657657
    False
    
    PS> $a.GetType().Name
    Int32

<!--more-->
本文国际来源：[Outputting File Sizes in Different Formats](http://community.idera.com/powershell/powertips/b/tips/posts/outputting-file-sizes-in-different-formats)
