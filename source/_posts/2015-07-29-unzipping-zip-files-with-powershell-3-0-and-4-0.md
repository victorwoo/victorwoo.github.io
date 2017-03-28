layout: post
date: 2015-07-29 11:00:00
title: "PowerShell 技能连载 - 在 PowerShell 3.0 和 4.0 中解压 ZIP 文件"
description: PowerTip of the Day - Unzipping ZIP Files with PowerShell 3.0 and 4.0
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
PowerShell 5.0 中引入了 ZIP 文件支持，但是如果您安装了 .NET Framework 4.5 并且希望更多地控制解压的过程，请试试这个方法：

    #requires -Version 2
    # .NET Framework 4.5 required!
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    
    $Source = 'C:\somezipfile.zip'
    $Destination = 'C:\somefolder'
    $Overwrite = $true
    $ShowDestinationFolder = $true
    
    if ((Test-Path $Destination) -eq $false)
    {
     $null = mkdir $Destination
    }
    
    $Content = [IO.Compression.ZipFile]::OpenRead($Source).Entries
    $Content |
     ForEach-Object -Process {
        $FilePath = Join-Path -Path $Destination -ChildPath $_
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($_,$FilePath,$Overwrite)
                }
    if ($ShowDestinationFolder)
    {
        explorer.exe $Destination
    }

<!--more-->
本文国际来源：[Unzipping ZIP Files with PowerShell 3.0 and 4.0](http://community.idera.com/powershell/powertips/b/tips/posts/unzipping-zip-files-with-powershell-3-0-and-4-0)
