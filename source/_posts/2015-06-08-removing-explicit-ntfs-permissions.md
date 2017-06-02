---
layout: post
date: 2015-06-08 11:00:00
title: "PowerShell 技能连载 - 移除非继承的 NTFS 权限"
description: PowerTip of the Day - Removing Explicit NTFS Permissions
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
在前一个例子中，我们演示了如何向已有的文件夹添加新的 NTFS 权限。如果您希望重置权限并且移除所有之前所有非继承的 NTFS 权限，以下是示例代码：

    # make sure this folder exists
    $Path = 'c:\sampleFolderNTFS'
    
    # get explicit permissions
    $acl = Get-Acl -Path $path
    $acl.Access |
      Where-Object { $_.isInherited -eq $false } |
      # ...and remove them
      ForEach-Object { $acl.RemoveAccessRuleAll($_) }
    
    # set new permissions
    $acl | Set-Acl -Path $path

<!--more-->
本文国际来源：[Removing Explicit NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/removing-explicit-ntfs-permissions)
