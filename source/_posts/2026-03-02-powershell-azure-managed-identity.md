---
layout: post
date: 2026-03-02 08:00:00
updated: 2026-03-02 08:00:00
title: "PowerShell 技能连载 - Azure 托管标识与无密码认证"
description: PowerTip of the Day - Azure Managed Identity and Passwordless Authentication in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- managed-identity
- security
- authentication
---

_适用于 PowerShell 7.0 及以上版本_

在云环境中，服务之间的认证一直是个令人头疼的问题。传统做法是创建服务主体（Service Principal），然后把客户端 ID 和密钥硬编码在配置文件或环境变量里。这些密码一旦泄露，攻击者就能以该身份访问你的 Azure 资源。更糟糕的是，密码有有效期，过期了服务就会中断，而定期轮换密码本身就是一项繁琐的运维负担。

Azure 托管标识（Managed Identity）从根本上解决了这个问题。它为 Azure 资源自动提供一个由 Azure AD（现称 Microsoft Entra ID）管理的标识，应用程序无需管理任何凭据就能获取 OAuth 2.0 令牌来访问支持 Azure AD 认证的服务。系统分配的托管标识与资源生命周期绑定，资源删除时标识自动回收；用户分配的托管标识则可以共享给多个资源使用。

本文将演示如何通过 PowerShell 完成托管标识的全生命周期管理：从启用标识、分配权限，到实际访问 Key Vault、Storage 和 SQL Database，最后展示虚拟机和容器中的令牌获取方式。让你从"到处藏密码"的窘境中彻底解脱出来。

<!-- more -->

## 托管标识配置与权限分配

配置托管标识是"无密码"运维的第一步。下面的脚本展示了如何为虚拟机启用系统分配标识和用户分配标识，并通过 RBAC 角色分配授予相应的 Azure 资源访问权限。系统分配标识与资源一一绑定，适合单一资源的场景；用户分配标识可以复用，适合多个资源需要共享同一权限集的场景。

```powershell
# 连接 Azure（交互式登录或使用设备码）
Connect-AzAccount -Subscription 'production-subscription'

$resourceGroup = 'rg-managed-identity-demo'
$location = 'eastasia'
$vmName = 'vm-demo-01'

# --- 启用系统分配标识 ---
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
Update-AzVM -ResourceGroupName $resourceGroup -VM $vm `
    -IdentityType SystemAssigned

Write-Host '系统分配标识已启用' -ForegroundColor Green

# 查看系统分配标识的主体 ID
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
$principalId = $vm.Identity.PrincipalId
Write-Host "主体 ID（PrincipalId）: $principalId"

# --- 创建并分配用户分配标识 ---
$identityName = 'id-shared-demo'
$userIdentity = New-AzUserAssignedIdentity `
    -ResourceGroupName $resourceGroup `
    -Name $identityName `
    -Location $location

Write-Host "用户分配标识已创建: $($userIdentity.Name)"

# 将用户分配标识附加到虚拟机
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
Update-AzVM -ResourceGroupName $resourceGroup -VM $vm `
    -IdentityType UserAssigned `
    -IdentityId $userIdentity.Id

# --- RBAC 角色分配 ---
# 授予系统分配标识对 Key Vault 的读取权限
$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName 'kv-demo-01'

New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName 'Key Vault Secrets User' `
    -Scope $keyVault.ResourceId

# 授予用户分配标识对存储账户的 Blob 读取权限
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name 'stademo01'

New-AzRoleAssignment `
    -ObjectId $userIdentity.PrincipalId `
    -RoleDefinitionName 'Storage Blob Data Reader' `
    -Scope $storageAccount.Id

Write-Host 'RBAC 角色分配完成' -ForegroundColor Green
```

执行结果示例：

