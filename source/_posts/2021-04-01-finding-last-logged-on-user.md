---
layout: post
date: 2021-04-01 00:00:00
title: "PowerShell 技能连载 - 查找上次登录的用户"
description: PowerTip of the Day - Finding Last Logged-on User
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要查找有关 Windows 上最后登录的用户的详细信息，可以查询注册表：

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" |
    Select-Object -Property LastLo*, Idle*
```

结果看起来像这样：

    LastLoggedOnDisplayName : Tobias Weltner
    LastLoggedOnProvider    : {D6886603-9D2F-4EB2-B667-1971041FA96B}
    LastLoggedOnSAMUser     : .\tobia
    LastLoggedOnUser        : .\tobia
    LastLoggedOnUserSID     : S-1-5-21-2770831484-2260150476-2133527644-1001
    IdleTime                : 62486093

同样，此行返回 Windows 注册表中注册的所有用户配置文件：

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\profilelist\*' |
Select-Object -Property ProfileImagePath, FullProfile
```

<!--本文国际来源：[Finding Last Logged-on User](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-last-logged-on-user)-->
