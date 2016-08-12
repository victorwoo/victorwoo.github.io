layout: post
title: "PowerShell 技能连载 - 正确地按日期时间筛选"
date: 2014-02-18 00:00:00
description: PowerTip of the Day - Correctly Filtering DateTime
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
当您使用 `Where-Object` 通过日期或时间来过滤信息时，它工作得很好——前提是您使用了正确的过滤格式。请不要使用输出结果中的格式。

要指定一个日期或时间，请永远使用中性文化的格式：

"year-month-day hour:minute:second"，所以 2014 年 5 月 14 日应该表述成这样：“2014-05-12 12:30:00”。

或者换种方法处理：当您输出结果时，PowerShell 将根据您控制面板的设置来格式化日期和时间。当您输入信息（例如过滤规则）时，PowerShell 永远期望接收一个通用的日期和时间格式。这是有道理的：脚本须在任何文化环境中运行一致。而结果需要格式化成读者的语言文化格式。

所以要在您的 Windows 文件夹中查找所有自从 2012 年 4 月 30 日以来没有修改过的文件，请尝试以下代码：

![](/img/2014-02-18-correctly-filtering-datetime-001.png)

<!--more-->
本文国际来源：[Correctly Filtering DateTime](http://powershell.com/cs/blogs/tips/archive/2014/02/18/correctly-filtering-datetime.aspx)
