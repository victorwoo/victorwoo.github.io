---
layout: post
date: 2017-04-18 00:00:00
title: "PowerShell 技能连载 - 确认重复的 CSV 表头（第一部分）"
description: PowerTip of the Day - Identifying Duplicate CSV Headers (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
CSV 文件只是文本文件，所以可以很容易地提取它的第一行并检查它的表头。如果您手头没有一个 CSV 文件，这行代码可以快速帮您创建一个：

```powershell
PS C:\> Get-Process | Export-Csv -Path $env:temp\test.csv -NoTypeInformation -Encoding UTF8 -UseCulture

PS C:\>
```

现在您可以分析它的表头。这个简单的方法告诉您 CSV 文件中是否有重复的标题（在这个例子中显然不存在）。这段代码假设您的 CSV 文件分隔符是逗号。如果使用一个不同的分隔符，请调整用于分割的字符：

```powershell
$headers = Get-Content $env:temp\test.csv | Select-Object -First 1
$duplicates = $headers.Split(',') | Group-Object -NoElement | Where-Object {$_.Count -ge 2}
if ($duplicates.Count -eq 0)
{
    Write-Host 'You are safe!'
}
else
{
    Write-Warning 'There are duplicate columns in your CSV file:'
    $duplicates
}
```

结果如预想的：

```powershell
You are safe!

PS C:\>
```

如果您好奇当遇到重复的标题时会如何失败，请试试这段代码：

```powershell
PS C:\> driverquery /V /FO CSV | Set-Content -Path $env:temp\test.csv -Encoding UTF8
```

如果您在一个的文系统中运行这段代码，结果将会类似这样：

```powershell
WARNUNG: There are  duplicate columns in your CSV file:

Count Name
----- ----
    2  "Status"
```

显然，在本地化时，Microsoft 将 "State" 和 "Status" 两个单词都翻译成了德文的 "Status"，造成了重复的列标题。

<!--本文国际来源：[Identifying Duplicate CSV Headers (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-duplicate-csv-headers-part-1)-->
