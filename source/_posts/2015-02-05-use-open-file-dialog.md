---
layout: post
date: 2015-02-05 12:00:00
title: "PowerShell 技能连载 - 使用打开文件夹对话框"
description: PowerTip of the Day - Use Open File Dialog
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
_适用于 PowerShell 所有版本_

为了在您的脚本中输入一些东西，以下是一个简单的打开“打开文件”对话框并让用户选择一个文件的函数。

    function Show-OpenFileDialog
    {
      param
      ($Title = 'Pick a File', $Filter = 'All|*.*|PowerShell|*.ps1')
      
      $type = 'Microsoft.Win32.OpenFileDialog'
      
      
      $dialog = New-Object -TypeName $type 
      $dialog.Title = $Title
      $dialog.Filter = $Filter
      if ($dialog.ShowDialog() -eq $true)
      {
        $dialog.FileName
      }
      else
      {
        Write-Warning 'Cancelled'
      }
    }

如您所见，您可以控制该对话框的标题栏和显示的文件类型。

<!--more-->
本文国际来源：[Use Open File Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/use-open-file-dialog)
