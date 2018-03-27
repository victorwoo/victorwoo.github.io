---
layout: post
date: 2018-03-20 00:00:00
title: "PowerShell 技能连载 - 合成语音（第 2 部分）"
description: "PowerTip of the Day - Synthesizing Speech – Recording to File (Part 2)"
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
在前一个技能中我们介绍了文字转语音引擎。这个引擎可以将文本转为一个 WAV 声音文件。这样我们可以利用它来生成语音信息：

```powershell
$Path = "$home\Desktop\clickme.wav"

Add-Type -AssemblyName System.Speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.SetOutputToWaveFile($Path)
$synthesizer.Rate = -10
$synthesizer.Speak('Uh, I am not feeling that well!')
$synthesizer.SetOutputToDefaultAudioDevice()

# run the WAV file (you can also double-click the file on your desktop!)
Invoke-Item -Path $Path
```

<!--more-->
本文国际来源：[Synthesizing Speech – Recording to File (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/synthesizing-speech-recording-to-file-part-2)
