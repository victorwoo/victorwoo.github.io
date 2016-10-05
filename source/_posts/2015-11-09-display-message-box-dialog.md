layout: post
date: 2015-11-09 12:00:00
title: "PowerShell 技能连载 - 显示消息对话框"
description: PowerTip of the Day - Display Message Box Dialog
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
PowerShell 是基于控制台的，但有些时候加入一些简单的对话框也很不错。以下是一个称为 `Show-MessageBox` 的函数，可以显示所有标准消息框，并支持智能显示参数：

    #requires -Version 2
    
    Add-Type -AssemblyName PresentationFramework
    function Show-MessageBox
    {
        param
        (
            [Parameter(Mandatory=$true)]
            $Prompt,
            
            $Title = 'Windows PowerShell',
            
            [Windows.MessageBoxButton]
            $Buttons = 'YesNo',
            
            [Windows.MessageBoxImage]
            $Icon = 'Information'
        )
        
        [System.Windows.MessageBox]::Show($Prompt, $Title, $Buttons, $Icon)
    }
    
    
    $result = Show-MessageBox -Prompt 'Rebooting.' -Buttons OKCancel -Icon Exclamation
    
    if ($result -eq 'OK')
    {
      Restart-Computer -Force -WhatIf
    }

<!--more-->
本文国际来源：[Display Message Box Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/display-message-box-dialog)
