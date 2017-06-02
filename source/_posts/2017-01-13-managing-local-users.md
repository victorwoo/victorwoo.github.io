---
layout: post
date: 2017-01-13 00:00:00
title: "PowerShell 技能连载 - 管理本地用户"
description: PowerTip of the Day - Managing Local Users
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
PowerShell 5.1 终于发布了管理本地用户账户的 cmdlet。要获取本地用户账户的列表，请使用 `Get-LocalUser` 并将结果通过管道传给 `Select-Object` 命令来查看所有属性：


```powershell
PS C:\> Get-LocalUser | Select-Object -Property *


AccountExpires         : 
Description            : Predefined Account to manage computer or domain
Enabled                : False
FullName               : 
PasswordChangeableDate : 
PasswordExpires        : 
UserMayChangePassword  : True
PasswordRequired       : True
PasswordLastSet        : 7/10/2015 2:22:01 PM
LastLogon              : 12/8/2015 5:44:47 AM
Name                   : Administrator
SID                    : S-1-5-21-2012478179-265285931-690539891-500
PrincipalSource        : Local
ObjectClass            : User

AccountExpires         : 
Description            : User Account managed by system
Enabled                : False
FullName               : 
PasswordChangeableDate : 
PasswordExpires        : 
UserMayChangePassword  : True
PasswordRequired       : False
PasswordLastSet        : 
LastLogon              : 
Name                   : DefaultAccount
SID                    : S-1-5-21-2012478179-265285931-690539891-503
PrincipalSource        : Local
ObjectClass            : User

AccountExpires         : 
Description            : Predefined Account for Guest access
Enabled                : False
FullName               : 
PasswordChangeableDate : 
PasswordExpires        : 
UserMayChangePassword  : False
PasswordRequired       : False
PasswordLastSet        : 
LastLogon              : 
Name                   : Guest
SID                    : S-1-5-21-2012478179-265285931-690539891-501
PrincipalSource        : Local
ObjectClass            : User
...
```

<!--more-->
本文国际来源：[Managing Local Users](http://community.idera.com/powershell/powertips/b/tips/posts/managing-local-users)
