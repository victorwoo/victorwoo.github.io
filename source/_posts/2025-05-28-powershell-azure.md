---
layout: post
date: 2025-05-28 08:00:00
updated: 2025-05-28 08:00:00
title: "PowerShell 技能连载 - Azure 自动化管理"
description: PowerTip of the Day - Azure Automation Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- cloud
- az-module
---

_适用于 PowerShell 7.0 及以上版本，需安装 Az PowerShell 模块_

微软 Azure 是全球第二大公有云平台，而 PowerShell 是管理 Azure 资源的首选工具之一。Az PowerShell 模块提供了覆盖所有 Azure 服务的命令集，从虚拟机管理到存储操作，从网络配置到安全策略，都可以通过 PowerShell 脚本自动化完成。相比于 Azure Portal 的点击操作，PowerShell 脚本具有可重复、可版本控制、可审计的优势。

本文将讲解 Az 模块的基础使用、虚拟机管理、存储操作，以及常见自动化场景。

## 安装与连接

```powershell
# 安装 Az 模块（如果尚未安装）
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# 查看已安装的 Az 模块版本
Get-InstalledModule -Name Az | Select-Object Name, Version

# 登录 Azure（交互式）
Connect-AzAccount

# 使用设备代码登录（无浏览器环境）
Connect-AzAccount -UseDeviceAuthentication

# 登录后查看默认订阅
Get-AzContext | Select-Object Account, Subscription, Tenant

# 列出所有订阅
Get-AzSubscription | Select-Object Name, Id, State |
    Format-Table -AutoSize

# 切换订阅
Select-AzSubscription -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 使用服务主体登录（自动化场景）
$securePassword = ConvertTo-SecureString "your-client-secret" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("app-client-id", $securePassword)
Connect-AzAccount -ServicePrincipal -TenantId "tenant-id" -Credential $credential
```

执行结果示例：

```
Name Version
---- -------
Az   12.0.0

Account              : admin@contoso.com
Subscription         : Production (xxx-xxx)
Tenant               : contoso.onmicrosoft.com

Name                 Id                                   State
----                 --                                   -----
Production           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx Enabled
Development          yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy Enabled
Staging              zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz Enabled
```

## 虚拟机管理

虚拟机是 Azure 上最基础的 IaaS 资源：

```powershell
# 列出所有虚拟机
Get-AzVM | Select-Object Name, ResourceGroupName, Location,
    @{N='Size'; E={$_.HardwareProfile.VmSize}},
    @{N='OS'; E={$_.StorageProfile.OSDisk.OSType}} |
    Format-Table -AutoSize

# 查看特定虚拟机详情
$vm = Get-AzVM -ResourceGroupName "rg-production" -Name "vm-web01"
$vm | Select-Object Name, Location,
    @{N='VM Size'; E={$_.HardwareProfile.VmSize}},
    @{N='OS Disk'; E={$_.StorageProfile.OSDisk.Name}},
    @{N='OS Type'; E={$_.StorageProfile.OSDisk.OSType}} |
    Format-List

# 启动虚拟机
Start-AzVM -ResourceGroupName "rg-production" -Name "vm-web01"

# 停止虚拟机（保留资源，仍计费）
Stop-AzVM -ResourceGroupName "rg-production" -Name "vm-web01" -Force

# 停止并释放资源（停止计费）
Stop-AzVM -ResourceGroupName "rg-production" -Name "vm-web01" -Force -NoWait

# 重启虚拟机
Restart-AzVM -ResourceGroupName "rg-production" -Name "vm-web01"

# 调整虚拟机大小
$vm = Get-AzVM -ResourceGroupName "rg-production" -Name "vm-web01"
$vm.HardwareProfile.VmSize = "Standard_D4s_v3"
Update-AzVM -ResourceGroupName "rg-production" -VM $vm
```

执行结果示例：

```
Name     ResourceGroupName Location   Size             OS
----     ----------------- --------   ----             --
vm-web01 rg-production     eastasia   Standard_D2s_v3  Windows
vm-db01  rg-production     eastasia   Standard_E4s_v3  Linux
vm-dev01 rg-development    eastasia   Standard_B2s     Linux

Name     : vm-web01
Location : eastasia
VM Size  : Standard_D2s_v3
OS Disk  : vm-web01-osdisk
OS Type  : Windows
```

## 批量虚拟机操作

```powershell
# 批量启动某资源组中的所有 VM
$rg = "rg-production"
$vms = Get-AzVM -ResourceGroupName $rg

foreach ($vm in $vms) {
    $status = (Get-AzVM -ResourceGroupName $rg -Name $vm.Name -Status).Statuses |
        Where-Object Code -match 'PowerState' |
        Select-Object -ExpandProperty DisplayStatus

    Write-Host "$($vm.Name): $status"

    if ($status -eq 'VM deallocated') {
        Write-Host "  启动中..." -ForegroundColor Cyan
        Start-AzVM -ResourceGroupName $rg -Name $vm.Name -NoWait
    }
}

# 按标签过滤虚拟机
Get-AzVM -Tag @{ Environment = 'Production'; Role = 'Web' } |
    Select-Object Name, ResourceGroupName |
    Format-Table -AutoSize

# 批量关闭开发环境（节省成本）
$devVMs = Get-AzVM | Where-Object {
    $_.Tags.Environment -eq 'Development'
}

foreach ($vm in $devVMs) {
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName `
        -Name $vm.Name -Force -NoWait
    Write-Host "正在停止：$($vm.Name)" -ForegroundColor Yellow
}
```

执行结果示例：

```
vm-web01: VM running
vm-db01: VM deallocated
  启动中...
