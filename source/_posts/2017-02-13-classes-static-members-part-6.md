layout: post
date: 2017-02-13 00:00:00
title: "PowerShell 技能连载 - 使用类（静态成员 - 第六部分）"
description: PowerTip of the Day - Classes (Static Members - Part 6)
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
Class 可以定义所谓的“静态”成员。静态成员（属性和方法）可以通过类本身调用，而不需要对象实例。

看看这个例子：

```powershell
#requires -Version 5.0
class TextToSpeech
{
  # store the initialized synthesizer here
  hidden static $synthesizer

  # static constructor, gets called whenever the type is initialized
  static TextToSpeech()
  {
    Add-Type -AssemblyName System.Speech
    [TextToSpeech]::Synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
  }

  # convert text to speech

  static Speak([string]$text)
  {
    [TextToSpeech]::Synthesizer.Speak($text)
  }
}
```

"`TextToSpeech`" 类包装了文本转语音的一切需要。它使用了静态的构造函数（当定义类型的时候执行）和一个静态方法，所以不需要实例化一个对象。立刻就可以使用 "`Speak`" 方法：

```powershell
# since this class uses static constructors and methods, there is no need
# to instantiate an object
[TextToSpeech]::Speak('Hello World!')
```

如果您不用“静态”成员来做相同的事情，这个类会长得十分相似。您只需要移除所有 "`static`" 关键字，并且通过 `$this` 代替类型名来存取类的属性：

```powershell
#requires -Version 5.0
class TextToSpeech
{
  # store the initialized synthesizer here
  hidden $synthesizer

  # static constructor, gets called whenever the type is initialized
  TextToSpeech()
  {
    Add-Type -AssemblyName System.Speech
    $this.Synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
  }

  # convert text to speech

  Speak([string]$text)
  {
    $this.Synthesizer.Speak($text)
  }
}
```

最显著的区别可能是在用户端：用户现在需要先实例化一个对象：

```powershell
    $speaker = [TextToSpeech]::new()
    $speaker.Speak('Hello World!')
```

所以使用规则提炼如下：

- 使用静态成员来实现只需要存在一次的功能（所以文本到语音转换器是一个静态类的好例子）
- 使用动态成员来实现需要在多于一个实例中同时存在（这样用户可以根据需要实例化任意多个独立的对象）的功能。

<!--more-->
本文国际来源：[Classes (Static Members - Part 6)](http://community.idera.com/powershell/powertips/b/tips/posts/classes-static-members-part-6)
