---
layout: post
date: 2020-08-04 00:00:00
title: "PowerShell 技能连载 - 详细的电池报告"
description: PowerTip of the Day - Sophisticated Battery Report
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的笔记本电脑电池电量过低，或者您想调查相关问题，可以通过一种简单的方法来生成大量的电池充电报告。它会准确显示电池的充电时间，电池容量以及电池耗尽的时间。

以下是创建 14 天报告的代码：

```powershell
$path = "$env:temp/battery_report2.html"
powercfg /batteryreport /output $Path /duration 14
Start-Process -FilePath $Path -Wait
Remove-Item -Path $path
```

请注意，此调用不需要管理员特权（如常所述）。只要确保报告文件是在您具有写权限的位置生成的。

<!--本文国际来源：[Sophisticated Battery Report](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sophisticated-battery-report)-->

