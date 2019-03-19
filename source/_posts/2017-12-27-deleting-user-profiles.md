---
layout: post
date: 2017-12-27 00:00:00
title: "PowerShell 技能连载 - 删除用户配置文件"
description: PowerTip of the Day - Deleting User Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个用户登录计算机时，将创建一套用户配置文件。在前一个技能中我们介绍了如何用 PowerShell 转储计算机中的用户配置文件列表。

如果您想删除一个用户账户，PowerShell 可以帮您清除。以下是使用方法：

首先，调整 `$domain` 和 `$username` 变量指向您想删除的用户配置文件。然后，在 PowerShell 中以管理员特权运行以下代码：

```powershell
#requires -RunAsAdministrator

$domain = 'ccie'
$username = 'user01'

# get user SID
$sid = (New-Object Security.Principal.NTAccount($domain, $username)).Translate([Security.Principal.SecurityIdentifier]).Value

Get-WmiObject -ClassName Win32_UserProfile -Filter "SID='$sid'" |
  ForEach-Object {
    $_.Delete()
  }
```

第一部分将用户名转换为 SID 并且用它来指定用户配置文件。WMI 的 `Delete()` 方法删除所有用户配置文件。注意：您将丢失删除的用户配置文件中的所有数据。

<!--本文国际来源：[Deleting User Profiles](http://community.idera.com/powershell/powertips/b/tips/posts/deleting-user-profiles)-->
