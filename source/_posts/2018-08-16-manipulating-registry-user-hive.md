---
layout: post
date: 2018-08-16 00:00:00
title: "PowerShell 技能连载 - 使用注册表用户配置单元"
description: PowerTip of the Day - Manipulating Registry User Hive
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
读写注册表的 `HKEY_LOCAL_USER` 十分容易，因为这个配置单元对于所有用户都一致。那么如何读写其他用户的 `HKEY_CURRENT_USER` 配置单元？

假设您是管理员并且希望为其他用户的 `HKEY_CURRENT_USER` 配置单元添加注册表值。

首先您需要挂载该用户的用户配置单元。该配置单元位于该用户的用户配置文件下的 `NTUSER.DAT` 文件中。作为一个管理员，您需要先运行以下 PowerShell 代码来挂载 UserTobias 用户的用户配置文件：

```powershell
PS C:\> REG LOAD HKEY_Users\UserTobias "C:\Users\Tobias\NTUSER.DAT"
```

该用户配置单元将挂载在 `HKEY_USERS` 下名为 `UserTobias` 的注册表键中，而且 PowerShell 可以类似这样存取该路径：

```powershell
PS C:\> Get-ChildItem -Path Registry::HKEY_USERS\UserTobias


    Hive: HKEY_USERS\UserTobias


Name                           Property
----                           --------
AppEvents
Console                        ColorTable00             : 789516
                                ColorTable01             : 14300928
                                ColorTable02             : 958739
                                ColorTable03             : 14521914
                                ColorTable04             : 2035653
                                ColorTable05             : 9967496
                                ColorTable06             : 40129
```

现在要读取甚至写入该指定用户的配置单元十分容易。以下代码将创建一个新的注册表键：

```powershell
PS C:\> $null = New-Item -Path Registry::HKEY_USERS\UserTobias\Software\Microsoft\Windows\CurrentVersion\Test
```

以下是如何读取/写入一个值：

```powershell
PS C:\> Get-ItemProperty -Path Registry::HKEY_USERS\UserTobias\Software\Microsoft\OneDrive


EnableDownlevelInstallOnBluePlus : 0
EnableTHDFFeatures               : 1
PSPath                           : Microsoft.PowerShell.Core\Registry::HKEY_USERS\UserTobias\Software\Microsoft\OneDrive
PSParentPath                     : Microsoft.PowerShell.Core\Registry::HKEY_USERS\UserTobias\Software\Microsoft
PSChildName                      : OneDrive
PSProvider                       : Microsoft.PowerShell.Core\Registry




PS C:\> Set-ItemProperty -Path Registry::HKEY_USERS\UserTobias\Software\Microsoft\OneDrive -Name EnableDownlevelInstallOnBluePlus -Value 1 -Type DWord

PS C:\> Get-ItemProperty -Path Registry::HKEY_USERS\UserTobias\Software\Microsoft\OneDrive


EnableDownlevelInstallOnBluePlus : 1
EnableTHDFFeatures               : 1
PSPath                           : Microsoft.PowerShell.Core\Registry::HKEY_USERS\UserTobias\Software\Microsoft\OneDrive
PSParentPath                     : Microsoft.PowerShell.Core\Registry::HKEY_USERS\UserTobias\Software\Microsoft
PSChildName                      : OneDrive
PSProvider                       : Microsoft.PowerShell.Core\Registry
```

当您操作完 `HKEY_USERS` 注册表配置单元之后，别忘了卸载它：

```powershell
PS C:\> $null = REG UNLOAD HKEY_Users\UserTobias
```

请注意这条命令将会抛出一个 "Access Denied" 错误，如果您没有管理员特权，或者该注册表配置单元正在被其他人使用。例如，如果您启动了 regedit.exe，当该用户配置单元加载以后，regedit.exe 可以显示加载的用户配置单元，而当 regedit 处于打开状态时，该配置单元被锁定并且无法关闭。

<!--more-->
本文国际来源：[Manipulating Registry User Hive](http://community.idera.com/powershell/powertips/b/tips/posts/manipulating-registry-user-hive)
