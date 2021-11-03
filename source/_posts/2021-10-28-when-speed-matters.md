---
layout: post
date: 2021-10-28 00:00:00
title: "PowerShell 技能连载 - 速度很重要"
description: PowerTip of the Day - When Speed Matters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是一种通用自动化语言，因此它的目标是多功能且易于使用。速度不是首要任务。

如果您确实关心最大速度，那么有一些 cmdlet 几乎可以完全满足 .NET 调用的功能。在这些实例中使用直接 .NET 调用会更快，尤其是在经常调用这些 cmdlet 时（例如在循环中）。但另一方面是它使您的代码更难阅读。

这里有一些例子：

```powershell
    # cmdlet
    PS> Join-Path -Path $env:temp -ChildPath test.txt
    C:\Users\tobia\AppData\Local\Temp\test.txt

    # direct .NET
    PS> [System.IO.Path]::Combine($env:temp, 'test.txt')
    C:\Users\tobia\AppData\Local\Temp\test.txt


    # cmdlet
    PS> Get-Date

    Monday, October 4, 2021 12:34:46

    # direct .NET
    PS> [DateTime]::Now

    Monday, October 4, 2021 12:34:52
```

<!--本文国际来源：[When Speed Matters](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/when-speed-matters)-->

