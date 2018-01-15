---
layout: post
date: 2018-01-11 00:00:00
title: "PowerShell 技能连载 - 列出用户配置文件"
description: PowerTip of the Day - List User Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
我们收到很多反馈，关于如何处理用户配置文件的技能，所以我们决定增加几个额外的技能。

WMI 可以方便地枚举出系统中所有用户的配置文件，但是只列出了 SID (security identifier)，而不是明文的用户名。

```powershell
Get-CimInstance -ClassName Win32_UserProfile |
    Out-GridView
```

要改进这个结果，以下是一小段将 SID 转换为用户名的示例代码：

```powershell
$sid = "S-1-5-32-544"
(New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
```

要向 `Get-CimInstance` 指令的输出结果添加明文的用户名，您可以使用 `Add-Member` 指令和 `ScriptProperty` 属性：

```powershell
Get-CimInstance -ClassName Win32_UserProfile |
    Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
    Out-GridView
```

网格视图显示了一个名为 `UserName` 的额外列，其中包括指定用户配置文件的明文用户名。

<!--more-->
本文国际来源：[List User Profiles](http://community.idera.com/powershell/powertips/b/tips/posts/list-user-profiles)
