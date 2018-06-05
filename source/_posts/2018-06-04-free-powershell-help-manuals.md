---
layout: post
date: 2018-06-04 00:00:00
title: "PowerShell 技能连载 - 免费的 PowerShell 帮助手册"
description: PowerTip of the Day - Free PowerShell Help Manuals
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
即便是有经验的 PowerShell 用户也会经常忽略 PowerShell 强大的帮助系统，它类似 Linux 中的 man page。您所需要做的只是一次性下载帮助文件。要下载帮助文件，您需要在提升权限的 PowerShell 中运行以下代码：

```powershell
PS> Update-Help -UICulture en-us -Force
```

当帮助文件下载完以后，以下是一个很棒的基础列表，展示 PowerShell 语言的几乎所有细节：

```powershell
PS> Get-Help about* | Select Name, Synopsis

Name                                   Synopsis                                
----                                   --------                                
about_ActivityCommonParameters         Describes the parameters that Windows...
about_Aliases                          Describes how to use alternate names ...
about_Arithmetic_Operators             Describes the operators that perform ...
about_Arrays                           Describes arrays, which are data stru...
about_Assignment_Operators             Describes how to use operators to ass...
about_Automatic_Variables              Describes variables that store state ...
about_Break                            Describes a statement you can use to ...
about_Checkpoint-Workflow              Describes the Checkpoint-Workflow act...
about_CimSession                       Describes a CimSession object and the...
about_Classes                          Describes how you can use classes to ...
about_Command_Precedence               Describes how Windows PowerShell dete...
about_Command_Syntax                   Describes the syntax diagrams that ar...
about_Comment_Based_Help               Describes how to write comment-based ...
about_CommonParameters                 Describes the parameters 
...  
```

您甚至可疑用这行代码创建您自己的 PowerShell 帮助查看器：

```powershell
Get-Help about* | 
    Select-Object -Property Name, Synopsis |
    Out-GridView -Title 'Select Topic' -OutputMode Multiple |
    ForEach-Object {
    Get-Help -Name $_.Name -ShowWindow
    }
```

当运行这行代码时，PowerShell 将搜索帮助主题并打开一个网格视图。只需要按住 `CTRL` 并选择所有您想阅读的主题，然后单击确认。选中的主题将会在独立的帮助查看窗口中打开。

<!--more-->
本文国际来源：[Free PowerShell Help Manuals](http://community.idera.com/powershell/powertips/b/tips/posts/free-powershell-help-manuals)
