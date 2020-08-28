---
layout: post
date: 2020-08-20 00:00:00
title: "PowerShell 技能连载 - 加速 PowerShell 远程操作"
description: PowerTip of the Day - Speeding Up PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 远程操作功能极其强大：借助 `Invoke-Command`，您可以将任意 PowerShell 代码发送到一台或多台远程计算机，并在其中并行执行。

在 Windows 服务器上，通常会启用 PowerShell 远程处理，因此您所需要的只是管理员权限。这是一个简单的示例：

```powershell
PS> Invoke-Command -ScriptBlock { "I am running on $env:computername!" } -ComputerName server1 -Credential domain\adminuser
```

本技巧不是关于设置 PowerShell 远程操作的，因此我们假定上述调用确实对您有效。相反，我们将重点放在 PowerShell 远程操作的最重要瓶颈之一上，以及如何解决它。

这是一个访问远程系统并从 Windows 文件夹中转储 DLL 的代码。使用一个 stopwatch 测量所需时间：

```powershell
# change this to the computer you want to access
$computername = 'server123'

# ask for a credential that has admin privileges on the target side
$cred = Get-Credential -Message "Log on as Administrator to $computername!"

# check how long it takes to retrieve information
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

$result = Invoke-Command -ScriptBlock {
    Get-ChildItem -Path c:\windows\system32 -Filter *.dll
} -ComputerName $computername -Credential $cred

$stopwatch.Stop()
$stopwatch.Elapsed
```

令人惊讶的是，此代码运行了很长时间。当我们在自己的本地计算机上尝试它时，花费了 95 秒。从 `Invoke-Command` 返回信息的速度可能非常慢，因为对象需要序列化为 XML 以跨越进程边界，并在它们返回调用者时重新反序列化。

为了加快远程处理速度，请记住这一点，并仅返回尽可能少的信息。通常，信息量很容易减少。

例如，如果您确实需要 Windows 文件夹中所有 DLL 文件的列表，则很可能只需要一些属性，例如 path 和 size。通过添加一个 `Select-Object` 并指定您真正需要的属性，之前花费了 95 秒的相同代码现在可以在不到一秒钟的时间内运行：

```powershell
# change this to the computer you want to access
$computername = 'server123'

# ask for a credential that has admin privileges on the target side
$cred = Get-Credential -Message "Log on as Administrator to $computername!"

# check how long it takes to retrieve information
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

$result = Invoke-Command -ScriptBlock {
    Get-ChildItem -Path c:\windows\system32 -Filter *.dll |
    # REDUCE DATA BY SPECIFYING THE PROPERTIES YOU REALLY NEED!
    Select-Object -Property FullName, LastWriteTime
} -ComputerName $computername -Credential $cred

$stopwatch.Stop()
$stopwatch.Elapsed
```

<!--本文国际来源：[Speeding Up PowerShell Remoting](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/speeding-up-powershell-remoting)-->

