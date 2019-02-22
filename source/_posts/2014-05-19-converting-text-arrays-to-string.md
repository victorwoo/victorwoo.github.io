---
layout: post
title: "PowerShell 技能连载 - 将文本数组转换为字符串"
date: 2014-05-19 00:00:00
description: PowerTip of the Day - Converting Text Arrays to String
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
某些时候，文本文件中的文字内容需要由其它命令来读取和处理。通常，您需要用 `Get-Content` 命令来读取文本文件内容，然后将结果传递给其它命令。但这有可能会失败。

以下是注意点：请牢记 `Get-Content` 总是返回一个文本行的数组，而不是单个文本行。所以当使用一个接收字符串而不是接收一系列文本行（字符串数组）的命令时，您需要将这些文本行转换为文本。 

从 PowerShell 3.0 开始，`Get-Content` 拥有一个新的开关变量 `-Raw`。它不仅提升了读取大量文本的速度，而且一次性返回原始文本文件的整个内容，而不是将其分割成文本行。

    PS> $info = Get-Content $env:windir\windowsupdate.log
    PS> $info -is [Array]
    True
    
    PS> $info = Get-Content $env:windir\windowsupdate.log -Raw
    PS> $info -is [Array] 
    False

如果您已经有文本数组并且希望将它们转换为一个单一的文本，请使用 `Out-String`：

    PS> $info = 'One', 'Two', 'Three'
    PS> $info -is [Array]
    True
    
    PS> $all = $info | Out-String
    PS> $all -is [Array]
    False 
    
<!--本文国际来源：[Converting Text Arrays to String](http://community.idera.com/powershell/powertips/b/tips/posts/converting-text-arrays-to-string)-->
