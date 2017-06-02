---
layout: post
date: 2014-09-02 11:00:00
title: "PowerShell 技能连载 - 使用 -f 操作符合并字符串和数据"
description: PowerTip of the Day - Using -f Operator to Combine String and Data
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
_适用于 PowerShell 所有版本_

用双引号包围的字符串能够解析变量，所以类似这样的书写方式很常见：

    $name = $host.Name
    "Your host is called $name." 

然而，这种技术有一些限制。如果您想显示对象的属性而不只是变量，将会失败：

    PS> "Your host is called $host.Name."
    Your host is called System.Management.Automation.Internal.Host.InternalHost.Name. 

这是因为 PowerShell 只会解析变量（在例子中是 `$host`），而不是代码中的剩余部分。

而且您也无法控制数字格式。这段代码可以工作，但是显示的小数位数太多，看起来不美观：

    # get available space in bytes for C: drive
    $freeSpace = ([WMI]'Win32_LogicalDisk.DeviceID="C:"').FreeSpace
    
    # convert to MB
    $freeSpaceMB = $freeSpace / 1MB
    
    # output
    "Your C: drive has $freeSpaceMB MB space available." 

`-f` 操作符可以解决这两个问题。它的左侧是一个静态的文本模板，右侧是提供给模板用的值：

    # insert any data into the text template
    'Your host is called {0}.' -f $host.Name 
    
    # calculate free space on C: in MB
    $freeSpace = ([WMI]'Win32_LogicalDisk.DeviceID="C:"').FreeSpace
    $freeSpaceMB = $freeSpace /1MB
    
    # output with just ONE digit after the comma
    'Your C: drive has {0:n1} MB space available.' -f $freeSpaceMB

如您所见，使用 `-f` 可以给您带来两个好处：占位符（花括号）指示 PowerShell 插入点的位置，并且占位符还可以接受格式化信息。“n1”代表小数点后 1 位。只需要调整数值就能满足您的需要。

<!--more-->
本文国际来源：[Using -f Operator to Combine String and Data](http://community.idera.com/powershell/powertips/b/tips/posts/using-f-operator-to-combine-string-and-data)
