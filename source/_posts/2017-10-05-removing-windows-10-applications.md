---
layout: post
date: 2017-10-05 00:00:00
title: "PowerShell 技能连载 - 移除 Windows 10 APP"
description: PowerTip of the Day - Removing Windows 10 Apps
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可能是最简单的移除预装 Windows 10 APP 的方法。如果您知道想要移除的应用程序名称，只需要以管理员身份打开 PowerShell，然后像这样移除 APP：

```powershell
PS> Get-AppxPackage *bingweather* | Remove-AppxPackage -WhatIf
What if: Performing the operation "Remove package" on target "Microsoft.BingWeather_4.20.1102.0_x64__8wekyb3d8bbwe".

PS>
```

注意：请去掉 `-WhatIf` 参数来实际移除 APP，不要删除作用不明的应用程序。可能其它 APP 会依赖这个 Appx 包。

<!--本文国际来源：[Removing Windows 10 Apps](http://community.idera.com/powershell/powertips/b/tips/posts/removing-windows-10-applications)-->
