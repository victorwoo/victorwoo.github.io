---
layout: post
date: 2017-06-29 00:00:00
title: "PowerShell 技能连载 - 每日问候"
description: PowerTip of the Day - Greetings of the Day
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个在 PowerShell 中接受一个字符串数组并返回一个随机的字符串，可以用作自定义问候语的简单方法：

```powershell
    $greetings = 
    'Hello there!',
    'Glad to see you!',
    'Happy coding!',
    'Have a great day!',
    'May the PowerShell be with you!'
    
    $greetings | Get-Random
```

您所需要做的只是将这段代码加到您的 profile 脚本，例如这样：

```powershell
# create profile if it does not yet exist
$exists = Test-Path -Path $Profile.CurrentUserAllHosts
if (!$exists) 
{ 
    $null = New-Item -Path $Profile.CurrentUserAllHosts -ItemType File -Force 
}

# add code to profile
@'
$greetings = 
'Hello there!',
'Glad to see you!',
'Happy coding!',
'Have a great day!',
'May the PowerShell be with you!'

$greetings | Get-Random
'@ | Add-Content -Path $Profile.CurrentUserAllHosts -Encoding Default
```

完成以后，PowerShell 将会使用自定义信息向您问候。

<!--本文国际来源：[Greetings of the Day](http://community.idera.com/powershell/powertips/b/tips/posts/greetings-of-the-day)-->
