layout: post
date: 2014-08-08 11:00:00
title: "PowerShell 技能连载 - 记录脚本做了什么事"
description: PowerTip of the Day - Logging What a Script Does
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
_适用于所有 PowerShell 版本_

您应该知道在 PowerShell 控制台（不是 ISE 编辑器）中，您可以打开记录功能：

    PS> Start-Transcript

这将会把所有键入的命令以及所有的命令执行结果都记录到一个文件中。不幸的是，当您运行一个脚本的时候，作用就受限了，因为您无法看到实际的脚本命令。

以下是一个激进的技巧，能够记录包括所有脚本中执行的命令。在您尝试这个技巧之前，请注意这将增加您的日志文件大小并且会导致脚本执行变慢，因为在循环体中，每一次循环都会被记录下来。

只要执行这行代码就可以打开脚本命令记录了：

    PS> Set-PSDebug -Trace 1

<!--more-->
本文国际来源：[Logging What a Script Does](http://community.idera.com/powershell/powertips/b/tips/posts/logging-what-a-script-does)
