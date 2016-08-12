layout: post
date: 2014-11-06 12:00:00
title: "PowerShell 技能连载 - Invoke-Expression 是邪恶的"
description: PowerTip of the Day - Invoke-Expression is Evil
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
_适用于 PowerShell 所有版本_

请在您的脚本中避免使用 `Invoke-Expression`。这个 cmdlet 接受一个字符串，并且像一个命令一样执行它。在大多数情况下，这是没必要的，它只能带来风险。

以下是一个故意构造的例子：

    function Test-BadBehavior($Path)
    {
      Invoke-Expression "Get-ChildItem -Path $Path"
    } 

这个函数用 `Invoke-Expression` 来运行一个命令并且加上一个参数值，用来返回输入参数代表的路径下的文件列表。

由于 `Invoke-Expression` 接受任意的字符串参数，所以您将自己带入了类似“SQL 注入攻击”的环境中。请试着以这种方式运行脚本：

    PS> Test-BadBehavior 'c:\;Get-Process'  

这样写第二个命令也会被执行，并会列出所有运行中的进程。`Invoke-Expression` 常常被攻击者用于从外部 URL 下载恶意的程序并轻松地执行。

当然，`Invoke-Expression` 本来就没必要用。平时在生产系统的脚本中基本没什么用。请注意确保以硬编码的方式编写您想执行的命令：

    function Test-BadBehavior($Path)
    {
      Get-ChildItem -Path $Path
    }

<!--more-->
本文国际来源：[Invoke-Expression is Evil](http://powershell.com/cs/blogs/tips/archive/2014/11/06/invoke-expression-is-evil.aspx)
