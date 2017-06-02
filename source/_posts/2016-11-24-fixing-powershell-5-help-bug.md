---
layout: post
date: 2016-11-24 00:00:00
title: "PowerShell 技能连载 - 修复 PowerShell 5 帮助的 Bug"
description: PowerTip of the Day - Fixing PowerShell 5 Help Bug
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
使用 `Update-Help` 下载 PowerShell 的帮助文件时，PowerShell 5 有一个 bug，目前可以修复：基于文本的帮助文件扩展名是“.txt”而不是“.help.txt”，所以 PowerShell 帮助系统会忽略它们。您可以自己试验一下——以下命令可能会返回一大堆关于主题：

```powershell
PS C:\> Get-Help about*

Name                              Category  Module                    Synopsis                                              
----                              --------  ------                    --------                                              
about_Aliases                     HelpFile                            SHORT DESCRIPTION                                     
about_Arithmetic_Operators        HelpFile                            SHORT DESCRIPTION                                     
about_Arrays                      HelpFile                            SHORT DESCRIPTION                                     
about_Assignment_Operators        HelpFile                            SHORT DESCRIPTION                                     
about_Automatic_Variables         HelpFile                            SHORT DESCRIPTION                                     
about_Break                       HelpFile                            SHORT DESCRIPTION                                     
about_Classes                     HelpFile                            SHORT DESCRIPTION                                     
about_Command_Precedence          HelpFile                            SHORT DESCRIPTION                                     
about_Command_Syntax              HelpFile                            SHORT DESCRIPTION                                     
about_Comment_Based_Help          HelpFile                            SHORT DESCRIPTION                                     
about_CommonParameters            HelpFile                            SHORT DESCRIPTION                                     
about_Comparison_Operators        HelpFile                            SHORT DESCRIPTION                                     
about_Continue                    HelpFile                            SHORT DESCRIPTION                                     
about_Core_Commands               HelpFile                            SHORT DESCRIPTION                                     
about_Data_Sections               HelpFile                            SHORT DESCRIPTION                                     
about_Debuggers                   HelpFile                            SHORT DESCRIPTION                                     
about_DesiredStateConfiguration   HelpFile                            SHORT DESCRIPTION 
```

如果没有显示上述的内容，您也许还没有事先运行过 `Update-Help` 来下载帮助文件，或者您被 bug 吃了。

无论这个 bug 是否正在修复中，用 PowerShell 您可以轻松地修改这些东西。以下是一个用于修复这些受影响的帮助文件的扩展名的脚本。

这个脚本需要管理员权限，因为帮助文件是位于受保护的 Windows 文件夹中：

```powershell
# find all text files inside the PowerShell folder that start
# with "about"
Get-ChildItem -Path $pshome -Filter about*.txt -Recurse |
  # identify those that do not end with ".help.txt"
  Where-Object { $_.Name -notlike '*.help.txt' } |
  # rename the extension using a regex:
  Rename-Item -NewName { $_.Name -replace '\.txt$', '.help.txt'}
```
<!--more-->
本文国际来源：[Fixing PowerShell 5 Help Bug](http://community.idera.com/powershell/powertips/b/tips/posts/fixing-powershell-5-help-bug)
