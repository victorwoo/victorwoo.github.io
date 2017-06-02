---
layout: post
date: 2015-06-26 11:00:00
title: "PowerShell 技能连载 - 获取 Active Directory 用户名"
description: PowerTip of the Day - Getting Active Directory User Name
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
以下是一个在 Active Directory 中快速当前用户并且获取账户信息，例如显示名称的方法：

    ([adsisearcher]"(samaccountname=$env:USERNAME)").FindOne().Properties['displayname']

<!--more-->
本文国际来源：[Getting Active Directory User Name](http://community.idera.com/powershell/powertips/b/tips/posts/getting-active-directory-user-name)
