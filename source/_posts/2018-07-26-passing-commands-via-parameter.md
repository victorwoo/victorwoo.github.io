---
layout: post
date: 2018-07-26 00:00:00
title: "PowerShell 技能连载 - 通过参数传递命令"
description: PowerTip of the Day - Passing Commands via Parameter
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
函数参数有一个很少见的用法：用户可以传入一个输出命令：

```powershell
function Get-ProcessList
{
  param
  (
    [string]
    [ValidateSet('GridView','String')]
    $OutputMode = 'String'
  )

  Get-Process | & "Out-$OutputMode"

}

# output as a string
Get-ProcessList -OutputMode String
# output in a grid view window
Get-ProcessList -OutputMode GridView
```

<!--本文国际来源：[Passing Commands via Parameter](http://community.idera.com/powershell/powertips/b/tips/posts/passing-commands-via-parameter)-->
