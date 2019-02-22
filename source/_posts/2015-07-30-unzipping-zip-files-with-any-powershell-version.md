---
layout: post
date: 2015-07-30 11:00:00
title: "PowerShell 技能连载 - 在任意 Powershell 版本中解压 ZIP 文件"
description: PowerTip of the Day - Unzipping ZIP Files with any PowerShell Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您没有安装 PowerShell 5.0，并且没有安装 .NET Framework 4.5，以下是一个使用 Windows 原生功能解压 ZIP 文件的办法。

不过，如果您安装了资源管理器自定义的 ZIP 文件扩展，这个方法可能不能用。

    $Source = 'C:\somezipfile.zip'
    $Destination = 'C:\somefolder'
    $ShowDestinationFolder = $true
    
    if ((Test-Path $Destination) -eq $false)
    {
      $null = mkdir $Destination
    }
    
    $shell = New-Object -ComObject Shell.Application
    $sourceFolder = $shell.NameSpace($Source)
    $destinationFolder = $shell.NameSpace($Destination)
    $DestinationFolder.CopyHere($sourceFolder.Items())
    
    if ($ShowDestinationFolder)
    {
      explorer.exe $Destination
    }

这个方法的好处是在需要覆盖文件的时候，会弹出 shell 的对话框。这个方法也可以解压 CAB 文件。

<!--本文国际来源：[Unzipping ZIP Files with any PowerShell Version](http://community.idera.com/powershell/powertips/b/tips/posts/unzipping-zip-files-with-any-powershell-version)-->
