---
layout: post
date: 2022-06-03 00:00:00
title: "PowerShell 技能连载 - 简单的类似 grep 的文本过滤器（第 1 部分）"
description: PowerTip of the Day - Simple Text-Based Filtering a la grep (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是面向对象的，因此与 Linux 和 grep 相比，文本过滤和正则表达式的应用不多。然而，有时候通过简单的文本模式来过滤命令对象是高效舒适的。

它的工作方式类似。PowerShell 确实带有类似 grep 的命令，即 `Select-String` cmdlet 。虽然它擅长过滤文件内容，但在尝试过滤命令输出时，它没什么用。

假设您只对运行中的服务感兴趣。按 "running" 来过滤，结果一无所获：

```powershell
PS> Get-Service | Select-String Running
```

不过，这不是 `Select-String` 的错。`Select-String` 需要文本输入，而 cmdlet 通常返回强类型的对象，而不是文本。 通过将命令输出转换为字符串，就能正常工作了：

```powershell
PS> Get-Service | Out-String -Stream | Select-String Running

Running  AdobeARMservice    Adobe Acrobat Update Service
Running  AgentShellService  Spiceworks Agent Shell Service
Running  Appinfo            Application Information
Running  AppMgmt            Application Management
Running  AppXSvc            AppX Deployment Service (AppXSVC)
...
```

如果您不介意最终结果是纯文本，那就太好了。这基本上就是简单文本过滤的处理代价。

不，其实不是。您可以创建自己的过滤器命令，该命令 *暂时* 将传入的对象转换为文本，进行文本模式匹配，然后返回未更改的强类型对象。听起来很简单，确实如此。这是 Powershell 的 grep：

```powershell
filter grep ([string]$Pattern)
{
    if ((Out-String -InputObject $_) -match $Pattern) { $_ }
}
```

运行代码，然后尝试：

```powershell
PS> Get-Service | grep running

Status   Name               DisplayName
------   ----               -----------
Running  AdobeARMservice    Adobe Acrobat Update Service
Running  AgentShellService  Spiceworks Agent Shell Service
Running  Appinfo            Application Information
Running  AppMgmt            Application Management
...
```

它的使用非常易于使用，最重要的是，输出强类型的对象，因此您仍然可以访问其属性

```powershell
PS> Get-Service | grep running | Select-Object Name, StartType, Status

Name                                        StartType  Status
----                                        ---------  ------
AdobeARMservice                             Automatic Running
AgentShellService                           Automatic Running
Appinfo                                        Manual Running
AppMgmt                                        Manual Running
AppXSvc                                        Manual Running
AudioEndpointBuilder                        Automatic Running
```

<!--本文国际来源：[Simple Text-Based Filtering a la grep (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/simple-text-based-filtering-a-la-grep-part-1)-->

