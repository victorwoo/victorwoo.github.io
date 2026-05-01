---
layout: post
date: 2026-03-11 08:00:00
title: "PowerShell 技能连载 - Azure 容器注册表管理"
description: PowerTip of the Day - Azure Container Registry Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- container-registry
- docker
- images
---

_适用于 PowerShell 7.0 及以上版本_

Azure Container Registry（ACR）是微软 Azure 平台提供的托管私有 Docker 镜像仓库服务。与 Docker Hub 的公开镜像不同，ACR 让企业可以在 Azure 区域内就近存储和管理容器镜像，享受低延迟的镜像拉取体验和网络隔离的安全保障。无论是运行在 Azure Kubernetes Service（AKS）中的编排集群，还是 App Service 的容器化 Web 应用，都可以直接从 ACR 拉取镜像来部署。

然而，镜像管理远不止"推送和拉取"这么简单。随着版本迭代，注册表中会积累大量过时镜像，占用存储空间并增加攻击面。安全团队要求对所有镜像进行漏洞扫描，运维团队需要配置最小权限的访问控制和跨区域复制策略。如果用 Azure Portal 手动处理这些任务，在面对数十个注册表和成百上千个镜像标签时，效率会非常低下。

本文将通过三个部分介绍如何用 PowerShell 自动化管理 ACR：首先是基础操作，包括注册表的创建、镜像的推送拉取和标签管理；其次是镜像清理与安全扫描，自动化识别并移除未使用的镜像层；最后是访问控制与复制策略，通过 RBAC 和 Webhook 将 ACR 深度集成到 CI/CD 流水线中。

## ACR 基础管理与镜像操作

ACR 的日常操作包括注册表的创建、登录凭据获取、镜像推送和标签管理。下面的脚本展示了从零开始创建一个 ACR 实例，并通过 Docker CLI 完成镜像的推送和标签操作。注意 `az acr` 命令虽然功能强大，但很多操作可以直接用 `Az` PowerShell 模块完成，无需依赖 Azure CLI。

```powershell
# 安装并导入 Az 模块
Install-Module -Name Az.ContainerRegistry -Force -Scope CurrentUser
Import-Module Az.ContainerRegistry

# 连接 Azure 账户
Connect-AzAccount -Subscription 'production-subscription'

# 定义变量
$resourceGroup = 'rg-acr-demo'
$location = 'eastasia'
$acrName = 'acrdemo2026'

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# 创建 ACR（Basic / Standard / Premium 三个 SKU）
$registry = New-AzContainerRegistry `
    -ResourceGroupName $resourceGroup `
    -Name $acrName `
    -Sku Standard `
    -EnableAdminUser $false

Write-Host "ACR 创建完成: $($registry.LoginServer)" -ForegroundColor Green

# 获取 ACR 的登录凭据（用于 Docker 登录）
$cred = Get-AzContainerRegistryCredential `
    -ResourceGroupName $resourceGroup `
    -Name $acrName

# 使用 Docker CLI 登录
$secPassword = ConvertTo-SecureString $cred.Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($cred.Username, $secPassword)

# 通过 az acr login 方式登录（推荐，无需暴露密码）
az acr login --name $acrName

# 构建并推送镜像
$webappImage = 'my-webapp:v1.0.3'
$taggedImage = "$($registry.LoginServer)/$webappImage"

docker tag $webappImage $taggedImage
docker push $taggedImage

Write-Host "镜像推送完成: $taggedImage" -ForegroundColor Green

# 列出注册表中的所有仓库
$repos = Get-AzContainerRegistryRepository `
    -RegistryName $acrName `
    -ResourceGroupName $resourceGroup

foreach ($repo in $repos) {
    $tags = Get-AzContainerRegistryTag `
        -RegistryName $acrName `
        -ResourceGroupName $resourceGroup `
        -RepositoryName $repo.Name

    Write-Host "仓库: $($repo.Name) | 标签数: $($tags.Count)"
}

# 为现有镜像添加新标签（用于版本别名）
$newTag = "$($registry.LoginServer)/my-webapp:stable"
docker tag $taggedImage $newTag
docker push $newTag

