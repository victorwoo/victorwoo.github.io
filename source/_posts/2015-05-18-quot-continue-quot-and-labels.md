layout: post
date: 2015-05-18 11:00:00
title: "PowerShell 技能连载 - “Continue” 和标签"
description: PowerTip of the Day - "Continue" and Labels
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
当您在循环中使用“`Continue`”语句时，您可以跳过循环中剩下的语句，然后继续下一次循环。“`Break`”的工作原理与之相似，不过它不仅结束循环而且将跳过所有剩下的循环。

这引出一个问题：当您使用嵌套的循环时，这些语句影响了哪层循环？缺省情况下，“`Continue`”针对的是内层的循环，但是通过使用标签，您可以使“`Continue`”和“`Break`”指向外层循环。

    :outer 
    Foreach ($element in (1..10))
    {
      for ($x = 1000; $x -lt 1500; $x += 100) 
      {
        "Frequency $x Hz"
        [Console]::Beep($x, 500)
        continue outer
        Write-Host 'I am never seen unless you change the code...'
      }
    }

由于这段示例代码的 continue 是针对外层循环的，所以您将见到（以及听到）10 次 1000Hz 的输出。

当您移除“`Continue`”之后的“`outer`”标签时，您会听到频率递增的蜂鸣，并且 `Write-Host` 语句不再被跳过。

<!--more-->
本文国际来源：["Continue" and Labels](http://community.idera.com/powershell/powertips/b/tips/posts/quot-continue-quot-and-labels)
