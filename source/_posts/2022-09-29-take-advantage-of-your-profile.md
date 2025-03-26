---
layout: post
date: 2022-09-29 00:00:00
title: "PowerShell 技能连载 - 利用用户配置文件的优势"
description: PowerTip of the Day - Take Advantage of Your Profile
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 PowerShell 启动时，它会自动查找一个特殊的自动启动脚本。默认情况下该脚本不存在，并且对于每个 PowerShell 环境是不同的。`$profile` 变量体现它的路径。这是在我机器的 Windows PowerShell 控制台环境中的路径：

```powershell
C:\Users\tobias\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

可以快速地检测这个文件是否存在，如果不存在的话，用 PowerShell 创建它：

```powershell
$exists = Test-Path -Path $profile
if ($exists -eq $false)
{
    $null = New-Item -Path $profile -ItemType File -Force
}

notepad $profile
```

有了这样的自启动脚本后，您可以在您的每个 PowerShell 会话中添加各种有用的东西。例如，创建一个较短的命令行提示符：

```powershell
function prompt
{
    'PS> '
    $host.UI.RawUI.WindowTitle = Get-Location
}
```

或通过简化的登录使生活更轻松：

```powershell
function in365
{
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -UserPrincipalName 'youremailhere'
}

function out365
{
    Disconnect-ExchangeOnline -Confirm:$false
}
```

只需确保您保存更改以及执行策略允许脚本运行即可。

<!--本文国际来源：[Take Advantage of Your Profile](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/take-advantage-of-your-profile)-->

