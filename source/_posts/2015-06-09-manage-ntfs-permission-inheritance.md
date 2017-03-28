layout: post
date: 2015-06-09 11:00:00
title: "PowerShell 技能连载 - 管理 NTFS 权限继承"
description: PowerTip of the Day - Manage NTFS Permission Inheritance
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
缺省情况下，文件和文件夹从它们的父节点继承权限。要停用继承，并且只保留显式权限，请做以下两件事情：增加你需要显式权限，然后禁止继承。

这个示例代码创建了一个名为“_PermissionNoInheritance_”的文件夹，然后为当前用户赋予读权限，为管理员组赋予完整权限，并且禁止继承。

    # create folder
    $Path = 'c:\PermissionNoInheritance'
    $null = New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue
    
    # get current permissions
    $acl = Get-Acl -Path $path
    
    # add a new permission for current user
    $permission = $env:username, 'Read,Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)
    
    # add a new permission for Administrators
    $permission = 'Administrators', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $acl.SetAccessRule($rule)
    
    # disable inheritance
    $acl.SetAccessRuleProtection($true, $false)
    
    # set new permissions
    $acl | Set-Acl -Path $path

<!--more-->
本文国际来源：[Manage NTFS Permission Inheritance](http://community.idera.com/powershell/powertips/b/tips/posts/manage-ntfs-permission-inheritance)
