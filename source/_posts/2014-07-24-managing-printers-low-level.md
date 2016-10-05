layout: post
date: 2014-07-24 11:00:00
title: "PowerShell 技能连载 - 以底层的方式管理打印机"
description: PowerTip of the Day - Managing Printers Low-Level
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

新版本的 Windows 操作系统，例如 Windows 8 和 Windows Server 2012 对打印机支持得很好，不过如果您在运行旧版的 Windows，那么这段代码可能有所帮助：

    PS> rundll32.exe PRINTUI.DLL,PrintUIEntry
    
    PS> 

请注意这段代码是大小写敏感的！请不要加空格，也不要改变大小写。

这段代码将打开一个帮助窗口，列出了许多东西，包括演示如何安装、删除和复制打印机驱动的例子。这个工具也可以远程使用，假设您通过合适的组策略允许远程操作。

<!--more-->
本文国际来源：[Managing Printers Low-Level](http://community.idera.com/powershell/powertips/b/tips/posts/managing-printers-low-level)
