---
layout: post
date: 2025-12-23 08:00:00
updated: 2025-12-23 08:00:00
title: "PowerShell 技能连载 - Azure Key Vault 密钥管理"
description: PowerTip of the Day - Azure Key Vault Secrets Management in PowerShell
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
- secrets
- security
---

_适用于 PowerShell 7.0 及以上版本_

在现代 DevOps 和云原生环境中，密钥管理是安全体系的重要基石。数据库连接字符串、API 密钥、存储账户凭据等敏感信息如果以明文形式散落在脚本、配置文件或环境变量中，一旦代码仓库泄露，攻击者就能直接获取这些凭据，进而访问生产环境的各类服务。这种安全隐患在自动化程度越高的团队中，影响面越大。

Azure Key Vault 是微软 Azure 提供的集中式密钥管理服务，支持存储机密（Secrets）、加密密钥（Keys）和证书（Certificates）。它不仅提供了硬件安全模块（HSM）保护的加密存储，还支持基于 Azure Active Directory 的细粒度访问控制、完整的访问日志审计以及自动化的密钥轮换策略。通过 PowerShell 的 Az.KeyVault 模块，我们可以将密钥的创建、读取、轮换和审计全部纳入自动化流水线。

本文将从三个实战场景出发，演示如何使用 PowerShell 完成密钥的创建与存储、在自动化脚本中安全引用密钥，以及建立密钥轮换与合规审计机制，帮助团队彻底消除脚本中的硬编码凭据。

<!-- more -->

## 创建 Key Vault 并存储密钥

第一步是创建 Key Vault 并将常用的敏感信息存储进去。以下脚本展示了完整的初始化流程，包括资源组创建、Key Vault 实例创建以及多种类型机密的写入。

```powershell
# 定义变量
$ResourceGroup = 'rg-security-demo'
$Location = 'eastasia'
$VaultName = 'kv-pstip-demo-2025'

# 连接 Azure 账户（交互式登录）
Connect-AzAccount

# 创建资源组
New-AzResourceGroup -Name $ResourceGroup -Location $Location

# 创建 Key Vault（启用软删除和清除保护）
New-AzKeyVault `
    -ResourceGroupName $ResourceGroup `
    -VaultName $VaultName `
    -Location $Location `
    -EnablePurgeProtection `
    -EnableSoftDelete

# 设置当前用户为机密管理员
$currentUser = (Get-AzContext).Account.Id
Set-AzKeyVaultAccessPolicy `
    -VaultName $VaultName `
    -UserPrincipalName $currentUser `
    -PermissionsToSecrets get,set,list,delete,recover

# 存储数据库连接字符串
$dbConnectionString = 'Server=tcp:prod-sql.database.windows.net,1433;Database=AppDb;User ID=appuser;Password=P@ssw0rd!2025;'
$secretValue = ConvertTo-SecureString $dbConnectionString -AsPlainText -Force
Set-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'DatabaseConnectionString' `
    -SecretValue $secretValue `
    -ContentType 'text/plain'

# 存储 API 密钥（带自定义元数据和过期时间）
$apiKey = 'sk-proj-abc123def456ghi789jkl012mno345pqr678'
$apiKeySecret = ConvertTo-SecureString $apiKey -AsPlainText -Force
$expiryDate = (Get-Date).AddDays(90)
Set-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'ExternalServiceApiKey' `
    -SecretValue $apiKeySecret `
    -Expires $expiryDate

# 存储存储账户凭据（使用标签标记用途）
$storageKey = 'DefaultEndpointsProtocol=https;AccountName=prodstorage;AccountKey=xyz789==;EndpointSuffix=core.windows.net'
$storageSecret = ConvertTo-SecureString $storageKey -AsPlainText -Force
$tags = @{
    Environment = 'Production'
    Service     = 'BlobStorage'
    Team        = 'DevOps'
    RotatedDate = (Get-Date).ToString('yyyy-MM-dd')
}
Set-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'StorageAccountKey' `
    -SecretValue $storageSecret `
    -Tag $tags

# 列出 Vault 中所有机密
Get-AzKeyVaultSecret -VaultName $VaultName |
    Select-Object Name, ContentType, Expires, Enabled |
    Format-Table -AutoSize
```

