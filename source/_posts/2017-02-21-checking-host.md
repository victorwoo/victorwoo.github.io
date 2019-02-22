---
layout: post
date: 2017-02-21 00:00:00
title: "PowerShell 技能连载 - 检测宿主"
description: PowerTip of the Day - Checking Host
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在过去，Microsoft 发布了两个 PowerShell 宿主 (host)：一个时基本的 PowerShell 控制台，以及更复杂的 PowerShell ISE。一些用户使用类似以下的代码来分辨脚本时运行在控制台中还是运行在 PowerShell ISE 中：

```powershell
$inISE = $psISE -ne $null

"Running in ISE: $inISE"
```

然而，现在有越来越多的宿主。Visual Studio 可以作为 PowerShell 的宿主，Visual Studio Code 也可以。而且还有许多商业编辑器。所以您需要确定一个脚本是否在一个特定的环境中运行，请使用宿主标识符来代替：

```powershell
$name = $host.Name
$inISE = $name -eq 'Windows PowerShell ISE Host'

"Running in ISE: $inISE"
```

Each host emits its own host name, so this approach can be adjusted to any host. When you run a script inside Visual Studio Code, for example, the host name is “Visual Studio Code Host”.
每个宿主会提供它的宿主名称，所以这种方法可以适用于任何宿主。例如当您在 Visual Studio Code 中运行一个脚本，宿主名会变为 "Visual Studio Code Host"。

<!--本文国际来源：[Checking Host](http://community.idera.com/powershell/powertips/b/tips/posts/checking-host)-->
