---
layout: post
date: 2017-04-27 00:00:00
title: "PowerShell 技能连载 - 克隆文件夹结构（含 NTFS 权限） – 第一部分"
description: "PowerTip of the Day - Cloning Folder Structures (with NTFS Permissions) – Part 1"
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
有些时候您需要重新创建一个嵌套的文件夹结构，并且希望克隆 NTFS 权限。今天我们我们专注第一个步骤：记录一个已有的文件夹结构，包括 SDDL 格式的 NTFS 权限。

我们可以用 `Get-FolderStructureWithPermission` 函数实现这个任务。它输入一个已存在文件夹的路径，并返回所有子文件夹，包括 SDDL 格式的 NTFS 权限：

```powershell
function Get-FolderStructureWithPermission
{
  param
  (
    [String]
    [Parameter(Mandatory)]
    $Path
  )

  if ((Test-Path -Path $Path -PathType Container) -eq $false)
  {
    throw "$Path does not exist or is no directory!"
  }

  Get-ChildItem -Path $Path -Recurse -Directory |
  ForEach-Object {
    $sd = Get-Acl -Path $_.FullName
    $sddl = $sd.GetSecurityDescriptorSddlForm('all')


    [PSCustomObject]@{
      Path = $_.FullName.Substring($Path.Length)
      SDDL = $sddl
    }

  }
}
```

您可以将结果通过管道输出到 `Out-GridView`，或将它保存到一个变量，或用 `Export-Csv` 将它写到磁盘中。

```powershell
PS C:\> Get-FolderStructureWithPermission -Path $home | Format-List


Path : \.dnx
SDDL : O:S-1-5-21-2012478179-265285931-690539891-1001G:S-1-5-21-2012478179-265285931-690539891-1001D:(A;OICIID;FA;;;SY)(A;OI
        CIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-2012478179-265285931-690539891-1001)

Path : \.plaster
SDDL : O:S-1-5-21-2012478179-265285931-690539891-1001G:S-1-5-21-2012478179-265285931-690539891-1001D:(A;OICIID;FA;;;SY)(A;OI
        CIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-2012478179-265285931-690539891-1001)

Path : \.vscode
SDDL : O:S-1-5-21-2012478179-265285931-690539891-1001G:S-1-5-21-2012478179-265285931-690539891-1001D:(A;OICIID;FA;;;SY)(A;OI
        CIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-2012478179-265285931-690539891-1001)

Path : \.vscode-insiders
SDDL : O:S-1-5-21-2012478179-265285931-690539891-1001G:S-1-5-21-2012478179-265285931-690539891-1001D:(A;OICIID;FA;;;SY)(A;OI
        CIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-2012478179-265285931-690539891-1001)

Path : \3D Objects
SDDL : O:S-1-5-21-2012478179-265285931-690539891-1001G:S-1-5-21-2012478179-265285931-690539891-1001D:(A;OICIID;FA;;;SY)(A;OI
        CIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-2012478179-265285931-690539891-1001)

...
```

免责声明：这里呈现的所有代码仅供学习使用。由于我们没有投入大量精力去测试它，所以没有任何保障，而且它并不是生产准备就绪的代码。您有责任对这段代码进行测试，并决定它是否完美符合您的需要。

<!--more-->
本文国际来源：[Cloning Folder Structures (with NTFS Permissions) – Part 1](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-folder-structures-with-ntfs-permissions-part-1)
