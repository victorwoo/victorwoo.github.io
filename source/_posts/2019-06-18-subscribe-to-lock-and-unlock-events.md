---
layout: post
date: 2019-06-18 00:00:00
title: "PowerShell 技能连载 - 订阅锁定和解锁事件"
description: PowerTip of the Day - Subscribe to Lock and Unlock Events
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个用户锁定或者解锁机器时，Windows 会发出事件。PowerShell 可以订阅这些事件并且进行操作，例如使用文字转语音引擎来发出问候。

但是还有许多有用的操作。您也许希望在锁定计算机时做清理操作，关闭所有的 Windows 资源管理器窗口，开始备份，或做其它事情。以下是示例代码：

```powershell
function Start-LogMessage {
  $null = Register-ObjectEvent -InputObject ([Microsoft.Win32.SystemEvents]) -SourceIdentifier SessSwitch -EventName "SessionSwitch" -Action {
    Add-Type -AssemblyName System.Speech

    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer

    switch($event.SourceEventArgs.Reason) {
'SessionLock'
{ $synthesizer.Speak("Have a good one, $env:username!") }
'SessionUnlock'
{ $synthesizer.Speak("Heya, nice to see you $env:username again!") }
    }
  }
}

function Stop-LogMessage {
    $events = Get-EventSubscriber -SourceIdentifier SessSwitch
    $jobs = $events | Select-Object -ExpandProperty Action
    $events | Unregister-Event
    $jobs | Remove-Job
}
```

<!--本文国际来源：[Subscribe to Lock and Unlock Events](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/subscribe-to-lock-and-unlock-events)-->

