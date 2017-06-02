---
layout: post
title: "在PowerShell中操作Word - 生成文档"
date: 2013-09-28 00:00:00
description: 'Integrating Microsoft Word with PowerShell: Generate a Document'
categories:
- powershell
- office
tags:
- powershell
- script
- translation
---
我假设许多读者用PowerShell生成服务器、事件以及Windows网络上各种数据的报表。您也许创建过纯文本文件，甚至漂亮的HTML报表。但是您也可以用上Microsoft Word，当然，前提是您已经安装了Word。在这个系列的第二部分，我将会向您演示[如何用PowerShell为Word文档套用样式][2]。

创建Word应用程序对象
==================

PowerShell可以通过COM接口控制Word应用程序。有趣的地方是，虽然您可以交互式地做所有的操作，但我希望您最终能够用脚本操作一切。我们从创建一个Word程序对象开始。

	PS C:\> $word=new-object -ComObject "Word.Application"

<!--more-->
如果您好奇的话，可以将这个对象输出到 `Get-Member` 命令。我们将创建一系列对象，您可以将每一个对象通过管道输出到 `Get-Member` 来探索它们。

下一步，我们创建一个文档对象。

	PS C:\> $doc=$word.documents.Add()

现在，Word程序已经启动，并且创建了一个新文档，但是您在屏幕上看不到任何东西。通常这是正常的，因为我们需要它在后台运行。但是如果您想查看所创建的文档，您需要将应用程序的 `Visible` 属性设置为 `True`。

	PS C:\> $word.Visible=$True

在我们插入文本之前，我们需要获取焦点。创建一个 `Selection` 对象可以帮我们做一些诸如设置字体大小和颜色等操作，我们将在第二部分介绍这些操作。

	PS C:\> $selection=$word.Selection

用PowerShell在文档中插入文本
==========================
现在光标在文档的顶部，现在可以开始插入文本了。我们将用 `Selection` 对象的 `TypeText()` 方法插入当前的日期和时间。

	PS C:\> $selection.TypeText((Get-Date))

如果我们继续插入文本，那么文本将会紧挨在日期的后面。现在我们用 `TypeParagraph()` 方法插入一个回车符。

	PS C:\> $selection.TypeParagraph()

让我们继续插入一些文本。我将用WMI获取本地计算机的操作系统信息。

	PS C:\> $os=Get-WmiObject -class win32_OperatingSystem
	PS C:\> $selection.TypeText("Operating System Information for $($os.CSName)")

由于我希望写入所有的非系统属性，所以我将快速递创建一个数组用来保存所有的属性名。

	PS C:\> $os.properties | select Name | foreach -begin {$props=@()} -proc {$props+="$($_.name)"}

现在我可以从 `$os` 获取所有的属性并插入Word文档。很重要的一点是 `TypeText()` 的值是字符串型的，所以我需要将内联的PowerShell表达式通过管道输出到 `Out-String`。

	PS C:\> $selection.TypeText(($os | Select -Property $props | Out-String))

如果需要的话，还可以继续插入文字和图片。当完成操作以后，我将保存并关闭文档。

	PS C:\> $doc.SaveAs([ref]"c:\work\osreport.docx")
	PS C:\> $doc.Close()

请确认使用 `[ref]` 为文件路径转换数据类型。假设我不再创建新的文档，那么剩下的就是关闭Word应用程序。

	PS C:\> $word.quit()

这些就是要做的所有事情。最终生成的Word文档是可用的，虽然可能不太漂亮。在我的例子中发现一个问题：Word用的事非等宽字体，而PowerShell的输出格式假设用的是等宽字体。（译者注：可能会造成输出的结果对不整齐）。在第二部分，我将向您演示如何解决这些问题。同时，欢迎[下载示例脚本 New-WordDoc.ps1](/download/New-WordDoc.ps1)。

用PowerShell操作Office系列文章
============================
* [在PowerShell中操作Word - 生成文档][1]
* [在PowerShell中操作Word - 使用格式化样式][2]
* [在PowerShell中操作Excel - 创建一个简单的报表][3]
* [在PowerShell中操作Excel - 创建一个富Excel文档][4]
* [在PowerShell中操作Excel - 读取数据][5]

[1]: /2013/09/28/integrating-microsoft-word-with-powershell-generate-a-document "在PowerShell中操作Word - 生成文档"
[2]: /2013/09/29/integrating-microsoft-word-with-powershell-format-style-documents "在PowerShell中操作Word - 使用格式化样式"
[3]: /2013/09/19/integrating-microsoft-excel-with-powershell-build-a-basic-report "在PowerShell中操作Excel - 创建一个简单的报表"
[4]: /2013/09/19/integrating-microsoft-excel-with-powershell-create-a-rich-excel-doc "在PowerShell中操作Excel - 创建一个富Excel文档"
[5]: /2013/09/21/integrating-microsoft-excel-with-powershell-reading-data "在PowerShell中操作Excel - 读取数据"
