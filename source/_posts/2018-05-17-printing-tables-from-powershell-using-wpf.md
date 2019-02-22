---
layout: post
date: 2018-05-17 00:00:00
title: "PowerShell 技能连载 - PowerShell 中打印表格（使用 WPF）"
description: PowerTip of the Day - Printing Tables from PowerShell (using WPF)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您需要以表格的形式显示、打印，或保存为 PDF，使用 WPF (Windows Presentation Foundation) 可能是一种好方法。以前，WPF 是用于定义用户界面，但是您可以用它来定义表格，填充数据，然后打印或者保存它们。

不要因为代码量而拖延。PowerShell 基本上是以面向对象的方式定义表格。

以下示例代码创建一个模块中所有命令的文档。您可以方便地改变代码创建更多列以及更多其他数据的表格。当您运行以下代码时，它打开一个选择打印机的对话框。选择 "Microsoft Print to PDF" 打印机，将输出结果保存为一个 PDF 文档。

请注意：当您在 PowerShell ISE（或任何其它基于 WPF 的编辑器）中运行这段代码，将无法显示打印机对话框，并且将自动打印到缺省的打印机中。当您在 powershell.exe 中运行这段代码，一切正常。

```powershell
# adjust the name of the module
# code will list all commands shipped by that module
# list of all modules: Get-Module -ListAvailable
$ModuleName = "PrintManagement"


# these assemblies provide access to UI
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework

# create a new document
$document = [System.Windows.Documents.FlowDocument]::new()

# create a new table with two columns (20%, 80% width)
$table = [System.Windows.Documents.Table]::new()
$column1 = [System.Windows.Documents.TableColumn]::new()
$column1.Width = [System.Windows.GridLength]::new(20, [System.Windows.GridUnitType]::Star)
$table.Columns.Add($column1)
$column2 = [System.Windows.Documents.TableColumn]::new()
$column2.Width = [System.Windows.GridLength]::new(80, [System.Windows.GridUnitType]::Star)
$table.Columns.Add($column2)

# create a new rowgroup that will store the table rows
$rowGroup = [System.Windows.Documents.TableRowGroup]::new()


# produce the command data to display in the table
Get-Command -Module $moduleName | 
Get-Help | 
ForEach-Object {
    # get the information to be added to the table
    $name = $_.Name
    $synopsis = $_.Synopsis
    $description = $_.Description.Text -join ' '

    # create a new table row
    $row = [System.Windows.Documents.TableRow]::new()

    # add a cell with the command name in bold:
    $cell = [System.Windows.Documents.TableCell]::new()
    $cell.Padding = [System.Windows.Thickness]::new(0,0,10,0)
    $para = [System.Windows.Documents.Paragraph]::new()
    $inline = [System.Windows.Documents.Run]::new($name)
    $inline.FontWeight = "Bold"
    $inline.FontSize = 12
    $inline.FontFamily = "Segoe UI"
    $para.Inlines.Add($inline)
    $cell.AddChild($para)
    $row.AddChild($cell)

    # add a second cell with the command synopsis
    $cell = [System.Windows.Documents.TableCell]::new()    
    $para = [System.Windows.Documents.Paragraph]::new()
    $inline = [System.Windows.Documents.Run]::new($synopsis)
    $inline.FontSize = 12
    $inline.FontFamily = "Segoe UI"
    $para.Inlines.Add($inline)
    $cell.AddChild($para)
    $row.AddChild($cell)

    # add both cells to the table
    $rowGroup.AddChild($row)
    
    # add a second table row than spans two columns and holds the 
    # command description in a smaller font:
    $row = [System.Windows.Documents.TableRow]::new()
    $cell = [System.Windows.Documents.TableCell]::new()
    $cell.ColumnSpan = 2
    # add a 20pt gap at the bottom to separate from next command
    $cell.Padding = [System.Windows.Thickness]::new(0,0,0,20)
    $para = [System.Windows.Documents.Paragraph]::new()
    $inline = [System.Windows.Documents.Run]::new($description)
    $inline.FontSize = 10
    $inline.FontFamily = "Segoe UI"
    $para.Inlines.Add($inline)
    $cell.AddChild($para)
    $row.AddChild($cell)
    # add row to table:
    $rowGroup.AddChild($row)
}

# add all collected table rows to the table, and add the table
# to the document
$table.AddChild($rowGroup)
$document.AddChild($table)

# add a paginator that controls where pages end and new pages start:
[System.Windows.Documents.IDocumentPaginatorSource]$paginator = $document

# create a print dialog to select the printer
$printDialog = [System.Windows.Controls.PrintDialog]::new()
# print dialog can not be shown in ISE due to threading issues
# selecting a printer will work only when running this code in powershell.exe
# else, the default printer is used
try 
{
    $result = $printDialog.ShowDialog()
    if ($result -eq $false) { 
        Write-Warning "User aborted."
        return 
    }
}
catch {}

# make sure the document is not printed in multiple columns
$document.PagePadding = [System.Windows.Thickness]::new(50)
$document.ColumnGap = 0
$document.ColumnWidth = $printDialog.PrintableAreaWidth

# print the document
$printDialog.PrintDocument($paginator.DocumentPaginator, "WPF-Printing from PowerShell")
```

<!--本文国际来源：[Printing Tables from PowerShell (using WPF)](http://community.idera.com/powershell/powertips/b/tips/posts/printing-tables-from-powershell-using-wpf)-->
