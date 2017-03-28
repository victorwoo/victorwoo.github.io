layout: post
date: 2016-10-28 00:00:00
title: "PowerShell 技能连载 - Cmelet 错误报告的简单策略"
description: PowerTip of the Day - Simple Strategy for Cmdlet Error Reporting
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
在 PowerShell 中，您可以创建复杂的错误处理代码，但有些时候您可能只是想知道出了什么错并且把它记录下来。不需要额外的技能。

以下是两个可能会遇到错误的 cmdlet。当这些 cmdlet 执行完成时，您将能通过 `$data1` 和 `$data2` 获得它们的执行结果，并在控制台中见到许多红色的错误信息：

```powershell
$data1 = Get-ChildItem -Path c:\windows -Filter *.ps1 -Recurse 
$data2 = Get-Process -FileVersionInfo
```

现在看看这个实验：

```powershell
$data1 = Get-ChildItem -Path c:\windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable errorList
$data2 = Get-Process -FileVersionInfo -ErrorAction SilentlyContinue -ErrorVariable +errorList
```

要禁止错误输出并同时将红色的错误信息写入自定义的错误变量 `$errorList` 并不需要做太多工作。请注意 `-ErrorVariable` 参数接受的是一个变量名（不含 "`$`" 前缀）。并请注意在这个变量名前添加 "`+`" 前缀将能把错误信息附加到变量中，而不是替换变量的值。

现在，两个 cmdlet 运行起来都看不到错误信息了。最后，您可以容易地在 `$errorList` 中容易地分析错误信息，例如用 `Out-File` 将它们写入某些错误日志文件：

```powershell
$issues = $errorList.CategoryInfo | Select-Object -Property Category, TargetName
$issues
$issues | Out-File -FilePath $home\Desktop\report.txt -Append
```
<!--more-->
本文国际来源：[Simple Strategy for Cmdlet Error Reporting](http://community.idera.com/powershell/powertips/b/tips/posts/simple-strategy-for-cmdlet-error-reporting-directory)
