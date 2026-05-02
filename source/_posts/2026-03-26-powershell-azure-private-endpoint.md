---
layout: post
date: 2026-03-26 08:00:00
updated: 2026-03-26 08:00:00
title: "PowerShell 技能连载 - Azure Private Endpoint 网络隔离"
description: PowerTip of the Day - Azure Private Endpoint Network Isolation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- private-endpoint
- networking
- security
---

_适用于 PowerShell 7.0 及以上版本_

在混合云架构中，数据安全的核心诉求之一是确保敏感流量不经过公共互联网。Azure PaaS 服务（如 Storage Account、SQL Database、Key Vault）默认通过公网端点提供服务，虽然传输层使用 TLS 加密，但出于合规要求（如金融行业的 PCI-DSS、医疗行业的 HIPAA），很多企业需要将所有数据路径锁定在私有网络内。Azure Private Endpoint 正是为满足这一需求而设计的网络隔离方案。

Private Endpoint 在虚拟网络中分配一个私有 IP 地址，将 PaaS 服务的入口映射到你的 VNet 内部。通过配合 Private DNS Zone，客户端可以使用原有的服务 FQDN（如 `mystorage.blob.core.windows.net`）直接解析到私有 IP，无需修改应用代码。整个数据平面流量都在 Microsoft 骨干网内传输，完全不暴露在公网上。

本文将从三个层面展开实战：首先是 Private Endpoint 的创建与 DNS 配置自动化；然后是 Private Link Service 的构建，将内部服务安全地暴露给合作伙伴网络；最后是网络隔离合规验证，通过脚本自动检测配置漂移并生成合规报告。

<!-- more -->

## Private Endpoint 创建与 DNS 配置

创建 Private Endpoint 需要同时处理网络接口和 DNS 解析两个层面。下面的脚本封装了完整的端点创建流程，包括自动关联 Private DNS Zone、配置 A 记录以及验证 DNS 解析结果。

