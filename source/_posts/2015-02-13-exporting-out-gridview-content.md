---
layout: post
date: 2015-02-13 12:00:00
title: "PowerShell 技能连载 - 导出 Out-GridView 的内容"
description: 'PowerTip of the Day - Exporting Out-GridView Content '
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

`Out-GridView` 是一个非常有用的将结果输出到一个外部窗口的 cmdlet。和输出到控制台不同，`Out-GridView` 不会将文本截断。不过它好像没有很明显的方法将信息拷贝出来。

试试这种方法！首先，生成一些数据，然后将它用管道输出到网格视图窗口：

    PS> Get-Process | Out-GridView

接下来，可以用顶部的文本框过滤结果，或单击列头来排序。

最后，要将信息导出到别的地方，例如要将进程列表导出到一个 Word 文档中，只需要在结果的任意位置单击，然后按下 `CTRL+A` 全选，然后按 `CTRL+C` 将选中的内容复制到剪贴板。

这样，您可以简单地将复制的数据粘贴到您要的应用程序中。不幸的是，列头并不会被复制到剪贴板中。

请注意 `Out-GridView` 有个内置的限制：它只能显示最多 30 个属性（列）。所以如果您的输入数据有更多的属性，您可能需要限制只显示您确实需要的属性：

    PS> Get-Process | Select-Object -Property Name, Company, StartTime | Out-GridView

<!--本文国际来源：[Exporting Out-GridView Content ](http://community.idera.com/powershell/powertips/b/tips/posts/exporting-out-gridview-content)-->