```
系统分配标识已启用
主体 ID（PrincipalId）: a1b2c3d4-e5f6-7890-abcd-ef1234567890
用户分配标识已创建: id-shared-demo

RoleAssignmentName : ra-keyvault-secrets-user
RoleAssignmentId   : /subscriptions/.../providers/Microsoft.Authorization/roleAssignments/...
Scope              : /subscriptions/.../resourceGroups/rg-managed-identity-demo/providers/Microsoft.KeyVault/vaults/kv-demo-01
DisplayName        : vm-demo-01
RoleDefinitionName : Key Vault Secrets User

RoleAssignmentName : ra-storage-blob-reader
RoleAssignmentId   : /subscriptions/.../providers/Microsoft.Authorization/roleAssignments/...
Scope              : /subscriptions/.../resourceGroups/rg-managed-identity-demo/providers/Microsoft.Storage/storageAccounts/stademo01
DisplayName        : id-shared-demo
RoleDefinitionName : Storage Blob Data Reader

RBAC 角色分配完成
```

## 无密码访问 Azure 服务

配置好标识和权限后，最令人兴奋的时刻来了——代码中不再需要任何密码。下面的脚本演示如何使用托管标识令牌直接访问 Key Vault 读取密钥、访问 Storage Blob 下载文件，以及连接 Azure SQL 数据库。整个过程完全无凭据，令牌的获取、缓存和刷新由 Azure SDK 自动处理。

```powershell
# --- 使用系统分配标识访问 Key Vault ---
$vaultName = 'kv-demo-01'

# 通过 Az 模块获取令牌并访问 Key Vault（推荐方式）
Connect-AzAccount -Identity  # 使用托管标识登录

# 读取密钥
$secret = Get-AzKeyVaultSecret -VaultName $vaultName -Name 'DatabaseConnectionString'
$secretValue = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
Write-Host "从 Key Vault 读取到数据库连接字符串（长度: $($secretValue.Length) 字符）"

# 列出所有可访问的密钥
$secrets = Get-AzKeyVaultSecret -VaultName $vaultName |
    Select-Object Name, ContentType, Updated
$secrets | Format-Table -AutoSize

# --- 使用用户分配标识访问 Storage Blob ---
$storageAccountName = 'stademo01'
$containerName = 'reports'

# 指定用户分配标识的 ClientId 获取上下文
$identity = Get-AzUserAssignedIdentity `
    -ResourceGroupName 'rg-managed-identity-demo' `
    -Name 'id-shared-demo'

Connect-AzAccount -Identity -AccountId $identity.ClientId

# 获取存储上下文（无需存储账户密钥）
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# 列出容器中的 Blob
$blobs = Get-AzStorageBlob -Container $containerName -Context $ctx |
    Select-Object Name, Length, LastModified
$blobs | Format-Table -AutoSize

# 下载最新的报告文件
$latestBlob = Get-AzStorageBlob -Container $containerName -Context $ctx |
    Sort-Object LastModified -Descending | Select-Object -First 1

$downloadPath = Join-Path $env:TEMP $latestBlob.Name
$latestBlob | Get-AzStorageBlobContent -Destination $downloadPath -Context $ctx -Force
Write-Host "已下载: $downloadPath ($($latestBlob.Length) 字节)"

# --- 无密码连接 Azure SQL ---
$serverName = 'sql-demo-01'
$databaseName = 'appdb'

# 获取访问令牌
$token = (Get-AzAccessToken -ResourceUrl 'https://database.windows.net/').Token

# 构建无密码连接字符串
$connectionString = "Server=tcp:$serverName.database.windows.net,1433;" +
    "Database=$databaseName;" +
    "Authentication=Active Directory Default;"

# 使用令牌执行查询
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$connection.AccessToken = $token
$connection.Open()

$command = $connection.CreateCommand()
$command.CommandText = 'SELECT TOP 5 name, create_date FROM sys.tables'
$reader = $command.ExecuteReader()

while ($reader.Read()) {
    Write-Host "$($reader['name'])  $($reader['create_date'])"
}

$connection.Close()
Write-Host 'SQL 查询完成（无密码连接）' -ForegroundColor Green
```

执行结果示例：

