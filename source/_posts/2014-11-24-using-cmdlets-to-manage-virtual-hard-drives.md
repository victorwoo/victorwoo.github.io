---
layout: post
date: 2014-11-24 12:00:00
title: "PowerShell 技能连载 - 用 Cmdlet 管理虚拟硬盘驱动器"
description: PowerTip of the Day - Using Cmdlets to Manage Virtual Hard Drives
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
_适用于 Windows 8.1 Pro/Enterprise 或 Server 2012 R2_

Windows 8.1 和 Server 2012 R2 带来一系列额外的 cmdlet 命令，有一部分用于管理虚拟磁盘。不过，在使用这些 cmdlet 之前，您需要先启用“Hyper-V 角色”（请注意需要 Windows 8.1 Pro 或 Enterprise 版才支持客户端的 Hyper-V。“Home”版则不支持该功能）。 

在 Windows 8.1 中，您需要手动做以下操作：打开控制面板，进入程序/程序和功能。您也可以在 PowerShell 中键入“appwiz.cpl”打开该功能。

下一步，点击“启用或关闭 Windows 功能”。这将打开一个列出所有功能的对话框。请定位到“Hyper-V”节点并启用它。然后点击 OK。如果找不到“Hyper-V”节点，那么您的 Windows 版本不支持客户端的 Hyper-V。如果“Hyper-V 平台”选项呈灰色，那么您需要在计算机的 BIOS 设置中启用虚拟化支持。

安装该功能需要几秒钟。当安装完成以后，您就可以使用一系列新的 cmdlet：

```
PS> Get-Command -Module Hyper-V

CommandType     Name                                               ModuleName     
-----------     ----                                               ----------     
Cmdlet          Add-VMDvdDrive                                     Hyper-V        
Cmdlet          Add-VMFibreChannelHba                              Hyper-V        
Cmdlet          Add-VMHardDiskDrive                                Hyper-V        
Cmdlet          Add-VMMigrationNetwork                             Hyper-V        
Cmdlet          Add-VMNetworkAdapter                               Hyper-V         
(...)
```

<!--more-->
本文国际来源：[Using Cmdlets to Manage Virtual Hard Drives](http://community.idera.com/powershell/powertips/b/tips/posts/using-cmdlets-to-manage-virtual-hard-drives)
