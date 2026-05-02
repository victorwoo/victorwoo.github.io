---
layout: post
date: 2025-10-23 08:00:00
updated: 2025-10-23 08:00:00
title: "PowerShell 技能连载 - Azure Key Vault 密钥管理"
description: PowerTip of the Day - Azure Key Vault Secret Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- keyvault
- secret-management
- security
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 背景引入

在现代云原生应用的运维与开发中，密钥管理是安全体系中不可或缺的一环。数据库连接字符串、API 密钥、证书私钥等敏感信息如果以明文形式存储在代码仓库或配置文件中，一旦泄露就会造成严重的安全事故。Azure Key Vault 正是微软 Azure 平台提供的集中式密钥管理服务，它可以安全地存储和管理密钥（Key）、机密（Secret）及证书（Certificate）。

对于 PowerShell 用户而言，通过 `Az.KeyVault` 模块可以方便地完成 Key Vault 的创建、密钥的读写、访问策略的配置等操作。无论是日常运维脚本中拉取数据库密码，还是在 CI/CD 流水线中注入签名证书，PowerShell 都提供了简洁高效的 cmdlet 来实现这些需求。

本文将围绕实际场景，演示如何使用 PowerShell 完成 Azure Key Vault 的创建、Secret 的增删改查、批量操作以及访问权限控制。

## 前置准备

在开始操作 Key Vault 之前，需要确保已安装 Azure PowerShell 模块并完成登录认证。

```powershell
# 安装 Az 模块（如果尚未安装）
Install-Module -Name Az -Repository PSGallery -Scope CurrentUser -Force

# 登录 Azure 账户（会弹出浏览器窗口进行交互式认证）
Connect-AzAccount

# 查看当前订阅信息，确认上下文正确
Get-AzContext | Select-Object Account, Subscription, Tenant
```

登录成功后，终端会显示当前账户的订阅和租户信息，确认是你期望操作的 Azure 订阅即可继续。

```text
Account        SubscriptionName   TenantId
-------        ----------------   --------
user@demo.com  MySubscription     xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 创建 Key Vault

Azure Key Vault 需要一个全局唯一的名称，并且必须指定资源组和所在区域。下面通过 PowerShell 一键完成创建。

```powershell
# 定义变量
$resourceGroupName = "rg-keyvault-demo"
$location = "EastAsia"
$vaultName = "kv-demo-$(Get-Random -Minimum 1000 -Maximum 9999)"

# 创建资源组（如果不存在）
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# 创建 Key Vault
# 启用软删除（Soft Delete）和清除保护（Purge Protection）以增强安全性
$newVaultSplat = @{
    VaultName       = $vaultName
    ResourceGroupName = $resourceGroupName
    Location        = $location
    EnableSoftDelete        = $true
    EnablePurgeProtection   = $true
    Sku = "Standard"
}
$vault = New-AzKeyVault @newVaultSplat

Write-Host "Key Vault 创建成功: $($vault.VaultName)"
Write-Host "Vault URI: $($vault.VaultUri)"
```

这段脚本首先创建了一个资源组作为容器，然后在其中创建 Key Vault。`EnableSoftDelete` 参数确保删除的密钥可以在保留期内恢复，`EnablePurgeProtection` 则防止密钥被立即永久清除。

```text
Key Vault 创建成功: kv-demo-7421
Vault URI: https://kv-demo-7421.vault.azure.net/
```

## 管理机密（Secret）

Key Vault 最常见的用途就是存储和管理机密信息。下面演示如何创建、读取、更新和删除 Secret。

```powershell
# 创建一个数据库连接字符串作为 Secret
$secretValue = ConvertTo-SecureString -String "Server=myserver.database.windows.net;Database=mydb;User=admin;Password=P@ssw0rd!" -AsPlainText -Force

$setSecretSplat = @{
    VaultName   = $vaultName
    Name        = "DatabaseConnectionString"
    SecretValue = $secretValue
    ContentType = "text/plain"
    Tag         = @{ Environment = "Production"; Owner = "DBA-Team" }
}
$secret = Set-AzKeyVaultSecret @setSecretSplat

Write-Host "Secret 创建成功"
Write-Host "名称: $($secret.Name)"
Write-Host "版本: $($secret.Version)"
Write-Host "过期时间: $($secret.Expires)"

# 读取 Secret 的值
$retrievedSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "DatabaseConnectionString"
$plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($retrievedSecret.SecretValue)
)
Write-Host "读取到的连接字符串: $plainText"
```

注意，Key Vault 返回的 Secret 值始终是 `SecureString` 类型。如果你需要在脚本中获取明文值（例如传递给数据库驱动），需要通过 `Marshal` 类进行转换。在实际生产环境中，应尽量避免将明文输出到控制台。

```text
Secret 创建成功
名称: DatabaseConnectionString
版本: 1a2b3c4d5e6f7890abcdef1234567890
过期时间:

