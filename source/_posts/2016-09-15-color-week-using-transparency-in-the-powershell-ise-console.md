---
layout: post
date: 2016-09-15 00:00:00
title: "PowerShell 技能连载 - 色彩之周: 在 PowerShell ISE 控制台中使用透明度"
description: 'PowerTip of the Day - Color Week: Using Transparency in the PowerShell ISE Console'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
本周我们将关注如何改变 PowerShell 控制台和 PowerShell ISE 的颜色，以便设置您的 PowerShell 环境。

在钱一个技能中您学到了三个设置控制 PowerShell ISE 控制台面板中的颜色。如果您希望的话，还可以为输入和输出设置不同的背景色：

```powershell
$psise.Options.ConsolePaneForegroundColor=[System.Windows.Media.Colors]::LightSkyBlue
$psise.Options.ConsolePaneBackgroundColor=[System.Windows.Media.Colors]::DarkGreen
$psise.Options.ConsolePaneTextBackgroundColor=[System.Windows.Media.Colors]::Yellow
```

结果类似这样：

```powershell
PS C:\>"Hello"
Hello

PS C:\>$Host


Name            : Windows PowerShell ISE Host
Version         : 4.0
InstanceId      : 840b9f0e-0c05-4b6d-84fc-c104971ac647
UI              : System.Management.Automation.Internal.Host.InternalHostUserInterface
CurrentCulture  : de-DE
CurrentUICulture: de-DE
PrivateData     : Microsoft.PowerShell.Host.ISE.ISEOptions
IsRunspacePushed: False
Runspace        : System.Management.Automation.Runspaces.LocalRunspace
```

如果您只希望将输出高亮一点点，那么可以使用透明色。文字的背景色可以变成透明，首先要确定希望使用的颜色的代码，然后用 alpha 通道创建自定义的颜色。它操作起来很简单。

在前一个例子中，文字的背景色被设置成 "Yellow"。以下是查找 "Yellow" 实际颜色值的方法：

```powershell
PS C:\> [System.Windows.Media.Colors]::Yellow.ToString()
#FFFFFF00
```

第一个十六进制值代表 alpha 通道（不透明度）。要使黄色变得更透明，请调低这个值：

```powershell
PS>$psise.Options.ConsolePaneTextBackgroundColor="#33FFFF00"
```

<!--本文国际来源：[Color Week: Using Transparency in the PowerShell ISE Console](http://community.idera.com/powershell/powertips/b/tips/posts/color-week-using-transparency-in-the-powershell-ise-console)-->
