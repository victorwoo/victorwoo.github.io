layout: post
date: 2015-02-18 12:00:00
title: "PowerShell 技能连载 - 将结果复制到剪贴板"
description: PowerTip of the Day - Copying Results to Clipboard
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

在前一个技能中我们介绍了如何简单地从 `Out-GridView` 的网格视图窗口中复制粘贴信息。不过这并不会复制列头。

您可以将这行代码加到任意命令中，并将它的结果复制到剪贴板中（包括列头）：

    PS> Get-Service | Format-Table -AutoSize -Wrap | Out-String -Width 200 | clip.exe

当您运行完这行代码后，所有服务的清单就保存到剪贴板中了，接下来可以将内容粘贴到 Word 或其它接受文本输入的应用程序中。

请注意 `Format-Table` 和 `Out-String` 的用法：它们确保数据不会按照 PowerShell 控制台的边界来格式化。相反地，可用的宽度被设为设为 200 字符，如果结果仍比这个长，那么将会折行。

如果忽略掉这两个 cmdlet，然后查看一下结果：如果没有它们，文本将会输出到 PowerShell 控制台。过长的结果将会被截断。

为了简化操作，您可以将这行代码封装为一个简单的函数，例如：

    PS> function Out-Clipboard { $input | Format-Table -AutoSize -Wrap | Out-String -Width 1000 | clip.exe }

现在，当您想将结果复制到剪贴板时，可以使用 `Out-Clipboard`：

    PS> Get-Process | Out-Clipboard

<!--more-->
本文国际来源：[Copying Results to Clipboard](http://powershell.com/cs/blogs/tips/archive/2015/02/18/copying-results-to-clipboard-021815.aspx)
