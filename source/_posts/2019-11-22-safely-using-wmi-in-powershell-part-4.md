---
layout: post
date: 2019-11-22 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中安全地使用 WMI（第 4 部分）"
description: PowerTip of the Day - Safely Using WMI in PowerShell (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在这个迷你系列中，我们在探索 `Get-WmiObject` 和 `Get-CimInstance` 之间的差异。未来的 PowerShell 版本不再支持 `Get-WMIObject`，因此，如果您尚未加入，则需要切换到 `Get-CimInstance`。

在前一个部分中您学到了通过网络查询信息时有明显的区别，并且 `Get-CimInstance` 可以使用可充分定制且可复用的会话对象，来帮助网络访问速度更快以及消耗更少的资源。

由于 `Get-CimInstance` 工作机制类似 Web Service，而不像 `Get-WmiObject` 是基于 DCOM 的，这在返回的数据上有许多重要的含义。`Get-CimInstance` 总是通过序列化，所以您总是不可避免地收到一个副本，而不是原始对象。这是为什么 `Get-CimInstance` 永远不返回方法的原因。您永远只会获取到属性。

以下是一个可实践的示例：`Win32_Process` WMI 类有一个名为 `GetOwner()` 的方法返回进程的所有者。如果您希望找出谁登录到您的计算机，您需要查询 explorer.exe 进程并列出他们的所有者：

```powershell
# find all explorer.exe instances
Get-WmiObject -Class Win32_Process -Filter 'Name="explorer.exe"' |
    ForEach-Object {
    # call the WMI method GetOwner()
    $owner = $_.GetOwner()
    if ($owner.ReturnValue -eq 0)
    {
        # return either the process owner...
        '{0}\{1}' -f $owner.Domain, $owner.User
    }
    else
    {
        # ...or the error code
        'N/A (Error Code {0})' -f $owner.ReturnValue
    }
    } |
    # remove duplicates
    Sort-Object -Unique
```

如果您希望将这段代码转换为使用 `Get-CimInstance`，那么将无法访问 `GetOwner()` 方法，因为 `Get-CimInstance` 只返回一个属性集合。相应地需要执行 `Invoke-CimMethod` 方法来调用方法：

```powershell
# find all explorer.exe instances
Get-CimInstance -ClassName Win32_Process -Filter 'Name="explorer.exe"' |
    ForEach-Object {
    # call the WMI method GetOwner()
    $owner = $_ | Invoke-CimMethod -MethodName GetOwner
    if ($owner.ReturnValue -eq 0)
    {
        # return either the process owner...
        '{0}\{1}' -f $owner.Domain, $owner.User
    }
    else
    {
        # ...or the error code
        'N/A (Error Code {0})' -f $owner.ReturnValue
    }
    } |
    # remove duplicates
    Sort-Object -Unique
```

`Invoke-CimMethod` 或者需要和 `CimInstance` 配合使用，或者需要和原始的查询合并，这可以进一步简化代码：

```powershell
# find all explorer.exe instances
Invoke-CimMethod -Query 'Select * From Win32_Process Where Name="explorer.exe"' -MethodName GetOwner |
    ForEach-Object {
    if ($_.ReturnValue -eq 0)
    {
        # return either the process owner...
        '{0}\{1}' -f $_.Domain, $_.User
    }
    else
    {
        # ...or the error code
        'N/A (Error Code {0})' -f $_.ReturnValue
    }
    } |
    # remove duplicates
    Sort-Object -Unique
```

`Invoke-CimMethod` 也可以调用静态的 WMI 方法，这些方法是属于 WMI 类的方法而不是属于一个独立的实例。如果您希望在本地或者远程创建一个新的进程（启动一个新的程序），那么可以使用这样的一行代码：

```powershell
PS> Invoke-CimMethod -ClassName Win32_Process -MethodName "Create" -Arguments @{ CommandLine = 'notepad.exe'; CurrentDirectory = "C:\windows\system32" }

ProcessId ReturnValue PSComputerName
--------- ----------- --------------
        3308           0
```

注意：如果您在一台远程计算机上启动了一个程序，它将会在您的隐藏登录会话中运行并且在屏幕上不可见。

<!--本文国际来源：[Safely Using WMI in PowerShell (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/safely-using-wmi-in-powershell-part-4)-->