执行结果示例：

```
ResourceGroupName : rg-security-demo
Location          : eastasia
ProvisioningState : Succeeded

Vault Name                       : kv-pstip-demo-2025
Resource Group Name              : rg-security-demo
Location                         : eastasia
Resource ID                      : /subscriptions/xxxx/resourceGroups/rg-security-demo/providers/Microsoft.KeyVault/vaults/kv-pstip-demo-2025
Vault URI                        : https://kv-pstip-demo-2025.vault.azure.net/
Tenant ID                        : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SKU                              : Standard
Enabled For Deployment?          : False
Enabled For Template Deployment? : False
Enabled For Disk Encryption?     : False
Soft Delete Enabled?             : True
Purge Protection Enabled?        : True

Name                     ContentType Expires                Enabled
----                     ----------- -------                -------
DatabaseConnectionString text/plain                         True
ExternalServiceApiKey                2026-03-23 08:00:00    True
StorageAccountKey                    2026-12-23 08:00:00    True
```

## 在自动化脚本中安全引用密钥

密钥存入 Key Vault 后，自动化脚本不再需要硬编码任何凭据。以下示例展示了如何使用托管标识（Managed Identity）或服务主体来读取密钥，并直接应用到数据库连接、API 调用等场景中。

```powershell
# 方式一：使用服务主体进行非交互式认证（适用于 CI/CD 流水线）
$tenantId = $env:AZURE_TENANT_ID
$appId = $env:AZURE_CLIENT_ID
$appSecret = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential($appId, $appSecret)
Connect-AzAccount `
    -ServicePrincipal `
    -TenantId $tenantId `
    -Credential $credential

# 方式二：使用托管标识（适用于 Azure VM / App Service / Functions）
# Connect-AzAccount -Identity

$VaultName = 'kv-pstip-demo-2025'

# 读取数据库连接字符串
$dbSecret = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'DatabaseConnectionString'
$dbConnectionString = $dbSecret.SecretValue | ConvertFrom-SecureString -AsPlainText

# 使用密钥连接数据库（以 SqlConnection 为例）
$connection = New-Object System.Data.SqlClient.SqlConnection($dbConnectionString)
$connection.Open()
Write-Host "数据库连接成功，服务器版本：$($connection.ServerVersion)"
$connection.Close()

# 读取 API 密钥并调用外部服务
$apiSecret = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'ExternalServiceApiKey'
$apiKey = $apiSecret.SecretValue | ConvertFrom-SecureString -AsPlainText

$headers = @{
    'Authorization' = "Bearer $apiKey"
    'Content-Type'  = 'application/json'
}
$response = Invoke-RestMethod `
    -Uri 'https://api.example.com/v1/status' `
    -Headers $headers `
    -Method Get

Write-Host "API 调用成功，状态：$($response.status)"

# 封装为可复用的辅助函数
function Get-KeyVaultSecretText {
    <#
    .SYNOPSIS
    从 Key Vault 读取机密并返回明文字符串
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,

        [Parameter(Mandatory)]
        [string]$SecretName,

        [string]$Version
    )

    $params = @{
        VaultName = $VaultName
        Name      = $SecretName
    }
    if ($Version) {
        $params['Version'] = $Version
    }

    $secret = Get-AzKeyVaultSecret @params
    if (-not $secret) {
        throw "机密 '$SecretName' 在 Vault '$VaultName' 中不存在"
    }

    return $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
}

# 使用辅助函数
$storageKey = Get-KeyVaultSecretText -VaultName $VaultName -SecretName 'StorageAccountKey'
Write-Host "成功读取存储账户密钥，长度：$($storageKey.Length) 字符"
```

