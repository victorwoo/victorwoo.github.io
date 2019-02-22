---
layout: post
date: 2017-11-13 00:00:00
title: "PowerShell 技能连载 - 多语言语音输出"
description: PowerTip of the Day - Multi-Language Voice Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 上，操作系统自带了一系列高质量的文本转语言引擎，而且不局限于英文。可用的 TTS 引擎数量依赖于您所安装的语言。

PowerShell 可以发送文本到这些 TTS 引擎，并且通过 tag 可以控制使用的语言。所以如果您同时安装了英语和德语的 TTS 引擎，您可以像下面这样混用不同的语言：

```powershell
$text = "<LANG LANGID=""409"">Your system will restart now!</LANG>
<LANG LANGID=""407""><PITCH MIDDLE = '2'>Oh nein, das geht nicht!</PITCH></LANG>
<LANG LANGID=""409"">I don't care baby</LANG>
<LANG LANGID=""407"">Ich rufe meinen Prinz! Herbert! Tu was!</LANG>
"

$speaker = New-Object -ComObject Sapi.SpVoice
$speaker.Rate = 0
$speaker.Speak($text)
```

如果您希望使用不同的语言，只需要将 LANGID 数字调整为您希望使用的文化代号。

<!--本文国际来源：[Multi-Language Voice Output](http://community.idera.com/powershell/powertips/b/tips/posts/multi-language-voice-output)-->
