---
layout: post
date: 2017-02-03 00:00:00
title: "PowerShell 技能连载 - 使用命名空间"
description: "PowerTip of the Day - Using “Using Namespace”"
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
使用 .NET 的类型名称很麻烦，因为这些名字很长。以下是一个例子：

```powershell
#requires -Version 2.0

Add-Type -AssemblyName System.Speech
$speak = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
$speak.Speak('Hello I am PowerShell!')
```

在 PowerShell 5.0 以上版本，您可以定义希望使用的 .NET 命名空间。这些 "`using namespace`" 语句必须放在脚本的开头。此时代码的可读性变得更好，并且 using 语句明确了该脚本使用了哪些 .NET 命名空间：

```powershell
#requires -Version 5.0

using namespace System.Speech.Synthesis

Add-Type -AssemblyName System.Speech

$speak = New-Object -TypeName SpeechSynthesizer
$speak.Speak('Hello I am PowerShell!')
```

以下是另一个例子：`System.IO.Path` .NET 命名空间包含一系列有用的路径工具方法。以下是一些例子：


```powershell
[System.IO.Path]::ChangeExtension('test.txt', 'bat')
[System.IO.Path]::GetExtension('test.txt')
```

现在可以不必重复地使用 `[System.IO.Path]` 来访问这些方法。添加一句 "`using namespace System.IO`" 语句之后就可以直接访问 `[Path]` 类型：

```powershell
#requires -Version 5.0

using namespace System.IO

[Path]::ChangeExtension('test.txt', 'bat')
[Path]::GetExtension('test.txt')
```

<!--more-->
本文国际来源：[Using “Using Namespace”](http://community.idera.com/powershell/powertips/b/tips/posts/using-using-namespace)
