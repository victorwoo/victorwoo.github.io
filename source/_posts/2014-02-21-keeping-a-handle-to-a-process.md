layout: post
title: "PowerShell 技能连载 - 持有一个进程的句柄"
date: 2014-02-21 00:00:00
description: PowerTip of the Day - Keeping a Handle to a Process
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
当您打开一个 EXE 文件时，PowerShell 将会开心地启动它，然后什么也不管：

![](/img/2014-02-21-keeping-a-handle-to-a-process-001.png)

如果您希望持有该进程的句柄，比如希望获得它的进程 ID，或者过一会儿检查该进程运行得如何，或者要中止它，请使用 `Start-Process` 和 `–PassThru` 参数。以下代码将返回一个进程对象： 

![](/img/2014-02-21-keeping-a-handle-to-a-process-002.png)

<!--more-->
本文国际来源：[Keeping a Handle to a Process](http://community.idera.com/powershell/powertips/b/tips/posts/keeping-a-handle-to-a-process)
