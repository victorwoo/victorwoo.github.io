---
layout: post
date: 2017-09-12 00:00:00
title: "PowerShell 技能连载 - 在 Linux 的 PowerShell Core 中安装模块"
description: PowerTip of the Day - Installing Modules in PowerShell Core on Linux
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您想通过 PowerShellGet 库为所有用户安装模块，您需要管理员权限。在 Linux 的 PowerShell Core 中，您可以用 `sudo` 命令来启用管理员权限，并且运行 PowerShell。只需要把命令写在在大括号中即可。

在 Linux 的 PowerShell Core 上，以下命令将为所有用户从 PowerShell Gallery 中安装 AzureRM.NetCore：

```powershell
sudo powershell -Command {Install-Module -Name AzureRM.Netcore}
```

<!--本文国际来源：[Installing Modules in PowerShell Core on Linux](http://community.idera.com/powershell/powertips/b/tips/posts/installing-modules-in-powershell-core-on-linux)-->
