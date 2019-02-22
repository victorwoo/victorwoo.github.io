---
layout: post
date: 2018-08-20 00:00:00
title: "PowerShell 技能连载 - 远程读取配置表（第 1 部分）"
description: PowerTip of the Day - Reading Registry Remotely (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您无法使用 PowerShell 远程处理，那么您需要通过 DCOM 从另一个系统中读取注册表值，以下是一些您可能希望试验的示例代码：

```powershell
$ComputerName = 'pc01'
# NOTE: RemoteRegistry Service needs to run on a target system!
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
$key = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')

$key.GetSubKeyNames() | ForEach-Object {
    $subkey = $key.OpenSubKey($_)
        [PSCustomObject]@{
            Name = $subkey.GetValue(‘DisplayName’)
            Version = $subkey.GetValue(‘DisplayVersion’)
        }
    $subkey.Close()
    }

$key.Close()
$reg.Close()
```

只需要做一些小改动，该代码就能返回一个 AD 使用的列表

这段示例代码需要：

* 您有目标机器的本地管理员特权
* `RemoteRegistry` 服务在对方机器上运行
* 对方机器的本地防火墙启用了“远程管理例外”

<!--本文国际来源：[Reading Registry Remotely (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-registry-remotely-part-1)-->
