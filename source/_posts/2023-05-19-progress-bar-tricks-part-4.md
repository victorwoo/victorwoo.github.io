---
layout: post
date: 2023-05-19 00:00:31
title: "PowerShell 技能连载 - 进度条技巧（第 4 部分）"
description: PowerTip of the Day - Progress Bar Tricks (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
由于广大用户的要求，这里提供了一段代码，演示如何使用嵌套进度条并显示每个任务的“真实”进度指示器：

```powershell
$servers = 'dc-01', 'dc-02', 'msv3', 'msv4'
$ports = 80, 445, 5985

$counterServers = 0
$servers | ForEach-Object {
    # increment server counter and calculate progress
    $counterServers++
    $percentServers = $counterServers * 100 / $servers.Count

    $server = $_
    Write-Progress -Activity 'Checking Servers' -Status $server -Id 1 -PercentComplete $percentServers

    $counterPorts = 0
    $ports | ForEach-Object {
        # increment port counter and calculate progress
        $counterPorts++
        $percentPorts = $counterPorts * 100 / $ports.Count


        $port = $_
        Write-Progress -Activity 'Checking Port' -Status $port -Id 2 -PercentComplete $percentPorts

        # here would be your code that performs some task, i.e. a port test:
        Start-Sleep -Seconds 1
    }
}
```
<!--本文国际来源：[Progress Bar Tricks (Part 4)](https://blog.idera.com/database-tools/powershell/powertips/progress-bar-tricks-part-4/)-->