```powershell
function New-AzPrivateEndpointWithDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$VirtualNetworkName,

        [Parameter(Mandatory = $true)]
        [string]$SubnetName,

        [Parameter(Mandatory = $true)]
        [string]$PrivateEndpointName,

        [Parameter(Mandatory = $true)]
        [string]$TargetResourceId,

        [Parameter(Mandatory = $true)]
        [string]$TargetSubresource,

        [Parameter(Mandatory = $false)]
        [string]$DnsZoneResourceGroup
    )

    # 获取子网信息，确认子网存在且可用
    $vnet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet

    if (-not $subnet) {
        Write-Error "子网 $SubnetName 不存在于虚拟网络 $VirtualNetworkName 中"
        return
    }

    Write-Host "目标子网: $($subnet.Name) ($($subnet.AddressPrefix))" -ForegroundColor Cyan

    # 构建 Private Link Service 连接配置
    $privateLinkConnection = New-AzPrivateLinkServiceConnection `
        -Name "$PrivateEndpointName-connection" `
        -PrivateLinkServiceId $TargetResourceId `
        -GroupId $TargetSubresource

    # 创建 Private Endpoint
    Write-Host "正在创建 Private Endpoint: $PrivateEndpointName ..." -ForegroundColor Yellow
    $pe = New-AzPrivateEndpoint `
        -Name $PrivateEndpointName `
        -ResourceGroupName $ResourceGroupName `
        -Location $vnet.Location `
        -Subnet $subnet `
        -PrivateLinkServiceConnection $privateLinkConnection `
        -ManualRequest:$false

    Write-Host "Private Endpoint 创建完成" -ForegroundColor Green

    # 自动确定 DNS Zone 名称
    $targetResource = Get-AzResource -ResourceId $TargetResourceId
    $dnsZoneMap = @{
        "Microsoft.Storage/storageAccounts"  = "privatelink.blob.core.windows.net"
        "Microsoft.Storage/storageAccounts/file" = "privatelink.file.core.windows.net"
        "Microsoft.Sql/servers"              = "privatelink.database.windows.net"
        "Microsoft.KeyVault/vaults"          = "privatelink.vaultcore.azure.net"
        "Microsoft.ContainerRegistry/registries" = "privatelink.azurecr.io"
        "Microsoft.Web/sites"                = "privatelink.azurewebsites.net"
    }

    $dnsZoneName = $dnsZoneMap[$targetResource.ResourceType]
    if (-not $dnsZoneName) {
        Write-Warning "未找到资源类型 $($targetResource.ResourceType) 的默认 DNS Zone，请手动指定"
        return $pe
    }

    # 查找或创建 Private DNS Zone
    $dnsRg = if ($DnsZoneResourceGroup) { $DnsZoneResourceGroup } else { $ResourceGroupName }
    $dnsZone = Get-AzPrivateDnsZone -ResourceGroupName $dnsRg -Name $dnsZoneName -ErrorAction SilentlyContinue

    if (-not $dnsZone) {
        Write-Host "创建 Private DNS Zone: $dnsZoneName" -ForegroundColor Yellow
        $dnsZone = New-AzPrivateDnsZone -ResourceGroupName $dnsRg -Name $dnsZoneName
    }

    # 创建 Virtual Network Link，将 DNS Zone 关联到 VNet
    $vnetLinkName = "link-$($VirtualNetworkName)-$($dnsZoneName -replace '\.','')"
    $existingLink = Get-AzPrivateDnsVirtualNetworkLink `
        -ResourceGroupName $dnsRg -ZoneName $dnsZoneName -Name $vnetLinkName -ErrorAction SilentlyContinue

    if (-not $existingLink) {
        Write-Host "关联 DNS Zone 到虚拟网络: $VirtualNetworkName" -ForegroundColor Yellow
        $null = New-AzPrivateDnsVirtualNetworkLink `
            -ResourceGroupName $dnsRg `
            -ZoneName $dnsZoneName `
            -Name $vnetLinkName `
            -VirtualNetworkId $vnet.Id
    }

    # 获取 Private Endpoint 的网络接口 IP 地址
    $networkInterface = Get-AzNetworkInterface -ResourceId $pe.NetworkInterfaces[0].Id
    $privateIpAddress = $networkInterface.IpConfigurations[0].PrivateIpAddress

    Write-Host "Private Endpoint IP: $privateIpAddress" -ForegroundColor Green

    # 创建 DNS A 记录
    $dnsRecordName = $targetResource.Name
    $existingRecord = Get-AzPrivateDnsRecordSet `
        -ResourceGroupName $dnsRg -ZoneName $dnsZoneName -Name $dnsRecordName -RecordType A -ErrorAction SilentlyContinue

    if (-not $existingRecord) {
        $null = New-AzPrivateDnsRecordSet `
            -ResourceGroupName $dnsRg `
            -ZoneName $dnsZoneName `
            -Name $dnsRecordName `
            -RecordType A `
            -Ttl 300 `
            -PrivateDnsRecord (New-AzPrivateDnsRecordConfig -IPv4Address $privateIpAddress)
        Write-Host "DNS A 记录已创建: $dnsRecordName -> $privateIpAddress" -ForegroundColor Green
    }

    return @{
        PrivateEndpoint  = $pe
        PrivateIpAddress = $privateIpAddress
        DnsZoneName      = $dnsZoneName
        DnsRecordName    = $dnsRecordName
    }
}

# 示例：为 Storage Account 创建 Private Endpoint
$result = New-AzPrivateEndpointWithDns `
    -ResourceGroupName "rg-production" `
    -VirtualNetworkName "vnet-prod-eastus" `
    -SubnetName "snet-endpoints" `
    -PrivateEndpointName "pe-prod-storage" `
    -TargetResourceId "/subscriptions/a1b2c3d4-e5f6-7890-abcd-ef1234567890/resourceGroups/rg-production/providers/Microsoft.Storage/storageAccounts/stproddata001" `
    -TargetSubresource "blob"

# 验证 DNS 解析
$storageFqdn = "stproddata001.blob.core.windows.net"
$resolved = Resolve-DnsName -Name $storageFqdn -DnsOnly -ErrorAction SilentlyContinue
Write-Host "`nDNS 解析验证: $storageFqdn -> $($resolved.IPAddress -join ', ')" -ForegroundColor Cyan
```

执行结果示例：

```
目标子网: snet-endpoints (10.0.2.0/24)
正在创建 Private Endpoint: pe-prod-storage ...
Private Endpoint 创建完成
创建 Private DNS Zone: privatelink.blob.core.windows.net
关联 DNS Zone 到虚拟网络: vnet-prod-eastus
Private Endpoint IP: 10.0.2.4
DNS A 记录已创建: stproddata001 -> 10.0.2.4

