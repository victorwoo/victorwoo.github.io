---
layout: post
date: 2021-09-14 00:00:00
title: "PowerShell 技能连载 - 简单的内置密码生成器"
description: PowerTip of the Day - Simple Built-In Password Generator
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
.NET `System.Web` 程序集中有一个隐藏的功能，它可以让您立即创建任意长度的随机密码：

```powershell
# total password length
$Length = 10

# number of non-alpha-chars
$NonChar = 3

Add-Type -AssemblyName 'System.Web'
$password = [System.Web.Security.Membership]::GeneratePassword($Length,$NonChar)

"Your password: $password"
```

<!--本文国际来源：[Simple Built-In Password Generator](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/simple-built-in-password-generator)-->

