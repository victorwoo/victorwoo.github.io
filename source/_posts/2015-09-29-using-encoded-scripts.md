layout: post
date: 2015-09-29 11:00:00
title: "PowerShell 技能连载 - 使用编码的脚本"
description: PowerTip of the Day - Using Encoded Scripts
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
在 VBScript 中有编码的脚本。编码并不是隐藏脚本内容的安全方法，但它能使用户获取代码内容略微更难一点。

以下是一个传入 PowerShell 脚本并对它编码的函数：

    function ConvertTo-EncodedScript
    {
      param
      (
        $Path,
    
        [Switch]$Open
      )
    
      $Code = Get-Content -Path $Path -Raw
      $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Code) 
      $Base64 = [Convert]::ToBase64String($Bytes) 
    
      $NewPath = [System.IO.Path]::ChangeExtension($Path, '.pse1')
      $Base64 | Set-Content -Path $NewPath
    
      if ($Open) { notepad $NewPath }
    }

编码后的脚本将会以 .pse1 扩展名来保存（这是一个完全随意定义的文件扩展名，并不是微软定义的）。

要执行这段编码后的脚本，请运行这段命令（不能在 PowerShell ISE 中运行）：

    powershell -encodedcommand (Get-Content 'Z:\pathtoscript\scriptname.pse1' -Raw)

请注意 PowerShell 最多支持大约 8000 个字符的编码命令。编码命令的本意是安全地将 PowerShell 代码传递给 powershell.exe，而不会被特殊字符打断命令行。

<!--more-->
本文国际来源：[Using Encoded Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/using-encoded-scripts)
