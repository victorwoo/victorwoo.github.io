layout: post
date: 2017-02-08 00:00:00
title: "PowerShell 技能连载 - 使用类（增加方法 - 第三部分）"
description: PowerTip of the Day - Using Classes (Adding Methods - Part 3)
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
相对于 `[PSCustomObject]`，使用 class 的最大好处之一是它也可以定义方法（命令）。以下例子实现了秒表功能。秒表可以用来计算代码执行了多少时间：

```powershell
#requires -Version 5.0
class StopWatch
{
  # property is marked "hidden" because it is used internally only
  # it is not shown by IntelliSense
  hidden [DateTime]$LastDate = (Get-Date)

  [int] TimeElapsed()
  {
    # get current date
    $now = Get-Date
    # and subtract last date, report back milliseconds
    $milliseconds =  ($now - $this.LastDate).TotalMilliseconds
    # use $this to access internal properties and methods
    # update the last date so that it now is the current date
    $this.LastDate = $now
    # use "return" to define the return value
    return $milliseconds
  }

  Reset()
  {
    $this.LastDate = Get-Date
  }
}
```

以下是秒表的使用方法：

```powershell
# create instance
$stopWatch = [StopWatch]::new()

$stopWatch.TimeElapsed()

Start-Sleep -Seconds 2
$stopWatch.TimeElapsed()

$a = Get-Service
$stopWatch.TimeElapsed()
```

结果类似如下：

```powershell
0
2018
69
```

当您在一个函数中定义方法时，要遵守一系列规则：

- 如果一个方法有返回值，那么必须指定返回值的数据类型
- 方法的返回值必须用关键字“`return`”来指定
- 方法中不能使用未赋值的变量，也不能从父作用域中读取变量
- 要引用这个类中的属性或方法，请在前面加上“`$this.`”

<!--more-->
本文国际来源：[Using Classes (Adding Methods - Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/using-classes-adding-methods-part-3)
