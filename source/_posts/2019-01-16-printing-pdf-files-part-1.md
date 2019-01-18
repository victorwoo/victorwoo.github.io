---
layout: post
date: 2019-01-16 00:00:00
title: "PowerShell 技能连载 - 打印 PDF 文件（第 1 部分）"
description: PowerTip of the Day - Printing PDF Files (Part 1)
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
如要自动打印 PDF 文档，不幸的是无法使用 `Out-Printer`。`Out-Printer` 只能发送纯文本文档到打印机。

不过，请看一下代码：

```powershell
# adjust this path to the PDF document of choice
$Path = "c:\docs\document.pdf"

Start-Process -FilePath $Path -Verb Print
```

假设您已经安装了可以打印 PDF 文档的软件，这段代码将会把文档发送到关联的程序并自动将它打印到缺省的打印机。

一些软件（例如 Acrobat Reader）执行完上述操作之后仍会驻留在内存里。可以考虑这种方法解决：

```powershell
# adjust this path to the PDF document of choice
$Path = "c:\docs\document.pdf"

# choose a delay (in seconds) for the print out to complete
$PrintDelay = 10

Start-Process -FilePath $Path -Verb Print -PassThru | 
  ForEach-Object{ Start-Sleep $printDelay; $_} | 
  Stop-Process
```

<!--more-->
本文国际来源：[Printing PDF Files (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/printing-pdf-files-part-1)
