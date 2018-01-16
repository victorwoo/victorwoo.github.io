---
layout: post
date: 2018-01-15 00:00:00
title: "PowerShell 技能连载 - 通过对话框移除用户配置文件"
description: PowerTip of the Day - Remove User Profiles Via Dialog
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
我们收到了许多关于处理用户配置文件的技能的反馈，所以我们决定增加一系列额外的技能文章。

在前一个技能中我们演示了如何用 WMI 删除用户配置文件。有一些用户推荐使用 Remove-WmiObject 来替代 WMI 内部的 `Delete()` 方法。然而，`Remove-WmiObject` 无法删除用户配置文件实例。

以下代码汇总了我们在之前的技能中提到的所有细节。它列出所有用户配置文件，除了当前加载的和系统账户的。您可以选择一个，PowerShell 会帮您移除这个用户配置文件。

请注意以下代码**并不会**删除任何内容。要防止丢失数据，我们注释掉了删除操作的代码。当您去掉注释，真正地删除用户配置文件之前，请确保您知道会发生什么！

```powershell
#requires -RunAsAdministrator

Get-WmiObject -ClassName Win32_UserProfile -Filter "Special=False AND Loaded=False" |
    Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
    Out-GridView -Title "Select User Profile" -OutputMode Single |
    ForEach-Object {
        # uncomment the line below to actually remove the selected user profile!
        #$_.Delete()
    }
```

Are you an experienced professional PowerShell user? Then learning from default course work isn’t your thing. Consider learning the tricks of the trade from one another! Meet the most creative and sophisticated fellow PowerShellers, along with Microsoft PowerShell team members and PowerShell inventor Jeffrey Snover. Attend this years’ PowerShell Conference EU, taking place April 17-20 in Hanover, Germany, for the leading edge. 35 international top speakers, 80 sessions, and security workshops are waiting for you, including two exciting evening events. The conference is limited to 300 delegates. More details at [www.psconf.eu](/powershell/powertips/b/tips/archive/2018/01/15/remove-user-profiles-via-dialog/edit/www.psconf.eu).

<!--more-->
本文国际来源：[Remove User Profiles Via Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/remove-user-profiles-via-dialog)