读取到的连接字符串: Server=myserver.database.windows.net;Database=mydb;User=admin;Password=P@ssw0rd!
```

## 批量管理 Secret

在真实项目中，我们往往需要一次性管理多个配置项。例如将应用的所有环境变量从本地配置文件批量导入到 Key Vault 中。下面演示一个批量写入和批量读取的完整流程。

```powershell
# 定义多个配置项（模拟从配置文件读取）
$configItems = @(
    @{ Name = "App-Api-Key"; Value = "sk-api-20251023-abcdefg123456" }
    @{ Name = "App-Jwt-Secret"; Value = "my-super-secret-jwt-key-2025" }
    @{ Name = "App-Redis-Connection"; Value = "redis://cache.redis.cache.windows.net:6380,password=xxx" }
    @{ Name = "App-Storage-Key"; Value = "storageAccountAccessKeyXYZ789" }
    @{ Name = "App-SendGrid-Key"; Value = "SG.sendgridapikey123456" }
)

# 批量写入 Key Vault
foreach ($item in $configItems) {
    $secureValue = ConvertTo-SecureString -String $item.Value -AsPlainText -Force

    $setSplat = @{
        VaultName   = $vaultName
        Name        = $item.Name
        SecretValue = $secureValue
    }
    Set-AzKeyVaultSecret @setSplat | Out-Null
    Write-Host "已写入 Secret: $($item.Name)"
}

Write-Host "`n批量写入完成，共 $($configItems.Count) 个 Secret"

# 批量读取并汇总
Write-Host "`n--- 当前 Key Vault 中的所有 Secret ---"
$allSecrets = Get-AzKeyVaultSecret -VaultName $vaultName

foreach ($s in $allSecrets) {
    $detail = Get-AzKeyVaultSecret -VaultName $vaultName -Name $s.Name
    $tagsStr = ""
    if ($detail.Tags) {
        $tagParts = @()
        foreach ($key in $detail.Tags.Keys) {
            $tagParts += "$key=$($detail.Tags[$key])"
        }
        $tagsStr = $tagParts -join ", "
    }
    Write-Host ("{0,-30} 创建于: {1}" -f $s.Name, $detail.Created.ToString("yyyy-MM-dd HH:mm"))
}
```

这段代码首先定义了一个配置数组，然后通过 `foreach` 循环逐个写入 Key Vault。读取时先获取所有 Secret 的列表，再逐个获取详细信息。这种方式适合在应用部署流水线中做配置初始化。

```text
已写入 Secret: App-Api-Key
已写入 Secret: App-Jwt-Secret
已写入 Secret: App-Redis-Connection
已写入 Secret: App-Storage-Key
已写入 Secret: App-SendGrid-Key

批量写入完成，共 5 个 Secret

--- 当前 Key Vault 中的所有 Secret ---
DatabaseConnectionString        创建于: 2025-10-23 08:15
App-Api-Key                     创建于: 2025-10-23 08:16
App-Jwt-Secret                  创建于: 2025-10-23 08:16
App-Redis-Connection            创建于: 2025-10-23 08:16
App-Storage-Key                 创建于: 2025-10-23 08:16
App-SendGrid-Key                创建于: 2025-10-23 08:16
```

## 配置访问策略

Key Vault 默认采用访问策略（Access Policy）模型来控制谁可以执行什么操作。创建者自动拥有全部权限，但对于团队协作场景，需要精确地为不同角色分配最小权限。

```powershell
# 获取当前用户或服务主体的对象 ID
$currentUser = Get-AzADUser -SignedIn

# 为当前用户设置只读权限（Get 和 List）
$readOnlySplat = @{
    VaultName           = $vaultName
    UserPrincipalName   = $currentUser.UserPrincipalName
    PermissionsToSecrets = "Get", "List"
}
Set-AzKeyVaultAccessPolicy @readOnlySplat

Write-Host "已为用户 $($currentUser.UserPrincipalName) 设置只读权限"

# 为另一个团队成员设置完整 Secret 权限
$devOpsUpn = "devops@demo.com"
$devOpsSplat = @{
    VaultName           = $vaultName
    UserPrincipalName   = $devOpsUpn
    PermissionsToSecrets = "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
}
Set-AzKeyVaultAccessPolicy @devOpsSplat

Write-Host "已为用户 $devOpsUpn 设置完整 Secret 管理权限"

