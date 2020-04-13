---
layout: post
date: 2020-04-08 00:00:00
title: "PowerShell 技能连载 - 管理自动磁盘检测"
description: PowerTip of the Day - Manage Automatic Disk Checks
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 Windows 检测到存储驱动器有异常，它就会启用自动完整性检查。对于系统分区，在下次启动时，Windows 会显示用户提示，并要求获得执行检查的权限。

要找出启用了这种检查的所有驱动器，请运行以下命令：

```powershell
PS> Get-CimInstance -ClassName Win32_AutochkSetting | Select-Object -Property SettingID, UserInputDelay

SettingID                                                        UserInputDelay
---------                                                        --------------
Microsoft Windows 10 Pro|C:\Windows|\Device\Harddisk0\Partition3              8
```

`UserInputDelay` 属性指定 Windows 在启动时等待用户提示的秒数。如果届时用户仍未响应，则将自动执行磁盘完整性检查。

WMI 可以更改此设置。如果要将延迟增加到 20 秒，请使用管理员权限运行以下命令：

```powershell
Set-CimInstance -Query "Select * From Win32_AutochkSetting" -Property @{UserInputDelay=20}
```

请注意，此命令为所有受支持的磁盘驱动器设置 `UserInputDelay`。要仅对选定的驱动器进行设置，请优化提交的查询，然后添加一个过滤器，例如：

```powershell
Set-CimInstance -Query 'Select * From Win32_AutochkSetting Where SettingID LIKE "%\\Device\\Harddisk0\\Partition3"' -Property @{UserInputDelay=30}
```

有关WMI查询的更多信息，请访问 [http://powershell.one/wmi/wql](http://powershell.one/wmi/wql)。


<!--本文国际来源：[Manage Automatic Disk Checks](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/manage-automatic-disk-checks)-->

