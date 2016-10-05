layout: post
date: 2015-11-24 12:00:00
title: "PowerShell 技能连载 - 为大量文件建立拷贝备份"
description: PowerTip of the Day - Creating Backup Copies of Many Files
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
PowerShell 可以为您的文件建立备份。您所需要调整的只是需要备份的文件类型，以及您需要备份的目标文件扩展名。

这个例子将影响（直接）存储在您的用户目录下的 PowerShell 脚本。也许这个文件夹下并没有这类文件，所以要么拷入一个文件来测试这个脚本，要么指定一个不同的文件夹路径。

每个脚本将被备份到相同的主文件名，而扩展名为“.ps1_old”的文件中。

当您改变 `$Recurese` 的值时，脚本将会为您的用户文件夹下的所有 PowerShell 创建备份。

    #requires -Version 1
    
    $ExtensionToBackup = '.ps1'
    $BackupExtension = '.ps1_old'
    $FolderToProcess = $HOME
    $Recurse = $false
    
    
    Get-ChildItem -Path $FolderToProcess -Filter $ExtensionToBackup -Recurse:$Recurse |
      ForEach-Object { 
        $newpath = [System.IO.Path]::ChangeExtension($_.FullName, $BackupExtension)
        Copy-Item -Path $_.FullName -Destination $newpath
     }

<!--more-->
本文国际来源：[Creating Backup Copies of Many Files](http://community.idera.com/powershell/powertips/b/tips/posts/creating-backup-copies-of-many-files)
