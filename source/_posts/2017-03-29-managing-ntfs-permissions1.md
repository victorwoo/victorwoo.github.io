---
layout: post
date: 2017-03-29 00:00:00
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
由于没有内置的管理 NTFS 权限的 cmdlet，所以有越来越多的开源 PowerShell module 实现这个功能。一个有前途的 module 是由 Raimund Andree，一个德国的 Microsoft 工程师写的。他也将在即将到来的 PowerShell 欧洲会议 ([www.psconf.eu](http://www.psconf.eu)) 中演讲。

如果您使用的是 PowerShell 5 或已经安装了 PowerShellGet ([www.powershellgallery.com](http://www.powershellgallery.com))，以下是从 PowerShell Gallery 下载并安装 "NTFSSecurity" module 的方法：

```powershell
# review module details
Find-Module -Repository PSGallery -Name NTFSSecurity | Select-Object -Property * | Out-GridView

# download module
Install-Module -Repository PSGallery -Name NTFSSecurity -Scope CurrentUser
```

要查看所有的新 cmdlet，请试试这段代码：

```powershell
PS C:\> Get-Command -Module NTFSSecurity

CommandType     Name                                               Version

-----------     ----                                               -------
Cmdlet          Add-NTFSAccess                                     4.2.3
Cmdlet          Add-NTFSAudit                                      4.2.3
Cmdlet          Clear-NTFSAccess                                   4.2.3
Cmdlet          Clear-NTFSAudit                                    4.2.3
Cmdlet          Copy-Item2                                         4.2.3
Cmdlet          Disable-NTFSAccessInheritance                      4.2.3
Cmdlet          Disable-NTFSAuditInheritance                       4.2.3
Cmdlet          Disable-Privileges                                 4.2.3
Cmdlet          Enable-NTFSAccessInheritance                       4.2.3
Cmdlet          Enable-NTFSAuditInheritance                        4.2.3
Cmdlet          Enable-Privileges                                  4.2.3
Cmdlet          Get-ChildItem2                                     4.2.3
Cmdlet          Get-DiskSpace                                      4.2.3
Cmdlet          Get-FileHash2                                      4.2.3
Cmdlet          Get-Item2                                          4.2.3
Cmdlet          Get-NTFSAccess                                     4.2.3
Cmdlet          Get-NTFSAudit                                      4.2.3
Cmdlet          Get-NTFSEffectiveAccess                            4.2.3
Cmdlet          Get-NTFSHardLink                                   4.2.3
Cmdlet          Get-NTFSInheritance                                4.2.3
Cmdlet          Get-NTFSOrphanedAccess                             4.2.3
Cmdlet          Get-NTFSOrphanedAudit                              4.2.3
Cmdlet          Get-NTFSOwner                                      4.2.3
Cmdlet          Get-NTFSSecurityDescriptor                         4.2.3
Cmdlet          Get-NTFSSimpleAccess                               4.2.3
Cmdlet          Get-Privileges                                     4.2.3
Cmdlet          Move-Item2                                         4.2.3
Cmdlet          New-NTFSHardLink                                   4.2.3
Cmdlet          New-NTFSSymbolicLink                               4.2.3
Cmdlet          Remove-Item2                                       4.2.3
Cmdlet          Remove-NTFSAccess                                  4.2.3
Cmdlet          Remove-NTFSAudit                                   4.2.3
Cmdlet          Set-NTFSInheritance                                4.2.3
Cmdlet          Set-NTFSOwner                                      4.2.3
Cmdlet          Set-NTFSSecurityDescriptor                         4.2.3
Cmdlet          Test-Path2                                         4.2.3
```

当您获取到这些 cmdlet，那么增加或设置 NTFS 权限就轻而易举：

```powershell
$path = 'c:\test1'

mkdir $path

Get-NTFSAccess -Path $Path |
    Add-NTFSAccess -Account training14\student14 -AccessRights CreateFiles -AccessType Allow
```

警告：您需要管理员权限才能更改 NTFS 权限，即使是操作您拥有的文件系统对象。

<!--本文国际来源：[Managing NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/managing-ntfs-permissions1)-->
