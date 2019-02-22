---
layout: post
title: "PowerShell 技能连载 - 自动加载 Module"
date: 2013-11-21 00:00:00
description: PowerTip of the Day - Loading Modules Automatically
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 3.0 开始，PowerShell 具备了能够智能识别哪些 Cmdlet 是由哪个扩展 Module 导出的特性。所以您再也不需要知道 Module 的名称并且（用 `Import-Module` 手动导入它）。与之相反，自动完成和智能感知特性将为所有安装在标准 Module 文件夹中的每一个命令提供建议。以下是列出这些标准文件夹的方法：

	PS> $env:PSModulePath -split ';'
	C:\Users\Victor\Documents\WindowsPowerShell\Modules
	C:\Program Files\WindowsPowerShell\Modules
	C:\Windows\system32\WindowsPowerShell\v1.0\Modules\

这些标准文件夹也许不一定相同，您可以根据需要增加更多的文件夹到环境变量中，甚至将 Module 存放在 USB 闪存盘或外置驱动器中。以下命令将把 USB 驱动器的路径增加到您的模块列表中，这样在该文件夹中的所有 Module 也将会被自动加载：

	PS> $env:PSModulePath += ';g:\mypersonalmodules'

<!--本文国际来源：[Loading Modules Automatically](http://community.idera.com/powershell/powertips/b/tips/posts/loading-modules-automatically)-->
