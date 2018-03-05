---
layout: post
date: 2018-02-14 00:00:00
title: "PowerShell 技能连载 - 获取 PowerShell 的帮助"
description: PowerTip of the Day - Getting Help for PowerShell
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
假设您下载了 PowerShell 的帮助文件，有一个获取各类 PowerShell 主题的快捷方法：

首先，确保您下载了帮助文件：以管理员权限启动 PowerShell，并且运行以下代码：

```powershell
Update-Help -UICulture en-us -Force
```

下一步，检查 "about" 主题：

```powershell
Get-Help about_*
```

在 PowerShell ISE 中，您所需要做的是点击 cmdlet 列出的主题，然后按 `F1` 键。这将产生一个类似这样的命令：

```powershell
PS> Get-Help -Name 'about_If' -ShowWindow
```

在其它编辑器里，例如 VSCode 的 PowerShell 控制台，您需要自己键入命令。它将在 PowerShell 帮助查看器中打开帮助主题。

您也可以搜索指定的帮助主题，例如：

```powershell
PS> help operator

Name                       Category Module Synopsis
----                       -------- ------ --------
about_Arithmetic_Operators HelpFile        Describes the operators that perform…
about_Assignment_Operators HelpFile        Describes how to use operators to…
about_Comparison_Operators HelpFile        Describes the operators that compare…
about_Logical_Operators    HelpFile        Describes the operators that connect…
about_Operators            HelpFile        Describes the operators that are…
about_Operator_Precedence  HelpFile        Lists the Windows PowerShell operators…
about_Type_Operators       HelpFile        Describes the operators that work with…
```

在 PowerShell ISE 中，仍然可以点击某个列出的 about 主题，并按 F1 查看它的内容。

技术上，所有 about 主题都是文本文件，它们的位置在这里：

```powershell
PS> explorer $pshome\en-us
```

<!--more-->
本文国际来源：[Getting Help for PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/getting-help-for-powershell)
