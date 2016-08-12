layout: post
title: "PowerShell 技能连载 - 轻松读取注册表键值"
date: 2014-06-19 00:00:00
description: PowerTip of the Day - Reading Registry Values the Easy Way
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
使用 PowerShell 读取注册表是小菜一碟。以下是一段代码模板：

    $RegPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion'
    $key = Get-ItemProperty -Path "Registry::$RegPath"

现在，只需要将 `RegPath` 替换成任意的注册表项路径。您还可以从 regedit.exe 中复制粘贴项路径。

当您运行完这段代码，`$key` 变量被赋值以后，只需键入 `$key` 以及 `.`，智能提示将列出该项下的所有键名，您可以简单地选取您希望读取的键。在控制台中，当您键入 `.` 之后按下 `TAB` 键可以显示所有可用的键名：

    $key.CommonFilesDir
    $key.MediaPathUnexpanded
    $key.ProgramW6432Dir

<!--more-->
本文国际来源：[Reading Registry Values the Easy Way](http://powershell.com/cs/blogs/tips/archive/2014/06/19/reading-registry-values-the-easy-way.aspx)
