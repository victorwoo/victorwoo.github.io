---
layout: post
date: 2018-03-27 00:00:00
title: "PowerShell 技能连载 - 在同一行输出日志信息"
description: PowerTip of the Day - Output Log Messages in the Same Line
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
从 PowerShell 5.1 开始，PowerShell 控制台支持 VT 转义序列，它可以用于对控制台文本定位和格式化。请注意它只对控制台有效，而对 PowerShell ISE 无效。另外还请注意您需要 Windows 10 或者类似 ConEmu 等模拟器。

VT 转义序列可以将控制台光标设置到当前行的任意位置。通过这种方式，您可以方便地创建一个函数，输出状态或者日志信息到控制台。并且每条新信息覆盖之前的信息而不是增加新的行。

```powershell
function Write-ConsoleMessage([string]$Message)
{
    $esc = [char]27
    $consoleWidth = [Console]::BufferWidth
    $outputText = $Message.PadRight($consoleWidth)
    $gotoFirstColumn = "$esc[0G"
    Write-Host "$gotoFirstColumn$outputText" -NoNewline
}

function test
{
    Write-ConsoleMessage -Message 'Starting...'
    Start-Sleep -Seconds 1
    Write-ConsoleMessage -Message 'Doing something!'
    Start-Sleep -Seconds 1
    Write-ConsoleMessage -Message 'OK.'
}

test
```

<!--more-->
本文国际来源：[Output Log Messages in the Same Line](http://community.idera.com/powershell/powertips/b/tips/posts/output-log-messages-in-the-same-line)
