---
layout: post
date: 2017-01-31 00:00:00
title: "PowerShell 技能连载 - 语音之周：使用语音合成器高级选项"
description: 'PowerTip of the Day - Speech-Week: Using Advanced Speech Synthesizer Options Synthesizer'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
.NET 语音引擎不止可以接受文本输入。如果您使用 `SpeakSsm()`，您可以使用 XML 来切换语言、速度，以及其它文本到语音转换的参数。

以下例子需要同时安装了英语和德语的语音。如果您没有安装德语语音，请使当地修改脚本中的语言 ID。以下是查找系统中可用的语言 ID 的方法：

```powershell
PS C:\> Add-Type -AssemblyName System.Speech 

PS C:\> $speak.GetInstalledVoices() | Select-Object -ExpandProperty VoiceInfo | Select-Object -ExpandProperty Culture | Sort-Object -Unique

LCID             Name             DisplayName                                                                                         
----             ----             -----------                                                                                         
1031             de-DE            German (Germany)                                                                                    
1033             en-US            English (United States)
```

以下是完整的例子：

```powershell
#requires -Version 2.0
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$ssml = '
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" 
    xml:lang="en-US">
    <voice xml:lang="en-US">
    <prosody rate="1">
        <p>I can speak English!</p>
    </prosody>
    </voice>
    <voice xml:lang="de-DE">
    <prosody rate="1">
        <p>und ich kann auch deutsch sprechen!</p>
    </prosody>
    </voice>
    <voice xml:lang="en-US">
    <prosody rate="0">
        <p>...and sometimes I get really tired.</p>
    </prosody>
    </voice>
</speak>
'

$speak.SpeakSsml($ssml)
```

<!--本文国际来源：[Speech-Week: Using Advanced Speech Synthesizer Options Synthesizer](http://community.idera.com/powershell/powertips/b/tips/posts/speech-week-using-advanced-speech-synthesizer-options-synthesizer)-->
