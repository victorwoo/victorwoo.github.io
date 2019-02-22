---
layout: post
date: 2018-12-21 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 结果发送到 PDF（第 2 部分）"
description: PowerTip of the Day - Sending PowerShell Results to PDF (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个示例中我们延时了如何使用内置的 "Microsoft Print to PDF" 打印机来将 PowerShell 输出结果发送到 PDF 文件。然而，这个打印机会提示选择选择输出的文件，所以不适合自动化任务。

要禁止文件提示，有一个很少人知道的秘密：只需要对打印机指定一个端口，端口名就是输出的文件路径。换句话说，运行这段代码可以创建一个新打印机，并打印到您选择的文件中：

```powershell
# requires Windows 10 / Windows Server 2016 or better

# choose a name for your new printer
$printerName = 'PrintPDFUnattended'
# choose a default path where the PDF is saved
$PDFFilePath = "$env:temp\PDFResultFile.pdf"
# choose whether you want to print a test page
$TestPage = $true

# see whether the driver exists
$ok = @(Get-PrinterDriver -Name "Microsoft Print to PDF" -ea 0).Count -gt 0
if (!$ok)
{
    Write-Warning "Printer driver 'Microsoft Print to PDF' not available."
    Write-Warning "This driver ships with Windows 10 or Windows Server 2016."
    Write-Warning "If it is still not available, enable the 'Printing-PrintToPDFServices-Features'"
    Write-Warning "Example: Enable-WindowsOptionalFeature -Online -FeatureName Printing-PrintToPDFServices-Features"
    return
}

# check whether port exists
$port = Get-PrinterPort -Name $PDFFilePath -ErrorAction SilentlyContinue
if ($port -eq $null)
{
    # create printer port
    Add-PrinterPort -Name $PDFFilePath 
}

# add printer
Add-Printer -DriverName "Microsoft Print to PDF" -Name $printerName -PortName $PDFFilePath 

# print a test page to the printer
if ($TestPage)
{
    $printerObject = Get-CimInstance Win32_Printer -Filter "name LIKE '$printerName'"
    $null = $printerObject | Invoke-CimMethod -MethodName printtestpage 
    Start-Sleep -Seconds 1
    Invoke-Item -Path $PDFFilePath
}
```

当这段脚本执行以后，可以获得一个全新的名为 `PrintPDFUnattended` 的打印机。并且当打印到该打印机不会产生提示，而是永远输出到临时文件夹的 `PDFResultFile.pdf`。

以下是一段演示如何从 PowerShell 打印 PDF 文件而不产生对话框的方法：

```powershell
# specify the path to the file you want to create
# (adjust if you want)
$OutPath = "$home\desktop\result.pdf"

# this is the file the print driver always prints to
$TempPDF = "$env:temp\PDFResultFile.pdf"

# make sure old print results are removed
$exists = Test-Path -Path $TempPDF
if ($exists) { Remove-Item -Path $TempPDF -Force }

# send PowerShell results to PDF
Get-Service | Out-Printer -Name "PrintPDFUnattended"

# wait for the print job to be completed, then move file
$ok = $false
do { 
    Start-Sleep -Milliseconds 500 
    Write-Host '.' -NoNewline
                
    $fileExists = Test-Path -Path $TempPDF
    if ($fileExists)
    {
        try
        {
            Move-Item -Path $TempPDF -Destination $OutPath -Force -ErrorAction Stop
            $ok = $true
        }
        catch
        {
            # file is still in use, cannot move
            # try again
        }
    }
} until ( $ok )
Write-Host

# show new PDF file in explorer
explorer "/select,$OutPath"
```

当运行这段代码时，将会在桌面上创建一个新的 `result.pdf` 文件。它包含了所有服务的列表。您可以将任何结果通过管道输出到 `Out-Printer` 来创建 PDF 文件。

<!--本文国际来源：[Sending PowerShell Results to PDF (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-powershell-results-to-pdf-part-2)-->
