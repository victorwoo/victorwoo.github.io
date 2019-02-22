---
layout: post
date: 2016-12-02 00:00:00
title: "PowerShell 技能连载 - 使用自定义作用域来屏蔽任何输出"
description: PowerTip of the Day - Using Custom Scopes to Discard Any Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
昨天我们看了自定义作用域能够自动还原变量并在您的代码之后清除现场。

自定义作用域也可以用来忽略域里任何一段代码输出的任何结果。要实现它，请使用这样的解构：`$null = .{[code]}`。无论您在方括号里执行什么代码，您创建的所有的变量和函数在域外都能使用，但是不会产生任何输出。

让我们看看这个函数：

```powershell
function Out-Voice ($Text)
{
  $sapi = New-Object -ComObject Sapi.SpVoice
  $sapi.Speak($Text)
}

Out-Voice -Text 'Hello, Dude.'
```

当你运行它时，它将能播放语音，但也输出了数字“1”。所以 `Speak()` 方法会造成这样的现象——当您的代码变得庞大而复杂时，有许多地方在输出不必要的数字。

以下是一个极简单的“补丁”函数能产生相同的小郭，但是保证不会返回任何值：

```powershell
function Out-Voice ($Text)
{
  $null = . {
      $sapi = New-Object -ComObject Sapi.SpVoice
      $sapi.Speak($Text)
    }
}

Out-Voice -Text 'Hello, Dude.'
```
<!--本文国际来源：[Using Custom Scopes to Discard Any Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-custom-scopes-to-discard-any-output)-->
