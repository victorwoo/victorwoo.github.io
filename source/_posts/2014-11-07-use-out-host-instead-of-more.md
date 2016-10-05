layout: post
date: 2014-11-07 12:00:00
title: "PowerShell 技能连载 - 用 Out-Host 代替 More"
description: PowerTip of the Day - Use Out-Host instead of More
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
_适用于 PowerShell 控制台_

请注意本文所述的内容仅限于“真实的”控制台使用。它不适用于 PowerShell ISE 编辑器。

在 PowerShell 控制台中，许多用户在要分页输出数据时仍然采用管道输出到 `more.com` 的老办法：

    PS> dir c:\windows | more 

这看起来能用。不过当您输出大量数据到管道的时候，PowerShell 看起来卡住了：

    PS> dir c:\windows -Recurse -ErrorAction SilentlyContinue | more 

这是因为 `more.com` 无法实时工作。它会首先收集所有的输入数据，然后开始分页输出。

更好的办法是使用 `Out-Host` cmdlet，结合 `-Paging` 参数：

    PS> dir c:\windows -Recurse -ErrorAction SilentlyContinue | Out-Host -Paging 

它能即时输出结果，因为它一旦从管道接收到数据，就可以开始处理。

<!--more-->
本文国际来源：[Use Out-Host instead of More](http://community.idera.com/powershell/powertips/b/tips/posts/use-out-host-instead-of-more)
