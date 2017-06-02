---
layout: post
date: 2017-03-10 00:00:00
title: "PowerShell 技能连载 - 危险的临时文件！"
description: PowerTip of the Day - Dangerous Temp Files!
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
内部的系统功能往往十分有用，但请确保真正了解它们的功能。

一个特别常见的系统方法叫做 `GetTempFileName()` ，能够创建临时文件名。而当您进一步观察的时候，您会发现它不仅创建临时文件名，而且还创建了临时文件：

```
$file = [System.IO.Path]::GetTempFileName()
Test-Path -Path $file
```    

所以如果在脚本中只是使用这个方法来创建临时文件名的话，会留下一大堆孤立的文件。

<!--more-->
本文国际来源：[Dangerous Temp Files!](http://community.idera.com/powershell/powertips/b/tips/posts/dangerous-temp-files)
