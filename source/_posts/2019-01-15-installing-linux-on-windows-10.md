---
layout: post
date: 2019-01-15 00:00:00
title: "PowerShell 技能连载 - 在 Windows 10 中安装 Linux"
description: PowerTip of the Day - Installing Linux on Windows 10
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
Windows 中带有适用于 Linux 的 Windows 子系统 (WSL) 功能，您可以通过它来运行各种 Linux 发型版。通过提升权限的 PowerShell 来启用 WSL：

```powershell
Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online  
```

下一步，在 Windows 10 中打开 Microsoft Store，并且搜索 "Linux"。安装某个支持的 Linux 发行版（例如，Debian）！

这是全部的步骤。您现在可以在 PowerShell 里或通过开始菜单打开 Debian。只需要运行 "Debian" 命令。当您首次运行时，您需要设置一个 root 账号和密码。

您也许已经知道，PowerShell 是跨平台的，并且可以运行在 Linux 上。如果您希望使用新的 Debian 环境并且测试在 Linux 上运行 PowerShell，请在 Debian 控制台中运行以下代码：

```bash
sudo apt-get update
sudo apt-get install curl apt-transport-https
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo sh -c 'echo "deb https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
sudo apt-get update
sudo apt-get install -y powershell
pwsh
```

下一步，从 Debian 中，运行 "`pwsh`" 命令切换到 PowerShell 6。

<!--more-->
本文国际来源：[Installing Linux on Windows 10](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-linux-on-windows-10)
