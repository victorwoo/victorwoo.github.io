layout: post
date: 2015-08-07 11:00:00
title: "PowerShell 技能连载 - 解码 PowerShell 命令"
description: PowerTip of the Day - Encode PowerShell Commands
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
当您需要在一个独立的 powershell.exe 以一个 PowerShell 命令的方式执行代码时，并不十分安全。这要看您从哪儿调用 powershell.exe，您的代码参数可能被解析器修改，而且代码中的特殊字符可能会造成宿主混淆。

一个更健壮的传递命令方法是将它们编码并用解码命令提交。这只适用于短的代码。长度必须限制在 8000 字符左右以内。

    $code = {
      Get-EventLog -LogName System -EntryType Error |
      Out-GridView
    }
    
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($code.ToString()) 
    $Encoded = [Convert]::ToBase64String($Bytes) 
    
    $args = '-noprofile -encodedcommand ' + $Encoded
    
    Start-Process -FilePath powershell.exe -ArgumentList $args

<!--more-->
本文国际来源：[Encode PowerShell Commands](http://powershell.com/cs/blogs/tips/archive/2015/08/07/encode-powershell-commands.aspx)
