---
layout: post
date: 2018-12-24 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 结果发送到 PDF（第 3 部分）"
description: PowerTip of the Day - Sending PowerShell Results to PDF (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何在 Windows 10 和 Windows Server 2016 中使用 PowerShell 来设置一个能将任何东西打印到 PDF 文件的打印机，当然，是无人值守的。要使它真的发挥作用，我们将它封装为一个名为 `Out-PDFFile` 的函数。任何通过管道传给这个新命令的内容都会被转换为一个 PDF 文件。

注意：要让这个函数生效，您必须按前一个技能介绍的方法先创建一个名为 `PrintPDFUnattended` 的打印机！

以下是 `Out-PDFFile` 函数：

```powershell
function Out-PDFFile
{
    param
    (
        $Path = "$env:temp\results.pdf",

        [Switch]
        $Open
    )

    # check to see whether the PDF printer was set up correctly
    $printerName = "PrintPDFUnattended"
    $printer = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
    if (!$?)
    {
        Write-Warning "Printer $printerName does not exist."
        Write-Warning "Make sure you have created this printer (see previous tips)!"
        return
    }

    # this is the file the print driver always prints to
    $TempPDF = $printer.PortName

    # is the printer set up correctly and the port name is the output file path?
    if ($TempPDF -notlike '?:\*')
    {
        Write-Warning "Printer $printerName is not set up correctly."
        Write-Warning "Make sure you have created this printer as instructed (see previous tips)!"
        return
    }

    # make sure old print results are removed
    $exists = Test-Path -Path $TempPDF
    if ($exists) { Remove-Item -Path $TempPDF -Force }

    # send anything that is piped to this function to PDF
    $input | Out-Printer -Name $printerName

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
```

现在导出结果到 PDF 文件十分简单：

```powershell
PS> Get-Service | Out-PDFFile -Path $home\desktop\services.pdf -Open

PS> Get-ComputerInfo | Out-PDFFile -Path $home\Desktop\computerinfo.pdf -Open
```

哇哦，真简单！

请注意我们有意地创建了一个“简单函数”。通过这种方式，所有通过管道输入的数据都可以在 `$Input` 自动变量中见到。如果您向参数添加属性，例如要使参数成为必选的，这个函数就变成了“高级函数”，并且 `$Input` 就不存在了。我们将在明天解决这个问题。

- - -

_[psconf.eu](http://www.psconf.eu/) – PowerShell Conference EU 2019 – June 4-7, Hannover Germany – visit [www.psconf.eu](http://www.psconf.eu/) There aren’t too many trainings around for experienced PowerShell scripters where you really still learn something new. But there’s one place you don’t want to miss: PowerShell Conference EU - with 40 renown international speakers including PowerShell team members and MVPs, plus 350 professional and creative PowerShell scripters. Registration is open at www.psconf.eu, and the full 3-track 4-days agenda becomes available soon. Once a year it’s just a smart move to come together, update know-how, learn about security and mitigations, and bring home fresh ideas and authoritative guidance. We’d sure love to see and hear from you!_

<!--本文国际来源：[Sending PowerShell Results to PDF (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-powershell-results-to-pdf-part-3)-->
