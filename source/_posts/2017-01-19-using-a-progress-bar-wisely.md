layout: post
date: 2017-01-19 00:00:00
title: "PowerShell 技能连载 - 明智地使用进度条"
description: PowerTip of the Day - Using a Progress Bar Wisely
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
PowerShell 支持使用进度条。这是一个很简单的例子：

```powershell
1..100 | ForEach-Object {
  Write-Progress -Activity 'Counting' -Status "Processing $_" -PercentComplete $_
  Start-Sleep -Milliseconds 100
}
```

如果您没有过度使用 `Write-Progress`，那么使用进度条是很有价值的。特别在一个长时间的循环中，在循环的每一圈中调用一次 `Write-Progress` 并没有意义。如果那么做，脚本会变得非常慢。

假设您的循环运行 10000 次。显示一个进度条会显著地拖慢脚本：

```powershell
$min = 1
$max = 10000

$start = Get-Date

$min..$max | ForEach-Object {
  $percent = $_ * 100 / $max
  Write-Progress -Activity 'Counting' -Status "Processing $_" -PercentComplete $percent
}

$end = Get-Date

($end-$start).TotalMilliseconds
```

延迟的时间和 `Write-Progress` 的调用次数直接相关，所以如果您将 `$max` 的值改为 100000，该脚本会运行 10 倍的时间，只因为 `Write-Progress` 调用的次数达到 10 倍。

所以您需要使用一种智能的机制来限制 `Write-Progress` 的次数。以下例子每增加 0.1% 时跟新一次进度条：

```powershell
$min = 1
$max = 10000

$start = Get-Date

# update progress bar every 0.1 %
$interval = $max / 1000

$min..$max | ForEach-Object {
  $percent = $_ * 100 / $max
  
  if ($_ % $interval -eq 0)
  {
    Write-Progress -Activity 'Counting' -Status "Processing $_" -PercentComplete $percent
  }
}

$end = Get-Date

($end-$start).TotalMilliseconds
```

当您增加 `$max` 的数值，您会注意到脚本并不会增加多少时间，因为调用 `Write-Progress` 的次数仍然没变。

<!--more-->
本文国际来源：[Using a Progress Bar Wisely](http://community.idera.com/powershell/powertips/b/tips/posts/using-a-progress-bar-wisely)
