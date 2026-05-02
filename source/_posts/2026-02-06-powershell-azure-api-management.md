---
layout: post
date: 2026-02-06 08:00:00
updated: 2026-02-06 08:00:00
title: "PowerShell 技能连载 - Azure API Management 管理"
description: PowerTip of the Day - Azure API Management Administration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- api-management
- gateway
- microservices
---

_适用于 PowerShell 7.0 及以上版本_

在微服务架构中，API 网关是连接前端应用与后端服务的关键枢纽。Azure API Management（APIM）作为微软云平台的企业级 API 网关，提供了 API 发布、流量控制、安全认证、请求转换和用量分析等一站式能力。无论是对外暴露开放 API，还是在内部微服务之间做统一入口，APIM 都能胜任。

然而 APIM 的配置项非常庞杂——API 定义、操作策略、产品打包、订阅密钥、后端服务池、开发者门户，每一项都需要精确配置。在多环境（开发、测试、生产）部署场景下，手动在 Azure 门户中点选配置既容易出错，也难以做到版本追溯。

通过 PowerShell 的 `Az.ApiManagement` 模块，我们可以将 APIM 的全部配置写成脚本，实现基础设施即代码（IaC）。这不仅保证了环境之间的一致性，还能将配置纳入 Git 版本控制，配合 CI/CD 管线实现 API 管理的自动化交付。本文将从实例管理、策略配置和产品运营三个维度，展示如何用 PowerShell 高效管理 APIM。

## APIM 实例与 API 管理

首先，我们来看如何创建 APIM 实例并导入 API 定义。下面的脚本展示了从创建实例到配置后端服务的完整流程：

```powershell
# 连接 Azure 账户
Connect-AzAccount -Subscription 'MySubscription'

# 定义变量
$resourceGroup = 'rg-apim-demo'
$location = 'eastasia'
$apimName = 'apim-demo-001'
$apiName = 'user-service-api'

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# 创建 APIM 实例（开发者层级，适合测试）
$apim = New-AzApiManagement `
    -ResourceGroupName $resourceGroup `
    -Name $apimName `
    -Location $location `
    -Organization 'Vichamp Corp' `
    -AdminEmail 'admin@vichamp.com' `
    -Sku 'Developer' `
    -Capacity 1

$context = $apim.Context

# 从 OpenAPI 规范导入 API
$openApiSpec = @'
{
    "openapi": "3.0.1",
    "info": { "title": "User Service", "version": "1.0.0" },
    "paths": {
        "/users": {
            "get": {
                "operationId": "list-users",
                "responses": { "200": { "description": "OK" } }
            },
            "post": {
                "operationId": "create-user",
                "responses": { "201": { "description": "Created" } }
            }
        },
        "/users/{id}": {
            "get": {
                "operationId": "get-user",
                "responses": { "200": { "description": "OK" } }
            }
        }
    }
}
'@

$specPath = Join-Path $env:TEMP 'user-service-openapi.json'
$openApiSpec | Set-Content -Path $specPath -Encoding utf8

# 导入 API，设置后端 URL
Import-AzApiManagementApi `
    -Context $context `
    -ApiId $apiName `
    -SpecificationFormat 'OpenApiJson' `
    -SpecificationPath $specPath `
    -Path 'users' `
    -ServiceUrl 'https://user-svc.internal.vichamp.com/api/v1'

# 配置后端服务（支持负载均衡和服务发现）
$backendId = 'user-service-backend'
New-AzApiManagementBackend `
    -Context $context `
    -BackendId $backendId `
    -Url 'https://user-svc.internal.vichamp.com/api/v1' `
    -Protocol 'http' `
    -Description 'User microservice backend'

# 将 API 操作绑定到后端
Set-AzApiManagementApi `
    -Context $context `
    -ApiId $apiName `
    -ApiIdSet $apiName `
    -ServiceUrl 'https://user-svc.internal.vichamp.com/api/v1'

Write-Host "APIM 实例 '$apimName' 创建完成，API '$apiName' 已导入" -ForegroundColor Green
```

执行结果示例：

```
确认
资源组 'rg-apim-demo' 已存在，是否覆盖？
[Y] 是  [N] 否  [S] 挂起  [?] 帮助 (默认值为“Y”):

ResourceId        : /subscriptions/xxxx/resourceGroups/rg-apim-demo
Location          : eastasia
ProvisioningState : Succeeded

APIM 实例 'apim-demo-001' 创建完成，API '$apiName' 已导入
```

