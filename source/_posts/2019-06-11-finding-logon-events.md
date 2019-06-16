---
layout: post
date: 2019-06-11 00:00:00
title: "PowerShell 技能连载 - 查找登录事件"
description: PowerTip of the Day - Finding Logon Events
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您有管理员特权，以下是一个快速、简单地转储所有登录事件的方法。这样你就可以知道谁登录了一台特定的电脑，以及使用了哪种身份验证类型：

```powershell
#requires -RunAsAdministrator

Get-EventLog -LogName Security -InstanceId 4624 |
  ForEach-Object {
      [PSCustomObject]@{
          Time = $_.TimeGenerated
          LogonType = $_.ReplacementStrings[8]
          Process = $_.ReplacementStrings[9]
          Domain = $_.ReplacementStrings[5]
          User = $_.ReplacementStrings[6]
          Method = $_.ReplacementStrings[10]
          Source = $_.Source

      }
  } | Out-GridView
```

<!--本文国际来源：[Finding Logon Events](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-logon-events)-->

