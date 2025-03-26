---
layout: post
date: 2023-05-13 22:19:55
title: "PowerShell 技能连载 - 进度条技巧（第 2 部分）"
description: PowerTip of the Day - Progress Bar Tricks (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
内置的 PowerShell 进度条支持“真实”的进度指示器，只要您提交一个在 0 到 100 范围内的“percentCompleted”值：

```powershell
0..100 | ForEach-Object {
    $message = '{0:p0} done' -f ($_/100)
    Write-Progress -Activity 'I am busy' -Status $message -PercentComplete $_

    Start-Sleep -Milliseconds 100
}
```

为了显示一个“真实”的进度指示器，因此您的脚本需要“知道”已经处理了多少给定任务。

以下是一个修改后的示例，它定义了需要处理多少个任务，然后从中计算出完成百分比：

```powershell
$data = Get-Service  # for illustration, let's assume you want to process all services

$counter = 0
$maximum = $data.Count  # number of items to be processed

$data | ForEach-Object {
    # increment counter
    $counter++
    $percentCompleted = $counter * 100 / $maximum
    $message = '{0:p1} done, processing {1}' -f ($percentCompleted/100), $_.DisplayName
    Write-Progress -Activity 'I am busy' -Status $message -PercentComplete $percentCompleted

    Write-Host $message
    Start-Sleep -Milliseconds 100
}
```
<!--本文国际来源：[Progress Bar Tricks (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/progress-bar-tricks-part-2/)-->

