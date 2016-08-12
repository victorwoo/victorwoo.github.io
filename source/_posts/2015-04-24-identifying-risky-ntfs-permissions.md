layout: post
date: 2015-04-24 11:00:00
title: "PowerShell 技能连载 - 检测危险的 NTFS 权限"
description: PowerTip of the Day - Identifying Risky NTFS Permissions
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
以下是一个查找潜在危险的 NTFS 权限的快速简单的方法。这段脚本检测所有 `$pathsToCheck` 的文件夹并且汇报错有具有 `$dangerousBitMask` 中定义的文件系统标志的安全存取控制项（译者注：也就是“路径”）。

在这个例子中，该脚本从您的 `%PATH%` 环境变量中得到所有查找到的路径。这些路径是高风险的，需要用 NTFS 权限来保护，只能由 Administrators 和 system 拥有写权限。

软件安装程序常常将它们自身加入环境变量而没有正确地保护它们所加入的文件夹权限。这将增加安全风险。以下脚本将检查这些地方并找出哪些有潜在危险的 NTFS 存取权限供您做决定。

    # list of paths to check for dangerous NTFS permissions
    $pathsToCheck = $env:Path -split ';'
    
    # these are the bits to watch for
    # if *any* one of these is set, the folder is reported
    $dangerousBitsMask = '011010000000101010110'
    $dangerousBits = [Convert]::ToInt64($dangerousBitsMask, 2)
    
    # check all paths...
    $pathsToCheck | 
    ForEach-Object { 
      $path = $_
      # ...get NTFS security descriptor...
      $acl = Get-Acl -Path  $path
      # ...check for any "dangerous" access right
      $acl.Access |
      Where-Object { $_.AccessControlType -eq 'Allow' } |
      Where-Object { ($_.FileSystemRights -band $dangerousBits) -ne 0 } |
      ForEach-Object {
        # ...append path information, and display filesystem rights as bitmask
        $ace = $_
        $bitmask = ('0' * 64) + [Convert]::toString([int]$ace.FileSystemRights, 2)
        $bitmask = $bitmask.Substring($bitmask.length - 64)
        $ace | Add-Member -MemberType NoteProperty -Name Path -Value $path -PassThru | Add-Member -MemberType NoteProperty -Name Rights -Value $bitmask -PassThru
      }
    } |
    Sort-Object -Property IdentityReference |
    Select-Object -Property IdentityReference, Path, Rights, FileSystemRights |
    Out-GridView

<!--more-->
本文国际来源：[Identifying Risky NTFS Permissions](http://powershell.com/cs/blogs/tips/archive/2015/04/24/identifying-risky-ntfs-permissions.aspx)
