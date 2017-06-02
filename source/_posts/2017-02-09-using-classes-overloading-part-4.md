---
layout: post
date: 2017-02-09 00:00:00
title: "PowerShell 技能连载 - 使用类（重载 - 第四部分）"
description: PowerTip of the Day - Using Classes (Overloading - Part 4)
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
类中的方法可以重载：您可以定义多个同名的方法，但是参数类型不同。它用起来和 cmdlet 中的参数集类似。请看：

```powershell
#requires -Version 5.0
class StopWatch
{
  # property is marked "hidden" because it is used internally only
  # it is not shown by IntelliSense
  hidden [DateTime]$LastDate = (Get-Date)

  # when no parameter is specified, do not emit verbose info

  [int] TimeElapsed()
  {
    return $this.TimeElapsedInternal($false)
  }

  # user can decide whether to emit verbose info or not
  [int] TimeElapsed([bool]$Verbose)
  {
    return $this.TimeElapsedInternal($Verbose)
  }

  # this method is called by all public methods

  hidden [int] TimeElapsedInternal([bool]$Verbose)
  {
    # get current date
    $now = Get-Date
    # and subtract last date, report back milliseconds
    $milliseconds =  ($now - $this.LastDate).TotalMilliseconds
    # use $this to access internal properties and methods
    # update the last date so that it now is the current date
    $this.LastDate = $now
    # output verbose information if requested
    if ($Verbose) {
      $VerbosePreference = 'Continue'
      Write-Verbose "Last step took $milliseconds ms." }
    # use "return" to define the return value
    return $milliseconds
  }

  Reset()
  {
    $this.LastDate = Get-Date
  }
}

# create instance
$stopWatch = [StopWatch]::new()

# do not output verbose info
$stopWatch.TimeElapsed()


Start-Sleep -Seconds 2
# output verbose info
$stopWatch.TimeElapsed($true)

$a = Get-Service
# output verbose info
$stopWatch.TimeElapsed($true)
```

结果类似如下：

```powershell
0
VERBOSE: Last step took  2018.1879 ms.
2018
VERBOSE: Last step took  68.8883 ms.
69
```

<!--more-->
本文国际来源：[Using Classes (Overloading - Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/using-classes-overloading-part-4)
