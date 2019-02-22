---
layout: post
title: "PowerShell 技能连载 - 查找当前的脚本文件夹"
date: 2013-10-18 00:00:00
description: PowerTip of the Day - Finding Current Script Folder
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 3.0 开始，有一个很简单的办法来确定一个脚本所在的文件夹：`$PSScriptRoot`。这个变量总是保存了指定脚本所存放的文件夹路径。

通过这种方法，可以很方便地加载额外的资源，比如说其它脚本。以下代码将读取位于同一个文件夹中，一个名为 *myFunctions.ps1* 的脚本文件：

	"$PSScriptRoot\myFunctions.ps1"

别忘了用“dot-source”语法（在路径之前加点号）。否则只会输出该路径名（而不是执行该路径表示的脚本）。

<!--本文国际来源：[Finding Current Script Folder](http://community.idera.com/powershell/powertips/b/tips/posts/finding-current-script-folder)-->