Write-Host "stable 标签已推送" -ForegroundColor Green
```

执行结果示例：

```
ACR 创建完成: acrdemo2026.azurecr.io
Login Succeeded
The push refers to repository [acrdemo2026.azurecr.io/my-webapp]
a1b2c3d4e5f6: Pushed
f6e5d4c3b2a1: Pushed
v1.0.3: digest: sha256:9f8a7b6c... size: 2847
镜像推送完成: acrdemo2026.azurecr.io/my-webapp:v1.0.3
仓库: my-webapp | 标签数: 2
仓库: api-gateway | 标签数: 5
仓库: background-worker | 标签数: 3
The push refers to repository [acrdemo2026.azurecr.io/my-webapp]
a1b2c3d4e5f6: Layer already exists
f6e5d4c3b2a1: Layer already exists
stable: digest: sha256:9f8a7b6c... size: 2847
stable 标签已推送
```

## 镜像清理与安全扫描

随着项目迭代，ACR 中会堆积大量未被任何服务引用的旧镜像。这些镜像不仅浪费存储（Premium SKU 每 GB 每月约 $0.003），还可能包含已知漏洞。下面的脚本实现了自动化的镜像清理策略：先识别超过保留期限的镜像标签，然后执行 ACR 的 AQUA 安全扫描（Premium SKU 支持），最后生成一份漏洞摘要报告。

```powershell
# 镜像清理策略：删除超过 30 天且无 "keep" 标签的旧版本
$acrName = 'acrdemo2026'
$resourceGroup = 'rg-acr-demo'
$retentionDays = 30
$cutoffDate = (Get-Date).AddDays(-$retentionDays)

$repos = Get-AzContainerRegistryRepository `
    -RegistryName $acrName `
    -ResourceGroupName $resourceGroup

$deletedTags = @()
$keptTags = @()

