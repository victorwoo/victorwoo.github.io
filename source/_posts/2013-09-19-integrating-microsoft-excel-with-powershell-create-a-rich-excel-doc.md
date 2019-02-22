---
layout: post
title: "在PowerShell中操作Excel - 创建一个富Excel文档"
date: 2013-09-19 00:00:00
description: 'Integrating Microsoft Excel with PowerShell: Create a Rich Excel Doc'
categories:
- powershell
- office
tags:
- powershell
- script
---
让我们继续《在PowerShell中操作Excel》系列文章。上一次我们掩饰了如何用Microsoft Excel和Windows PowerShell来创建一个基本的报表。从某些方面来讲，我们上次创建的东西和创建CSV并在Excel中打开差不了多少。所以，如果您希望用Excel，让我们彻彻底底地使用它！在今天的文章中，我将沿用上次的演示脚本，但是创建一个更“富（richer）”的Excel文档。下一步，在第三部分中，我将为您演示如何从Excel文件中读取数据。

创建一个富Excel文档
===================

和之前一样，我们将通过WMI获取磁盘信息，并创建一个Excel应用程序对象。

	$disks=Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -Filter "DriveType=3"
	$xl=New-Object -ComObject "Excel.Application"

和Microsoft Word类似，Excel自动化很大程度依赖于使用类似 `xlDown` 等内置常量。我可以记下一个常量值并创建一个变量，或者可以读取包含所需常量的合适的类。在我印象中，我将需要提取以下信息：

	$xlConditionValues=[Microsoft.Office.Interop.Excel.XLConditionValueTypes]
	$xlTheme=[Microsoft.Office.Interop.Excel.XLThemeColor]
	$xlChart=[Microsoft.Office.Interop.Excel.XLChartType]
	$xlIconSet=[Microsoft.Office.Interop.Excel.XLIconSet]
	$xlDirection=[Microsoft.Office.Interop.Excel.XLDirection]

将来当我希望使用 `xlDown` 时，我可以通过 `$xlDirection::xlDown` 来指定它。您等等会看到一些这样的代码。现在，我将像第一部分那样写入磁盘数据，但先让我们加入一些样式。另一种引用电子表格的一部分是使用工作簿对象的 `Range` 属性。您既可以通过类似的方式 A1 引用一个单元格，或者通过类似 A1:A10 的方式引用一个范围。范围（`Range`）对象有一个样式（`Style`）属性。我将把 A1 单元格的样式设置成“Title”，并且把我的表头样式设置成“Heading 2”。

	$range=$ws.range("A1")
	$range.Style="Title"
	#或者用这种方法
	$ws.Range("A3:F3").Style = "Heading 2"

另一个常见的格式化选项是调整列宽。我们可以设置列宽为固定值或者为自动调整列宽。

	$ws.columns.item("C:C").columnwidth=15
	$ws.columns.item("D:F").columnwidth=10.5
	$ws.columns.item("B:B").EntireColumn.AutoFit() | out-null

顺便提一句，我将某些方法，比如 `AutoFit()` 输出到管道 `Out-Null` 来禁止不需要的输出。以下是很有意思的地方：我想如果能用上Excel的条件格式功能将会很酷。具体来说，我想用交通灯图标集来反映每个驱动器的使用量。如我之前所说，既然我们要创建一个Excel文件，那么尽量做到极致。我将为您演示这些代码，不用紧张:)

	$start=$ws.range("F4")
	#获取最后一个单元格
	$Selection=$ws.Range($start,$start.End($xlDirection::xlDown))
	#增加图标集
	$Selection.FormatConditions.AddIconSetCondition() | Out-Null
	$Selection.FormatConditions.item($($Selection.FormatConditions.Count)).SetFirstPriority()
	$Selection.FormatConditions.item(1).ReverseOrder = $True
	$Selection.FormatConditions.item(1).ShowIconOnly = $False
	$Selection.FormatConditions.item(1).IconSet = xlIconSet::xl3TrafficLights1
	$Selection.FormatConditions.item(1).IconCriteria.Item(2).Type = xlConditionValues::xlConditionValueNumber
	$Selection.FormatConditions.item(1).IconCriteria.Item(2).Value = 0.8
	$Selection.FormatConditions.item(1).IconCriteria.Item(2).Operator = 7
	$Selection.FormatConditions.item(1).IconCriteria.Item(3).Type = xlConditionValues::xlConditionValueNumber
	$Selection.FormatConditions.item(1).IconCriteria.Item(3).Value = 0.9
	$Selection.FormatConditions.item(1).IconCriteria.Item(3).Operator = 7

我并不是一夜之间突然知道怎么用PowerShell来做这些事情。相反地，我创建了一个Excel宏，然后应用样式，然后将代码翻译成PowerShell脚本。我希望我可以为您提供一系列翻译的规则，但是碰到一系列障碍和错误。请注意常量的使用？
（译者注：原文为I wish I could give you a set of translation rules, but it just takes trial and error and experience. Notice the use of the constant values?）

下一步，我将为插入一个柱形图到工作表：

	$chart=$ws.Shapes.AddChart().Chart
	$chart.chartType=$xlChart::xlBarClustered

我又一次采用了创建一个宏来观察其中的方法并修正其中的值的方法。接下来，我需要为图表选择数据源。

	$start=$ws.range("A3")
	#获取最后一个单元格
	$Y=$ws.Range($start,$start.End($xlDirection::xlDown))
	$start=$ws.range("F3")
	#获取最后一个单元格
	$X=$ws.Range($start,$start.End($xlDirection::xlDown))

驱动器名称将作为Y轴，%Used将作为X轴。我将用这个区域的集合来定义图表的数据。

	$chartdata=$ws.Range("A$($Y.item(1).Row):A$($Y.item($Y.count).Row),F$($X.item(1).Row):F$($X.item($X.count).Row)")
	$chart.SetSourceData($chartdata)

我希望对这个图表做的最后一件事是增加数据标题和图表标题。

	$chart.seriesCollection(1).Select() | Out-Null
	$chart.SeriesCollection(1).ApplyDataLabels() | out-Null
	$chart.ChartTitle.Text = "Utilization"

Excel很可能并不会按您所希望的位置摆放这个图表，所以您可以使用以下代码来定位它：

	$ws.shapes.item("Chart 1").top=40
	$ws.shapes.item("Chart 1").left=400

`Top` 和 `Left` 是从Excel窗口开始计算的顶边距和左边距。可能会在获取右边距的时候遇到一些障碍和错误，但请注意在多台计算机上进行测试。最后一步是将工作表以计算机名来命名。

	$xl.worksheets.Item("Sheet1").name=$name

当您明白所有这些Excel的魔法师如何工作的，那么要为您希望查看的每台计算机增加一个工作表也不是那么难了。以下截图显示最终的结果：

![增强的Excel报表](/img/2013-09-19-integrating-microsoft-excel-with-powershell-create-a-rich-excel-doc-001.png)

结论
====
您可以[下载](/download/New-ExcelDiskSpace2.ps1)我的演示脚本并且自己进行测试。如果您的确需要写数据到Excel，我建议您完整地操作一遍。也许需要掌握一些基础知识，但这方面的努力是值得的。下一步我们将演示如何从Excel文件中读取数据。

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
