---
layout: post
date: 2018-03-22 00:00:00
title: "PowerShell 技能连载 - 语音合成 – 使用不同的语音（第 4 部分）"
description: "PowerTip of the Day - Synthesizing Speech – Using Different Voices (Part 4)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 10 自带优秀的文本转语音功能，以及不同的高品质语音。要查看哪些语音可用，请试试以下代码：

```powershell
Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

$synthesizer.GetInstalledVoices().VoiceInfo |
    Where-Object { $_.Name -notlike 'Microsoft Server*' } |
    Select-Object -Property Name, Gender, Age, Culture
```

结果类似如下（根据您的 windows 版本、语言文化，和安装的组件可能有所不同）：

```powershell
    Name                    Gender   Age Culture
    ----                    ------   --- -------
    Microsoft Zira Desktop  Female Adult en-US
    Microsoft David Desktop   Male Adult en-US
    Microsoft Hedda Desktop Female Adult de-DE
```

要使用这些语音，请用 `SelectVoice()`：

```powershell
$sampleText = @{
    [System.Globalization.CultureInfo]::GetCultureInfo("en-us") = "Hello, I am speaking English! I am "
    [System.Globalization.CultureInfo]::GetCultureInfo("de-de") = "Halli Hallo, man spricht deutsch hier! Ich bin "
    [System.Globalization.CultureInfo]::GetCultureInfo("es-es") = "Una cerveza por favor! Soy "
    [System.Globalization.CultureInfo]::GetCultureInfo("fr-fr") = "Vive la france! Je suis "
    [System.Globalization.CultureInfo]::GetCultureInfo("it-it") = "Il mio hovercraft è pieno di anguille! Lo sono "


    }


Add-Type -AssemblyName System.speech
$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

$synthesizer.GetInstalledVoices().VoiceInfo |
    Where-Object { $_.Name -notlike 'Microsoft Server*' } |
    Select-Object -Property Name, Gender, Age, Culture |
    ForEach-Object {
        $_
        $synthesizer.SelectVoice($_.Name)
        $synthesizer.Speak($sampleText[$_.Culture] + $_.Name)

    }
```

哪些语音可用，依赖于系统已安装了哪些语言。以下链接解释了不同语言的 Windows 10 自带了哪些语音：

[https://support.microsoft.com/en-us/help/22797/windows-10-narrator-tts-voices](https://support.microsoft.com/en-us/help/22797/windows-10-narrator-tts-voices). 
请注意 `SeletVoice()` 并不能使用所有已安装的语音。

<!--本文国际来源：[Synthesizing Speech – Using Different Voices (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/synthesizing-speech-using-different-voices-part-4)-->