# 查看当前所有访问策略
$vault = Get-AzKeyVault -VaultName $vaultName
Write-Host "`n--- 当前访问策略 ---"
foreach ($policy in $vault.AccessPolicies) {
    $secrets = $policy.PermissionsToSecrets -join ", "
    Write-Host ("对象ID: {0} | Secret权限: {1}" -f $policy.ObjectId, $secrets)
}
```

在实际项目中，建议遵循最小权限原则：运维人员只授予 `Get` 和 `List` 权限，密钥管理员才授予 `Set`、`Delete` 等写入权限。对于应用程序，可以使用托管标识（Managed Identity）代替服务主体，避免在代码中硬编码凭据。

```text
已为用户 user@demo.com 设置只读权限
已为用户 devops@demo.com 设置完整 Secret 管理权限

--- 当前访问策略 ---
对象ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Secret权限: Get, List, Set, Delete, Recover, Backup, Restore, Purge
对象ID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy | Secret权限: Get, List
对象ID: zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz | Secret权限: Get, List, Set, Delete, Recover, Backup, Restore, Purge
```

## 设置 Secret 过期与版本管理

Key Vault 支持 Secret 的自动过期和版本管理。当密钥需要定期轮换时（例如每 90 天更换一次 API 密钥），可以通过设置过期时间来实现自动提醒。

```powershell
# 为已有的 Secret 设置过期时间
$expireDate = (Get-Date).AddDays(90)

$secretValue = ConvertTo-SecureString -String "sk-new-api-key-$(Get-Random -Minimum 100000 -Maximum 999999)" -AsPlainText -Force

$setExpiringSplat = @{
    VaultName   = $vaultName
    Name        = "App-Api-Key"
    SecretValue = $secretValue
    Expires     = $expireDate
    ContentType = "text/plain"
    Tag         = @{ RotatedBy = "PowerShell-Script"; RotationCycle = "90-days" }
}
$newVersion = Set-AzKeyVaultSecret @setExpiringSplat

Write-Host "Secret 已更新，新版本过期时间: $($newVersion.Expires.ToString('yyyy-MM-dd HH:mm'))"

# 查看某个 Secret 的所有历史版本
$allVersions = Get-AzKeyVaultSecret -VaultName $vaultName -Name "App-Api-Key" -IncludeVersions

Write-Host "`n--- App-Api-Key 版本历史 ---"
foreach ($ver in $allVersions) {
    $status = if ($ver.Expires -and $ver.Expires -lt (Get-Date)) { "已过期" } else { "有效" }
    Write-Host ("版本: {0} | 状态: {1} | 创建: {2}" -f $ver.Version.Substring(0, 8), $status, $ver.Created.ToString("yyyy-MM-dd HH:mm"))
}
```

每次对同一个 Secret 名称调用 `Set-AzKeyVaultSecret`，都会生成一个新版本。旧版本不会被自动删除，你可以随时回滚到之前的版本。这在密钥轮换出现问题时非常有用。

```text
Secret 已更新，新版本过期时间: 2026-01-21 08:30

--- App-Api-Key 版本历史 ---
版本: 1a2b3c4d | 状态: 有效 | 创建: 2025-10-23 08:16
版本: 5e6f7g8h | 状态: 有效 | 创建: 2025-10-23 08:30
```

## 注意事项

1. **启用软删除和清除保护**：创建 Key Vault 时务必启用 `SoftDelete` 和 `PurgeProtection`。软删除允许在保留期内（默认 90 天）恢复误删的 Secret，清除保护则防止恶意永久删除。这两项是生产环境的最低安全要求。

2. **避免在日志中泄露明文**：Key Vault 返回的 Secret 值是 `SecureString` 类型，在脚本中读取后切勿通过 `Write-Host` 或日志输出明文。如果确实需要调试，可以在开发环境使用 `Marshal` 转换，但在生产脚本中应删除此类代码。

3. **使用托管标识代替硬编码凭据**：在 Azure VM、App Service 或 AKS 上运行的应用，应使用系统分配或用户分配的托管标识（Managed Identity）访问 Key Vault，避免在代码或环境变量中存储服务主体密码。

4. **遵循最小权限原则**：为每个用户和服务主体仅授予其所需的最小权限集合。只读应用只需 `Get` 和 `List`，只有密钥管理员才需要 `Set` 和 `Delete` 权限。定期审计访问策略，移除不再需要的权限。

5. **定期轮换密钥**：为所有 Secret 设置合理的过期时间（如 30 天到 90 天），并建立自动轮换流程。Key Vault 支持通过 Event Grid 事件触发 Azure Function 来实现密钥的自动轮换，减少人工介入。

6. **网络隔离与防火墙**：对于高安全要求的场景，可以配置 Key Vault 的网络防火墙规则，仅允许特定虚拟网络的流量访问。结合 Private Endpoint 可以确保密钥数据不会经过公共互联网。
