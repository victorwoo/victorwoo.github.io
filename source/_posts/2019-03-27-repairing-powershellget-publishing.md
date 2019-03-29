---
layout: post
date: 2019-03-27 00:00:00
title: "PowerShell 技能连载 - 修复 PowerShellGet 发布"
description: PowerTip of the Day - Repairing PowerShellGet Publishing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您在使用 `Publish-Module` 来将您的模块发布到 PowerShell 仓库，并且您一直收到不支持的命令的错误信息，那么可能需要重新安装管理模块上传的可执行程序。当这些可执行程序太旧时，它们可能不能再能和最新的 `PowerShellGet` 模块同步。

运行这段代码，以管理员权限（对所有用户有效）下载并更新 nuget.exe：

```powershell
$Path = "$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet"
$exists = Test-Path -Path $Path
if (!$exists)
{
    $null = New-Item -Path $Path -ItemType Directory
}
Invoke-WebRequest -Uri https://aka.ms/psget-nugetexe -OutFile "$Path\NuGet.exe"
```

运行这段代码只针对当前用户下载并安装 nuget.exe：

```powershell
$Path = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet"
$exists = Test-Path -Path $Path
if (!$exists)
{
    $null = New-Item -Path $Path -ItemType Directory
}
Invoke-WebRequest -Uri https://aka.ms/psget-nugetexe -OutFile "$Path\NuGet.exe"
```

<!--本文国际来源：[Repairing PowerShellGet Publishing](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-powershellget-publishing)-->

