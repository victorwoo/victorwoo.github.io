---
layout: post
date: 2020-07-31 00:00:00
title: "PowerShell 技能连载 - 添加 SharePoint 的 PowerShell 命令"
description: PowerTip of the Day - Adding PowerShell commands for SharePoint
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过 PowerShell 库，可以轻松访问其他 PowerShell 命令。例如，您可以下载并安装 SharePoint 的命令扩展，并使用 PowerShell 来自动化 SharePoint 网站：

```powershell
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force

# listing all new SharePoint commands
Get-Command -Module Microsoft.Online.SharePoint.PowerShell
```

在 PowerShell 库中，还有许多用于处理 SharePoint 的 PowerShell 模块。`Find-Module` 可帮助您确定更多有用的资源：

```powershell
Find-Module -Name *sharepoint*
```

知道您感兴趣的模块名称后，请使用 `Install-Module` 下载并安装它，或使用 `Save-Module` 将其下载到您选择的隔离文件夹中。这样，您可以调查源代码并确定是否信任该代码。

要了解有关 SharePoint 的 PowerShell 命令的更多信息，请访问官方帮助页面：

```powershell
Start-Process -FilePath https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online?view=sharepoint-ps
```

<!--本文国际来源：[Adding PowerShell commands for SharePoint](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-powershell-commands-for-sharepoint)-->

