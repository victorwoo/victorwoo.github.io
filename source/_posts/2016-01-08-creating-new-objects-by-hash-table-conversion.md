layout: post
date: 2016-01-08 12:00:00
title: "PowerShell 技能连载 - 通过哈希表转换创建新的对象"
description: PowerTip of the Day - Creating New Objects by Hash Table Conversion
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
从 PowerShell 3.0 开始，您可以通过哈希表创建预先初始化好的对象。只需要添加您希望预先初始化的属性，然后将哈希表转换为期望的类型。

以下是一个实际的例子：

```powershell
#requires -Version 3

$preInit = @{
  Rate = -10
  Volume = 100
}

Add-Type -AssemblyName System.Speech
$speaker = [System.Speech.Synthesis.SpeechSynthesizer] $preInit
$null = $Speaker.SpeakAsync(“Oh boy, that was a New Year’s party. I guess I need a little break.”)
```

当您运行这段代码时，PowerShell 创建一个新的 `System.Speech` 对象并且预先初始化了 rate 和 volume 的值。当您用 `SpeakAsync()` 方法将文本输出到语音时，文本会被很慢地念出来。`Rate` 的取值在 -10 到 10 之间。

<!--more-->
本文国际来源：[Creating New Objects by Hash Table Conversion](http://community.idera.com/powershell/powertips/b/tips/posts/creating-new-objects-by-hash-table-conversion)
