---
layout: post
date: 2019-01-11 00:00:00
title: "PowerShell 技能连载 - 当前用户的 SID"
description: PowerTip of the Day - SID of Current User
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一行返回当前用户 SID 并且可以用于登录脚本的代码，例如：

```powershell
([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
```

<!--本文国际来源：[SID of Current User](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sid-of-current-user)-->