执行结果示例：

```
数据库连接成功，服务器版本：Microsoft SQL Server 2019 (RTM)
API 调用成功，状态：healthy
成功读取存储账户密钥，长度：142 字符
```

## 密钥轮换策略与合规审计

密钥的定期轮换是安全合规的基本要求。以下脚本演示了如何实现自动化的密钥轮换流程，并通过 Key Vault 的诊断日志功能进行访问审计，确保所有密钥操作可追溯。

```powershell
$VaultName = 'kv-pstip-demo-2025'

# --- 密钥轮换 ---

# 查找即将过期（30 天内）的机密
$warningDate = (Get-Date).AddDays(30)
$expiringSecrets = Get-AzKeyVaultSecret -VaultName $VaultName |
    Where-Object { $_.Expires -and $_.Expires -le $warningDate -and $_.Enabled }

Write-Host "发现 $($expiringSecrets.Count) 个即将过期的机密："
$expiringSecrets | Select-Object Name, Expires | Format-Table

# 轮换函数：生成新密钥值并更新到 Key Vault
function Invoke-SecretRotation {
    [CmdletBinding()]
    param(
        [string]$VaultName,
        [string]$SecretName,
        [int]$ValidityDays = 90
    )

    # 获取当前机密信息
    $current = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
    if (-not $current) {
        Write-Warning "机密 $SecretName 不存在，跳过"
        return
    }

    # 根据机密类型生成新值（示例使用随机字符串）
    $newSecretValue = -join ((48..57) + (65..90) + (97..122) |
        Get-Random -Count 48 |
        ForEach-Object { [char]$_ })

    $newSecret = ConvertTo-SecureString $newSecretValue -AsPlainText -Force

    # 更新机密（Key Vault 会自动创建新版本）
    $newExpiry = (Get-Date).AddDays($ValidityDays)
    Set-AzKeyVaultSecret `
        -VaultName $VaultName `
        -Name $SecretName `
        -SecretValue $newSecret `
        -Expires $newExpiry `
        -Tag @{
            RotatedDate = (Get-Date).ToString('yyyy-MM-dd')
            RotatedBy   = $env:USERNAME
            PreviousVersion = $current.Version
        }

    Write-Host "已轮换机密 '$SecretName'，新过期时间：$newExpiry"
}