DNS 解析验证: stproddata001.blob.core.windows.net -> 10.0.2.4
```

从输出可以看到，Storage Account 的 FQDN 已经解析到 VNet 内的私有 IP `10.0.2.4`，而不是公网地址。这意味着同一 VNet 内的所有虚拟机访问该 Storage Account 时，流量不会离开 Microsoft 骨干网。DNS Zone 的自动关联确保了无需修改应用配置，原有的连接字符串即可直接工作。

## Private Link Service 构建

Private Link Service 是 Private Endpoint 的镜像能力——它允许你将 VNet 内部运行的服务（如 API 服务、中间件）通过私有连接暴露给其他 Azure 租户或订阅。下面的脚本展示了如何创建 Private Link Service，配置 NAT 规则和访问控制策略。

```powershell
function New-AzPrivateLinkServiceAutomation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $true)]
        [string]$LoadBalancerName,

        [Parameter(Mandatory = $true)]
        [string]$FrontendIpConfigName,

        [Parameter(Mandatory = $false)]
        [string[]]$AllowedSubscriptions = @(),

        [Parameter(Mandatory = $false)]
        [bool]$EnableProxyProtocol = $false,

        [Parameter(Mandatory = $false)]
        [string]$Visibility = "AutoApproval"
    )

    # 获取内部负载均衡器和前端 IP 配置
    $lb = Get-AzLoadBalancer -Name $LoadBalancerName -ResourceGroupName $ResourceGroupName
    $frontendIp = $lb.FrontendIpConfigurations | Where-Object { $_.Name -eq $FrontendIpConfigName }

    if (-not $frontendIp) {
        Write-Error "未找到前端 IP 配置: $FrontendIpConfigName"
        return
    }

    Write-Host "负载均衡器: $($lb.Name)" -ForegroundColor Cyan
    Write-Host "前端 IP: $($frontendIp.PrivateIpAddress)" -ForegroundColor Cyan

    # 创建 Private Link Service 的 IP 配置
    $ipConfig = New-AzPrivateLinkServiceIpConfig `
        -Name "$ServiceName-ipconfig" `
        -PrivateIpAddress "10.0.3.10" `
        -Subnet (Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName |
            Get-AzVirtualNetworkSubnetConfig -Name "snet-privatelink")

    # 构建访问控制参数
    $autoApproval = $null
    $visibilityList = @()

    if ($Visibility -eq "AutoApproval" -and $AllowedSubscriptions.Count -gt 0) {
        # 指定的订阅自动批准连接请求
        $autoApproval = $AllowedSubscriptions
        $visibilityList = $AllowedSubscriptions
        Write-Host "访问策略: 自动批准 (订阅白名单: $($AllowedSubscriptions.Count) 个)" -ForegroundColor Yellow
    }
    elseif ($Visibility -eq "Private") {
        # 仅对特定订阅可见
        $visibilityList = $AllowedSubscriptions
        Write-Host "访问策略: 私有可见 (订阅白名单: $($AllowedSubscriptions.Count) 个)" -ForegroundColor Yellow
    }
    else {
        # 对所有订阅可见
        Write-Host "访问策略: 公开可见 (需手动批准连接)" -ForegroundColor Yellow
    }

    # 创建 Private Link Service
    Write-Host "正在创建 Private Link Service: $ServiceName ..." -ForegroundColor Yellow

    $plsParams = @{
        Name                              = $ServiceName
        ResourceGroupName                 = $ResourceGroupName
        Location                          = $lb.Location
        LoadBalancerFrontendIpConfiguration = $frontendIp
        IpConfiguration                   = $ipConfig
        EnableProxyProtocol               = $EnableProxyProtocol
    }

    if ($visibilityList.Count -gt 0) {
        $plsParams["Visibility"] = $visibilityList
    }

    if ($autoApproval) {
        $plsParams["AutoApproval"] = $autoApproval
    }

    $pls = New-AzPrivateLinkService @plsParams

    Write-Host "Private Link Service 创建完成" -ForegroundColor Green
    Write-Host "服务别名 (Alias): $($pls.Alias)" -ForegroundColor Green
    Write-Host "服务资源 ID: $($pls.Id)" -ForegroundColor DarkGray

    # 查看待处理的连接请求
    $connections = Get-AzPrivateEndpointConnection -PrivateLinkServiceId $pls.Id -ErrorAction SilentlyContinue
    if ($connections) {
        Write-Host "`n当前连接请求:" -ForegroundColor Cyan
        $connections | Format-Table Name, PrivateEndpointId, ConnectionState, Description -AutoSize
    }

    return $pls
}

# 示例：创建 Private Link Service，暴露内部 API 给合作伙伴
$partnerSubscriptions = @(
    "b2c3d4e5-f6a7-8901-bcde-f12345678901"
    "c3d4e5f6-a7b8-9012-cdef-123456789012"
)

