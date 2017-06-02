---
layout: post
date: 2017-01-12 00:00:00
title: "PowerShell 技能连载 - 获取 AD 用户属性"
description: PowerTip of the Day - Getting AD User Attributes
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
缺省情况下，`Get-ADUser`（由 ActiveDirectory 模块提供，该模块是免费的 Microsoft RSAT 工具的一部分）只获取一小部分缺省属性。要获取更多信息，请使用 `-Properties` 参数，并且指定您需要获取的属性。

要获取所有 AD 用户的列表，以及他们的备注和描述字段，请使用这段代码：

    #requires -Modules ActiveDirectory 
    Get-ADUser -Filter * -Properties Description, Info

如果你不知道所有可用属性的名字，请使用“*”代替，来获取所有可用的属性。

<!--more-->
本文国际来源：[Getting AD User Attributes](http://community.idera.com/powershell/powertips/b/tips/posts/getting-ad-user-attributes)
