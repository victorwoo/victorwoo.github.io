---
layout: post
date: 2015-05-22 11:00:00
title: "PowerShell 技能连载 - 在控制台输出中使用绿色的复选标记"
description: PowerTip of the Day - Using Green Checkmarks in Console Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中您已见到了如何使 PowerShell 控制台支持 TrueType 字体中所有可用的字符。您只需要将字符代码转换为“`Char`”类型即可。

以下是一个更高级的示例代码，使用了 splatting 技术将一个绿色的复选标记插入您的控制台输出中：

    $greenCheck = @{
      Object = [Char]8730
      ForegroundColor = 'Green'
      NoNewLine = $true
      }
    
    Write-Host "Status check... " -NoNewline
    Start-Sleep -Seconds 1
    Write-Host @greenCheck
    Write-Host " (Done)"
    

这样当您需要一个绿色的复选标记时，使用这行代码：

    Write-Host @greenCheck

如果该复选标记并没有显示出来，请确保您的控制台字体设置成了 TrueType 字体，例如“Consolas”。您可以点击控制台标题栏左上角的图标，并选择“属性”来设置字体。

<!--本文国际来源：[Using Green Checkmarks in Console Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-green-checkmarks-in-console-output)-->
