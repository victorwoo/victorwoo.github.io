---
layout: post
date: 2014-07-16 04:00:00
title: "PowerShell 技能连载 - 快速查找 AD 账户"
description: PowerTip of the Day - Finding AD Accounts Easily
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
_适用于所有 PowerShell 版本_

您不必使用额外的 cmdlet 就能在您的活动目录中搜索用户账户或计算机。假设您已登录了一个域，只需要使用这段代码：

    $ldap = '(&(objectClass=computer)(samAccountName=dc*))'
    $searcher = [adsisearcher]$ldap
    
    $searcher.FindAll()

这段代码将查找所有以“dc”开头的计算机账户。`$ldap` 可以是任何合法的 LDAP 查询语句。要查找用户，请将“computer”替换为“user”。

<!--more-->
本文国际来源：[Finding AD Accounts Easily](http://community.idera.com/powershell/powertips/b/tips/posts/finding-ad-accounts-easily)
