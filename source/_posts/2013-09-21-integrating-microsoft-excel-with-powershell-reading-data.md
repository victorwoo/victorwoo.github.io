---
layout: post
title: "在PowerShell中操作Excel - 读取数据"
date: 2013-09-21 00:00:00
description: 'Integrating Microsoft Excel with PowerShell: Reading Data'
categories:
- powershell
- office
tags:
- powershell
- script
- translation
---
欢迎回到“在PowerShell中操作Excel”三部曲系列文章。在这一系列的前两部分，我们学习了如何将数据写入Excel并且创建“富”报表，以及额外的格式化选项等Microsoft Excel高级用法。

对于IT专家来说，这个故事的另一半是如何从一个Excel文档中读取数据。它的挑战性在于您必须事先知道工作表的结构。我们可以搜索数据，但那是更复杂的情况。我假设您已有一个用过且了其解结构的Excel文档。这样，用PowerShell读取数据就不那么复杂。
<!--more-->

读取数据
========

像我们在本系列文章的前两部分那样，第一步是创建一个Excel应用程序对象。

	$xl=New-Object -ComObject "Excel.Application"

我将在我的脚本中使用这个Excel文件。

![Excel数据](/img/2013-09-21-integrating-microsoft-excel-with-powershell-reading-data-001.png)

用工作簿对象的 `Open()` 方法打开文件。 

	$wb=$xl.Workbooks.Open($file)
	$ws=$wb.ActiveSheet

$ws对象是我们对数据最重要的的引用点。我需要用的数据从A2单元格开始。在我的测试环境中，我也许知道我需要处理多少行，但是既然我知道从哪儿开始，我可以用一个Do循环来读取每一行，获取数据，进行进一步操作。

	$Row=2
	
	do {
	  $data=$ws.Range("A$Row").Text
	...

通过使用Range属性，我可以获取A2单元格。Text属性是该单元格的值。我的示例脚本将要从第一列获取计算机名，获取一些WMI信息，然后向管道写入一个和电子表格的其它部分数据有关的自定义数据。

当您处理Excel数据的时候，我建议您进行一系列校验。假设单元格里有一个数据，我假设它是一个机器名，那么我会试着ping一下它。

	if ($data) {
	    Write-Verbose "Querying $data" 
	      $ping=Test-Connection -ComputerName $data -Quiet

如果ping通了，我将会使用WMI来获取操作系统名称，否则我会设置$OS变量为$Null。

	if ($Ping) {
	        $OS=(Get-WmiObject -Class Win32_OperatingSystem -Property Caption -computer $data).Caption
	      }
	      else {
	        $OS=$Null

最后，对于每台计算机，我将用 `New-Object` cmdlet创建一个自定义对象。

	New-Object -TypeName PSObject -Property @{
	        Computername=$Data.ToUpper()
	        OS=$OS
	        Ping=$Ping
	        Location=$ws.Range("B$Row").Text
	        AssetAge=((Get-Date)-($ws.Range("D$Row").Text -as [datetime])).TotalDays -as [int]
	      }

请注意我设置的其它属性值，比如说Location，是位于B2单元格，至少对于这台计算机而言。请注意您从它的Text属性获取到的只是文本。但您还可以将它们转换为各种数据类型，就像我对AssetAge属性的处理那样。我从D2单元格读取文本，并把它转换为一个 `DateTime` 对象，于是我可以将它和当前时间做减法，得到一个 `TimeSpan` 对象。该对象有一个 `TotalDays` 属性。

loop循环的最后一步是使行计数器自增1。

	$Row++
	} While ($data)

下一次进入lopp循环的时候，脚本将会处理第3行的数据。直到PowerShell遇到一个空行。在最后，我将关闭文件并且退出。

	$xl.displayAlerts=$False
	$wb.Close()
	$xl.Application.Quit()

我的脚本运行以后生成一下输出结果：

	PS C:\scripts> .\Demo-ReadExcel.ps1
	
	AssetAge     : 687
	Ping         : True
	Computername : SERENITY
	Location     : R1-1
	OS           : Microsoft Windows 7 Ultimate
	
	AssetAge     : 293
	Ping         : True
	Computername : QUARK
	Location     : R1-4
	OS           : Microsoft Windows 7 Professional
	
	AssetAge     : 293
	Ping         : False
	Computername : SERVER01
	Location     : R3-2
	OS           :
	
	AssetAge     : 2005
	Ping         : True
	Computername : JDHIT-DC01
	Location     : R2-1
	OS           : Microsoft(R) Windows(R) Server 2003, Enterprise Edition

我在PowerShell中用数的代码就可以实现从Excel电子表格中读取数据并且在我的程序中使用它。如果需要的话，我可以结合前面文章中的技术，在读取的同时更新电子表格的内容！

结论
====
您可以下载我的[示例脚本](/download/Demo-ReadExcel.ps1)并且自己做一下实验。记住，当使用PowerShell读取Excel文件的时候，您需要事先了解文档的结构，并且做好错误处理和数据有效性验证。我并不推荐初学者用PowerShell操作Excel，但具有一些经验并投入一些耐心以后，您可以得到很丰厚的回报。

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
