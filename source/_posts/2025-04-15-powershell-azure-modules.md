---
layout: post
date: 2025-04-15 08:00:00
updated: 2025-04-15 08:00:00
title: "PowerShell 技能连载 - Azure PowerShell 模块入门"
description: PowerTip of the Day - Getting Started with Azure PowerShell Modules
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
---

_适用于 PowerShell 7.0 及以上版本_

<!-- more -->

## 背景引入

随着云计算的普及，越来越多的运维工程师和开发人员需要在日常工作中管理 Azure 资源。Azure PowerShell 模块提供了一套完整的命令行工具，让我们能够通过 PowerShell 脚本自动化管理虚拟机、存储账户、网络资源等各种 Azure 服务。

对于 PowerShell 用户来说，Azure PowerShell 模块是最直接的 Azure 管理方式之一。它不仅支持交互式操作，还可以轻松地集成到 CI/CD 流水线和自动化运维脚本中。本文将带你从零开始，了解如何安装、配置和使用 Azure PowerShell 模块。

## 安装 Az 模块

Azure PowerShell 的官方推荐模块是 `Az`。它是一个统一的模块集合，包含了管理所有 Azure 服务所需的 cmdlet。建议在 PowerShell 7 及以上版本中使用。

```powershell
# 安装 Az 模块（需要管理员权限）
Install-Module -Name Az -Repository PSGallery -Force

# 如果只需要特定服务模块，可以单独安装
# 例如仅安装计算资源模块
Install-Module -Name Az.Compute -Repository PSGallery -Force

# 验证安装结果
Get-InstalledModule -Name Az* | Select-Object Name, Version
```

安装完成后，可以通过查看模块版本来确认安装是否成功。

## 连接到 Azure 账户

在使用任何 Azure cmdlet 之前，你需要先通过身份验证连接到 Azure。

```powershell
# 交互式登录（会弹出浏览器窗口）
Connect-AzAccount

# 如果有多个订阅，可以指定订阅
Connect-AzAccount -SubscriptionId "your-subscription-id"

# 使用服务主体进行非交互式登录（适合自动化场景）
$SecurePassword = ConvertTo-SecureString "your-client-secret" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential("your-app-id", $SecurePassword)
Connect-AzAccount -ServicePrincipal -TenantId "your-tenant-id" -Credential $Credential
```

连接成功后，可以查看当前的账户信息和订阅列表。

```powershell
# 查看当前账户信息
Get-AzContext

# 列出所有可用的订阅
Get-AzSubscription | Select-Object Name, Id, State
```

## 常用操作示例

以下是一些最常用的 Azure 资源管理操作。

### 查看资源组

```powershell
# 列出所有资源组
Get-AzResourceGroup | Select-Object ResourceGroupName, Location, Tags

# 按名称查找特定资源组
Get-AzResourceGroup -Name "my-resource-group"
```

### 创建资源组和存储账户

```powershell
# 定义变量
$ResourceGroupName = "my-demo-rg"
$Location = "eastasia"
$StorageAccountName = "mydemostorage$(Get-Random -Maximum 9999)"

# 创建资源组
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# 创建存储账户
$StorageAccount = New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -SkuName Standard_LRS `
    -Location $Location `
    -Kind StorageV2

Write-Host "存储账户 $($StorageAccount.StorageAccountName) 创建成功"
```

### 管理虚拟机

```powershell
# 列出指定资源组中的虚拟机
Get-AzVM -ResourceGroupName "my-resource-group" |
    Select-Object Name, Location, @{N='状态';E={$_.ProvisioningState}}

# 启动虚拟机
Start-AzVM -ResourceGroupName "my-resource-group" -Name "my-vm"

# 停止虚拟机
Stop-AzVM -ResourceGroupName "my-resource-group" -Name "my-vm" -Force
```

## 查询和过滤资源

当 Azure 资源数量增多后，高效的查询和过滤变得尤为重要。

```powershell
# 使用 Where-Object 过滤特定区域的资源
Get-AzResource | Where-Object { $_.Location -eq "eastasia" } |
    Select-Object Name, ResourceType, Location

# 使用 Get-AzResource 按标签过滤
Get-AzResource -TagName "Environment" -TagValue "Production" |
    Select-Object Name, ResourceType

# 结合 Out-GridView 进行交互式选择
$VM = Get-AzVM | Out-GridView -Title "请选择一台虚拟机" -PassThru
Write-Host "你选择了: $($VM.Name)"
```

## 执行结果示例

```
PS> Get-InstalledModule -Name Az* | Select-Object Name, Version

Name           Version
----           -------
Az.Accounts    3.0.2
Az.Compute     7.0.0
Az.Storage     6.1.0
Az.Resources   7.2.0

PS> Get-AzContext

Name             : my-subscription (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
Account          : user@example.com
Environment      : AzureCloud
Subscription     : my-subscription
Tenant           : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

PS> Get-AzResourceGroup | Select-Object ResourceGroupName, Location

ResourceGroupName    Location
-----------------    --------
my-demo-rg           eastasia
my-production-rg     eastasia
my-test-rg           southeastasia
```

## 更新和卸载模块

保持 Az 模块为最新版本可以确保你拥有最新的功能和修复。

```powershell
# 更新 Az 模块到最新版本
Update-Module -Name Az -Force

# 查看当前安装的版本
Get-InstalledModule -Name Az | Select-Object Name, Version, PublishedDate

# 如果需要卸载（例如重新安装）
# 注意：先卸载所有 Az 子模块，再卸载主模块
Get-InstalledModule -Name Az* | Uninstall-Module -Force
```

## 注意事项

- **模块大小**：Az 模块集合较大，完整安装可能需要较长时间。如果磁盘空间有限，可以只安装所需的服务子模块（如 `Az.Compute`、`Az.Storage`）。
- **PowerShell 版本**：强烈建议使用 PowerShell 7.x，部分 cmdlet 在 Windows PowerShell 5.1 中可能存在兼容性问题。
- **身份验证安全**：在自动化脚本中使用服务主体时，请勿将密钥硬编码在脚本中。建议使用 Azure Key Vault 或环境变量来存储敏感信息。
- **模块冲突**：不要同时安装旧的 `AzureRM` 模块和新的 `Az` 模块，它们之间存在 cmdlet 名称冲突。如果之前安装了 `AzureRM`，请先使用 `Uninstall-AzureRm` 将其卸载。
- **中国区 Azure**：如果使用的是 Azure 中国区（世纪互联运营），需要额外指定 `Environment` 参数，使用 `Connect-AzAccount -Environment AzureChinaCloud` 进行连接。
