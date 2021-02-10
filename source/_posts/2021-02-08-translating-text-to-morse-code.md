---
layout: post
date: 2021-02-08 00:00:00
title: "PowerShell 技能连载 - 将文本翻译成莫尔斯电码"
description: PowerTip of the Day - Translating Text to Morse Code
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
似乎几乎所有东西都有 Web Service。这是一个将文本转换为摩尔斯电码的 Web Service：

```powershell
$Text = 'SOS This is an emergency!'

# URL-encode text
Add-Type -AssemblyName System.Web
$encoded = [System.Web.HttpUtility]::UrlEncode($Text)

# compose web service URL
$Url = "https://api.funtranslations.com/translate/morse.json?text=$encoded"

# call web service
(Invoke-RestMethod -UseBasicParsing -Uri $url).contents.translated
```

结果看起来像这样：

    ... --- ...     - .... .. ...     .. ...     .- -.     . -- . .-. --. . -. -.-. -.-- ---.


如果您确实对摩尔斯电码有兴趣，请解析结果文本并创建真正的哔哔声：

```powershell
$Text = 'Happy New Year 2021!'

# URL-encode text
Add-Type -AssemblyName System.Web
$encoded = [System.Web.HttpUtility]::UrlEncode($Text)

# compose web service URL
$Url = "https://api.funtranslations.com/translate/morse.json?text=$encoded"

# call web service
$morse = (Invoke-RestMethod -UseBasicParsing -Uri $url).contents.translated

Foreach ($char in $morse.ToCharArray())
{
    switch ($char)
    {
        '.'      { [Console]::Beep(800, 300) }
        '-'      { [Console]::Beep(800, 900) }
        ' '      { Start-Sleep -Milliseconds 500 }
        default  { Write-Warning "Unknown char: $_"
                    [Console]::Beep(2000, 500) }

    }
    Write-Host $char -NoNewline
    Start-Sleep -Milliseconds 200
}
Write-Host "OK"
```

<!--本文国际来源：[Translating Text to Morse Code](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/translating-text-to-morse-code)-->

