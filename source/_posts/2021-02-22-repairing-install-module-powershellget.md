---
layout: post
date: 2021-02-22 00:00:00
title: "PowerShell 技能连载 - 修复 Install-Module (PowerShellGet)"
description: PowerTip of the Day - Repairing Install-Module (PowerShellGet)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 `Install-Module` ，您可以轻松地从 PowerShell Gallery ([www.powershellgallery.com](http://www.powershellgallery.com)) 下载和安装其他 PowerShell 模块。但是，在 Windows 系统上，此命令可能会中断。许多 Windows 系统仍随附 1.x 版本，并且 PowerShell Gallery 已切换到 Internet 协议 TLS 1.2，较早的 Windows 版本不会自动支持该协议。

要解决 Install-Module 的问题，您应确保 PowerShell 可以使用 TLS 1.2 来访问 PowerShell Gallery：

```powershell
[System.Net.ServicePointManager]::SecurityProtocol =
[System.Net.ServicePointManager]::SecurityProtocol -bor
[System.Net.SecurityProtocolType]::Tls12
```

接下来，您应该像这样手动重新安装 PowerShellGet 和 Packagemanagement 模块的当前版本（不需要管理员权限）：

```powershell
Install-Module -Name PowerShellGet -Scope CurrentUser -Force -AllowClobber
Install-Module -Name Packagemanagement -Scope CurrentUser -Force -AllowClobber
```

这应该能为大多数用户解决问题。

如果根本无法使用 `Install-Module`，则可以手动将 PowerShellGet 和 Packagemanagement 的模块文件夹从更新的 Windows 版本复制到另一个版本。运行以下行以查找可以在何处找到最新版本的 PowerShellGet：

```powershell
Get-Module -Name powershellget -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
```

最新版本是 2.2.5，并且您不应使用低于 2.x 的版本。如果您的 PowerShell 报告系统上同时存在版本 1.x 和 2.x，则一切正常。PowerShell始终会自动选择最新版本。

<!--本文国际来源：[Repairing Install-Module (PowerShellGet)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-install-module-powershellget)-->