```
从 Key Vault 读取到数据库连接字符串（长度: 156 字符）

Name                            ContentType Updated
----                            ----------- -------
DatabaseConnectionString                  2026/3/1 上午 10:30:00
StorageAccountKey                         2026/2/28 下午 3:15:00
ThirdPartyApiKey                          2026/2/25 上午 9:00:00

Name              Length LastModified
----              ------ ------------
report-202601.pdf 245678 2026/3/1 上午 8:00:00
report-202602.pdf 312456 2026/3/1 上午 8:05:00
data-export.csv    89123 2026/2/28 下午 4:30:00

已下载: /tmp/report-202602.pdf (312456 字节)

Users           2026-01-15 10:00:00
Orders          2026-01-15 10:01:00
Products        2026-01-15 10:02:00
AuditLog        2026-02-01 09:00:00
Sessions        2026-02-10 14:30:00
SQL 查询完成（无密码连接）
```

## 从虚拟机和容器中使用托管标识

在生产环境中，托管标识最常见的使用场景是从虚拟机或容器内部获取令牌。Azure 虚拟机通过 IMDS（Instance Metadata Service）端点提供本地令牌服务，而 Azure 容器实例（ACI）和 AKS Pod 也支持类似的机制。下面的脚本可以在虚拟机或容器内运行，自动获取访问令牌并执行运维操作。

```powershell
# ============================================
# 方式一：通过 IMDS 端点获取令牌（适用于 VM 内部）
# ============================================
function Get-ManagedIdentityToken {
    <#
    .SYNOPSIS
    通过 IMDS 端点获取托管标识的 OAuth 令牌
    .PARAMETER Resource
    目标资源的服务 URL，如 https://vault.azure.net
    .PARAMETER UserAssignedClientId
    用户分配标识的 ClientId（可选，不指定则使用系统分配标识）
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Resource,

        [string]$UserAssignedClientId
    )

    $imdsUrl = 'http://169.254.169.254/metadata/identity/oauth2/token'
    $params = @{
        Uri             = $imdsUrl
        Method          = 'GET'
        Headers         = @{ Metadata = 'true' }
        Body            = @{ 'api-version' = '2018-02-01'; resource = $Resource }
        UseBasicParsing = $true
    }

    # 如果指定了用户分配标识，添加 client_id 参数
    if ($UserAssignedClientId) {
        $params.Body['client_id'] = $UserAssignedClientId
    }

    try {
        $response = Invoke-RestMethod @params
        Write-Host "令牌获取成功，有效期至: $($response.expires_on)" -ForegroundColor Green
        return $response.access_token
    }
    catch {
        Write-Error "令牌获取失败: $($_.Exception.Message)"
        return $null
    }
}

# 使用系统分配标识获取 Key Vault 令牌
$kvToken = Get-ManagedIdentityToken -Resource 'https://vault.azure.net'

# 使用令牌直接调用 Key Vault REST API
$vaultName = 'kv-demo-01'
$secretName = 'DatabaseConnectionString'

$uri = "https://$vaultName.vault.azure.net/secrets/$secretName" +
    '?api-version=7.4'

$headers = @{
    Authorization = "Bearer $kvToken"
    ContentType   = 'application/json'
}

$result = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
Write-Host "通过 REST API 读取密钥成功: $($result.id)"

# ============================================
# 方式二：在容器中使用环境变量获取令牌
# ============================================
# Azure 容器实例会通过环境变量注入标识信息
function Get-ContainerManagedToken {
    param(
        [Parameter(Mandatory)]
        [string]$Resource
    )

    # 容器中通过 AZURE_ACCESS_TOKEN 环境变量或 IMDS 获取
    $msiEndpoint = $env:MSI_ENDPOINT
    $msiSecret = $env:MSI_SECRET

    if ($msiEndpoint -and $msiSecret) {
        # Azure 容器实例的标识端点
        $params = @{
            Uri             = "$msiEndpoint`?resource=$Resource&api-version=2017-09-01"
            Method          = 'GET'
            Headers         = @{ Secret = $msiSecret }
            UseBasicParsing = $true
        }
        $response = Invoke-RestMethod @params
        return $response.access_token
    }

    # 回退到 IMDS（AKS Pod 或标准虚拟机）
    return Get-ManagedIdentityToken -Resource $Resource
}

