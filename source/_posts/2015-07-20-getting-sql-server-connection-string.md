layout: post
date: 2015-07-20 11:00:00
title: "PowerShell 技能连载 - 获取 SQL Server 连接字符串"
description: PowerTip of the Day - Getting SQL Server Connection String
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
如果您希望用 PowerShell 访问 SQL Server，您需要一个连接字符串。连接字符串包含了访问 SQL Server 实例所需的所有信息。

通常，要正确地组织一个连接字符串并不容易。以下是一个帮您实现这个目的的 `Get-ConnectionString` 函数：

    #requires -Version 2
    function Get-ConnectionString
    {
        $Path = Join-Path -Path $env:TEMP -ChildPath 'dummy.udl'
    
        $null = New-Item -Path $Path -ItemType File -Force
    
        $CommandArg = """$env:CommonProgramFiles\System\OLE DB\oledb32.dll"",OpenDSLFile "  + $Path
    
        Start-Process -FilePath Rundll32.exe -ArgumentList $CommandArg -Wait
        $ConnectionString = Get-Content -Path $Path | Select-Object -Last 1
        $ConnectionString | clip.exe
        Write-Warning -Message 'Connection String is also available from clipboard'
        $ConnectionString
    }
    

当您运行 `Get-ConnectionString` 时，PowerShell 会打开一个对话框，您可以提交和测试连接的情况。当您关闭对话框窗口时，PowerShell 将返回由 UI 对话框创建的连接字符串。

<!--more-->
本文国际来源：[Getting SQL Server Connection String](http://community.idera.com/powershell/powertips/b/tips/posts/getting-sql-server-connection-string)
