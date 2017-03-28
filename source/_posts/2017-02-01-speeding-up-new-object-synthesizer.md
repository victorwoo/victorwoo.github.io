layout: post
date: 2017-02-01 00:00:00
title: "PowerShell 技能连载 - 加速 New-Object Synthesizer"
description: PowerTip of the Day - Speeding Up New-Object Synthesizer
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
`New-Object` 创建新的对象实例，在之前的“语音之周”中，您已经见到了如何创建一个语音合成器对象，并且将文本转换为语音：

```powershell
Add-Type -AssemblyName System.Speech
$speak = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
$speak.Speak('Hello I am PowerShell!')
```

创建对象的方法是类似的，所以如果换成一个不同的类，例如 `System.Net.NetworkInformation.Ping`，就可以 ping 某个 IP 地址或主机名：

```powershell
$ping = New-Object -TypeName System.Net.NetworkInformation.Ping
$timeout = 1000
$result = $ping.Send('powershellmagazine.com', $timeout)

$result
```

在 PowerShell 5.0 或以上版本，有另一种方法来代替 `New-Object`，而且用起来更快：使用任意类型暴露的 `New()` 静态方法。您可以像这样重写以上的例子：

```powershell
Add-Type -AssemblyName System.Speech
$speak = [System.Speech.Synthesis.SpeechSynthesizer]::New()
$speak.Speak('Hello I am PowerShell!')
```

类似地：

```powershell
$ping = [System.Net.NetworkInformation.Ping]::New()
$timeout = 1000
$result = $ping.Send('powershellmagazine.com', $timeout)

$result
```

或者，可以精简：

```powershell
[System.Net.NetworkInformation.Ping]::New().Send('powershellmagazine.com', 1000)
```
请注意：一旦您使用 `New()` 来代替 `New-Object`，您的代码需要 PowerShell 5.0 以上版本。

<!--more-->
本文国际来源：[Speeding Up New-Object Synthesizer](http://community.idera.com/powershell/powertips/b/tips/posts/speeding-up-new-object-synthesizer)
