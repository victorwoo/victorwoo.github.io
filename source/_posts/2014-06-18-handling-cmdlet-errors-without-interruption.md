layout: post
title: "PowerShell 技能连载 - 不中断处理 Cmdlet 中的错误"
date: 2014-06-18 00:00:00
description: PowerTip of the Day - Handling Cmdlet Errors without Interruption
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
当您想要错误处理器处理 cmdlet 内部产生的错误时，您只能将该 cmdlet 的 `-ErrorAction` 设为 `Stop` 才能捕获这类异常。否则，cmdlet 将在内部处理该错误。

这么做是有副作用的，因为将 `-ErrorAction` 设为 `Stop` 将会在发生第一个错误的时候停止该 cmdlet。

所以如果您希望不中断一个 cmdlet 并仍然能够获得该 cmdlet 产生的所有错误，那么请使用 `-ErrorVariable`。这段代码递归地获取您 Windows 文件夹中的所有 PowerShell 脚本（可能需要消耗一些时间）。错误不会导致停止执行，而是记录到一个变量中：

    Get-ChildItem -Path c:\Windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable myErrors

当该 cmdlet 执行完成以后，您可以检测 `$myErrors` 变量。它包含了所有发生的错误信息。例如，这段代码可以获取所有 `Get-ChildItem` 无法进入的子文件夹列表：

    $myErrors.TargetObject

上面一段代码使用了自动展开特性（PowerShell 3.0 中引入）。所以在 PowerShell 2.0 中，您需要这么写：

    $myErrors | Select-Object -ExpandProperty TargetObject

<!--more-->
本文国际来源：[Handling Cmdlet Errors without Interruption](http://community.idera.com/powershell/powertips/b/tips/posts/handling-cmdlet-errors-without-interruption)
