---
layout: post
date: 2018-11-02 00:00:00
title: "PowerShell 技能连载 - 隐藏参数"
description: PowerTip of the Day - Hiding Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In the previous tip we explained how you can dump all the legal values for a PowerShell attribute. Today we’ll take a look at the [Parameter()] attribute and its value DontShow. Take a look at this function:
在前一个技能中我们介绍了如何导出一个 PowerShell 属性的所有合法值。今天我们将关注 `[Parameter()]` 属性和它的值 `DontShow`。我们来看看这个函数：

```powershell
function Test-Something
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        $Name,

        [Parameter(DontShow)]
        [Switch]
        $Internal
    )

    "You entered: $name"
    if ($Internal)
    {
        Write-Warning "We are in secret test mode!"
    }
}
```

当您运行这个函数时，`IntelliSense` 只暴露 `-Name` 参数。`-Internal` switch 参数并没有显示，然而您仍然可以使用它。它只是一个隐藏的参数：

```powershell
PS> Test-Something -Name tobias
You entered: tobias

PS> Test-Something -Name tobias -Internal
You entered: tobias
WARNING: We are in secret test mode!
```

<!--本文国际来源：[Hiding Parameters](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hiding-parameters)-->