## 策略配置与安全

APIM 的核心能力在于策略（Policy）。策略是一段 XML 配置，可以在请求和响应的各个阶段注入逻辑。下面展示如何配置速率限制、JWT 验证和请求转换策略：

```powershell
$context = (Get-AzApiManagement -ResourceGroupName 'rg-apim-demo' -Name 'apim-demo-001').Context

# --- 策略 1：速率限制（API 级别） ---
$rateLimitPolicy = @'
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <rate-limit-by-key calls="20" renewal-period="60"
                           counter-key="@(context.Request.IpAddress)" />
    </inbound>
</policies>
'@

Set-AzApiManagementPolicy `
    -Context $context `
    -ApiId 'user-service-api' `
    -PolicyValue $rateLimitPolicy

Write-Host "速率限制策略已应用：全局 100 次/分钟，单 IP 20 次/分钟" -ForegroundColor Cyan

# --- 策略 2：JWT 验证（操作级别） ---
$jwtPolicy = @'
<policies>
    <inbound>
        <validate-jwt header-name="Authorization"
                      failed-validation-httpcode="401"
                      failed-validation-error-message="Unauthorized. Invalid token.">
            <openid-config url="https://login.microsoftonline.com/tenant-id/v2.0/.well-known/openid-configuration" />
            <required-claims>
                <claim name="aud" match="all">
                    <value>api://user-service</value>
                </claim>
                <claim name="roles" match="any">
                    <value>API.Reader</value>
                    <value>API.Writer</value>
                </claim>
            </required-claims>
        </validate-jwt>
    </inbound>
</policies>
'@

Set-AzApiManagementPolicy `
    -Context $context `
    -ApiId 'user-service-api' `
    -OperationId 'get-user' `
    -PolicyValue $jwtPolicy

Write-Host "JWT 验证策略已应用到 get-user 操作" -ForegroundColor Cyan

# --- 策略 3：请求头转换与响应缓存 ---
$transformPolicy = @'
<policies>
    <inbound>
        <set-header name="X-Request-Source" exists-action="override">
            <value>APIM-Gateway</value>
        </set-header>
        <set-header name="X-Correlation-Id" exists-action="skip">
            <value>@(Guid.NewGuid().ToString())</value>
        </set-header>
        <rewrite-uri template="/users/{id}/profile?fields=basic" />
    </inbound>
    <outbound>
        <cache-store duration="300" />
        <set-header name="X-Response-Time" exists-action="override">
            <value>@(DateTime.UtcNow.ToString("O"))</value>
        </set-header>
    </outbound>
</policies>
'@

Set-AzApiManagementPolicy `
    -Context $context `
    -ApiId 'user-service-api' `
    -OperationId 'get-user' `
    -PolicyValue $transformPolicy

Write-Host "请求转换与缓存策略已应用" -ForegroundColor Cyan

# 导出当前 API 的完整策略用于版本控制
$policyXml = Get-AzApiManagementPolicy `
    -Context $context `
    -ApiId 'user-service-api'

$policyXml.Save("$(Join-Path $PWD 'policies\user-service-api-policy.xml')")
Write-Host "策略已导出到文件，可纳入 Git 版本控制" -ForegroundColor Green
```

执行结果示例：

```
速率限制策略已应用：全局 100 次/分钟，单 IP 20 次/分钟
JWT 验证策略已应用到 get-user 操作
请求转换与缓存策略已应用
策略已导出到文件，可纳入 Git 版本控制
```

## 产品管理与开发者门户

APIM 中的"产品"（Product）是 API 的打包和发布单元。开发者通过订阅产品来获取 API 访问权限。下面展示产品配置、订阅管理和用量分析的完整流程：

```powershell
$context = (Get-AzApiManagement -ResourceGroupName 'rg-apim-demo' -Name 'apim-demo-001').Context

# --- 创建产品并关联 API ---
$productId = 'user-service-basic'
$productTitle = 'User Service - Basic Tier'

New-AzApiManagementProduct `
    -Context $context `
    -ProductId $productId `
    -Title $productTitle `
    -Description '基础套餐：提供用户查询和创建功能，速率限制 100 次/分钟' `
    -LegalTerm '使用本 API 即表示同意服务条款 v2.0' `
    -SubscriptionRequired $true `
    -ApprovalRequired $false `
    -State 'Published'