# 对即将过期的机密执行轮换
foreach ($secret in $expiringSecrets) {
    Invoke-SecretRotation `
        -VaultName $VaultName `
        -SecretName $secret.Name `
        -ValidityDays 90
}

# --- 合规审计 ---

# 查看 Key Vault 的访问策略
$accessPolicies = (Get-AzKeyVault -VaultName $VaultName).AccessPolicies
Write-Host "`n当前访问策略（共 $($accessPolicies.Count) 条）："
$accessPolicies | ForEach-Object {
    [PSCustomObject]@{
        PrincipalId     = $_.ObjectId
        Permissions     = ($_.PermissionsToSecrets -join ', ')
        ApplicationId   = $_.ApplicationId
    }
} | Format-Table -AutoSize

# 获取机密版本历史（确认轮换记录）
$secretVersions = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'ExternalServiceApiKey' `
    -IncludeVersions |
    Select-Object Version, Created, Expires, Enabled |
    Sort-Object Created -Descending |
    Select-Object -First 5

Write-Host "`n机密 'ExternalServiceApiKey' 最近 5 个版本："
$secretVersions | Format-Table -AutoSize

# 生成合规报告
$allSecrets = Get-AzKeyVaultSecret -VaultName $VaultName
$report = $allSecrets | ForEach-Object {
    $detail = Get-AzKeyVaultSecret -VaultName $VaultName -Name $_.Name
    [PSCustomObject]@{
        Name           = $_.Name
        Enabled        = $_.Enabled
        Created        = $_.Created.ToString('yyyy-MM-dd')
        Updated        = $_.Updated.ToString('yyyy-MM-dd')
        Expires        = if ($_.Expires) { $_.Expires.ToString('yyyy-MM-dd') } else { '永不过期' }
        DaysUntilExpiry = if ($_.Expires) { ($_.Expires - (Get-Date)).Days } else { 'N/A' }
        Status         = if (-not $_.Enabled) { '已禁用' }
                          elseif ($_.Expires -and $_.Expires -le (Get-Date)) { '已过期' }
                          elseif ($_.Expires -and ($_.Expires - (Get-Date)).Days -le 30) { '即将过期' }
                          else { '正常' }
    }
}

$reportPath = "./keyvault-compliance-report-$(Get-Date -Format 'yyyyMMdd').csv"
$report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding Utf8
Write-Host "`n合规报告已导出：$reportPath"
$report | Format-Table -AutoSize
```

执行结果示例：

```
发现 2 个即将过期的机密：

Name                  Expires
----                  -------
ExternalServiceApiKey 2026-03-23 08:00:00
StorageAccountKey     2025-12-30 08:00:00

已轮换机密 'ExternalServiceApiKey'，新过期时间：2026-03-23 08:00:00
已轮换机密 'StorageAccountKey'，新过期时间：2026-03-22 08:00:00

当前访问策略（共 1 条）：

PrincipalId                         Permissions                                        ApplicationId
-----------                         ------------                                        -------------
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx get,set,list,delete,recover,purge,backup,restore

机密 'ExternalServiceApiKey' 最近 5 个版本：

Version                            Created             Expires              Enabled
-------                            -------             -------              -------
abc12345def67890                   2025-12-23 08:00:00 2026-03-23 08:00:00     True
fed09876cba54321                   2025-12-23 07:55:00 2026-03-23 08:00:00     True

合规报告已导出：./keyvault-compliance-report-20251223.csv

Name                     Enabled Created    Updated    Expires     DaysUntilExpiry Status
----                     ------- -------    -------    -------     --------------- ------
DatabaseConnectionString True    2025-12-23 2025-12-23 永不过期    N/A             正常
ExternalServiceApiKey    True    2025-12-23 2025-12-23 2026-03-23             90    正常
StorageAccountKey        True    2025-12-23 2025-12-23 2026-03-22             89    正常
```

## 注意事项

1. **使用托管标识代替服务主体**：在 Azure VM、App Service 或 Azure Functions 中运行脚本时，优先使用系统分配的托管标识（`Connect-AzAccount -Identity`），避免在环境中再存储服务主体的凭据，从根本上消除凭据泄露风险。

2. **启用软删除和清除保护**：创建 Key Vault 时务必启用 `EnableSoftDelete` 和 `EnablePurgeProtection`。软删除保留了 90 天的恢复窗口，清除保护则防止恶意删除后立即清空，两者配合可以有效防御勒索类攻击。

3. **遵循最小权限原则**：为不同的应用和服务主体分配最小必要的权限。只读工作负载只需 `Get` 和 `List` 权限，轮换脚本需要 `Set` 和 `Delete` 权限。避免为所有主体授予完全控制权限。

4. **密钥轮换后同步下游服务**：轮换密钥后，所有使用该密钥的下游应用需要及时获取新版本。建议在应用层实现自动重试逻辑，或者在轮换后触发一次服务重启或配置热加载，确保不会出现认证失败。

5. **定期审计访问日志**：通过 Key Vault 的诊断设置，将访问日志导出到 Log Analytics 工作区或存储账户。定期检查异常访问模式（如非工作时间的频繁读取、未知主体的访问尝试），及时发现潜在的安全威胁。

6. **不要将密钥输出到日志或控制台**：在调试时避免使用 `Write-Host` 输出机密明文。如果必须记录操作，只记录机密名称和操作结果，永远不要记录 `SecretValue` 的内容。CI/CD 流水线中也应屏蔽包含密钥值的变量输出。
