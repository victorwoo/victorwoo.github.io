---
layout: post
date: 2026-03-20 08:00:00
updated: 2026-03-20 08:00:00
title: "PowerShell 技能连载 - Bicep 基础设施即代码"
description: PowerTip of the Day - Bicep Infrastructure as Code in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- bicep
- iac
- azure
- infrastructure
---

_适用于 PowerShell 7.0 及以上版本_

在现代云原生开发中，基础设施即代码（Infrastructure as Code，IaC）已经成为团队协作和持续交付的基石。传统 ARM Template 虽然功能强大，但 JSON 语法的冗长和嵌套层级让维护成本居高不下。微软推出的 Bicep 语言正是为了解决这个痛点而诞生的——它是一种透明抽象（transparent abstraction），编译后生成标准 ARM Template，同时提供了更简洁的声明式语法、类型安全和模块化支持。

Bicep 的核心优势在于：语法简洁（去掉了 JSON 的大量样板代码）、编译期类型检查（在部署前就能发现错误）、模块化设计（支持将复杂部署拆分为可复用的模块），以及与 Azure 生态的深度集成。配合 PowerShell 的 `Az` 模块，我们可以构建从开发到生产的完整部署流水线，实现环境一致性管理和自动化运维。

本文将从 Bicep 模板编写、PowerShell 部署脚本以及模块化与重用三个层面，介绍如何通过 PowerShell + Bicep 构建 Azure 基础设施的自动化部署方案。

<!-- more -->

## Bicep 模板编写

Bicep 模板以 `.bicep` 为扩展名，采用声明式语法定义 Azure 资源。以下是一个完整的 Bicep 模板，包含参数定义、变量计算、资源声明和输出值。

```powershell
# 安装 Bicep CLI（如果尚未安装）
az bicep install

# 检查 Bicep 版本
az bicep version
```

下面是 Bicep 模板文件 `main.bicep` 的内容：

```powershell
@description('资源部署的目标区域')
param location string = resourceGroup().location

@description('环境名称，用于资源命名前缀')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('应用名称，用于资源命名')
param appName string

@description('SKU 定价层')
@allowed([
  'F1'
  'B1'
  'S1'
  'P1v3'
])
param skuName string = 'B1'

// 变量：统一命名前缀
var namingPrefix = '${appName}-${environment}'
var tags = {
  Environment: environment
  Application: appName
  ManagedBy: 'bicep'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// 应用服务计划
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${namingPrefix}-asp'
  location: location
  sku: {
    name: skuName
    tier: (skuName startsWith('F') ? 'Free' : (skuName startsWith('B') ? 'Basic' : 'Standard'))
    capacity: 1
  }
  properties: {
    reserved: false
  }
  tags: tags
}

// Web 应用
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${namingPrefix}-web'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
  tags: tags
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${namingPrefix}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    SamplingPercentage: 100
    DisableIpMasking: false
  }
  tags: tags
}

// 输出部署结果
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.defaultHostName}'
output appInsightsKey string = appInsights.properties.InstrumentationKey
output resourceGroupName string = resourceGroup().name
```

执行结果示例：

```text
PS> az bicep version
Bicep CLI version 0.32.4 (SHA: abc123def)

PS> az bicep build --file main.bicep
# 编译成功，生成 main.json（ARM Template）

PS> Test-AzResourceGroupDeployment `
      -ResourceGroupName "myapp-dev-rg" `
      -TemplateFile ./main.bicep `
      -TemplateParameterObject @{
          appName = "myapp"
          environment = "dev"
      }

# 输出验证结果（无错误）
```

## PowerShell 部署脚本

有了 Bicep 模板后，我们通过 PowerShell 构建自动化部署脚本，支持多环境参数化配置和部署状态跟踪。

```powershell
<#
.SYNOPSIS
    使用 Bicep 模板部署 Azure 基础设施

.DESCRIPTION
    支持多环境部署（dev/staging/prod），自动读取参数文件，
    支持差异预览（WhatIf）和实际部署两种模式。
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$AppName,

    [string]$ResourceGroupName,

    [string]$Location = 'eastasia',

    [string]$BicepTemplatePath = './main.bicep',

    [string]$ParameterFilePath = "./parameters/${Environment}.bicepparam"
)

# 导入 Az 模块
$RequiredModules = @('Az.Resources', 'Az.Accounts')
foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Host "安装模块: $Module" -ForegroundColor Yellow
        Install-Module -Name $Module -Force -Scope CurrentUser
    }
    Import-Module $Module -ErrorAction Stop
}

