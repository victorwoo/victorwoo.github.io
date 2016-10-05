layout: post
date: 2014-12-18 12:00:00
title: "PowerShell 技能连载 - 用 SDDL 替换 NTFS 权限"
description: PowerTip of the Day - Replacing NTFS Permissions with SDDL Information
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

您可以通过 `Get-Acl` 命令将文件和文件夹的安全信息导出成 SDDL 格式（安全描述定义语言）的纯文本文件：

    $FolderToRead = 'C:\folder1'
    
    $securityDescriptor = Get-Acl -Path $FolderToRead
    $securityDescriptor.GetSecurityDescriptorSddlForm('All') 

您可以将 SDDL 通过管道输出到剪贴板，然后将它粘贴到另一个脚本中：

    $FolderToRead = 'C:\folder1'
    
    $securityDescriptor = Get-Acl -Path $FolderToRead
    $securityDescriptor.GetSecurityDescriptorSddlForm('All') | clip.exe 

类似这样将 SDDL 加入脚本中，例如（请注意 SDDL 总是只有一行，所以请不要添加换行符）：

    $sddl = 'O:S-1-5-21-2649034417-1209187175-3910605729-1000G:S-1-5-21-2649034417-1209187175-3910605729-513D:(A;ID;FA;;;BA)(A;OICIIOID;GA;;;BA)(A;ID;FA;;;SY)(A;OICIIOID;GA;;;SY)(A;OICIID;0x1200a9;;;BU)(A;ID;0x1301bf;;;AU)(A;OICIIOID;SDGXGWGR;;;AU)'
    
    
    $FolderToConfigure = 'C:\folder2'
    
    $securityDescriptor = Get-Acl -Path $FolderToConfigure
    $securityDescriptor.SetSecurityDescriptorSddlForm($sddl)
    Set-Acl -Path $FolderToConfigure -AclObject $securityDescriptor 

将 SDDL 插入脚本之后，您就不再需要生成 SDDL 用的模板文件夹了。您可以将安全信息应用到其它文件系统对象中，例如设置基本 NTFS 权限，或先编辑 SDDL 再应用它。

为您提供一些启示，在域迁移的场景中，您可以比如创建一个转换表，用于将旧的 SID 转换为新的 SID。然后，将旧的 SID 替换成新的 SID，然后将记录下的安全信息克隆到一个新的（或测试的）域中。

<!--more-->
本文国际来源：[Replacing NTFS Permissions with SDDL Information](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-ntfs-permissions-with-sddl-information)
