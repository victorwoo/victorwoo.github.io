layout: post
date: 2015-07-10 11:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 的帮助"
description: PowerTip of the Day - Using PowerShell Help
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
要查看完整的 PowerShell 帮助，您首先需要从 Internet 下载帮助信息。只需要以管理员权限打开一个 PowerShell 控制台执行以下代码：

    PS> Start-Process -FilePath powershell.exe -Verb runas

下一步，下载 PowerShell 帮助：

    PS> Update-Help -UICulture en-us -Force

请注意：PowerShell 帮助只有英语的版本。这是为什么要指定 `-UICulture` 确保请求下载英文帮助文件的原因。

当帮助文件安装完后，在 PowerShell 4.0 及以上版本就可以使用了。您可以显示一个命令的完整帮助，或只是显示示例代码：

    PS> Get-Help -Name Get-Random -ShowWindow
    
    PS> Get-Help -Name Get-Random -Examples
    
    NAME
        Get-Random
        
    SYNOPSIS
        Gets a random number, or selects objects randomly from a collection.
        
        -------------------------- EXAMPLE 1 --------------------------
        
        PS C:\>Get-Random
        3951433
        
        
        This command gets a random integer between 0 (zero) and Int32.MaxValue.
        
        
        
        
        -------------------------- EXAMPLE 2 --------------------------
        
        PS C:\>Get-Random -Maximum 100
        47
        
        
        This command gets a random integer between 0 (zero) and 99.
        
        
        
       ...

在 PowerShell 3.0 中，如果您并不是使用英语，您需要手动将帮助文件从 en-US 文件夹复制到您语言对应的文件夹中：

    #requires -RunAsAdministrator
    #requires -Version 3
    
    $locale = $host.CurrentUICulture.Name
    if ($locale -eq 'en-us')
    {
        Write-Warning 'You are using the English locale, all is good.'
    }
    else
    {
        Copy-Item -Path "$pshome\en-us\*" -Destination "$pshome\$locale\" -Recurse -ErrorAction SilentlyContinue -Verbose
        Write-Host "Help updated in $locale locale"
    }

当帮助文件复制到您语言对应的文件夹中后，您就可以在非英语系统中使用英语的帮助文件了。

<!--more-->
本文国际来源：[Using PowerShell Help](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-help)
