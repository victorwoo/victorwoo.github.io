---
layout: post
date: 2014-08-13 11:00:00
title: "PowerShell 技能连载 - 使用“打开文件”对话框"
description: PowerTip of the Day - Using the OpenFile Dialog
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

以下是一个快捷的函数，可以用在 ISE 编辑器和 PowerShell 控制台中（适用于 PowerShell 3.0 及以上版本）：`Show-OpenFileDialog`。

    function Show-OpenFileDialog
    {
      param
      (
        $StartFolder = [Environment]::GetFolderPath('MyDocuments'),
    
        $Title = 'Open what?',
        
        $Filter = 'All|*.*|Scripts|*.ps1|Texts|*.txt|Logs|*.log'
      )
      
      
      Add-Type -AssemblyName PresentationFramework
      
      $dialog = New-Object -TypeName Microsoft.Win32.OpenFileDialog
      
      
      $dialog.Title = $Title
      $dialog.InitialDirectory = $StartFolder
      $dialog.Filter = $Filter
      
      
      $resultat = $dialog.ShowDialog()
      if ($resultat -eq $true)
      {
        $dialog.FileName
      }
    }
    

这个函数将打开一个“打开文件”对话框。用户可以选择一个文件，并且选择的文件对象将返回给 PowerShell。所以下次您的脚本需要打开一个 CSV 文件时，您可能就能用上。

<!--more-->
本文国际来源：[Using the OpenFile Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/using-the-openfile-dialog)
