---
layout: post
title: "PowerShell 技能连载 - 在 ISE 编辑器中打开文件"
date: 2014-01-17 00:00:00
description: PowerTip of the Day - Opening Files in ISE Editor
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
如果您想在 ISE 编辑器中打开一个脚本，一个快捷的方法是使用命令“ise”。例如要打开您的配置脚本（每次 ISE 启动时自动调用的脚本），请试试一下代码：

	PS> ise $profile

您现在可以方便地增加或删除您希望 ISE 每次启动时自动执行的命令。

如果您的配置脚本不存在，以下单行的代码可以为您创建一个（它将覆盖已经存在的文件，所以只能在文件确实还不存在的时候运行它）：

	PS> New-Item -Path $profile -ItemType File -Force

您也可以从一个 PowerShell.exe 控制台中使用“ise”命令来启动一个 ISE 编辑器。

（顺便提一下：有一个叫做 `psEdit` 的函数使用效果十分相似，但是只在 PowerShell ISE 内部有效，在 PowerShell.exe 控制台中无效。）

<!--more-->
本文国际来源：[Opening Files in ISE Editor](http://community.idera.com/powershell/powertips/b/tips/posts/opening-files-in-ise-editor)