# ============================================
# 自动化运维示例：定时备份 Key Vault 中的密钥
# ============================================
function Backup-KeyVaultSecrets {
    param(
        [string]$VaultName,
        [string]$BackupPath = '/tmp/kv-backup'
    )

    $token = Get-ManagedIdentityToken -Resource 'https://vault.azure.net'

    # 创建备份目录
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

    # 获取所有密钥列表
    $listUri = "https://$VaultName.vault.azure.net/secrets" +
        '?api-version=7.4'
    $headers = @{ Authorization = "Bearer $token" }

    $secrets = (Invoke-RestMethod -Uri $listUri -Headers $headers).value

    $backupSummary = foreach ($secret in $secrets) {
        $secretName = $secret.id.Split('/')[-1]
        $detail = Invoke-RestMethod -Uri $secret.id`?api-version=7.4 `
            -Headers $headers

        # 脱敏后保存元数据
        $backup = [PSCustomObject]@{
            Name         = $secretName
            ContentType  = $detail.contentType
            BackupTime   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Enabled      = $detail.attributes.enabled
            Expires      = $detail.attributes.exp
        }

        $backup | ConvertTo-Json | Out-File "$BackupPath/$secretName.json"
        $backup
    }

    $backupSummary | Format-Table -AutoSize
    Write-Host "备份完成，共 $($backupSummary.Count) 个密钥" -ForegroundColor Green
}

# 执行备份
Backup-KeyVaultSecrets -VaultName 'kv-demo-01'
```

执行结果示例：

```
令牌获取成功，有效期至: 1740916800
通过 REST API 读取密钥成功: https://kv-demo-01.vault.azure.net/secrets/DatabaseConnectionString/abc123def456

Name                        ContentType  BackupTime           Enabled Expires
----                        -----------  ----------           ------- -------
DatabaseConnectionString                 2026-03-02 08:30:00    True
StorageAccountKey                        2026-03-02 08:30:00    True
ThirdPartyApiKey              text/plain 2026-03-02 08:30:00    True 1743571200
CertificateThumbprint                    2026-03-02 08:30:00    True

备份完成，共 4 个密钥
```

## 注意事项

1. **RBAC 传播延迟**：新创建的角色分配可能需要 5 到 10 分钟才能生效。如果脚本执行后立即访问资源时报权限不足的错误，请等待一段时间后重试，也可以在脚本中加入轮询等待逻辑。

2. **系统标识 vs 用户标识的选择**：系统分配标识与资源生命周期绑定，资源删除时标识自动清除，适合一对一场景。用户分配标识独立于资源存在，适合多个资源需要共享权限的场景，但需要手动管理生命周期。

3. **IMDS 端点仅限虚拟机内部**：IMDS 端点 `169.254.169.254` 是链路本地地址，只能在 Azure 虚拟机内部访问。不要在本地开发环境或非 Azure 环境中尝试调用这个端点，开发调试时请使用 `Connect-AzAccount -Identity` 配合 Azure Cloud Shell。

4. **令牌缓存与刷新**：Azure SDK 和 Az 模块会自动缓存令牌并在过期前刷新。如果你直接调用 REST API 获取令牌，需要自行处理令牌的缓存和刷新逻辑，令牌通常有效期为 1 小时。

5. **最小权限原则**：为托管标识分配 RBAC 角色时，务必遵循最小权限原则，只授予实际需要的角色。避免使用 Owner 或 Contributor 等高权限角色，优先选择如 Key Vault Secrets User、Storage Blob Data Reader 等精确的内置角色。

6. **本地开发调试技巧**：在本地开发时可以使用 `Connect-AzAccount` 交互式登录，然后通过 `-DefaultProfile` 参数切换不同的认证上下文，模拟托管标识的行为。部署到 Azure 后，将认证方式切换为 `Connect-AzAccount -Identity` 即可无缝迁移到托管标识，代码逻辑无需大幅修改。