$pls = New-AzPrivateLinkServiceAutomation `
    -ResourceGroupName "rg-production" `
    -ServiceName "pls-internal-api" `
    -LoadBalancerName "lb-internal-api" `
    -FrontendIpConfigName "feip-api-v1" `
    -AllowedSubscriptions $partnerSubscriptions `
    -EnableProxyProtocol $false `
    -Visibility "AutoApproval"
```

执行结果示例：

```
负载均衡器: lb-internal-api
前端 IP: 10.0.3.5
访问策略: 自动批准 (订阅白名单: 2 个)
正在创建 Private Link Service: pls-internal-api ...
Private Link Service 创建完成
服务别名 (Alias): pls-internal-api.7b8c9d0e-eastus.azure.privatelinkservice
服务资源 ID: /subscriptions/a1b2c3d4-.../Microsoft.Network/privateLinkServices/pls-internal-api

当前连接请求:
Name                PrivateEndpointId                     ConnectionState Description
----                -----------------                     --------------- -----------
pe-partner-a-eastus /subscriptions/b2c3d4e5-.../pe-partner Approved
pe-partner-b-eastus /subscriptions/c3d4e5f6-.../pe-partner Pending
```

Private Link Service 的核心价值在于安全可控的跨租户连接。通过 `AutoApproval` 机制，指定的合作伙伴订阅（如 `b2c3d4e5-...`）创建的 Private Endpoint 连接会被自动批准，无需人工干预；而 `Pending` 状态的连接则需要运维团队手动审核。`Alias` 是消费方创建 Private Endpoint 时使用的唯一标识，不需要暴露你的资源 ID。`EnableProxyProtocol` 参数在需要获取客户端真实 IP 的场景中开启，但会增加少量网络开销。

## 网络隔离验证与合规检查

Private Endpoint 部署完成后，持续验证网络隔离状态是合规审计的基本要求。下面的脚本实现了自动化合规检查，覆盖 DNS 解析、公网端点状态、网络路由和访问策略等多个维度，并生成结构化的合规报告。

