---
layout: post
date: 2023-01-19 06:00:21
title: "PowerShell 技能连载 - 订阅锁定和解锁事件"
description: PowerTip of the Day - Subscribing to Session Lock/Unlock Events
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个用户在 Windows 系统中锁定了会话，会发出一个事件。当解锁会话的时候会发出另一个事件。两个事件都可以触发 PowerShell 代码，这样可以实现锁定和解锁系统时运行任意 PowerShell 代码。

以下两个函数演示该功能：

```powershell
function Start-Fun {
  $null = Register-ObjectEvent -InputObject ([Microsoft.Win32.SystemEvents]) -EventName "SessionSwitch" -Action {
    Add-Type -AssemblyName System.Speech

    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer

    switch($event.SourceEventArgs.Reason) {
    'SessionLock'    { $synthesizer.Speak("Bye bye $env:username!") }
    'SessionUnlock'  { $synthesizer.Speak("Nice to see you again $env:username!") }
    }
  }
}

function End-Fun {
    $events = Get-EventSubscriber | Where-Object { $_.SourceObject -eq [Microsoft.Win32.SystemEvents] }
    $jobs = $events | Select-Object -ExpandProperty Action
    $events | Unregister-Event
    $jobs | Remove-Job
}
```

运行以上代码，然后运行 `Start-Fun` 将代码附加到事件上。当您锁定或解锁电脑时，您将会得到一个 PowerShell 发出的语音提示。当然，您可以做其它事情，例如将设备设为节能模式。

运行 `End-Fun` 来移除事件订阅。
<!--本文国际来源：[Subscribing to Session Lock/Unlock Events](https://blog.idera.com/database-tools/powershell/powertips/subscribing-to-session-lock-unlock-events/)-->

