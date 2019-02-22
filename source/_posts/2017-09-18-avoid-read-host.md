---
layout: post
date: 2017-09-18 00:00:00
title: "PowerShell 技能连载 - 避免使用 Read-Host"
description: PowerTip of the Day - Avoid Read-Host
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您是否使用 `Read-Host` 来接受用户的输入？如果您是这么做的，请重新考虑一下。`Read-Host` 总是提示用户，并且用了 `Read-Host` 就无法自动化运行脚本：

```powershell
$City = Read-Host -Prompt 'Enter City'
```

一个更好的简单方法是这样：

```powershell
param
(
    [Parameter(Mandatory)]$City
)
```

它创建了一个必选参数。如果用户没有提供传输这个实参，那么会创建一个提示，效果类似 Read-Host。但是，用户始终可以传入这个脚本的参数并使脚本自动化运行。只需要确保只有一个 `param()` 语句，并且必须放在脚本的开始处。逗号来分隔多个参数。

如果您不喜欢 `param()` 创建的提示，那么可以用这种方法：

```powershell
param
(
    $City = (Read-Host -Prompt 'Enter City')
)
```

这样，您可以完全控制提示的内容，并且用户又可以通过实参传入参数，并且无人值守运行脚本。

<!--本文国际来源：[Avoid Read-Host](http://community.idera.com/powershell/powertips/b/tips/posts/avoid-read-host)-->
