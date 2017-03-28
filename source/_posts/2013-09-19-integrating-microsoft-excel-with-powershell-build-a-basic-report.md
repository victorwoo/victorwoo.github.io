layout: post
title: "在PowerShell中操作Excel - 创建一个简单的报表"
date: 2013-09-19 00:00:00
description: 'Integrating Microsoft Excel with PowerShell: Build a Basic Report'
categories:
- powershell
- office
tags:
- powershell
- script
- translation
---
除了文本文件之外，Windows系统管理员最常用的工具是Microsoft Excel。我观察论坛中人们的讨论发现，有一大堆关于Excel电子表格讨论。许多人想要读写Excel的方法。通常，我告诉人们如果他们使用PowerShell，那么可以简单地将结果导出到CSV文件，然后用Excel打开，但是您很有可能需要一个真正的Excel文件。


我着手准备写几个关于如何在PowerShell中操作Excel的专题。今天我们将要通过Microsoft Excel和Windows PowerShell创建一个简单的报表。在第二部分中，我将演示如何创建一个更复杂的Excel文档。然后在第三部分中，我将向您演示如何从Excel文件中读取数据。
<!--more-->

创建一个简单的报表
==================

Microsoft Excel包含一个非常复杂的COM对象模型，我们可以在Windows Powershell中和它交互。让我们从头开始创建一个Excel应用程序的对象。

	PS C:\> $xl=New-Object -ComObject "Excel.Application"

执行完这一步以后，Excel已经开始在后台运行，虽然看不见可交互窗口。

	PS C:\> get-process excel
	
	Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id ProcessName
	-------  ------    -----      ----- -----   ------     -- -----------
	    203      23    16392      24340   267     0.28   1280 EXCEL

下一步，我们将要创建一个工作簿对象。

	PS C:\> $wb=$xl.Workbooks.Add()

下一步，我们将要创建一个工作表对象。

	PS C:\> $ws=$wb.ActiveSheet

您可以将任何一个对象通过管道输出到 `Get-Member` 来学习它们。下一步，我们将使这个应用程序可见。

	PS C:\> $xl.Visible=$True

当您开始写脚本的时候，您可以不必做这步。但是这步能帮您检验我们写的PowerShell命令的执行结果。有很多种办法能将信息输入到电子表格中。做为一个简单的任务，我将演示如何使用单元格（`cell`）对象。

	PS C:\> $cells=$ws.Cells

我们可以用行和列坐标来获取每一个单元格对象。

	PS C:\> $cells.item(1,1)

如果您试这行代码，您将获取到很多信息。我们将继续往下并且输入一些信息到这个单元格。

	PS C:\> $cells.item(1,1)=$env:computername

您的计算机名将会被填入 `A1` 单元格。让我们来填入更多的数据。

	PS C:\> $cells.item(1,2)=$env:username
	PS C:\> $cells.item(2,1)=(get-Date)

这个过程真的很简单。您只需要不断地记下当前的位置即可。如果您需要基本的格式，您可以使用每个单元格的 `Font` 属性。

	PS C:\> $cells.item(1,1).font.bold=$True
	PS C:\> $cells.item(1,2).font.bold=$True
	PS C:\> $cells.item(1,1).font.size=16
	PS C:\> $cells.item(1,2).font.size=16

好了，现在我们可以用 `WorkBook` 对象的 `SaveAs()` 方法保存这个文件。

	PS C:\> $wb.SaveAs("c:\work\test.xlsx")

To fully exit, we'll close the workbook and quit Excel.
若要完全退出，我们需要关闭工作簿并且退出Excel。

	PS C:\> $wb.Close()
	PS C:\> $xl.Quit()

