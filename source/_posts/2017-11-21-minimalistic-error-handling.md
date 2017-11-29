---
layout: post
date: 2017-11-21 00:00:00
title: "PowerShell 技能连载 - 极简的错误处理"
description: PowerTip of the Day - Minimalistic Error Handling
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
错误处理不必做的很复杂。它可以简单到检测上一条命令是否执行成功：

```powershell
# suppress errors by default
$ErrorActionPreference = 'SilentlyContinue'
# if a command runs into an error...
Get-Process -Name zumsel
# ...then $? is $false, and you can exit PowerShell
# with a return value, i.e. 55
if (!$?) { exit 55 }
```

PowerShell 将上一个命令是否遇到错误的信息记录在 `$?` 变量中。在这个例子中，返回的是 `$false`。使用 `exit` 加上一个正数，就可以退出脚本，并且将退出码返回给调用者。

<!--more-->
本文国际来源：[Minimalistic Error Handling](http://community.idera.com/powershell/powertips/b/tips/posts/minimalistic-error-handling)
