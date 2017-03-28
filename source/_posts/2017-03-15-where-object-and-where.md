layout: post
date: 2017-03-15 00:00:00
title: "PowerShell 技能连载 - Where-Object 和 .Where()"
description: PowerTip of the Day - Where-Object and .Where()
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
从 PowerShell 4 开始，当您不想使用管道的时候，可以使用 `Where()` 和 `ForEach()` 方法来代替 `Where-Object` 和 `ForEach-Object`。

所以如果您已经将所有数据加载到一个变量中，那么非流式操作会更高效：

```powershell
$Services = Get-Service

# streaming
$Services | Where-Object { $_.Status -eq 'Running' }
# non-streaming
$Services.Where{ $_.Status -eq 'Running' }
```

要节约资源，最有效地方法仍然是使用流式管道，而不是用变量：

```powershell
    Get-Service | Where-Object { $_.Status -eq 'Running' }
```

请注意 `Where-Object` 和 `.Where()` 使用不同的数组类型，所以它们的输出技术上是不同的：

```powershell
PS C:\> (1..19 |  Where-Object { $_ -gt 10 }).GetType().FullName
System.Object[]

PS C:\>  ((1..19).Where{ $_ -gt 10 }).GetType().FullName
System.Collections.ObjectModel.Collection`1[[System.Management.Automation.PSObject, System.Management.Automation, Version=3.0.0.0, Culture=neutral,  PublicKeyToken=31bf3856ad364e35]]
```

<!--more-->
本文国际来源：[Where-Object and .Where()](http://community.idera.com/powershell/powertips/b/tips/posts/where-object-and-where)
