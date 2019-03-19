---
layout: post
date: 2017-06-30 00:00:00
title: "PowerShell 技能连载 - 每日问候（带语音）"
description: PowerTip of the Day - Greetings of the Day (with Voice)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何在 PowerShell 配置文件中增加个人问候。这个问候信息也可以朗读出来，假设音量打开的情况下。这对所有的 PowerShell 宿主都有效，包括 VSCode。

这将把代码增加到您的配置文件脚本中：

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

$text = $greetings | Get-Random
$null = (New-Object -COM Sapi.SpVoice).Speak($text)
'@ | Add-Content -Path $Profile.CurrentUserAllHosts -Encoding Default
```

要编辑用户配置文件，请运行这段代码：

```powershell
PS> notepad $profile.CurrentUserAllHosts
```

<!--本文国际来源：[Greetings of the Day (with Voice)](http://community.idera.com/powershell/powertips/b/tips/posts/greetings-of-the-day-with-voice)-->