# 确保已登录 Azure
$Context = Get-AzContext
if (-not $Context) {
    Write-Host '请先登录 Azure...' -ForegroundColor Cyan
    Connect-AzAccount
    $Context = Get-AzContext
}

Write-Host "当前订阅: $($Context.Subscription.Name)" -ForegroundColor Green

# 构建资源组名称
if (-not $ResourceGroupName) {
    $ResourceGroupName = "${AppName}-${Environment}-rg"
}

# 确保资源组存在
$Rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $Rg) {
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, '创建资源组')) {
        $Rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "已创建资源组: $ResourceGroupName" -ForegroundColor Green
    }
}

# 构建部署参数
$DeployParams = @{
    ResourceGroupName = $ResourceGroupName
    TemplateFile      = $BicepTemplatePath
    Verbose           = $true
}

# 优先使用参数文件，其次使用命令行参数
if (Test-Path $ParameterFilePath) {
    $DeployParams['TemplateParameterFile'] = $ParameterFilePath
    Write-Host "使用参数文件: $ParameterFilePath" -ForegroundColor Cyan
} else {
    $DeployParams['TemplateParameterObject'] = @{
        appName      = $AppName
        environment  = $Environment
        location     = $Location
    }
    Write-Host '使用命令行参数' -ForegroundColor Cyan
}

# WhatIf 模式：预览变更
if ($PSCmdlet.ShouldProcess('Azure 资源', '差异预览')) {
    Write-Host "`n========== 差异预览 ==========" -ForegroundColor Yellow
    $WhatIfResult = Get-AzResourceGroupDeploymentWhatIfResult @DeployParams
    $WhatIfResult.Changes | ForEach-Object {
        Write-Host "  [$($_.ChangeType)] $($_.ResourceId)" -ForegroundColor White
    }
}

# 实际部署
if ($PSCmdlet.ShouldProcess('Azure 资源', '执行部署')) {
    $DeploymentName = "${AppName}-${Environment}-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $DeployParams['Name'] = $DeploymentName

    Write-Host "`n========== 开始部署 ==========" -ForegroundColor Yellow
    $Result = New-AzResourceGroupDeployment @DeployParams

    # 输出部署结果
    Write-Host "`n========== 部署结果 ==========" -ForegroundColor Green
    Write-Host "  部署名称: $($Result.DeploymentName)"
    Write-Host "  状态:     $($Result.ProvisioningState)"

    if ($Result.Outputs) {
        Write-Host "`n  输出变量:" -ForegroundColor Cyan
        foreach ($Key in $Result.Outputs.Keys) {
            Write-Host "    $Key = $($Result.Outputs[$Key].Value)"
        }
    }
}
```

执行结果示例：

```text
PS> .\Deploy-Infrastructure.ps1 -Environment dev -AppName myapp -WhatIf

当前订阅: Visual Studio Enterprise
使用命令行参数

========== 差异预览 ==========
  [Create] /subscriptions/.../resourceGroups/myapp-dev-rg/providers/Microsoft.Web/serverfarms/myapp-dev-asp
  [Create] /subscriptions/.../resourceGroups/myapp-dev-rg/providers/Microsoft.Web/sites/myapp-dev-web
  [Create] /subscriptions/.../resourceGroups/myapp-dev-rg/providers/Microsoft.Insights/components/myapp-dev-ai

PS> .\Deploy-Infrastructure.ps1 -Environment dev -AppName myapp

当前订阅: Visual Studio Enterprise
使用命令行参数

========== 开始部署 ==========

========== 部署结果 ==========
  部署名称: myapp-dev-20260320-080000
  状态:     Succeeded

  输出变量:
    webAppName = myapp-dev-web
    webAppUrl = https://myapp-dev-web.azurewebsites.net
    appInsightsKey = 12345678-abcd-efgh-ijkl-1234567890ab
    resourceGroupName = myapp-dev-rg
```

## 模块化与重用

当基础设施规模增长后，将 Bicep 模板拆分为模块是提高可维护性的关键。以下展示如何创建 Bicep 模块、构建共享模板库，并与 CI/CD 流水线集成。

首先是共享模块 `modules/storage.bicep`：

```powershell
# modules/storage.bicep - 存储账户共享模块

@description('存储账户位置')
param location string

