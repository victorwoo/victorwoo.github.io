---
layout: post
date: 2018-07-19 00:00:00
title: "PowerShell 技能连载 - 进度条定时器"
description: PowerTip of the Day - Progress Bar Timer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个使用 PowerShell 进度条的简单例子。这段代码显示一个休息倒计时的进度条。只需要调整您希望暂停的秒数即可。您可以使用这个例子在班级或会议中显示休息时间：

```powershell
$seconds = 60
1..$seconds |
ForEach-Object { $percent = $_ * 100 / $seconds; 

Write-Progress -Activity Break -Status "$($seconds - $_) seconds remaining..." -PercentComplete $percent; 

Start-Sleep -Seconds 1
}
```

<!--本文国际来源：[Progress Bar Timer](http://community.idera.com/powershell/powertips/b/tips/posts/progress-bar-timer)-->
