---
layout: post
date: 2015-10-12 11:00:00
title: "PowerShell 技能连载 - 快速创建编码的 PowerShell 命令"
description: PowerTip of the Day - Creating Encoded PowerShell Commands on the Fly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当在 PowerShell 控制台之外执行 PowerShell 代码时，您需要传递代码给 powershell.exe。要确保您的代码不与特殊字符冲突，命令可以编码后传给 powershell.exe。

一个最简单的将纯文本命令行转换为编码后的命令的方法如下：

    PS C:\> cmd /c echo powershell { Get-Service | Where-Object Status -eq Running }
    powershell -encodedCommand IABHAGUAdAAtAFMAZQByAHYAaQBjAGUAIAB8ACAAVwBoAGUAcgBlAC0ATwBiAGoAZQ
    BjAHQAIABTAHQAYQB0AHUAcwAgAC0AZQBxACAAUgB1AG4AbgBpAG4AZwAgAA== -inputFormat xml -outputFormat
     xml
    PS C:\>

Here you'd find out that you can run the Get-Service | Where-Object statement as an encoded command like this:
然后可以以这样的方式执行编码后的 `Get-Service | Where-Object` 语句。

    powershell.exe -encodedCommand
    IABHAGUAdAAtAFMAZQByAHYAaQBjAGUAIAB8ACAAVwBoAGUAcgBlAC0ATwBiAGoAZQBjAHQAIABTAHQAYQB0AHUAcwAgAC0AZQBxACAAUgB1AG4AbgBpAG4AZwAgAA==

当您在 cmd.exe（或 PowerShell 控制台中）运行这段语句时，您能够得到所有运行中的服务。只需要移除 `-inputFormat` 和 `-outputFormat` 参数，并且移除所有换行符。编码后的命令是一个长长的字符串。

<!--本文国际来源：[Creating Encoded PowerShell Commands on the Fly](http://community.idera.com/powershell/powertips/b/tips/posts/creating-encoded-powershell-commands-on-the-fly)-->
