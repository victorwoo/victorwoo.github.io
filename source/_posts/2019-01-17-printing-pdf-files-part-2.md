---
layout: post
date: 2019-01-17 00:00:00
title: "PowerShell 技能连载 - 打印 PDF 文件（第 2 部分）"
description: PowerTip of the Day - Printing PDF Files (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何用 PowerShell 将 PDF 文档发送到缺省的 PDF 打印机。这个通用方案对于简单场景是没问题的，但是无法让用户指定打印机。

如果使用特定的软件可以控制更多内容，因为您可以使用该软件暴露的特殊功能。

以下示例使用 Acrobat Reader 来打印到 PDF 文档。它展示了如何使用 Acrobat Reader 中的特殊选项来任意选择打印机，此外 Acrobat Reader 打印完文档将会自动关闭。

```powershell
# PDF document to print out
$PDFPath = "C:\docs\document.pdf"

# find Acrobat Reader
$Paths = @(Resolve-Path -Path "C:\Program Files*\Adobe\*\reader\acrord32.exe")

# none found
if ($Paths.Count -eq 0)
{
    Write-Warning "Acrobat Reader not installed. Cannot continue."
    return
}

# more than one found, choose one manually
if ($Paths.Count -gt 1)
{
$Paths = @($Paths |
Out-GridView -Title 'Choose Acrobat Reader' -OutputMode Single)
}

$Software = $Paths[0]

# does it exist?
$exists = Test-Path -Path $Software
if (!$exists)
{
    Write-Warning "Acrobat Reader not found. Cannot continue."
    return
}

# choose printer
$printerName = Get-Printer |
    Select-Object -ExpandProperty Name |
    Sort-Object |
    Out-GridView -Title "Choose Printer" -OutputMode Single

$printer = Get-Printer -Name $printerName
$drivername= $printer.DriverName
$portname=$printer.PortName
$arguments='/S /T "{0}" "{1}" "{2}" {3}' -f $PDFPath, $printername, $drivername, $portname

Start-Process $Software -ArgumentList $arguments -Wait
```

<!--本文国际来源：[Printing PDF Files (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/printing-pdf-files-part-2)-->
