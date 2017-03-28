layout: post
date: 2015-11-05 12:00:00
title: "PowerShell 技能连载 - 将数字列表转换为有用的列表"
description: PowerTip of the Day - Turning Lists of Numbers Into Useful Lists
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
PowerShell 将 "`..`" 操作符的功能定义为生成一个数字列表。通过 `-join` 操作符，您可以将这些数字转换为几乎您想要的所有东西，例如逗号分隔的值。

当您希望将数字转换为字符时，您也可以将 ASCII 码转换为字母。

用管道将它们输出到 `ForEach-Object`，您就可以将它进一步处理成驱动器号。

或者使用 `-f` 操作符来创建服务器列表。以下是示例代码：

    #requires -Version 1
    
    
    1..10 -join ','
    
    [Char[]][Byte[]](65..90) -join ','
    
    ([Char[]][Byte[]](65..90) | ForEach-Object { $_ + ':\' })  -join ','
    
    1..10 | ForEach-Object { 'Server{0:0000}' -f $_ }

<!--more-->
本文国际来源：[Turning Lists of Numbers Into Useful Lists](http://community.idera.com/powershell/powertips/b/tips/posts/turning-lists-of-numbers-into-useful-lists)
