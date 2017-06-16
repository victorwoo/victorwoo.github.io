---
layout: post
date: 2017-06-07 00:00:00
title: "PowerShell 技能连载 - 重要的 PowerShell 变量"
description: PowerTip of the Day - Important PowerShell Variables
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
以下是一个重要的 PowerShell 变量的列表：`$pshome` 表示 PowerShell 所在的位置。`$home` 是个人用户配置文件夹的路径。`$PSVersionTable` 返回 PowerShell 的版本和重要的子组件的版本：

```powershell
PS> $pshome
C:\Windows\System32\WindowsPowerShell\v1.0

PS> $HOME
C:\Users\tweltner

PS> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      5.1.14393.0
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.14393.0
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
```

`$profile` 是您个人的自启动脚本所在的位置。每当您当前的 PowerShell 宿主启动时，自启动脚本就会自动加载（假设文件存在）。`$profile.CurrentUserAllHosts` 是任何宿主都会加载的配置文件脚本。并且 `$env:PSModulePath` 列出 PowerShell 可以自动发现的存放 PowerShell module 的文件夹：

```powershell
PS> $profile
C:\Users\tweltner\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

PS> $profile.CurrentUserAllHosts
C:\Users\tweltner\Documents\WindowsPowerShell\profile.ps1

PS> $env:PSModulePath -split ';'
C:\Users\tweltner\Documents\WindowsPowerShell\Modules
C:\Program Files\WindowsPowerShell\Modules
C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules

PS>
```

<!--more-->
本文国际来源：[Important PowerShell Variables](http://community.idera.com/powershell/powertips/b/tips/posts/important-powershell-variables)