# 将 API 添加到产品
Add-AzApiManagementApiToProduct `
    -Context $context `
    -ProductId $productId `
    -ApiId 'user-service-api'

Write-Host "产品 '$productTitle' 已创建并发布" -ForegroundColor Cyan

# --- 创建开发者账户并生成订阅 ---
$userId = 'dev-user-001'
$email = 'developer@partner.com'

New-AzApiManagementUser `
    -Context $context `
    -UserId $userId `
    -FirstName 'Alice' `
    -LastName 'Chen' `
    -Email $email `
    -Password (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force) `
    -State 'Active'

# 为开发者创建订阅
$subscription = New-AzApiManagementSubscription `
    -Context $context `
    -ProductId $productId `
    -Name "Alice 的订阅 - $productTitle" `
    -UserId $userId `
    -PrimaryKey (New-Guid).ToString() `
    -SecondaryKey (New-Guid).ToString() `
    -State 'Active'

Write-Host "开发者 $email 已订阅产品，订阅 ID: $($subscription.SubscriptionId)" -ForegroundColor Cyan

# --- 用量分析报告 ---
# 获取按 API 汇总的请求统计
$reportSasToken = Get-AzApiManagementSsoToken `
    -ResourceGroupName 'rg-apim-demo' `
    -Name 'apim-demo-001'

Write-Host "`n--- API 用量报告（最近 30 天）---" -ForegroundColor Yellow

$apis = Get-AzApiManagementApi -Context $context

foreach ($api in $apis) {
    # 获取 API 级别的指标
    $metrics = Get-AzApiManagementDiagnostic `
        -Context $context `
        -ApiId $api.ApiId `
        -DiagnosticId 'applicationinsights' `
        -ErrorAction SilentlyContinue

    $operations = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId

    [PSCustomObject]@{
        API名称     = $api.Name
        路径前缀    = $api.Path
        操作数量    = $operations.Count
        协议        = ($api.Protocols -join ', ')
        后端URL     = $api.ServiceUrl
        状态        = $api.IsCurrent
    }
}

# 导出订阅密钥列表（运维审计用）
$allSubscriptions = Get-AzApiManagementSubscription -Context $context

$subscriptionReport = $allSubscriptions | ForEach-Object {
    [PSCustomObject]@{
        订阅名称   = $_.Name
        产品ID     = $_.ProductId
        创建时间   = $_.CreatedDate
        状态       = $_.State
        过期时间   = $_.EndDate
    }
}

$subscriptionReport | Format-Table -AutoSize
Write-Host "共 $($subscriptionReport.Count) 个活跃订阅" -ForegroundColor Green
```

执行结果示例：

```
产品 'User Service - Basic Tier' 已创建并发布
开发者 developer@partner.com 已订阅产品，订阅 ID: sub-20260206-001

--- API 用量报告（最近 30 天）---

API名称          路径前缀   操作数量  协议     后端URL                                     状态
------          --------  --------  ----     -------                                     ----
User Service    users             3  https    https://user-svc.internal.vichamp.com/api/v1  True

订阅名称                          产品ID                创建时间              状态    过期时间
--------                          ------                --------              ----    --------
Alice 的订阅 - User Service...   user-service-basic    2026/2/6 10:30:00    Active
共 1 个活跃订阅
```

## 注意事项

1. **SKU 选择**：开发者层级（Developer）仅用于非生产环境，不提供 SLA 保证。生产环境应选择基本（Basic）、标准（Standard）或高级（Premium）层级，高级层支持多区域部署和虚拟网络集成。
2. **策略 XML 格式**：APIM 策略是严格的 XML 文档，拼写错误或标签未闭合会导致整个 API 无法响应。建议在本地用 XML 校验工具验证后再部署，并将策略文件纳入 Git 版本控制。
3. **订阅密钥安全**：`New-AzApiManagementSubscription` 生成的主密钥和次密钥是访问 API 的凭证，切勿硬编码在脚本中，应存储在 Azure Key Vault 或环境变量中。
4. **策略继承顺序**：APIM 策略按"全局 → 产品 → API → 操作"的层级继承，子级策略会覆盖父级同名的策略节点。配置时务必明确各层级的职责边界，避免策略冲突。
5. **后端健康检查**：生产环境建议配置后端服务池（Backend Pool）和健康探针（Health Probe），当某个后端实例不可用时 APIM 能自动切换，提高服务可用性。
6. **成本监控**：APIM 按层级和容量计费，高级层每个单元约 2,800 美元/月。建议在非工作时间缩减容量（Premium 层支持弹性扩缩），并设置 Azure 成本告警防止超支。
