---
layout: post
date: 2015-03-13 11:00:00
title: "PowerShell 技能连载 - 检查网站的响应（和执行时间）"
description: PowerTip of the Day - Measuring Website Response (and Execution Times)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

有些时候了解一个命令的执行时间是十分重要的。例如，要监控网站的响应时间，您可以使用 `Invoke-WebRequest`。用 `Measure-Command` 来测量执行的耗时。

    $url = 'http://www.powershell.com'


    # track execution time:
    $timeTaken = Measure-Command -Expression {
      $site = Invoke-WebRequest -Uri $url
    }

    $milliseconds = $timeTaken.TotalMilliseconds

    $milliseconds = [Math]::Round($milliseconds, 1)

    "This took $milliseconds ms to execute"

它返回一个 `TimeSapn` 对象，该对象包含了一个 "`TotalMilliseconds`" 属性。使用 "`Math`" 类提供的 `Round()` 方法将结果四舍五入。在这例子中，毫秒值被精确到小数点后 1 位。

<!--本文国际来源：[Measuring Website Response (and Execution Times)](http://community.idera.com/powershell/powertips/b/tips/posts/measuring-website-response-and-execution-times)-->
