layout: post
date: 2015-11-25 12:00:00
title: "PowerShell 技能连载 - 理解 -f 操作符"
description: "PowerTip of the Day - Understanding the –f Operator"
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
您也许已经遇到过 `-f` 操作符并且很好奇它做了什么。它是一个格式化操作符并且提供了一种相当简单的方法来操作数组元素并创建字符串。

让我们从一个值数组开始，比如这个：

    $info = 'PowerShell', $PSVersionTable.PSVersion.Major, $pshome

您可以通过序号访问单个数组元素。

     
    PS> $info[0]
    PowerShell
    
    PS> $info[1]
    4
    
    PS> $info[2]
    C:\Windows\System32\WindowsPowerShell\v1.0

如果您需要将该数组的元素合并为一个字符串，这时候 `-f` 操作符就能够大显身手了。它能够使用相同的序号来读取数组元素并将它们组成一个字符串。以下是一些例子，它们使用 `$info` 中的信息来组成不同的字符串：

    PS> '{0} Version is {1}. Location "{2}' -f $info
    
    PowerShell Version is 4. Location "C:\Windows\System32\WindowsPowerShell\v1.0
    
    PS> '{0} {1}' -f $info
    
    PowerShell 4
    
    PS> '{0} {1:0.0}' -f $info
    
    PowerShell 4.0
    
    PS> '{0}: {2}' -f $info
    
    PowerShell: C:\Windows\System32\WindowsPowerShell\v1.0

<!--more-->
本文国际来源：[Understanding the –f Operator](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-the-f-operator)
