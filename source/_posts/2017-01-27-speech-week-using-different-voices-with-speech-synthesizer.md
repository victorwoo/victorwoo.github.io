layout: post
date: 2017-01-27 00:00:00
title: "PowerShell 技能连载 - 语音之周：更改讲述人的语音"
description: 'PowerTip of the Day - Speech-Week: Using Different Voices with Speech Synthesizer'
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
在前一个技能中我们演示了如何使用语音转换器来念出文本。以下是查找您系统中安装的语言的方法：

```powershell
#requires -Version 2.0
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.GetInstalledVoices() | 
  Select-Object -ExpandProperty VoiceInfo | 
  Select-Object -Property Culture, Name, Gender, Age
```

结果类似如下：


```powershell
Culture Name                    Gender   Age
------- ----                    ------   ---
en-US   Microsoft Zira Desktop  Female Adult
en-US   Microsoft David Desktop   Male Adult
de-DE   Microsoft Hedda Desktop Female Adult
```

用这行代码可以返回缺省的语音：

```powershell
$speak.Voice
```
假设您的系统安装了多个语音，以下是选择一个不同语音的方法。只需要传入您想使用的语音名字。这个例子在德文 Windows 10 系统上使用德语语音引擎：

```powershell
#requires -Version 2.0
Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.SelectVoice('Microsoft Hedda Desktop')
$speak.Speak('Jetzt spreche ich deutsch.')
```

<!--more-->
本文国际来源：[Speech-Week: Using Different Voices with Speech Synthesizer](http://community.idera.com/powershell/powertips/b/tips/posts/speech-week-using-different-voices-with-speech-synthesizer)
