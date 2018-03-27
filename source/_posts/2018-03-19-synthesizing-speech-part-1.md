---
layout: post
date: 2018-03-19 00:00:00
title: "PowerShell 技能连载 - 合成语音（第 1 部分）"
description: PowerTip of the Day - Synthesizing Speech (Part 1)
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
在之前的技能中，我们演示了 PowerShell 如何通过播放系统声音或 WAV 声音文件来生成声音信号。PowerShell 也可以调用内置的语音合成器：

```powershell
Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.Speak('Hello! I am your computer!')
```

请注意 Windows 10 自带了本地化的文字转语音引擎，所以如果您的 Windows 不是使用英语语言，您可能需要将以上文字转为您的语言。

可以用一系列属性来调整输出的效果。请试试这段代码：

```powershell
Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.Rate = -10
$synthesizer.Speak('Uh, I am not feeling that well!')
```

<!--more-->
本文国际来源：[Synthesizing Speech (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/synthesizing-speech-part-1)
