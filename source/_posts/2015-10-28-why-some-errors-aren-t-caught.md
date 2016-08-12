layout: post
date: 2015-10-28 11:00:00
title: "PowerShell 技能连载 - 为什么捕获不到某些错误 "
description: PowerTip of the Day - Why Some Errors Aren't Caught
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
当您在 PowerShell 中收到一条红色的错误信息时，您总是可以用一个 `try..catch` 代码块将代码包裹起来，然后自行处理该错误：

    try
    {
      1/0
    }
    catch
    {
      Write-Warning "Something crazy happened: $_"
    }

然而，一些错误，特别是来自 cmdlet 的，并不能被处理。当那些情况发生时，说明缺失的错误是被 cmdlet 内部的错误处理器处理了，并且您可以通过 `-ErrorAction` 通用参数来控制 cmdlet 的错误处理器。

当您设置 `ErrorAction` 的值为 `Stop` 时，您实际上告知 cmdlet 抛出一个异常，该以上可以被您的异常处理器捕获。

要让所有 cmdlet 发出异常，而不是内部处理，您可以用 `$ErrorActionPreference = 'Stop'` 语句，该语句将设置所有 cmdlet 的缺省错误动作为“停止”。

请注意它的副作用：当您告知一个 cmdlet 的错误处理器要在某些错误发生时抛出异常，则该 cmdlet 将会在发生第一个错误的地方抛出异常，并且不会继续执行。

<!--more-->
本文国际来源：[Why Some Errors Aren't Caught](http://powershell.com/cs/blogs/tips/archive/2015/10/28/why-some-errors-aren-t-caught.aspx)
