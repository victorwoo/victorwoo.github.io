---
layout: post
date: 2020-07-13 00:00:00
title: "PowerShell 技能连载 - 丢弃数据流"
description: PowerTip of the Day - Discarding Streams
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 通过不同的流输出信息。警告写入到与输出不同的流中，而错误也写入不同的流。每个流都有一个唯一的数字标识符：

<table><tbody><tr><td>ID</td><td>Stream</td></tr><tr><td>1</td><td>Output</td></tr><tr><td>2</td><td>Error</td></tr><tr><td>3</td><td>Warning</td></tr><tr><td>4</td><td>Verbose</td></tr><tr><td>5</td><td>Debug</td></tr><tr><td>6</td><td>Information</td></tr></tbody></table>

如果要丢弃某个流，可以使用重定向运算符（“`>`”）并将流重定向到 `$null`。此行代码将丢弃任何错误或警告消息：

```powershell
Get-Process -FileVersionInfo 2>$null 3>$null
```

<!--本文国际来源：[Discarding Streams](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discarding-streams)-->

