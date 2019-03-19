---
layout: post
date: 2014-09-22 11:00:00
title: "PowerShell 技能连载 - 比较服务配置"
description: 'PowerTip of the Day - Comparing Service Configuration '
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 或更高版本_

假设您在两台服务器上启用了 PowerShell 远程服务，那么下面这个简单的脚本演示了如何从每台服务器上获取所有服务的状态并且计算两台服务器之间的差异。

    $Server1 = 'myServer1'
    $Server2 = 'someOtherServer'

    $services1 = Invoke-Command { Get-Service } -ComputerName $Server1 |
      Sort-Object -Property Name, Status

    $services2 = Invoke-Command { Get-Service } -ComputerName $Server2 |
      Sort-Object -Property Name, Status

    Compare-Object -ReferenceObject $services1 -DifferenceObject $services2 -Property Name, Status -PassThru |
      Sort-Object -Property Name

得到的结果是服务配置差异的清单。

<!--本文国际来源：[Comparing Service Configuration ](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-service-configuration)-->
