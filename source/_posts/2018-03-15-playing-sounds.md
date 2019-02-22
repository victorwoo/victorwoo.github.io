---
layout: post
date: 2018-03-15 00:00:00
title: "PowerShell 技能连载 - 播放声音"
description: PowerTip of the Day - Playing Sounds
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您只是需要蜂鸣，那么 PowerShell 可以很轻松地帮助您：

```powershell
$frequency = 800
$durationMS = 2000
[console]::Beep($frequency, $durationMS)
```

如果您需要做一些更复杂的事，那么您可以让 PowerShell 播放一段系统声音：

```powershell
[System.Media.SystemSounds]::Asterisk.Play()
```

以下是支持的系统声音列表：

```powershell
PS> [System.Media.SystemSounds] | Get-Member -Static -MemberType Property


    TypeName: System.Media.SystemSounds

Name        MemberType Definition
----        ---------- ----------
Asterisk    Property   static System.Media.SystemSound Asterisk {get;}
Beep        Property   static System.Media.SystemSound Beep {get;}
Exclamation Property   static System.Media.SystemSound Exclamation {get;}
Hand        Property   static System.Media.SystemSound Hand {get;}
Question    Property   static System.Media.SystemSound Question {get;}
```

<!--本文国际来源：[Playing Sounds](http://community.idera.com/powershell/powertips/b/tips/posts/playing-sounds)-->