```powershell
function Test-AzPrivateEndpointCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$HOME/PrivateEndpointCompliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    $results = @()
    $now = Get-Date
    $compliantCount = 0
    $nonCompliantCount = 0

    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "Private Endpoint 网络隔离合规检查" -ForegroundColor Cyan
    Write-Host "检查时间: $($now.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "资源组: $ResourceGroupName"
    Write-Host ("=" * 70) -ForegroundColor Cyan

    # 获取资源组内所有 Private Endpoint
    $privateEndpoints = Get-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName
    Write-Host "`n发现 $($privateEndpoints.Count) 个 Private Endpoint" -ForegroundColor Yellow

    foreach ($pe in $privateEndpoints) {
        $checkResult = [ordered]@{
            Name         = $pe.Name
            ResourceId   = $pe.Id
            Location     = $pe.Location
            CheckTime    = $now.ToString("yyyy-MM-dd HH:mm:ss")
            Status       = "Compliant"
            Issues       = @()
        }

        Write-Host "`n--- 检查: $($pe.Name) ---" -ForegroundColor White

        # 检查 1: 连接状态是否为 Approved
        foreach ($conn in $pe.PrivateLinkServiceConnections) {
            $connStatus = $conn.PrivateLinkServiceConnectionState.Status
            if ($connStatus -ne "Approved") {
                $checkResult.Status = "NonCompliant"
                $checkResult.Issues += "连接状态非 Approved: $connStatus (服务: $($conn.PrivateLinkServiceId))"
                Write-Host "  [FAIL] 连接状态: $connStatus" -ForegroundColor Red
            }
            else {
                Write-Host "  [PASS] 连接状态: Approved" -ForegroundColor Green
            }
        }

        # 检查 2: 关联的网络接口是否具有私有 IP
        $nic = Get-AzNetworkInterface -ResourceId $pe.NetworkInterfaces[0].Id
        $privateIp = $nic.IpConfigurations[0].PrivateIpAddress
        if ($privateIp -match "^10\.|^172\.(1[6-9]|2[0-9]|3[01])\.|^192\.168\.") {
            Write-Host "  [PASS] 私有 IP 地址: $privateIp (RFC1918)" -ForegroundColor Green
        }
        else {
            $checkResult.Status = "NonCompliant"
            $checkResult.Issues += "IP 地址不在 RFC1918 私有范围: $privateIp"
            Write-Host "  [FAIL] IP 地址不在 RFC1918 范围: $privateIp" -ForegroundColor Red
        }

        # 检查 3: 目标资源的公网端点是否已禁用
        $targetResourceId = $pe.PrivateLinkServiceConnections[0].PrivateLinkServiceId
        $targetResource = Get-AzResource -ResourceId $targetResourceId
        $resourceType = $targetResource.ResourceType

        $publicAccessEnabled = $false
        switch ($resourceType) {
            "Microsoft.Storage/storageAccounts" {
                $storage = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $targetResource.Name
                $publicAccessEnabled = $storage.NetworkRuleSet.DefaultAction -eq "Allow"
            }
            "Microsoft.KeyVault/vaults" {
                $kv = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $targetResource.Name
                $publicAccessEnabled = $kv.NetworkAcls.DefaultAction -eq "Allow"
            }
            "Microsoft.Sql/servers" {
                $sql = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $targetResource.Name
                $publicAccessEnabled = $sql.PublicNetworkAccess -eq "Enabled"
            }
        }

        if ($publicAccessEnabled) {
            $checkResult.Status = "NonCompliant"
            $checkResult.Issues += "目标资源的公网访问未禁用 (类型: $resourceType)"
            Write-Host "  [FAIL] 公网端点未禁用 ($resourceType)" -ForegroundColor Red
        }
        else {
            Write-Host "  [PASS] 公网端点已禁用 ($resourceType)" -ForegroundColor Green
        }

        # 检查 4: DNS 解析是否指向私有 IP
        $dnsZoneMap = @{
            "Microsoft.Storage/storageAccounts" = "{0}.blob.core.windows.net"
            "Microsoft.KeyVault/vaults"         = "{0}.vault.azure.net"
            "Microsoft.Sql/servers"             = "{0}.database.windows.net"
        }

        $fqdnTemplate = $dnsZoneMap[$resourceType]
        if ($fqdnTemplate) {
            $fqdn = $fqdnTemplate -f $targetResource.Name
            $resolved = Resolve-DnsName -Name $fqdn -DnsOnly -ErrorAction SilentlyContinue
            $resolvedIp = if ($resolved) { $resolved[0].IPAddress } else { "未解析" }

            if ($resolvedIp -eq $privateIp) {
                Write-Host "  [PASS] DNS 解析: $fqdn -> $resolvedIp" -ForegroundColor Green
            }
            else {
                $checkResult.Status = "NonCompliant"
                $checkResult.Issues += "DNS 解析不匹配: $fqdn 解析为 $resolvedIp，应为 $privateIp"
                Write-Host "  [FAIL] DNS 解析不匹配: $resolvedIp (应为 $privateIp)" -ForegroundColor Red
            }
        }

        # 汇总
        if ($checkResult.Status -eq "Compliant") {
            $compliantCount++
        }
        else {
            $nonCompliantCount++
        }

        $results += [PSCustomObject]$checkResult
    }

    # 生成合规报告
    $report = [ordered]@{
        ReportTime       = $now.ToString("yyyy-MM-dd HH:mm:ss")
        ResourceGroup    = $ResourceGroupName
        TotalEndpoints   = $privateEndpoints.Count
        Compliant        = $compliantCount
        NonCompliant     = $nonCompliantCount
        ComplianceRate   = if ($privateEndpoints.Count -gt 0) {
            [math]::Round(($compliantCount / $privateEndpoints.Count) * 100, 1)
        } else { 100 }
        Details          = $results
    }

    $reportJson = $report | ConvertTo-Json -Depth 5
    $reportJson | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "`n" ("=" * 70) -ForegroundColor Cyan
    Write-Host "合规检查完成" -ForegroundColor Cyan
    Write-Host "  通过: $compliantCount / $($privateEndpoints.Count)" -ForegroundColor Green
    Write-Host "  不通过: $nonCompliantCount / $($privateEndpoints.Count)" -ForegroundColor Red
    Write-Host "  合规率: $($report.ComplianceRate)%" -ForegroundColor Cyan
    Write-Host "  报告已保存: $OutputPath" -ForegroundColor White
    Write-Host ("=" * 70) -ForegroundColor Cyan

    return $report
}

# 执行合规检查
$compliance = Test-AzPrivateEndpointCompliance `
    -ResourceGroupName "rg-production" `
    -OutputPath "$HOME/PrivateEndpointCompliance_20260326.json"
```

执行结果示例：

```
======================================================================
Private Endpoint 网络隔离合规检查
检查时间: 2026-03-26 08:30:00
资源组: rg-production
======================================================================

