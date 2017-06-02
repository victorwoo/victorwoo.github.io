---
layout: post
date: 2014-12-17 12:00:00
title: "PowerShell 技能连载 - 克隆 NTFS 权限"
description: 'PowerTip of the Day - Cloning NTFS Permissions '
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
_适用于 PowerShell 所有版本_

以下代码从一个文件夹读取 NTFS 权限并将该设置应用到另外一个文件夹上。请注意两个文件夹都必须存在：

    $FolderToCopyFrom = 'C:\folder1'
    $FolderToCopyTo = 'C:\folder2'
    
    $securityDescriptor = Get-Acl -Path $FolderToCopyFrom
    Set-Acl -Path $FolderToCopyTo -AclObject $securityDescriptor 

复制安全描述符操作可能需要管理员权限。请注意第二个文件夹的所有安全规则都会被第一个文件夹的安全信息覆盖。

<!--more-->
本文国际来源：[Cloning NTFS Permissions ](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-ntfs-permissions)
