---
layout: post
date: 2015-06-03 11:00:00
title: "PowerShell 技能连载 - 创建一个包含 NTFS 权限的文件夹"
description: PowerTip of the Day - Create Folder with NTFS Permissions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您常常会需要创建一个文件夹并且为它设置 NTFS 权限。

这是一个简单的创建新文件夹并演示如何向已有权限中增加新的权限的示例代码：

    $Path = 'c:\protectedFolder'

    # create new folder
    $null = New-Item -Path $Path -ItemType Directory

    # get permissions
    $acl = Get-Acl -Path $path

    # add a new permission
    $permission = 'Everyone', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)

    # add another new permission
    # WARNING: Replace username "Tobias" with the user name or group that you want to grant permissions
    $permission = 'Tobias', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)

    # set new permissions
    $acl | Set-Acl -Path $path

<!--本文国际来源：[Create Folder with NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/create-folder-with-ntfs-permissions)-->
