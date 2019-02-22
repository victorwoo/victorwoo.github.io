---
layout: post
date: 2017-01-30 00:00:00
title: "PowerShell 技能连载 - 语音之周：记录语音到文件合成器"
description: 'PowerTip of the Day - Speech-Week: Recording Voice to File Synthesizer'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
内置的 Microsoft 文本到语音引擎可以将音频文件保存到文件。通过这种方式，您可以自动生成 WAV 文件。以下是一个例子：它在您的桌面上创建一个新的 "clickme.wav" 文件，当您打开这个文件时，将会听到语音文本：

```powershell
#requires -Version 2.0
$Path = "$home\Desktop\clickme.wav"

Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.SetOutputToWaveFile($Path)
$speak.Speak('Hello I am PowerShell!')
$speak.SetOutputToDefaultAudioDevice()

Invoke-Item -Path $Path
```

<!--本文国际来源：[Speech-Week: Recording Voice to File Synthesizer](http://community.idera.com/powershell/powertips/b/tips/posts/speech-week-recording-voice-to-file-synthesizer)-->
