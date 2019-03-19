---
layout: post
date: 2014-08-11 04:00:00
title: "PowerShell 技能连载 - 用 PowerShell 来励志"
description: PowerTip of the Day - Have PowerShell Cheer You Up!
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于所有 PowerShell 版本_

编写 PowerShell 代码是十分带劲的，但是某些时候会令人感到沮丧。这是一个用 PowerShell 来励志的函数。只需要打开音箱，PowerShell 会在您执行每一条命令之后鼓励你。

    function prompt
    {
      $text = 'You are great!', 'Hero!', 'What a checker you are.', 'Champ, well done!', 'Man, you are good!', 'Guru stuff I would say.', 'You are magic!'
      'PS> '
      $host.UI.RawUI.WindowTitle = Get-Location
      (New-Object -ComObject Sapi.SpVoice).Speak(($text | Get-Random))
    }

<!--本文国际来源：[Have PowerShell Cheer You Up!](http://community.idera.com/powershell/powertips/b/tips/posts/have-powershell-cheer-you-up)-->
