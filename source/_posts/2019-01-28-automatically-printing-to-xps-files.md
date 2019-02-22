---
layout: post
date: 2019-01-28 00:00:00
title: "PowerShell 技能连载 - 自动打印到 XPS 文件"
description: PowerTip of the Day - Automatically Printing to XPS Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
XPS 是由 Microsoft 开发的类似 PDF 的文档格式。虽然它并没有大规模使用，但它仍然是一种打印信息到文件的很好的内部格式。要无人值守地打印到 XPS 文件，首先您需要设置一个新的打印机，该打印机将自动打印到一个指定的输出文件：

```powershell
#requires -RunAsAdministrator

$OutPath = "$env:temp\out.xps"
$PrinterName = "XPSPrinter"
Add-PrinterPort -Name $OutPath
Add-Printer -Name $PrinterName -DriverName 'Microsoft XPS Document Writer v4' -PortName $OutPath
```

请确保 XPS 查看器已经安装：

```powershell
#requires -RunAsAdministrator
Enable-WindowsOptionalFeature -Online -FeatureName Xps-Foundation-Xps-Viewer -NoRestart
```

基于以上的准备工作，现在要将输出结果自动打印到 XPS 文件非常简单。以下是一个日常使用的打印函数：

```powershell
function Out-PrinterXPS ($Path = $(Read-Host -Prompt 'XPS document path to create'))
{
  $PrinterName = "XPSPrinter"
  $OutPath = "$env:temp\out.xps"

  $exists = Test-Path -Path $OutPath
  if ($exists)
  {
    Remove-Item -Path $OutPath
  }

  $input | Out-Printer -Name $PrinterName
  do
  {
    Start-Sleep -Milliseconds 500
    $exists = Test-Path -Path $OutPath
  } while (!$exists)

  Move-Item -Path $OutPath -Destination $Path -Force
}
```

让我们试试使用它！以下是一行在桌面上创建系统清单报告的代码：

```powershell
# print to this file
$Path = "$home\desktop\inventar.xps"

# pipe the data to the file
systeminfo.exe /FO CSV | ConvertFrom-Csv | Out-PrinterXPS -Path $Path

# open the XPS file with the built-in viewer
Invoke-Item -Path $Path
```

<!--本文国际来源：[Automatically Printing to XPS Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/automatically-printing-to-xps-files)-->
