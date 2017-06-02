---
layout: post
date: 2017-01-26 00:00:00
title: "PowerShell 技能连载 - 语音之周：使用语音讲述人"
description: 'PowerTip of the Day - Speech-Week: Using a Speech Synthesizer'
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
当您将 "`System.Speech`" 程序集添加到 PowerShell 中后，就可以使用新增的 "`SpeechSynthesizer`" 类将文字转成语音：

```powershell
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.Speak('Hello I am PowerShell!')
```

请注意语音讲述人用的是您系统的缺省语音。您的讲述人缺省情况下可能说的不是英文。我们将在接下来的技能当中介绍如何使用不同的语音。

<!--more-->
本文国际来源：[Speech-Week: Using a Speech Synthesizer](http://community.idera.com/powershell/powertips/b/tips/posts/speech-week-using-a-speech-synthesizer)
