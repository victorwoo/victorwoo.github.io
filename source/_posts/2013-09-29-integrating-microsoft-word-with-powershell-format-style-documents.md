layout: post
title: "在PowerShell中操作Word - 使用格式化样式"
date: 2013-09-29 00:00:00
description: 'Integrating Microsoft Word with PowerShell: Format Style Documents'
categories:
- powershell
- office
tags:
- powershell
- script
- translation
---
在这个系列的上一步中，我们演示了[用Windows PowerShell创建Microsoft Word文档][1]的基本步骤。如果您试用了我的示例脚本，您会注意到文档格式化方面略有不足。幸运的是，我们有一些简洁的办法来改进您文档的质量，我将会在这篇文章中向您演示这个过程。我们将用第一部分的脚本作为起点。
<!--more-->

关键之处在于 `Selection` 对象。

	PS C:\>$word=new-object -ComObject "Word.Application"
	PS C:\>$doc=$word.documents.Add()
	PS C:\> $selection=$word.Selection

您可以更改 `Selection` 对象的一个重要元素是 `Font`。您可以轻松地修改字体大小和颜色，以及使用哪种字体。我将把日期和时间的字体改为绿色。

	PS C:\> $selection.Font.Color="wdColorGreen"
	PS C:\> $selection.TypeText((Get-Date))

在VBScript的年代中，我们需要定义 *wdColorGreen* 的值并将它赋给一个常量。但是在PowerShell中我们可以轻松地以字符串的形式插入这个常量。您一定很好奇有哪些颜色可以使用？问问PowerShell吧：

	PS C:\> [enum]::GetNames([microsoft.office.interop.word.wdcolor])

您需要把字体颜色改回来，除非您需要把整个文档设为这个颜色。

	PS C:\ >$selection.font.Color="wdColorAutomatic"
	PS C:\> $selection.TypeParagraph()

在我原先的脚本中我插入了一个标题。现在我们把它变成大一点的字体。我将用我上次使用的WMI代码。

	$selection.Font.Size=12
	$selection.TypeText("Operating System Information for $($os.CSName)")

回顾一下前面一篇文章，有一个问题是PowerShell输出到Word早期是用等宽字体而后来用的是非等宽字体。解决方法是从PowerShell中插入结果之前指定一个合适的字体。

	PS C:\> $selection.Font.Size=10
	PS C:\> $selection.Font.Name="Consolas"
	PS C:\> $selection.TypeText(($os | Select -Property $props | Out-String))

还要做的最后一件事是添加一段格式化的文本，说明报告的创建者。我希望采用Word的斜体格式来呈现。

	PS C:\> $selection.Font.size=8
	PS C:\> $selection.Font.Name="Calibri"
	PS C:\> $selection.Font.Italic=$True
	PS C:\> $by="Report created by $env:userdomain\$env:username"
	PS C:\> $selection.TypeText($by)

我相信您一定也掌握了如何使文本变成粗体。

除了指定字体之外，您还可以采用Word内置的样式。

	$selection.Style="Title"
	$selection.TypeText("Operating System Report")
	$selection.TypeParagraph()

您可以用PowerShell查询 `Document` 对象，看看有哪些样式可以用。

	$doc.Styles | select NameLocal

大多数这些样式只能应用在文本的第一行，不过您也可以自己做实验调整一下。

通过这些步骤您可以简洁地通过您的PowerShell脚本创建一个漂亮的Word文档。请下载版本修订过的脚本，[New-WordDoc2](/download/New-WordDoc2.ps1)，并且自己做一下实验。

用PowerShell操作Office系列文章
============================
* [在PowerShell中操作Word - 生成文档][1]
* [在PowerShell中操作Word - 使用格式化样式][2]
* [在PowerShell中操作Excel - 创建一个简单的报表][3]
* [在PowerShell中操作Excel - 创建一个富Excel文档][4]
* [在PowerShell中操作Excel - 读取数据][5]

[1]: /powershell/office/2013/09/28/integrating-microsoft-word-with-powershell-generate-a-document "在PowerShell中操作Word - 生成文档"
[2]: /powershell/office/2013/09/29/integrating-microsoft-word-with-powershell-format-style-documents "在PowerShell中操作Word - 使用格式化样式"
[3]: /powershell/office/2013/09/19/integrating-microsoft-excel-with-powershell-build-a-basic-report "在PowerShell中操作Excel - 创建一个简单的报表"
[4]: /powershell/office/2013/09/19/integrating-microsoft-excel-with-powershell-create-a-rich-excel-doc "在PowerShell中操作Excel - 创建一个富Excel文档"
[5]: /powershell/office/2013/09/21/integrating-microsoft-excel-with-powershell-reading-data "在PowerShell中操作Excel - 读取数据"
