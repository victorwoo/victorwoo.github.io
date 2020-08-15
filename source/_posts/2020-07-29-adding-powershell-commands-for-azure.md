---
layout: post
date: 2020-07-29 00:00:00
title: "PowerShell 技能连载 - 添加 Azure 的 PowerShell 命令"
description: PowerTip of the Day - Adding PowerShell commands for Azure
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要在 Azure 云中管理和自动化操作您的资产，可以轻松安装免费的 PowerShell 模块，该模块带有大量新的 PowerShell 命令：

```powershell
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning 'AzureRM and Az modules installed at the same time is not supported.')
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
```

在 Windows PowerShell 上，如果您已经安装了较旧的 "AzureRM" 模块，不建议再安装 "Az" 模块，因此上面的代码检查 "AzureRM" 模块是否存在，仅当 Windows PowerShell 中不存在该模块时下载并安装新的 "Az" 模块。

"Az" 模块由许多嵌套模块组成，并且都已安装。此过程可能需要几分钟。安装模块后，您可以查看所有新模块以及它们带来的命令：

```powershell
# listing all new commands
Get-Command -Module Az.*

# listing all new modules
Get-Module -Name Az.* -ListAvailable
```

第一步是连接到您的Azure帐户：

```powershell
PS> Connect-AzAccount
```

如果您有多个 Azure 订阅，则可以像这样选择一个订阅：

```powershell
Get-AzSubscription | Out-GridView -Title 'Subscription?' -OutputMode Single | Select-AzSubscription
```

连接后，您就可以开始使用新命令了。作为初学者，您应该专注于动词为 "Get" 的命令，这样您就不会弄乱任何东西：

```powershell
# listing all Azure VMs
Get-AzVM

# listing all safe Get-* cmdlets
Get-Command -Verb Get -Module Az.*
```

若要了解您可以使用新的 Azure 命令做什么，请在浏览器中访问扩展的联机帮助：

```powershell
Start-Process -FilePath https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az
```

<!--本文国际来源：[Adding PowerShell commands for Azure](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-powershell-commands-for-azure)-->

