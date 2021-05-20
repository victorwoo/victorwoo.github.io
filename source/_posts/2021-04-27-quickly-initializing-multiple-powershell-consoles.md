---
layout: post
date: 2021-04-27 00:00:00
title: "PowerShell 技能连载 - 快速初始化多个PowerShell控制台"
description: PowerTip of the Day - Quickly Initializing Multiple PowerShell Consoles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您是许多领域的管理员，例如，Azure、SharePoint、SQL、Microsoft 365。对于每种环境，您可能需要运行一些先决条件，登录某些系统并运行一些命令，直到您的 PowerShell 环境准备好为止。

这是一个简单的策略，可以帮助您自动启动不同的PowerShell控制台。在新文件夹中，放置一个具有以下内容的脚本：

```powershell
# safely serialize a credential
$credPath = "$PSScriptRoot\secret.xml"
$exists = Test-Path -Path $credPath
if (!$exists)
{
    $cred = Get-Credential
    $cred | Export-Clixml -Path $credPath
}

# define your different environments
$action = @{
  'Azure'  = "$PSScriptRoot\azure.ps1"
  'Teams'  = "$PSScriptRoot\teams.ps1"
  'Office' = "$PSScriptRoot\office.ps1"
}

# run a new PowerShell for each environment, and run the
# associated "spin-up" script:
$action.Keys | ForEach-Object {
  $path = $action[$_]
  Start-Process -FilePath powershell -ArgumentList "-noexit -noprofile -executionpolicy bypass -file ""$path"""
}
```

该示例启动了三个 PowerShell 控制台，并为每个控制台运行一个单独的启动脚本。通过将脚本 azure.ps1，teams.ps1 和 office.ps1 添加到您的文件夹，您现在可以定义初始化和准备每个控制台所需的代码。您还可以通过从任何其他脚本中读取主凭据来使用公共凭据。这是一个例子：

```powershell
# set the console title bar
$host.UI.RawUI.WindowTitle = 'Administering Office'
# read the common credential from file
$cred = Import-Clixml -Path "$PSScriptRoot\secret.xml"
```

<!--本文国际来源：[Quickly Initializing Multiple PowerShell Consoles](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/quickly-initializing-multiple-powershell-consoles)-->
