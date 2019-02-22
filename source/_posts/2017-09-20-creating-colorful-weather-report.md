---
layout: post
date: 2017-09-20 00:00:00
title: "PowerShell 技能连载 - 创建彩色的天气报告"
description: PowerTip of the Day - Creating Colorful Weather Report
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了如何用 `Invoke-WebRequest` 来获取天气预报数据。获取到的数据是纯黑白的文本。

要获取彩色的报告，Windows 10 可以利用 powershell.exe 的控制序列特性。只需要在 PowerShell 控制台中运行以下代码：

```powershell
$City = 'Hannover'

(Invoke-WebRequest "http://wttr.in/$City" -UserAgent curl).content -split "`n"
```

只需要将 user agent 设为“curl”，Windows 10 powershell.exe 就能收到包含色彩控制序列的输出。

<!--本文国际来源：[Creating Colorful Weather Report](http://community.idera.com/powershell/powertips/b/tips/posts/creating-colorful-weather-report)-->
