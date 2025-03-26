---
layout: post
date: 2023-05-17 00:00:02
title: "PowerShell 技能连载 - 进度条技巧（第 3 部分）"
description: PowerTip of the Day - Progress Bar Tricks (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 内置的进度条可以嵌套，每个任务显示一个进度条。为了使其正常工作，请为您的进度条分配不同的 ID 号码：

```powershell
$servers = 'dc-01', 'dc-02', 'msv3', 'msv4'
$ports = 80, 445, 5985

$servers | ForEach-Object {
    $server = $_
    Write-Progress -Activity 'Checking Servers' -Status $server -Id 1

    $ports | ForEach-Object {
        $port = $_
        Write-Progress -Activity 'Checking Port' -Status $port -Id 2

        # here would be your code that performs some task, i.e. a port test:
        Start-Sleep -Seconds 1
    }
}
```
<!--本文国际来源：[Progress Bar Tricks (Part 3)](https://blog.idera.com/database-tools/powershell/powertips/progress-bar-tricks-part-3/)-->

