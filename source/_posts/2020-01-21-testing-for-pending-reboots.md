---
layout: post
date: 2020-01-21 00:00:00
title: "PowerShell 技能连载 - 测试等待重启"
description: PowerTip of the Day - Testing for Pending Reboots
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 Windows 安装了更新或对操作系统做了相关改变，改变可能需要在重启以后才能生效。当有一个挂起的重启时，操作系统可能不能被完全保护，而且可能无法安装其它软件。

可以通过测试指定的注册表项来确定是否有挂起的重启：

```powershell
$rebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

"Pending reboot: $rebootRequired"
```

如果 `$rebootRequired` 的值是 `$true`，那么就存在一个挂起的重启。

<!--本文国际来源：[Testing for Pending Reboots](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-for-pending-reboots)-->

