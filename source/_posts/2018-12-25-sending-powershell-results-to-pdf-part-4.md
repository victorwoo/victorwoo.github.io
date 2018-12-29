---
layout: post
date: 2018-12-25 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 结果发送到 PDF（第 4 部分）"
description: PowerTip of the Day - Sending PowerShell Results to PDF (Part 4)
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
在前一个技能中我们将建了 `Out-PDFFile` 函数，能够接受任意 PowerShell 的结果数据并将它们转换为 PDF 文件——使用 Windows 10 和 Windows Server 2016 内置的打印驱动。

我们使用了一个简单的函数，用 `$Input` 自动变量来读取管道输入的数据，从而达到上述目的。如果您更希望使用高级函数，利用它们的必选参数等功能，我们将该工程包装成一个更优雅的高级函数，它能够在检测到未安装 PDF 打印机的情况下先安装它：

```powershell
function Out-PDFFile
{
    param
    (
        [Parameter(Mandatory)]
        [String]
        $Path,

        [Parameter(ValueFromPipeline)]
        [Object]
        $InputObject,

        [Switch]
        $Open
    )

    begin
    {
        # check to see whether the PDF printer was set up correctly
        $printerName = "PrintPDFUnattended"
        $printer = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
        if (!$?)
        {
            $TempPDF = "$env:temp\tempPDFResult.pdf"
            $port = Get-PrinterPort -Name $TempPDF -ErrorAction SilentlyContinue
            if ($port -eq $null)
            {
                # create printer port
                Add-PrinterPort -Name $TempPDF 
            }

            # add printer
            Add-Printer -DriverName "Microsoft Print to PDF" -Name $printerName -PortName $TempPDF 
        }
        else
        {
            # this is the file the print driver always prints to
            $TempPDF = $printer.PortName
            
            # is the port name is the output file path?
            if ($TempPDF -notlike '?:\*')
            {
                throw "Printer $printerName is not set up correctly. Remove the printer, and try again."
            }
        }

        # make sure old print results are removed
        $exists = Test-Path -Path $TempPDF
        if ($exists) { Remove-Item -Path $TempPDF -Force }
        
        # create an empty arraylist that takes the piped results
        [Collections.ArrayList]$collector = @()
    }

    process
    {
        $null = $collector.Add($InputObject)
    }

    end
    {
        # send anything that is piped to this function to PDF
        $collector | Out-Printer -Name $printerName

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
                    Move-Item -Path $TempPDF -Destination $Path -Force -ea Stop
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

        # open file if requested
        if ($Open)
        {
            Invoke-Item -Path $Path
        }
    }
}
```

假设您使用的是 Windows 10 或 Windows 2016，并且 "Microsoft Print to PDF" 打印机可用，那么您可以像这样方便地创建 PDF 文档：

```powershell
PS> Get-Service | Out-PDFFile -Path $home\desktop\services.pdf -Open

PS> Get-ComputerInfo | Out-PDFFile -Path $home\Desktop\computerinfo.pdf -Open 
```

如果指定的 "PrintPDFUnattended" 打印机还未安装，该函数也会事先安装该打印机。

<!--more-->
本文国际来源：[Sending PowerShell Results to PDF (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-powershell-results-to-pdf-part-4)
