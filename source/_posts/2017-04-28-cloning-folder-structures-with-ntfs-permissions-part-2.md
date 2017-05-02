layout: post
date: 2017-04-28 00:00:00
title: "PowerShell 技能连载 - 克隆文件夹结构（含 NTFS 权限） – 第二部分"
description: "PowerTip of the Day - Cloning Folder Structures (with NTFS Permissions) – Part 2"
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
在前一个技能中我们演示了 `Get-FolderStructureWithPermission` 如何以结构化的形式记录并创建一个包含所有嵌套文件夹的清单，包含它们各自的 NTFS 安全设置。结果可以保存到一个变量中，或用 `Export-Csv` 序列化后保存到磁盘中。

今天我们演示第二部分：当您拥有一个指定文件夹结构的信息之后，可以使用这个 `Set-FolderStructureWithPermission`。它输入一个要克隆其结构的文件夹路径，加上通过 `Get-FolderStructureWithPermission` 获得的结构信息：

```powershell
#requires -RunAsAdministrator

function Set-FolderStructureWithPermission
{
  param
  (
    [String]
    [Parameter(Mandatory)]
    $Path,

    [Object[]]
    $folderInfo
  )

  $folderInfo | ForEach-Object {
    $relativePath = $_.Path
    $sddl = $_.SDDL

    $newPath = Join-Path -Path $Path -ChildPath $relativePath
    $exists = Test-Path -Path $newPath
    if ($exists -eq $false)
    {
      $null=New-Item -Path $newPath -ItemType Directory -Force
    }
    $sd = Get-Acl -Path $newPath
    $sd.SetSecurityDescriptorSddlForm($sddl)
    Set-Acl -Path $newPath -AclObject $sd
  }
}
```

由于设置 NTFS 权限的需要，这个函数需要管理员特权才能运行。

免责声明：这里呈现的所有代码仅供学习使用。由于我们没有投入大量精力去测试它，所以没有任何保障，而且它并不是生产准备就绪的代码。您有责任对这段代码进行测试，并决定它是否完美符合您的需要。

一个典型的用例是克隆一个现有的文件夹结构：

```powershell
# clone user profile
$infos = Get-FolderStructureWithPermission -Path $home
Set-FolderStructureWithPermission -Path c:\CloneHere -folderInfo $infos
```

<!--more-->
本文国际来源：[Cloning Folder Structures (with NTFS Permissions) – Part 2](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-folder-structures-with-ntfs-permissions-part-2)
