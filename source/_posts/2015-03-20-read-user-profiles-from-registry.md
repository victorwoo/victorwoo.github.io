---
layout: post
date: 2015-03-20 11:00:00
title: "PowerShell 技能连载 - 从注册表中读取用户配置文件"
description: PowerTip of the Day - Read User Profiles from Registry
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

要查看哪个用户在您的机器上拥有（本地）配置文件，以及配置文件位于什么位置，请使用这段代码：

    $path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

    Get-ItemProperty -Path $path |
      Select-Object -Property PSChildName, ProfileImagePath

它将自动枚举配置文件列表中的所有键，并返回用户 SID 和配置文件的路径：

    PSChildName                              ProfileImagePath
    -----------                              ----------------
    S-1-5-18                                 C:\WINDOWS\system32\config\systemprofile
    S-1-5-19                                 C:\Windows\ServiceProfiles\LocalService
    S-1-5-20                                 C:\Windows\ServiceProfiles\NetworkSer...
    S-1-5-21-1907506615-3936657230-268413... C:\Users\Tobias
    S-1-5-80-3880006512-4290199581-164872... C:\Users\MSSQL$SQLEXPRESS

<!--本文国际来源：[Read User Profiles from Registry](http://community.idera.com/powershell/powertips/b/tips/posts/read-user-profiles-from-registry)-->
