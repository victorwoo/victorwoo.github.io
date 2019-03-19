---
layout: post
date: 2018-03-21 00:00:00
title: "PowerShell 技能连载 - 合成语音 – 使用语音合成标记语言 SSML（第 3 部分）"
description: "PowerTip of the Day - Synthesizing Speech – Using Speech Synthesis Markup Language SSML (Part 3)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 内置的文字转语音引擎可以输入纯文本，并且将它转换为语音，但它也可以通过“语音合成标记语言”来控制。通过这种方式，您可以对语音调优，控制音调，以及语言。

Windows 自带本地的语音引擎，所以最好控制一下采用的语言。否则，在德文系统上，您的英文文本发音听起来会很奇怪。

```powershell
Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

$Text = '
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
    xml:lang="en-US">
    <voice xml:lang="en-US">
    <prosody rate="1">
        <p>Normal pitch. </p>
        <p><prosody pitch="x-high"> High Pitch. </prosody></p>
    </prosody>
    </voice>
</speak>
'
$synthesizer.SpeakSsml($Text)
```

根据已经安装的语音引擎，您现在甚至可以切换语言：

```powershell
Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

$Text1 = '
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
    xml:lang="en-US">
    <voice xml:lang="en-US">
    <prosody rate="1">
        <p>Normal pitch. </p>
        <p><prosody pitch="x-high"> High Pitch. </prosody></p>
    </prosody>
    </voice>
</speak>
'

$text2 = '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
    xml:lang="en-US">
    <voice xml:lang="de-de">
    <prosody rate="1">
        <p>Normale Tonhöhe. </p>
        <p><prosody pitch="x-high"> Höhere Tonlage. </prosody></p>
    </prosody>
    </voice>
</speak>'

$synthesizer.SpeakSsml($Text1)
$synthesizer.SpeakSsml($Text2)
```

如果您想在文字中混合多种语言，您也可以使用传统的 COM 对象 `Sapi.SpVoice`。以下代码来自前一个技能：

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

<!--本文国际来源：[Synthesizing Speech – Using Speech Synthesis Markup Language SSML (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/synthesizing-speech-using-speech-synthesis-markup-language-ssml-part-3)-->