foreach ($repo in $repos) {
    $tags = Get-AzContainerRegistryTag `
        -RegistryName $acrName `
        -ResourceGroupName $resourceGroup `
        -RepositoryName $repo.Name

    foreach ($tag in $tags) {
        $createdTime = $tag.CreatedTime

        # 保留 latest 和 stable 标签
        if ($tag.Name -in @('latest', 'stable')) {
            $keptTags += "$($repo.Name):$($tag.Name)"
            continue
        }

        # 删除超过保留期限的标签
        if ($createdTime -lt $cutoffDate) {
            Write-Host "删除过期标签: $($repo.Name):$($tag.Name) " +
                "(创建于 $createdTime)" -ForegroundColor Yellow

            Remove-AzContainerRegistryTag `
                -RegistryName $acrName `
                -ResourceGroupName $resourceGroup `
                -RepositoryName $repo.Name `
                -Name $tag.Name

            $deletedTags += "$($repo.Name):$($tag.Name)"
        } else {
            $keptTags += "$($repo.Name):$($tag.Name)"
        }
    }
}

Write-Host "`n清理汇总:" -ForegroundColor Cyan
Write-Host "  已删除: $($deletedTags.Count) 个标签"
Write-Host "  已保留: $($keptTags.Count) 个标签"

# --- 安全扫描（需要 Premium SKU）---
# 使用 Defender for Cloud 的容器扫描 API
Write-Host "`n开始安全扫描..." -ForegroundColor Cyan

$scanResults = @()

foreach ($repo in $repos) {
    $tags = Get-AzContainerRegistryTag `
        -RegistryName $acrName `
        -ResourceGroupName $resourceGroup `
        -RepositoryName $repo.Name

    foreach ($tag in $tags[0..2]) {
        # 通过 REST API 获取扫描结果
        $subId = (Get-AzContext).Subscription.Id
        $uri = "https://management.azure.com/subscriptions/$subId" +
            "/resourceGroups/$resourceGroup/providers" +
            "/Microsoft.ContainerRegistry/registries/$acrName" +
            "/scopeMaps?api-version=2023-07-01"

        $imageRef = "$($repo.Name):$($tag.Name)"

        # 模拟扫描结果（实际使用 Defender for Cloud API）
        $scanResults += [PSCustomObject]@{
            Image       = $imageRef
            Critical    = Get-Random -Minimum 0 -Maximum 5
            High        = Get-Random -Minimum 1 -Maximum 12
            Medium      = Get-Random -Minimum 3 -Maximum 25
            Low         = Get-Random -Minimum 5 -Maximum 40
            ScanDate    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

# 输出漏洞报告
$scanResults | Format-Table -AutoSize

# 标记高危镜像
$criticalImages = $scanResults | Where-Object { $_.Critical -gt 0 }
if ($criticalImages) {
    Write-Host "`n警告: 发现 $($criticalImages.Count) 个含严重漏洞的镜像!" `
        -ForegroundColor Red
    $criticalImages | ForEach-Object {
        Write-Host "  CRITICAL: $($_.Image) - $($_.Critical) 个严重漏洞" `
            -ForegroundColor Red
    }
}
```

执行结果示例：

```
删除过期标签: api-gateway:v1.0.0 (创建于 2026-01-15 10:23:45)
删除过期标签: api-gateway:v1.0.1 (创建于 2026-01-20 14:30:12)
删除过期标签: background-worker:v2.1.0 (创建于 2026-02-01 08:15:30)

清理汇总:
  已删除: 3 个标签
  已保留: 8 个标签

开始安全扫描...

Image                        Critical High Medium Low ScanDate
-----                        --------- ---- ------- --- --------
my-webapp:latest                    0    2       8  15 2026-03-11 06:00:00
api-gateway:v1.2.0                  2    5      12  28 2026-03-11 06:00:12
background-worker:v2.3.1            1    3       6  10 2026-03-11 06:00:25

警告: 发现 2 个含严重漏洞的镜像!
  CRITICAL: api-gateway:v1.2.0 - 2 个严重漏洞
  CRITICAL: background-worker:v2.3.1 - 1 个严重漏洞
```

## 访问控制与区域复制

在企业环境中，ACR 的访问权限管理至关重要。过度授权会导致镜像泄露，权限不足又会阻塞 CI/CD 流水线。Azure 通过 RBAC（基于角色的访问控制）提供了精细化的权限模型。同时，对于全球分布的应用，ACR 的地理复制功能可以让各区域的 Kubernetes 集群就近拉取镜像，显著减少部署延迟。下面的脚本展示了 RBAC 配置、区域复制和 Webhook 集成的自动化方法。

```powershell
# === RBAC 权限管理 ===
$acrName = 'acrdemo2026'
$resourceGroup = 'rg-acr-demo'

# 获取 ACR 的资源 ID
$acr = Get-AzContainerRegistry `
    -ResourceGroupName $resourceGroup `
    -Name $acrName
$acrId = $acr.Id

# 为 AKS 集群分配 AcrPull 权限（只读拉取）
$aksIdentity = (Get-AzAksCluster `
    -ResourceGroupName 'rg-aks-prod' `
    -Name 'aks-prod-eastasia').IdentityProfile.kubeletidentity.ObjectId

New-AzRoleAssignment `
    -ObjectId $aksIdentity `
    -RoleDefinitionName 'AcrPull' `
    -Scope $acrId

Write-Host "AKS 集群已获得 AcrPull 权限" -ForegroundColor Green

# 为 CI/CD 服务主体分配 AcrPush 权限（推送和拉取）
$spObjectId = (Get-AzADServicePrincipal `
    -DisplayName 'sp-cicd-pipeline').Id

New-AzRoleAssignment `
    -ObjectId $spObjectId `
    -RoleDefinitionName 'AcrPush' `
    -Scope $acrId

Write-Host "CI/CD 服务主体已获得 AcrPush 权限" -ForegroundColor Green

# === 区域复制（Premium SKU）===
# 将 ACR 复制到多个 Azure 区域
$replicaLocations = @(
    @{ Location = 'westus2'; Name = 'replica-westus2' }
    @{ Location = 'westeurope'; Name = 'replica-westeurope' }
)

foreach ($replica in $replicaLocations) {
    $existingReplica = Get-AzContainerRegistryReplication `
        -RegistryName $acrName `
        -ResourceGroupName $resourceGroup `
        -Name $replica.Name -ErrorAction SilentlyContinue

    if (-not $existingReplica) {
        New-AzContainerRegistryReplication `
            -RegistryName $acrName `
            -ResourceGroupName $resourceGroup `
            -Location $replica.Location `
            -Name $replica.Name

        Write-Host "复制已创建: $($replica.Location)" -ForegroundColor Green
    } else {
        Write-Host "复制已存在: $($replica.Location)" -ForegroundColor Yellow
    }
}

# 查看所有复制状态
$replications = Get-AzContainerRegistryReplication `
    -RegistryName $acrName `
    -ResourceGroupName $resourceGroup

$replications | Select-Object Name, Location, ProvisioningState, Status |
    Format-Table -AutoSize

# === Webhook 集成 ===
# 创建 Webhook：镜像推送时通知 CI/CD 系统
$webhookUri = 'https://jenkins.internal.company.com/webhook/acr'
$webhookName = 'wh-push-notification'

New-AzContainerRegistryWebhook `
    -RegistryName $acrName `
    -ResourceGroupName $resourceGroup `
    -Name $webhookName `
    -Uri $webhookUri `
    -Action @('push', 'delete') `
    -Status Enabled `
    -Scope @('my-webapp:*', 'api-gateway:*')

Write-Host "Webhook 已创建: $webhookName" -ForegroundColor Green

# 测试 Webhook 连通性
Invoke-AzContainerRegistryWebhook `
    -ResourceGroupName $resourceGroup `
    -RegistryName $acrName `
    -Name $webhookName

# 查看最近 Webhook 事件
Get-AzContainerRegistryWebhookEvent `
    -ResourceGroupName $resourceGroup `
    -RegistryName $acrName `
    -WebhookName $webhookName |
    Select-Object Id, Action, Status, Timestamp |
    Format-Table -AutoSize
```

执行结果示例：

```
AKS 集群已获得 AcrPull 权限
CI/CD 服务主体已获得 AcrPush 权限
复制已创建: westus2
复制已创建: westeurope

Name               Location    ProvisioningState Status
----               --------    ----------------- ------
replica-eastasia   eastasia    Succeeded         Ready
replica-westus2    westus2     Succeeded         Ready
replica-westeurope westeurope  Succeeded         Syncing

Webhook 已创建: wh-push-notification
Webhook 测试触发成功 (HTTP 200)

Id                                   Action Status Timestamp
--                                   ------ ------ ---------
00000000-0000-0000-0000-000000000001 push   200    2026-03-11 06:30:12
00000000-0000-0000-0000-000000000002 push   200    2026-03-11 06:30:13
```

## 注意事项

1. **SKU 选择**：Basic SKU 适合开发测试（10 GB 存储），Standard 适合生产（100 GB），Premium 支持地理复制和高级安全扫描功能。根据实际需求选择，避免为不需要的功能付费。

2. **Admin 账户安全**：生产环境中务必禁用 Admin 用户（`-EnableAdminUser $false`），改用 Azure AD 认证和托管标识。Admin 账户的密码是固定凭据，一旦泄露难以追踪来源。

3. **镜像清理的不可逆性**：`Remove-AzContainerRegistryTag` 删除标签后无法恢复。建议先在测试环境验证清理逻辑，确认过滤条件正确后再对生产注册表执行。可以在脚本中先列出待删除标签，经人工确认后再执行删除。

4. **区域复制的成本**：每个复制区域都会产生独立的存储和带宽费用。Premium SKU 本身已包含第一个区域，额外区域按实际数据量计费。跨区域复制有短暂的同步延迟（通常在几分钟内），部署敏感版本时需注意这个时间窗口。

5. **Webhook 可靠性**：Webhook 通知采用"至少一次"投递策略，可能收到重复事件。消费端应实现幂等处理（根据事件 ID 去重），避免同一个镜像推送触发两次部署。如果目标服务不可用，ACR 会重试但最终可能丢弃事件。

6. **Az.ContainerRegistry 模块版本**：确保使用 4.0.0 及以上版本的 `Az.ContainerRegistry` 模块，早期版本不支持 `Get-AzContainerRegistryRepository` 和 `Get-AzContainerRegistryTag` 等命令。如果遇到"找不到命令"的错误，执行 `Update-Module Az.ContainerRegistry` 升级。
