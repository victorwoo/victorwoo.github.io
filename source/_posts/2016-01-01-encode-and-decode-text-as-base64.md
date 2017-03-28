layout: post
date: 2016-01-01 12:00:00
title: "PowerShell 技能连载 - 用 Base64 编解码文本"
description: 'PowerTip of the Day - Encode and Decode Text as Base64 '
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
以下是将文本用 Base64 编码的简单方法：

```powershell
#requires -Version 1

$text = 'Hello World!'
[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($text), 'InsertLineBreaks')
```

结果字符串看起来大概如下：

    SABlAGwAbABvACAAVwBvAHIAbABkACEA 

文本编码可以用于简易的混淆文本，或是保护文本防止不小心被错误地格式化。例如 PowerShell.exe 可运行 Base64 编码过的命令。以下是一个例子（请打开您机器的声音）：

```shell
powershell.exe -EncodedCommand ZgBvAHIAKAAkAHgAIAA9ACAAMQAwADAAMAA7ACAAJAB4ACAALQBsAHQAIAAxADIAMAAwADAAOwAgACQAeAArAD0AMQAwADAAMAApACAAewAgAFsAUwB5AHMAdABlAG0ALgBDAG8AbgBzAG8AbABlAF0AOgA6AEIAZQBlAHAAKAAkAHgALAAgADMAMAAwACkAOwAgACIAJAB4ACAASAB6ACIAfQA=
```

要解码一个 Base64 字符串，您可以使用以下代码。

```powershell
#requires -Version 1

$text = 'SABlAGwAbABvACAAVwBvAHIAbABkACEA'
[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($text))
```

您也可以使用这段代码来解码上面那段编码后的命令，看看它做了什么。只需要用编码过的命令替换掉 `$test`。

<!--more-->
本文国际来源：[Encode and Decode Text as Base64 ](http://community.idera.com/powershell/powertips/b/tips/posts/encode-and-decode-text-as-base64)
