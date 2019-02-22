---
layout: post
date: 2014-10-06 11:00:00
title: "PowerShell 技能连载 - 重命名变量"
description: PowerTip of the Day - Renaming Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell ISE 3 或更高版本_

以下是一个简单的变量重命名函数，您可以在 PowerShell 3.0 及以上版本的 ISE 编辑器中使用它

它将识别某个变量的所有实例，然后将它重命名为一个新的名字。

    function Rename-Variable
    {
      param
      (
        [Parameter(Mandatory=$true)]
        $OldName,
        
        [Parameter(Mandatory=$true)]
        $NewName
      )
      
      $InputText = $psise.CurrentFile.Editor.Text
      $token = $null
      $errors = $null
      
      $ast = [System.Management.Automation.Language.Parser]::ParseInput($InputText, [ref] $token, [ref] $errors)
      
      $token | 
      Where-Object { $_.Kind -eq 'Variable'} | 
      Where-Object { $_.Name -eq $OldName } |
      Sort-Object { $_.Extent.StartOffset } -Descending |
      ForEach-Object {
        $start = $_.Extent.StartOffset + 1
        $end = $_.Extent.EndOffset
        $InputText = $InputText.Remove($start, $end-$start).Insert($start, $NewName)
      }
      
      $psise.CurrentFile.Editor.Text = $InputText
    } 

运行这个函数之后，您将得到一个名为 `Rename-Variable` 的新命令。

下一步，在 ISE 编辑器中打开一个脚本，然后在控制台面板中，键入以下内容（当然，需要将旧的变量名“_oldVariableName_”改为您当前所打开的 ISE 脚本中实际存在的变量名）。

    PS> Rename-Variable -OldName oldVariableName -NewName theNEWname   

立刻，旧变量的所有出现的地方都被替换成新的变量名。

注意：这是一个非常简易的变量重命名函数。一定要记得备份您的脚本。它还不能算是一个能用在生产环境的重构方案。

当您重命名变量时，您脚本的许多别处地方也可能需要更新。例如，当一个变量是函数参数时，所有调用该函数的地方都得修改它们的参数名。

<!--本文国际来源：[Renaming Variables](http://community.idera.com/powershell/powertips/b/tips/posts/renaming-variables)-->
