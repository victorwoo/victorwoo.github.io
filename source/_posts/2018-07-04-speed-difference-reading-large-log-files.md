---
layout: post
date: 2018-07-04 00:00:00
title: "PowerShell 技能连载 - 速度差别：读取大型日志文件"
description: 'PowerTip of the Day - Speed Difference: Reading Large Log Files'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
需要读取大型日志文件时，例如，解析错误信息，PowerShell 既可以使用低内存占用的管道，也可以使用高内存占用的循环。不过，区别不仅在于内存的消耗，而且在速度上。

通过管道，不需要消耗太多的内存但是速度可能非常慢。通过传统的循环，脚本可以 10 倍甚至 100 倍的速度生成相同的结果：

```powershell
# make sure this file exists, or else
# pick a different text file that is very large
$path = 'C:\Windows\Logs\DISM\dism.log'
# SLOW
# filtering text file via pipeline (low memory usage)
Measure-Command {
  $result = Get-Content -Path $Path | Where-Object { $_ -like '*Error*' }
}

# FAST
# filtering text by first reading in all
# content (high memory usage!) and then
# using a classic loop

Measure-Command {
  $lines = Get-Content -Path $Path -ReadCount 0
  $result = foreach ($line in $lines)
  {
    if ($line -like '*Error*') { $line }
  }
}
```

<!--本文国际来源：[Speed Difference: Reading Large Log Files](http://community.idera.com/powershell/powertips/b/tips/posts/speed-difference-reading-large-log-files)-->
