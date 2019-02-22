---
layout: post
date: 2017-10-16 00:00:00
title: "PowerShell 技能连载 - 用管道将信息输出到 Excel"
description: PowerTip of the Day - Pipe Information to Excel
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个短小但是十分有用的函数，能够从其它 cmdlet 接收数据并发送到 Excel：

```powershell
function Out-Excel
{

    param(
    $path = "$env:temp\report$(Get-Date -Format yyyyMMddHHmmss).csv"
    )

    $Input |
    Export-Csv $path -NoTypeInformation -UseCulture -Encoding UTF8
    Invoke-Item $path
}
```

只需要将任何数据通过管道输出至 `Out-Excel`。例如：

```powershell
PS C:\> Get-Process | Out-Excel
```

<!--本文国际来源：[Pipe Information to Excel](http://community.idera.com/powershell/powertips/b/tips/posts/pipe-information-to-excel)-->
