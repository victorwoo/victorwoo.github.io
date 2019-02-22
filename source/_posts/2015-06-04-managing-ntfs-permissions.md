---
layout: post
date: 2015-06-04 11:00:00
title: "PowerShell 技能连载 - 管理 NTFS 权限"
description: PowerTip of the Day - Managing NTFS Permissions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何向一个文件夹增加 NTFS 权限。要查看可以设置哪些权限，看以下示例：

    PS> [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])
    ListDirectory
    ReadData
    WriteData
    CreateFiles
    CreateDirectories
    AppendData
    ReadExtendedAttributes
    WriteExtendedAttributes
    Traverse
    ExecuteFile
    DeleteSubdirectoriesAndFiles
    ReadAttributes
    WriteAttributes
    Write
    Delete
    ReadPermissions
    Read
    ReadAndExecute
    Modify
    ChangePermissions
    TakeOwnership
    Synchronize
    FullControl

假设您已创建了一个名为“_protectedfolder_”的文件夹：

    $Path = 'c:\protectedFolder'
    
    # create new folder
    $null = New-Item -Path $Path -ItemType Directory

要为“_Tobias_”用户（请将用户名替换为您系统中实际存在的用户名）增加文件系统权限，请运行这段代码：

    # get permissions
    $acl = Get-Acl -Path $path
    
    # add a new permission
    $permission = 'Tobias', 'Read,Write,Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)
    
    # set new permissions
    $acl | Set-Acl -Path $path

<!--本文国际来源：[Managing NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/managing-ntfs-permissions)-->
