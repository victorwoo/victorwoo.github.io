layout: post
date: 2014-11-12 12:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中使用 F1 键"
description: PowerTip of the Day - Use F1 in PowerShell ISE
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
_适用于 PowerShell ISE 3 及以上版本_

当您下载了 PowerShell 帮助文件之后（在提升权限的 shell 中，用 `Update-Help`），您就可以用 `Get-Help` 命令来查找许多有用主题背后的信息。例如，以下代码将列出所有包含关键字“Parameter”的主题：

    PS> Get-Help parameter
    
    Name                              Category  Module                    Synopsis 
    ----                              --------  ------                    -------- 
    Get-ClusterParameter              Cmdlet    FailoverClusters          Get-Cl...
    Set-ClusterParameter              Cmdlet    FailoverClusters          Set-Cl...
    about_CommonParameters            HelpFile                            Descri...
    about_Functions_Advanced_Param... HelpFile                            Explai...
    about_Parameters                  HelpFile                            Descri...
    about_Parameters_Default_Values   HelpFile                            Descri...
    about_ActivityCommonParameters    HelpFile                            Descri...
    about_WorkflowCommonParameters    HelpFile                   

一般性的帮助主题都是以“about_”开头的。

在 PowerShell ISE 中，只需要单击任何一个列出的名称，然后按下 `F1` 键，就可以在独立的帮主窗口中打开关联的主题。

<!--more-->
本文国际来源：[Use F1 in PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/use-f1-in-powershell-ise)
