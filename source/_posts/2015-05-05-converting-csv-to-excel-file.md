layout: post
date: 2015-05-05 11:00:00
title: "PowerShell 技能连载 - 将 CSV 转换为 Excel 文件"
description: PowerTip of the Day - Converting CSV to Excel File
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
PowerShell 可以用 `Export-Csv` 很容易创建 CSV 文件。如果您的系统中安装了 Microsoft Excel，PowerShell 可以调用 Excel 将一个 CSV 文件转换为一个 XLSX Excel 文件。

以下是一段示例代码。它使用 `Get-Process` 来获取一些数据，然后将数据写入一个 CSV 文件。`Export-Csv` 使用 `-UseCulture` 来确保 CSV 文件使用您所安装的 Excel 期望的分隔符。

    $FileName = "$env:temp\Report"
    
    # create some CSV data
    Get-Process | Export-Csv -UseCulture -Path "$FileName.csv" -NoTypeInformation -Encoding UTF8
    
    # load into Excel
    $excel = New-Object -ComObject Excel.Application 
    $excel.Visible = $true
    $excel.Workbooks.Open("$FileName.csv").SaveAs("$FileName.xlsx",51)
    $excel.Quit()
    
    explorer.exe "/Select,$FileName.xlsx"

下一步，Excel 打开该 CSV 文件，然后将数据保存为一个 XLSX 文件。

它工作得很好，不过可能会遇到一个类似这样的异常：

    PS>  $excel.Workbooks.Open("$FileName.csv")
    Exception  calling "Open" with "1" argument(s): "Old format or  invalid type library. (Exception from HRESULT: 0x80028018 
    (TYPE_E_INVDATAREAD))"
    At line:1 char:1
    +  $excel.Workbooks.Open("$FileName.csv")
    +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [],  MethodInvocationException
        + FullyQualifiedErrorId :  ComMethodTargetInvocation

这是一个长期已知的问题。当您的 Excel 语言和您的 Windows 操作系统不一致时可能会碰到。当您的 Windows 操作系统使用一个本地化的 MUI 包时，也许根本不会遇到这个问题。

要解决这个问题，您可以临时改变该线程的语言文化设置来适应您的 Excel 版本：

    $FileName = "$env:temp\Report"
    
    # create some CSV data
    Get-Process | Export-Csv -Path "$FileName.csv" -NoTypeInformation -Encoding UTF8
    
    # load into Excel
    $excel = New-Object -ComObject Excel.Application 
    $excel.Visible = $true
    
    # change thread culture
    [System.Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
    
    $excel.Workbooks.Open("$FileName.csv").SaveAs("$FileName.xlsx",51)
    $excel.Quit()
    
    explorer.exe "/Select,$FileName.xlsx"

这也会带来另外一个问题：当您以 en-US 语言文化设置运行 Excel 的 `Open()` 方法时，它不再需要 CSV 文件使用您的本地化分隔符。现在它需要的是一个以半角逗号分隔的文件，所以第二个脚本去掉了 `-UseCulture` 设置。

<!--more-->
本文国际来源：[Converting CSV to Excel File](http://community.idera.com/powershell/powertips/b/tips/posts/converting-csv-to-excel-file)
