---
layout: post
date: 2018-01-12 00:00:00
title: "PowerShell 技能连载 - 查找用户配置文件"
description: PowerTip of the Day - Find User Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我们收到了许多关于处理用户配置文件的技能的反馈，所以我们决定增加一系列额外的技能文章。

通常，每次当用户登录一个系统时，无论是本地登录还是远程登录，将会创建一个用户配置文件。所以随着时间的增长，可能会存在许多孤岛的用户配置文件。如果您想管理用户配置文件（包括删除不需要的），请确保排除系统使用的用户配置文件。它们可以通过 "Special" 属性来识别。

以下是一段在网格视图窗口中显示显示所有普通的用户配置文件，并且允许您选择一条记录的代码：

```powershell
$selected = Get-CimInstance -ClassName Win32_UserProfile -Filter "Special=False" |
    Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
    Out-GridView -Title "Select User Profile" -OutputMode Single

$selected
```

<!--本文国际来源：[Find User Profiles](http://community.idera.com/powershell/powertips/b/tips/posts/find-user-profiles)-->
