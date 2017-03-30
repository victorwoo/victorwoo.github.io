layout: post
date: 2017-03-30 00:00:00
title: "PowerShell 技能连载 - 到处 ActiveDirectory 模块"
description: PowerTip of the Day - Exporting ActiveDirectory Module
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
要在 PowerShell 中管理 Active Directory 的用户和计算机，您需要 Microsoft 提供的免费的 RSAT 工具中的 Active Directory 模块。

假设您是一个域管理员并且拥有远程管理域控制器的权限，您也可以从 DC 中导出 ActiveDirectory 模块，并且可以通过隐式远程操作在本地使用它。

以下是使用方法：

```powershell
$DC = 'dc1'  # rename, must be name of one of your domain controllers

# create a session
$s = New-PSSession -ComputerName dc1
# export the ActiveDirectory module from the server to a local module "ADStuff"
Export-PSSession -Session $s -OutputModule ADStuff -Module ActiveDirectory -AllowClobber -Force

# remove session
Remove-PSSession $s
```

当您运行这段代码时，并且您拥有连接到 DC 的权限时，这段代码创建了一个名为 "ADStuff" 的本地 module，其中包含了所有 AD cmdlet。您可以通过隐式远程处理使用 AD cmdlet而不需要安装 RSAT 工具。

警告：由于所有 cmdlet 实际上都是运行在服务器端，所有结果都被序列化后传到本地。这会改变对象类型，所以当您用将对象通过管道从一个 AD cmdlet 传到另一个 AD cmdlet 时，您可能会遇到绑定问题。只要您在管道之外使用 cmdlet，那么一切都没问题。

<!--more-->
本文国际来源：[Exporting ActiveDirectory Module](http://community.idera.com/powershell/powertips/b/tips/posts/exporting-activedirectory-module)