如果您检查进程的话，您也许会发现Excel任然在运行，但它将会在5-10分钟之内退出，自少按我的经验是这样。以上是基本的要点，但在圆满完成之前，让我整理一个脚本，将这些材料整合在一起。

	Param([string]$computer=$env:computername)
	
	#get disk data
	$disks=Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -Filter "DriveType=3"
	
	$xl=New-Object -ComObject "Excel.Application" 
	
	$wb=$xl.Workbooks.Add()
	$ws=$wb.ActiveSheet
	
	$cells=$ws.Cells
	
	$cells.item(1,1)="{0} Disk Drive Report" -f $disks[0].SystemName
	$cells.item(1,1).font.bold=$True
	$cells.item(1,1).font.size=18
	
	#define some variables to control navigation
	$row=3
	$col=1
	
	#insert column headings
	"Drive","SizeGB","FreespaceGB","UsedGB","%Free","%Used" | foreach {
	    $cells.item($row,$col)=$_
	    $cells.item($row,$col).font.bold=$True
	    $col++
	}
	
	foreach ($drive in $disks) {
	    $row++
	    $col=1
	    $cells.item($Row,$col)=$drive.DeviceID
	    $col++
	    $cells.item($Row,$col)=$drive.Size/1GB
	    $cells.item($Row,$col).NumberFormat="0"
	    $col++
	    $cells.item($Row,$col)=$drive.Freespace/1GB
	    $cells.item($Row,$col).NumberFormat="0.00"
	    $col++
	    $cells.item($Row,$col)=($drive.Size - $drive.Freespace)/1GB
	    $cells.item($Row,$col).NumberFormat="0.00"
	    $col++
	    $cells.item($Row,$col)=($drive.Freespace/$drive.size)
	    $cells.item($Row,$col).NumberFormat="0.00%"
	    $col++
	    $cells.item($Row,$col)=($drive.Size - $drive.Freespace) / $drive.size
	    $cells.item($Row,$col).NumberFormat="0.00%"
	}
	
	$xl.Visible=$True
	
	$filepath=Read-Host "Enter a path and filename to save the file"
	
	if ($filepath) {
	    $wb.SaveAs($filepath)
	}

这也许是您想在PowerShell里做的事情：用WMI获取磁盘使用信息并将其记录在Excel电子表格中。这段脚本以计算机名做为参数，缺省值为localhost。然后使用Get-WMIObject来获取磁盘信息。

脚本的第一部分看起来应该很熟悉，它创建一个Excel应用程序和对象。该脚本向A1单元格插入一个标题。

	$cells.item(1,1)="{0} Disk Drive Report" -f $disks[0].SystemName
	$cells.item(1,1).font.bold=$True
	$cells.item(1,1).font.size=18

脚本的主体部分从每个逻辑磁盘中提取数据，并且将一些属性写入Excel。由于我需要通过行和列来操作这些单元格对象，所以我将定义一些用来定位用的辅助变量。

	$row=3
	$col=1

通过它们，我可以插入我的表头。

	"Drive","SizeGB","FreespaceGB","UsedGB","%Free","%Used" | foreach {
	    $cells.item($row,$col)=$_
	    $cells.item($row,$col).font.bold=$True
	    $col++
	}

每循环一次，$col就增加1，所以达到向右“移动”的效果。现在我需要遍历disks集合。每次需要“向下”移动一行，并且从第一列开始。

	foreach ($drive in $disks) {
	    $row++
	    $col=1
	    $cells.item($Row,$col)=$drive.DeviceID
	    $col++
	    $cells.item($Row,$col)=$drive.Size/1GB
	    $cells.item($Row,$col).NumberFormat="0"
	    $col++
	...

接下来我将合适的WMI属性插入对应的单元格。每增加一行，我可以从左开始这个过程。请注意我使用了 `NumberFormat` 属性来格式化每个单元格的值。有一种探索的方法是创建一个Excel宏来记下所有您希望的步骤，然后查看生成的VBA代码。通过稍许的练习，您可以将这些命令翻译为PowerShell代码。

当脚本向电子表格写完数据以后，我把它显示出来并且提示用户输入文件名。如果用户输入的文件名，那么文件以该文件名保存。否则，您可以继续编辑电子表格，然后手动保存它。这个演示脚本并不会自动关闭Excel。这个脚本执行的结果如图1所示：

![PowerShell生成的Excel报表](/img/2013-09-19-integrating-microsoft-excel-with-powershell-build-a-basic-report-001.png)

结论
====
我知道还有很多问题，所以我将会把它们总结出来。在第二部分，我们将看到一些高级的格式化选项，以及其它使用Microsoft Excel的深入用法。如果您将要用PowerShell来创建Excel文档，您会尽可能做到极致。

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