发现 4 个 Private Endpoint

--- 检查: pe-prod-storage ---
  [PASS] 连接状态: Approved
  [PASS] 私有 IP 地址: 10.0.2.4 (RFC1918)
  [PASS] 公网端点已禁用 (Microsoft.Storage/storageAccounts)
  [PASS] DNS 解析: stproddata001.blob.core.windows.net -> 10.0.2.4

--- 检查: pe-prod-keyvault ---
  [PASS] 连接状态: Approved
  [PASS] 私有 IP 地址: 10.0.2.5 (RFC1918)
  [PASS] 公网端点已禁用 (Microsoft.KeyVault/vaults)
  [PASS] DNS 解析: kv-prod-eastus.vault.azure.net -> 10.0.2.5

--- 检查: pe-prod-sql ---
  [PASS] 连接状态: Approved
  [PASS] 私有 IP 地址: 10.0.2.6 (RFC1918)
  [FAIL] 公网端点未禁用 (Microsoft.Sql/servers)
  [PASS] DNS 解析: sql-prod-eastus.database.windows.net -> 10.0.2.6

--- 检查: pe-staging-storage ---
  [PASS] 连接状态: Approved
  [PASS] 私有 IP 地址: 10.0.2.10 (RFC1918)
  [PASS] 公网端点已禁用 (Microsoft.Storage/storageAccounts)
  [FAIL] DNS 解析不匹配: 20.150.12.34 (应为 10.0.2.10)

======================================================================
合规检查完成
  通过: 2 / 4
  不通过: 2 / 4
  合规率: 50.0%
  报告已保存: /home/admin/PrivateEndpointCompliance_20260326.json
======================================================================
```

合规报告清晰地暴露了两个风险点：`pe-prod-sql` 的 SQL Server 公网端点未禁用，意味着虽然 Private Endpoint 已配置，但数据仍可能通过公网路径被访问，网络隔离形同虚设；`pe-staging-storage` 的 DNS 解析指向公网 IP `20.150.12.34`，说明 Private DNS Zone 配置不完整或 VNet Link 缺失。合规率 50% 表明环境存在明显的配置漂移，建议将此检查集成到 Azure DevOps Pipeline 中，在每次基础设施变更后自动运行。

## 注意事项

1. **子网委派要求**：Private Endpoint 所在的子网必须禁用 `privateEndpointNetworkPolicies` 属性。创建子网时需要显式执行 `Set-AzVirtualNetworkSubnetConfig -PrivateEndpointNetworkPoliciesFlag Disabled`，否则 Private Endpoint 创建会失败。建议在 Terraform 或 Bicep 模板中将此设置标准化。

2. **DNS 解析范围**：Private DNS Zone 的 A 记录仅在关联的 VNet 内生效。如果本地数据中心通过 ExpressRoute 或 VPN 连接到 Azure VNet，需要额外配置 DNS 条件转发器或自定义 DNS 服务器，将 Azure 服务域名转发到 Azure 提供的 DNS 代理（168.63.129.16）进行解析。

3. **连接审批流程**：当 Private Endpoint 的连接请求需要手动审批时，服务提供方会收到 Azure Activity Log 事件。可以使用 `Approve-AzPrivateEndpointConnection` 和 `Deny-AzPrivateEndpointConnection` cmdlet 在脚本中自动处理审批流程，结合 Azure Automation Runbook 实现审批自动化。

4. **配额与限制**：每个 Private Endpoint 占用子网中的一个 IP 地址，单个子网最多支持一定数量的 Private Endpoint（具体取决于子网大小）。此外，每个订阅的 Private Endpoint 数量有默认配额限制，大规模部署前请通过 Azure Portal 提交配额提升请求。

5. **公网端点必须显式禁用**：仅创建 Private Endpoint 并不能阻止公网访问。对于 Storage Account，需要将网络规则集的 `DefaultAction` 设为 `Deny`；对于 SQL Server，需要将 `PublicNetworkAccess` 设为 `Disabled`。合规检查脚本中已包含此验证，建议在 CI/CD 流程中强制执行。

6. **成本考量**：Private Endpoint 按小时计费（约 $0.01/小时），加上数据处理的出入站费用。在大规模部署场景下（数十个 PaaS 服务 + 多个区域），Private Endpoint 成本可能显著增加。建议按环境区分策略——生产环境全面使用 Private Endpoint，开发和测试环境可选择性使用或使用 Service Endpoint 作为替代。
