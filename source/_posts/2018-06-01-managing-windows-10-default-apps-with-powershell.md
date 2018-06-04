---
layout: post
date: 2018-06-01 00:00:00
title: "PowerShell 技能连载 - 用 PowerShell 管理 Windows 10 的缺省 APP"
description: PowerTip of the Day - Managing Windows 10 Default Apps with PowerShell
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
Windows 10 缺省安装了一系列 APP，而且即使您手动卸载了它们，它们有可能在下一个重大 Windows 10 更新的时候又回来。

PowerShell 也可以移除这些 Windows 10 APP。您可以在任意时候重新运行脚本，来确保要清除的 APP 确实被删除了。例如这行代码将移除 3D Builder APP：

```powershell
PS> Get-AppxPackage *3dbuilder* | Remove-AppxPackage
```

有许多类似 http://www.thewindowsclub.com/remove-built-windows-10-apps-users-using-powershell-script 的网站，提供许多更多如何移除特定的 Windows 10 APP 的例子。

<!--more-->
本文国际来源：[Managing Windows 10 Default Apps with PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/managing-windows-10-default-apps-with-powershell)
