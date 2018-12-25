---
layout: post
date: 2018-12-20 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 结果发送到 PDF（第 1 部分）"
description: PowerTip of the Day - Sending PowerShell Results to PDF (Part 1)
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
Windows 10 和 Windows Server 2016 终于带来了内置的 PDF 打印机，名为 "Microsoft Print to PDF"。您可以在 PowerShell 中用它来创建 PDF 文件。请运行这段代码来测试您的 PDF 打印机：

```powershell
$printer = Get-Printer -Name "Microsoft Print to PDF" -ErrorAction SilentlyContinue
if (!$?)
{
    Write-Warning "Your PDF Printer is not yet available!"
}
else
{
    Write-Warning "PDF printer is ready for use."
}
```

如果您的打印机不能用（或是暂时不能用），那么您可能使用的不是 Windows 10 或 Windows Server 2016，或者 PDF 打印功能尚未启用。请在管理员权限下运行 PowerShell 并执行这段命令来修复它：

```powershell
PS> Enable-WindowsOptionalFeature -Online -FeatureName Printing-PrintToPDFServices-Features 
```

请确保使用管理员权限运行上述代码，您也可以试着使用以下代码：

```powershell
$code = 'Enable-WindowsOptionalFeature -Online -FeatureName Printing-PrintToPDFServices-Features'

Start-Process -Verb Runas -FilePath powershell.exe -ArgumentList "-noprofile -command $code"
```

当 PDF 打印机安装好后，从 PowerShell 中创建 PDF 文件十分简单。只需要将输出结果发送到 `Out-Printer`。以下是一个示例：

```powershell
PS> Get-Service | Out-Printer -Name "Microsoft Print to PDF"
```

打印机驱动将会打开一个对话框，您可以选择输出的文件名。如果不希望显示这个对话框，而以无人值守的方式打印，我们将在明天介绍。

<!--more-->
本文国际来源：[Sending PowerShell Results to PDF (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-powershell-results-to-pdf-part-1)
