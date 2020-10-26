---
layout: post
date: 2020-09-25 00:00:00
title: "PowerShell 技能连载 - 使用 Profile 脚本"
description: PowerTip of the Day - Using Profile Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
配置文件脚本的工作方式类似于 PowerShell 中的自动启动脚本。它们不一定存在，但是如果存在，PowerShell 会在每次启动时静默执行其内容。最多有四个配置文件脚本，此行代码显示它们的路径：

```powershell
PS> $profile | Select-Object -Property *

AllUsersAllHosts       : C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
AllUsersCurrentHost    : C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1
CurrentUserAllHosts    : C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\profile.ps1
CurrentUserCurrentHost : C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1
Length                 : 87
```

不必担心属性 “Length”：它是基于 `$profile` 是字符串这一事实的产物。PowerShell已在其中添加了四个属性，以返回受支持的配置文件的路径。

请注意，任何包含 “AllHosts” 的配置文件的路径对于所有 PowerShell 宿主都是相同的。您添加到其中的任何内容都可以在任何宿主中执行，包括 powershell.exe、PowerShell ISE、Visual Studio Code 或 PowerShell 7。包含 “CurrentHost” 的属性中的路径仅限于正在执行此行代码的宿主。

默认情况下，所有这些路径哪儿也不指向。要使用一个或多个，请确保创建了路径指向的文件。

<!--本文国际来源：[Using Profile Scripts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-profile-scripts2)-->