vm-cache01: VM running

正在停止：vm-dev01
正在停止：vm-dev02
```

## 存储账户管理

Azure 存储是云应用的基础设施：

```powershell
# 列出存储账户
Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName,
    Location, Kind, SkuName,
    @{N='访问层'; E={$_.AccessTier}} |
    Format-Table -AutoSize

# 创建存储账户
New-AzStorageAccount -ResourceGroupName "rg-production" `
    -Name "stproddata001" `
    -Location "eastasia" `
    -SkuName "Standard_LRS" `
    -Kind "StorageV2" `
    -AccessTier "Hot"

# 获取存储账户上下文
$ctx = (Get-AzStorageAccount -ResourceGroupName "rg-production" `
    -Name "stproddata001").Context

# 列出容器
Get-AzStorageContainer -Context $ctx |
    Select-Object Name, PublicAccess |
    Format-Table -AutoSize

# 上传文件到 Blob
Set-AzStorageBlobContent -Context $ctx `
    -Container "backups" `
    -File "C:\Backups\db-20250528.bak" `
    -Blob "db-backups/db-20250528.bak" `
    -StandardBlobTier "Cool"

# 下载 Blob
Get-AzStorageBlobContent -Context $ctx `
    -Container "backups" `
    -Blob "db-backups/db-20250528.bak" `
    -Destination "C:\Downloads\"

# 列出容器中的 Blob
Get-AzStorageBlob -Context $ctx -Container "backups" |
    Select-Object Name,
        @{N='大小MB'; E={[math]::Round($_.Length/1MB, 2)}},
        LastModified,
        BlobType |
    Sort-Object LastModified -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
StorageAccountName ResourceGroupName Location Kind      SkuName       访问层
------------------ ----------------- -------- ----      -------       ------
stproddata001      rg-production     eastasia StorageV2 Standard_LRS  Hot
stdevdata001       rg-development    eastasia StorageV2 Standard_LRS  Hot

Name       PublicAccess
----       ------------
backups    Off
logs       Off
uploads    Blob

Name                          大小MB  LastModified          BlobType
----                          ------  -------------         --------
db-backups/db-20250528.bak    456.78  2025-05-28 02:00:00   BlockBlob
db-backups/db-20250527.bak    445.23  2025-05-27 02:00:00   BlockBlob
```

## 资源标签管理

标签是 Azure 资源组织和管理的关键机制：

```powershell
# 为资源添加标签
$tags = @{
    Environment = 'Production'
    Department  = 'Engineering'
    CostCenter  = 'CC-1001'
    Owner       = 'admin@contoso.com'
}

# 更新虚拟机标签
$vm = Get-AzVM -ResourceGroupName "rg-production" -Name "vm-web01"
Update-AzTag -ResourceId $vm.Id -Tag $tags -Operation Merge

Write-Host "标签已更新" -ForegroundColor Green

# 按标签查找资源
Find-AzResource -TagName "Environment" -TagValue "Production" |
    Select-Object Name, ResourceType, ResourceGroupName |
    Format-Table -AutoSize

# 批量为资源组中的所有资源添加标签
$rg = "rg-production"
$resources = Get-AzResource -ResourceGroupName $rg

foreach ($res in $resources) {
    Update-AzTag -ResourceId $res.ResourceId -Tag $tags -Operation Merge
    Write-Host "已标记：$($res.Name)" -ForegroundColor Green
}

# 生成标签报告
$allResources = Get-AzResource
$tagReport = $allResources | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.Name
        Type        = $_.ResourceType
        Environment = $_.Tags.Environment ?? 'N/A'
        Department  = $_.Tags.Department ?? 'N/A'
        CostCenter  = $_.Tags.CostCenter ?? 'N/A'
    }
}

$tagReport | Format-Table -AutoSize
```

执行结果示例：

```
标签已更新

Name        ResourceType               ResourceGroupName
----        ------------               ------------------
vm-web01    Microsoft.Compute/virtualMachines  rg-production
stproddata001  Microsoft.Storage/storageAccounts  rg-production

已标记：vm-web01
已标记：vm-db01
已标记：stproddata001

Name        Type                       Environment Department CostCenter
----        ----                       ----------- ---------- ----------
vm-web01    Microsoft.Compute/virtualMachines Production Engineering CC-1001
vm-db01     Microsoft.Compute/virtualMachines Production DBA         CC-1002
```

## 注意事项

1. **模块更新**：Az 模块每月更新，使用 `Update-Module -Name Az` 保持最新版本
2. **服务主体安全**：自动化脚本应使用服务主体而非个人账户，客户端密钥应存储在 Azure Key Vault
3. **订阅上下文**：执行操作前始终确认当前订阅上下文，避免误操作生产资源
4. **资源命名规范**：遵循 Azure 资源命名规范（如 `rg-` 前缀、`vm-` 前缀），便于管理
5. **成本控制**：使用 `Stop-AzVM` 释放资源可以停止计算计费，但存储和网络资源仍会计费
6. **幂等操作**：大部分 Az 命令是幂等的（如 `Set-AzStorageBlobContent` 重复上传会覆盖），但仍建议在脚本中检查资源状态
