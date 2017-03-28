layout: post
date: 2015-02-20 12:00:00
title: "PowerShell 技能连载 - 在 ISE 中使用代码区域"
description: PowerTip of the Day - Using Code Regions in ISE
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
_适用于 PowerShell 3.0 及以上版本_

PowerShell ISE 已经支持了可折叠的代码区域。当您编写函数、循环，或是条件时，您也许会注意到在左边距的上方有一个“减号”符号。点击它可实现折叠该区域。

如果看不到区域特性，您可以这样启用它们：视图/显示大纲(区域)。

您也可以在脚本的其它部分使用区域和代码折叠。要将代码的任意部分包括在一个可折叠的区域内，请在代码中加入一些特殊的注释：

    #region Variable Declarations
    $a = $b = $c = 1
    $d, $e, $f = 2,3,4
    #endregion

请注意这些特殊的注释是大小写敏感的。在将区域折叠之后，"`#region`" 后的文本将变为折叠区域的标题。

<!--more-->
本文国际来源：[Using Code Regions in ISE](http://community.idera.com/powershell/powertips/b/tips/posts/using-code-regions-in-ise)
