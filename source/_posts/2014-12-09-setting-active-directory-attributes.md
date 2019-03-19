---
layout: post
date: 2014-12-09 12:00:00
title: "PowerShell 技能连载 - 设置 Active Directory 属性"
description: PowerTip of the Day - Setting Active Directory Attributes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_需要 ActiveDirectory 模块_

PowerShell 用哈希表来设置一个用户账户的 AD 属性这是一种多功能的指定任意键值对的方法。

这个简单的例子将设置用户“_testuser_”的“_l_”和“_mail_”属性。您可以向哈希表加入任意多的键值对，假设在您的 AD schema 中不存在该属性名，并且指定的数据类型是合法的：

    $infos = @{}
    $infos.l = 'Bahamas'
    $infos.mail = 'sunny@offshore.com'

    Set-ADUser -Identity testuser -Replace $infos

<!--本文国际来源：[Setting Active Directory Attributes](http://community.idera.com/powershell/powertips/b/tips/posts/setting-active-directory-attributes)-->
