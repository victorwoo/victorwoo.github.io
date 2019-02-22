---
layout: post
date: 2015-06-05 11:00:00
title: "PowerShell 技能连载 - 获取非继承的 NTFS 权限"
description: PowerTip of the Day - Getting Explicit NTFS Permissions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要查看某个文件或者文件夹被直接赋予了哪些 NTFS 权限，请注意“isInherited”属性。这段代码将创建一个名为“_sampleFolderNTFS_”的新文件夹，并且列出所有非继承的 NTFS 权限。当您创建该文件夹时，它只拥有继承的权限，所以您查看非继承权限的时候获得不到任何结果：

    $Path = 'c:\sampleFolderNTFS'
    
    # create new folder
    $null = New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue
    
    # get permissions
    $acl = Get-Acl -Path $path
    $acl.Access |
      Where-Object { $_.isInherited -eq $false }

当您增加了非继承权限时，这段代码将会产生结果。这是通过 PowerShell 增加非继承权限的方法。它将针对当前用户添加读、写、修改权限：

    $acl = Get-Acl -Path $path
    
    # add a new permission
    $permission = $env:username, 'Read,Write,Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)
    
    # set new permissions
    $acl | Set-Acl -Path $path

<!--本文国际来源：[Getting Explicit NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/getting-explicit-ntfs-permissions)-->
