---
layout: post
date: 2019-03-20 00:00:00
title: "PowerShell 技能连载 - 智力游戏生成器"
description: PowerTip of the Day - Mind Jogging Generator
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
人脑可以阅读每个单词头尾字母正确而其它字母顺序错乱的橘子。以下是一个可以自己实验的 PowerShell 函数。它输入一个句子，并将除了每个单词首末字母之外的字母打乱：

```powershell
function Convert-Text
{
    param
    (
      $Text = 'Early to bed and early to rise makes a man healthy, wealthy and wise.'
    )
    $words = $Text -split ' '

    $newWords = foreach($word in $words)
    {
        if ($word.Length -le 2)
        {
            $word
        }
        else
        {
            $firstChar = $word[0]
            $lastChar = $word[-1]
            $charLen = $word.Length -2
            $inbetween = $word[1..$charLen]
            $chars = $inbetween | Get-Random -Count $word.Length
            $inbetweenScrambled = $chars -join ''
            "$firstChar$inbetweenScrambled$lastChar"
        }
    }

    $newWords -join ' '
}
```

如果没有输入文本，那么将采用默认文本。您可以猜出它的意思吗？

```powershell
PS C:\> Convert-Text
Ealry to bed and erlay to rsie maeks a man hylhtea, wlhtaey and wies.
```

<!--本文国际来源：[Mind Jogging Generator](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/mind-jogging-generator)-->

