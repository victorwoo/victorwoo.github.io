layout: post
title: "PowerShell 技能连载 - 使用缺省参数"
date: 2014-07-04 00:00:00
description: PowerTip of the Day - Using Default Parameters
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
在 PowerShell 3.0 中，任意的 cmdlet 参数都可以定义一个缺省值。

例如这行代码，将设置所有 cmdlet 的 `-Path` 参数的缺省值为一个指定的路径：

    $PSDefaultParameterValues.Add('*:Path', 'c:\Windows')

所以当您运行 `Get-ChildItem` 或任何其它包含 `-Path` 参数的 cmdlet 时，看起来好像您已经指定了这个参数。

除了 `*` 之外，您当然也可以指定 cmdlet 的名称。所以如果您希望将 `Get-WmiObject` 的 `-ComputerName` 参数设置为指定的远程主机，那么只需要这样做：

    $PSDefaultParameterValues.Add('Get-WmiObject:ComputerName', 'server12')

所有这些缺省值只在当前的 PowerShell 会话中有效。如果您想使它们始终有效，那么只需要在您的配置脚本中定义缺省值即可。

要移除所有的缺省值，请使用这行代码：

    $PSDefaultParameterValues.Clear()

<!--more-->
本文国际来源：[Using Default Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/using-default-parameters)