@description('存储账户名称（全局唯一）')
param storageAccountName string

@description('存储账户 SKU')
param skuName string = 'Standard_LRS'

@description('资源标签')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
  tags: tags
}

// 启用 Blob 软删除
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: '${storageAccount.name}/default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

output storageAccountId string = storageAccount.id
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

然后在主模板中引用模块，并构建共享模板仓库：

```powershell
<#
.SYNOPSIS
    管理共享 Bicep 模块仓库
#>

param(
    [ValidateSet('publish', 'list', 'restore')]
    [string]$Action = 'restore',

    [string]$RegistryName = 'myacr.azurecr.io',
    [string]$ModulePath = 'bicep/modules'
)

# 模块清单：定义所有需要发布到 ACR 的模块
$ModuleManifest = @{
    'storage'    = @{
        Source = './modules/storage.bicep'
        Tag    = 'v1.2.0'
    }
    'keyvault'   = @{
        Source = './modules/keyvault.bicep'
        Tag    = 'v1.0.0'
    }
    'appservice' = @{
        Source = './modules/appservice.bicep'
        Tag    = 'v2.1.0'
    }
    'sql'        = @{
        Source = './modules/sql.bicep'
        Tag    = 'v1.3.0'
    }
}

switch ($Action) {
    'publish' {
        Write-Host '发布模块到 Azure Container Registry...' -ForegroundColor Cyan
        foreach ($ModuleName in $ModuleManifest.Keys) {
            $Module = $ModuleManifest[$ModuleName]
            $Target = "br:${RegistryName}/${ModulePath}/${ModuleName}:${$Module.Tag}"
            Write-Host "  发布: ${ModuleName}@$($Module.Tag)" -ForegroundColor White

            az bicep publish `
                --file $Module.Source `
                --target $Target

            if ($LASTEXITCODE -eq 0) {
                Write-Host "    成功" -ForegroundColor Green
            } else {
                Write-Host "    失败" -ForegroundColor Red
            }
        }
    }

    'restore' {
        Write-Host '从 ACR 还原模块依赖...' -ForegroundColor Cyan
        az bicep restore --file ./main.bicep --force
        Write-Host '还原完成' -ForegroundColor Green
    }

    'list' {
        Write-Host '已注册的 Bicep 模块:' -ForegroundColor Cyan
        foreach ($ModuleName in $ModuleManifest.Keys | Sort-Object) {
            $Module = $ModuleManifest[$ModuleName]
            Write-Host "  ${ModuleName}:$($Module.Tag) -> $($Module.Source)"
        }
    }
}
```

在主模板中使用远程模块：

```powershell
# main.bicep - 引用 ACR 中的共享模块

param location string = resourceGroup().location
param environment string
param appName string

var namingPrefix = '${appName}-${environment}'
var tags = {
  Environment: environment
  ManagedBy: 'bicep'
}

// 引用 ACR 中的存储模块
module storage 'br:myacr.azurecr.io/bicep/modules/storage:v1.2.0' = {
  name: '${namingPrefix}-storage-deploy'
  params: {
    location: location
    storageAccountName: '${namingPrefix}st01'
    skuName: (environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS')
    tags: tags
  }
}

output storageEndpoint string = storage.outputs.primaryEndpoint
```

CI/CD 集成脚本（GitHub Actions 本地验证）：

```powershell
<#
.SYNOPSIS
    CI/CD 流水线中的 Bicep 验证与部署步骤
#>

param(
    [string]$BicepPath = './main.bicep',
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'

# 步骤 1: 语法验证
Write-Host '== 步骤 1: Bicep 语法验证 ==' -ForegroundColor Yellow
$LintResult = az bicep lint --file $BicepPath 2>&1
if ($LintResult -match 'Error') {
    Write-Host "语法检查失败:`n$LintResult" -ForegroundColor Red
    exit 1
}
Write-Host '语法检查通过' -ForegroundColor Green

# 步骤 2: 编译为 ARM Template
Write-Host "`n== 步骤 2: 编译 Bicep 模板 ==" -ForegroundColor Yellow
az bicep build --file $BicepPath --outfile ./artifacts/main.json
Write-Host '编译成功' -ForegroundColor Green

