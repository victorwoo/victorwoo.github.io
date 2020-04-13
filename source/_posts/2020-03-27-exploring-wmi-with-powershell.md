---
layout: post
date: 2020-03-27 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 探索 WMI"
description: PowerTip of the Day - Exploring WMI with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Win32_LogicalDevice WMI 类代表计算机中可用的所有逻辑设备，通过查询此“超类”，您可以获取所有专用的单个类。这是找出 WMI 可以为您提供哪些信息以及 WMI 类的名称的简单方法：

```powershell
Get-CimInstance -ClassName CIM_LogicalDevice |
    Select-Object -Property Name, CreationClassName, DeviceID, SystemName |
    Out-GridView -Title 'Select one or more (hold CTRL)' -PassThru
```

在网格视图窗口中，选择一个或多个您感兴趣的实例（按住CTRL键选择多个实例），然后将选定的实例转储到控制台。请等待网格视图窗口填充完毕，然后再尝试选择某些内容。

在我的笔记本上，我选择了一个“音频设备”：

    Name                   CreationClassName DeviceID
    ----                   ----------------- --------
    Intel(R) Display-Audio Win32_SoundDevice INTELAUDIO\FUNC_01&VEN_8086&DEV_280...

要查找有关它的更多信息，请使用 "`CreationClassName`" 中的 WMI 类（即 `Win32_SoundDevice`）查询特定信息，运行以下命令：

```powershell
PS> Get-CimInstance -ClassName Win32_SoundDevice

Manufacturer         Name                          Status StatusInfo
------------         ----                          ------ ----------
Intel(R) Corporation Intel(R) Display-Audio        OK              3
DisplayLink          DisplayLink USB Audio Adapter OK              3
Realtek              Realtek Audio                 OK              3
```

显然，我的机器中有三个声音设备。要查看所有详细信息，请将数据发送到 `Select-Object`：

```powershell
PS> Get-CimInstance -ClassName Win32_SoundDevice | Select-Object *


ConfigManagerUserConfig     : False
Name                        : Intel(R) Display-Audio
Status                      : OK
StatusInfo                  : 3
Caption                     : Intel(R) Display-Audio
Description                 : Intel(R) Display-Audio
InstallDate                 :
Availability                :
ConfigManagerErrorCode      : 0
CreationClassName           : Win32_SoundDevice
DeviceID                    : INTELAUDIO\FUNC_01&VEN_8086&DEV_280F&SUBSYS_80860
                                101&REV_1000\5&6790FB4&0&0201
ErrorCleared                :
ErrorDescription            :
LastErrorCode               :
PNPDeviceID                 : INTELAUDIO\FUNC_01&VEN_8086&DEV_280F&SUBSYS_80860
                                101&REV_1000\5&6790FB4&0&0201
PowerManagementCapabilities :
PowerManagementSupported    : False
SystemCreationClassName     : Win32_ComputerSystem
SystemName                  : DESKTOP-8DVNI43
DMABufferSize               :
Manufacturer                : Intel(R) Corporation
MPU401Address               :
ProductName                 : Intel(R) Display-Audio
PSComputerName              :
CimClass                    : root/cimv2:Win32_SoundDevice
CimInstanceProperties       : {Caption, Description, InstallDate, Name...}
CimSystemProperties         : Microsoft.Management.Infrastructure.CimSystemProp
                                erties

ConfigManagerUserConfig     : False
Name                        : DisplayLink USB Audio Adapter
Status                      : OK
StatusInfo                  : 3
Caption                     : DisplayLink USB Audio Adapter
...
```

并且，如果您想进一步了解此类（或其它类），请访问PowerShell WMI参考：[http://powershell.one/wmi/root/cimv2/win32_sounddevice](http://powershell.one/wmi/root/cimv2/win32_sounddevice)。只需将WMI类名替换为您要使用的类名即可。

<!--本文国际来源：[Exploring WMI with PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-wmi-with-powershell)-->

