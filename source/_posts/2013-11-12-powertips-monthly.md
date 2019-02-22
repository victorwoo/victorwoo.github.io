---
layout: post
title: "PowerShell 技能月刊"
date: 2013-11-12 00:00:00
description: Index of PowerTips Monthly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- download
- monthly
---
| 编号   | 发布时间   | 标题              | PDF        |
| ------ | ---------- | ----------------- | ---------- |
| Vol.01 | 2013年06月 | 文件系统任务      | [下载][1]  |
| Vol.02 | 2013年07月 | 数组和哈希表      | [下载][2]  |
| Vol.03 | 2013年08月 | 日期、时间和文化  | [下载][3]  |
| Vol.04 | 2013年09月 | 对象和类型        | [下载][4]  |
| Vol.05 | 2013年10月 | WMI               | [下载][5]  |
| Vol.06 | 2013年11月 | 正则表达式        | [下载][6]  |
| Vol.07 | 2013年12月 | 函数              | [下载][7]  |
| Vol.08 | 2013年12月 | 静态 .NET 方法    | [下载][8]  |
| Vol.09 | 2014年01月 | 注册表            | [下载][9]  |
| Vol.10 | 2014年02月 | Internet 相关任务 | [下载][10] |
| Vol.11 | 2014年03月 | XML 相关任务      | [下载][11] |
| Vol.12 | 2014年08月 | 安全相关任务      | [下载][12] |

如果您（和我一样）足够懒，也可以用这样一行 PowerShell 代码来下载：

    1..12 | ForEach-Object { Invoke-WebRequest "http://powershell.com/cs/PowerTips_Monthly_Volume_$_.pdf" -OutFile "PowerTips_Monthly_Volume_$_.pdf" }

[1]: http://powershell.com/cs/PowerTips_Monthly_Volume_1.pdf
[2]: http://powershell.com/cs/PowerTips-Monthly-Volume2.pdf
[3]: http://powershell.com/cs/PowerTips_Monthly_Volume_3.pdf
[4]: http://powershell.com/cs/PowerTips_Monthly_Volume_4.pdf
[5]: http://powershell.com/cs/PowerTips_Monthly_Volume_5.pdf
[6]: http://powershell.com/cs/PowerTips_Monthly_Volume_6.pdf
[7]: http://powershell.com/cs/PowerTips_Monthly_Volume_7.pdf
[8]: http://powershell.com/cs/PowerTips_Monthly_Volume_8.pdf
[9]: http://powershell.com/cs/PowerTips_Monthly_Volume_9.pdf
[10]: http://powershell.com/cs/PowerTips_Monthly_Volume_10.pdf
[11]: http://powershell.com/cs/PowerTips_Monthly_Volume_11.pdf
[12]: http://powershell.com/cs/PowerTips_Monthly_Volume_12.pdf

<!--本文国际来源：[PowerTips Reference Library](http://powershell.com/cs/media/28/default.aspx)-->
