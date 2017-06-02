---
layout: post
date: 2016-12-01 00:00:00
title: "PowerShell 技能连载 - 使用自定义域"
description: PowerTip of the Day - Using Custom Scopes
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
当您改变变量时，您可能需要在稍后清除它们并且确保它们回退到缺省值——用自定义作用域就可以做到。昨天，我们学习了如何处理控制台程序的错误。并且回顾那段代码，您会发现重置 `$ErrorActionPreference` 系统变量要费很多事：

```powershell
try
{
    # set the preference to STOP
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    # RUN THE CONSOLE EXE THAT MIGHT EMIT AN ERROR,
    # and redirect the error channel #2 to the
    # output channel #1
    net user doesnotexist 2>&1
}

catch [System.Management.Automation.RemoteException]
{
    # catch the error emitted by the EXE,
    # and do what you want
    $errmsg = $_.Exception.Message
    Write-Warning $errmsg
}

finally
{
    # reset the erroractionpreference to what it was before
    $ErrorActionPreference = $old
}
```

一个简单得多的办法是使用自定义作用域：

```powershell
& {
    try
    {
        # set the preference to STOP
        $ErrorActionPreference = 'Stop'
        # RUN THE CONSOLE EXE THAT MIGHT EMIT AN ERROR,
        # and redirect the error channel #2 to the
        # output channel #1
        net user doesnotexist 2>&1
    }

    catch [System.Management.Automation.RemoteException]
    {
        # catch the error emitted by the EXE,
        # and do what you want:
        $errmsg = $_.Exception.Message
        Write-Warning $errmsg
    }
}
```

`${[code]}` 这段代码创建了一个新的作用域，并且任何在其中定义的变量都会在退出该作用域时删除。这是为何在上述例子中，`$ErrorActionPreference` 能够自动还原为它之前的值。

<!--more-->
本文国际来源：[Using Custom Scopes](http://community.idera.com/powershell/powertips/b/tips/posts/using-custom-scopes)
