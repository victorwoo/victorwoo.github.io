---
layout: post
date: 2019-06-12 00:00:00
title: "PowerShell 技能连载 - 谁执行了隐藏的程序？"
description: PowerTip of the Day - Who is Starting Hidden Programs?
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有没有想过为什么 CPU 负载有时会这么高，或者为什么黑色的窗口会一闪而过？我们可以检查程序启动的事件日志，并找出什么时候什么程序自动启动了：

```powershell
Get-EventLog -LogName System -InstanceId 1073748869 |
ForEach-Object {

    [PSCustomObject]@{
        Date = $_.TimeGenerated
        Name = $_.ReplacementStrings[0]
        Path = $_.ReplacementStrings[1]
        StartMode = $_.ReplacementStrings[3]
        User = $_.ReplacementStrings[4]


    }
}  | Out-GridView
```

<!--本文国际来源：[Who is Starting Hidden Programs?](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/who-is-starting-hidden-programs)-->

