---
layout: post
date: 2015-07-06 11:00:00
title: "PowerShell 技能连载 - 设置本地 Administrator 账号的密码"
description: PowerTip of the Day - Changing Local Administrator Account Password
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要操作本地用户账号并设置一个新密码，您可以使用底层的 WinNT: 命名空间。

请注意，您需要管理员权限来设置新密码。

这个脚本可以为本地 Administrator 账号设置密码：

    #requires -Version 1
    $Password = 'P@ssw0rd'

    $admin = [adsi]("WinNT://$env:computername/administrator, user")
    $admin.psbase.invoke('SetPassword', $Password)

<!--本文国际来源：[Changing Local Administrator Account Password](http://community.idera.com/powershell/powertips/b/tips/posts/changing-local-administrator-account-password)-->
