layout: post
title: "PowerShell 技能连载 - 快速创建新的本地管理员账户"
date: 2014-01-24 00:00:00
description: PowerTip of the Day - Create New Local Admin Account on the Fly
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
是否有为了测试而创建新的本地管理员账户的经历？假设您已经以 Administrator 账户登录，并且使用管理员特权开启 PowerShell，那么增加这样一个账户只需要几行代码就可以完成：

	$user = 'splitpersonality'
	
	net user /add $user
	net localgroup Administrators /add $user

注意目标的组名是本地化的，所以在非英文系统中，您需要将 Administrators 替换成您的 Administrators 组的本地化名称。

> 译者注：我在中文操作系统上实验了一下，直接用 `Administrators` 也没有问题的。 

<!--more-->
本文国际来源：[Create New Local Admin Account on the Fly](http://community.idera.com/powershell/powertips/b/tips/posts/create-new-local-admin-account-on-the-fly)
