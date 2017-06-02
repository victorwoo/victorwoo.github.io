---
layout: post
date: 2017-05-24 00:00:00
title: "PowerShell 技能连载 - 生成随机密码"
description: PowerTip of the Day - Generating Random Passwords
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
以下是一个非常简单的创建复杂随机密码的方法：

```powershell
Add-Type -AssemblyName System.Web
$PasswordLength = 12
$SpecialCharCount = 3
[System.Web.Security.Membership]::GeneratePassword($PasswordLength, $SpecialCharCount)
```

The API call lets you choose the length of the password, and the number of non-alphanumeric characters it contains.

<!--more-->
本文国际来源：[Generating Random Passwords](http://community.idera.com/powershell/powertips/b/tips/posts/generating-random-password)