# 步骤 3: 安全扫描（检查硬编码密钥等）
Write-Host "`n== 步骤 3: 模板安全扫描 ==" -ForegroundColor Yellow
$ArmContent = Get-Content ./artifacts/main.json -Raw
$SensitivePatterns = @(
    @{ Name = '密码明文'; Pattern = '"password"\s*:\s*"[^{}"]+"' }
    @{ Name = '密钥明文'; Pattern = '"secretKey"\s*:\s*"[^{}"]+"' }
    @{ Name = '连接字符串'; Pattern = '"connectionString"\s*:\s*"[^{}"]+"' }
)
$SecurityPassed = $true
foreach ($Pattern in $SensitivePatterns) {
    if ($ArmContent -match $Pattern.Pattern) {
        Write-Host "  警告: 检测到 $($Pattern.Name)" -ForegroundColor Red
        $SecurityPassed = $false
    }
}
if ($SecurityPassed) {
    Write-Host '安全扫描通过' -ForegroundColor Green
} else {
    Write-Host '安全扫描未通过，请修复后重试' -ForegroundColor Red
    exit 1
}

# 步骤 4: WhatIf 预览
Write-Host "`n== 步骤 4: 部署差异预览 ==" -ForegroundColor Yellow
$WhatIf = Get-AzResourceGroupDeploymentWhatIfResult `
    -ResourceGroupName "myapp-${Environment}-rg" `
    -TemplateFile $BicepPath `
    -TemplateParameterFile "./parameters/${Environment}.bicepparam"

$CreateCount = ($WhatIf.Changes | Where-Object { $_.ChangeType -eq 'Create' }).Count
$ModifyCount = ($WhatIf.Changes | Where-Object { $_.ChangeType -eq 'Modify' }).Count
$DeleteCount = ($WhatIf.Changes | Where-Object { $_.ChangeType -eq 'Delete' }).Count

Write-Host "  新增: $CreateCount | 修改: $ModifyCount | 删除: $DeleteCount" -ForegroundColor White
Write-Host "`n验证流程全部通过，可以执行部署" -ForegroundColor Green
```

执行结果示例：

```text
PS> .\Manage-BicepModules.ps1 -Action list

已注册的 Bicep 模块:
  appservice:v2.1.0 -> ./modules/appservice.bicep
  keyvault:v1.0.0 -> ./modules/keyvault.bicep
  sql:v1.3.0 -> ./modules/sql.bicep
  storage:v1.2.0 -> ./modules/storage.bicep

PS> .\CiCd-Validate.ps1 -BicepPath ./main.bicep -Environment staging

== 步骤 1: Bicep 语法验证 ==
语法检查通过

== 步骤 2: 编译 Bicep 模板 ==
编译成功

== 步骤 3: 模板安全扫描 ==
安全扫描通过

== 步骤 4: 部署差异预览 ==
  新增: 3 | 修改: 1 | 删除: 0

验证流程全部通过，可以执行部署
```

## 注意事项

1. **Bicep CLI 安装方式**：Bicep CLI 可通过 Azure CLI（`az bicep install`）或独立 MSI 安装。推荐使用 Azure CLI 方式管理，避免版本不一致的问题。确保 Bicep 版本与目标 Azure API 版本兼容。

2. **参数文件优先级**：使用 `.bicepparam` 文件替代 `.json` 参数文件，前者支持 Bicep 语法并可直接引用变量和函数，比纯 JSON 参数文件更灵活。命令行传入的参数会覆盖参数文件中的同名参数。

3. **模块版本管理**：将 Bicep 模块发布到 Azure Container Registry（ACR）后，主模板通过 `br:` 前缀引用。建议使用语义化版本号（SemVer），生产环境应锁定具体版本号而非使用 `latest` 标签。

4. **敏感信息处理**：绝不要在 Bicep 模板中硬编码密码、密钥等敏感信息。应使用 `secureString` 或 `secureObject` 类型参数，配合 Azure Key Vault 引用（`referenceKeyId`）在部署时动态获取。

5. **WhatIf 的局限性**：`Get-AzResourceGroupDeploymentWhatIfResult` 的差异预览是一种预测，某些资源类型的变更可能无法准确检测（如应用设置、连接字符串等嵌套属性的变更）。在关键环境部署前，建议先在非生产环境进行完整测试。

6. **订阅级与租户级部署**：`New-AzResourceGroupDeployment` 用于资源组级部署，`New-AzDeployment` 用于订阅级部署（如创建资源组、策略分配），`New-AzTenantDeployment` 用于租户级部署。选择正确的部署范围可以避免权限错误。
