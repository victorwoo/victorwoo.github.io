---
layout: post
date: 2014-09-11 11:00:00
title: "PowerShell 技能连载 - 忽略输出结果"
description: PowerTip of the Day - Discarding Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

由于 PowerShell 会将所有命令的执行结果返回，所以在 PowerShell 脚本中忽略掉所有不希望返回的结果是十分重要的。

有很多方法能实现这个目的，以下是最常见的两种。请注意每行都会尝试在您的 C: 创建一个新的文件夹。`New-Item` 命令将会返回一个新的文件夹对象，但是如果您只是希望创建一个新的文件夹，那么您很可能希望忽略掉返回的结果：

```powershell
$null = New-Item -Path c:\newfolderA -ItemType Directory

New-Item -Path c:\newfolderB -ItemType Directory | Out-Null
```

哪么那种方式更好呢？当然是第一种方式了。将不需要的结果通过管道传送给 `Out-Null` 的开销是很大的，能达到将近 40 倍的差别。只调用一次的差别并不明显，但如果在一个循环中的话，差异就很明显了。

So better get into the habit of using $null rather than Out-Null!
所以最好养成习惯使用 `$null` 而不是 `Out-Null`！

<!--本文国际来源：[Discarding Results](http://community.idera.com/powershell/powertips/b/tips/posts/discarding-results)-->
