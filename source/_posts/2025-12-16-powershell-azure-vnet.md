---
layout: post
date: 2025-12-16 08:00:00
updated: 2025-12-16 08:00:00
title: "PowerShell 技能连载 - Azure 虚拟网络管理"
description: PowerTip of the Day - Azure Virtual Network Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- virtualization
- network
---

_适用于 PowerShell 5.1 及以上版本_

Azure 虚拟网络（Virtual Network，简称 VNet）是云端基础设施的基石，所有 Azure 资源之间的通信都建立在虚拟网络之上。无论是虚拟机、应用服务还是数据库，都需要通过 VNet 进行网络隔离与互联。对于运维工程师而言，掌握虚拟网络的创建、子网划分、安全组配置和对等连接等操作，是管理 Azure 环境的必备技能。

在多区域、多订阅的企业级架构中，网络配置的复杂度会迅速攀升。手动在 Azure Portal 中逐个配置子网和规则不仅耗时，还容易出现人为错误。通过 PowerShell 的 `Az.Network` 模块，我们可以将网络配置脚本化，实现版本控制和自动化部署，确保开发、测试、生产各环境的网络拓扑一致。

本文将从零开始演示如何使用 PowerShell 创建虚拟网络、管理子网、配置网络安全组以及建立 VNet 对等连接，帮助你构建一套可复用的网络管理脚本库。

<!-- more -->

## 前置准备：安装模块并连接 Azure

在操作虚拟网络之前，需要确保已安装 `Az` 模块并完成 Azure 认证。`Az.Network` 模块包含在 `Az` 总包中，无需单独安装。如果你在受限环境中只需要网络管理功能，也可以单独安装 `Az.Network`。

```powershell
# 安装 Az 模块（如果尚未安装）
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# 连接 Azure 账户（交互式登录）
Connect-AzAccount

# 查看当前订阅列表，选择目标订阅
$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    Write-Host "名称: $($sub.Name)  ID: $($sub.Id)"
}

# 选择目标订阅
Select-AzSubscription -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 验证当前上下文
Get-AzContext | Select-Object Account, Subscription
```

执行结果示例：

```
名称: Visual Studio Enterprise  ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
名称: Production-Sub            ID: b2c3d4e5-f6a7-8901-bcde-f12345678901

Account           Subscription
-------           ------------
user@example.com  Production-Sub (b2c3d4e5-...)
```

连接成功后，我们就可以开始操作虚拟网络资源了。建议在生产操作前先在测试订阅中验证脚本。

## 创建虚拟网络和子网

虚拟网络的核心概念是地址空间（Address Space）和子网（Subnet）。地址空间定义了整个 VNet 的 IP 范围，子网则是从地址空间中划分出的更小网段，用于隔离不同类型的资源。

下面的脚本演示如何创建一个包含三个子网（前端、后端、数据层）的虚拟网络，这是典型的三层架构网络拓扑。

```powershell
# 定义变量
$resourceGroup = "rg-network-demo"
$location = "EastAsia"
$vnetName = "vnet-demo"
$addressPrefix = "10.0.0.0/16"

# 创建资源组（如果不存在）
$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $resourceGroup -Location $location
    Write-Host "已创建资源组: $resourceGroup"
}

# 定义子网配置
$subnetConfigs = @(
    @{ Name = "snet-frontend"; Prefix = "10.0.1.0/24" }
    @{ Name = "snet-backend";  Prefix = "10.0.2.0/24" }
    @{ Name = "snet-data";     Prefix = "10.0.3.0/24" }
)

# 创建子网配置对象
$subnets = @()
foreach ($config in $subnetConfigs) {
    $subnet = New-AzVirtualNetworkSubnetConfig `
        -Name $config.Name `
        -AddressPrefix $config.Prefix
    $subnets += $subnet
    Write-Host "已准备子网配置: $($config.Name) ($($config.Prefix))"
}

# 创建虚拟网络
$vnet = New-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AddressPrefix $addressPrefix `
    -Subnet $subnets

# 查看创建结果
$vnet | Select-Object Name, Location, AddressSpace
$vnet.Subnets | Select-Object Name, AddressPrefix
```

执行结果示例：

```
已创建资源组: rg-network-demo
已准备子网配置: snet-frontend (10.0.1.0/24)
已准备子网配置: snet-backend (10.0.2.0/24)
已准备子网配置: snet-data (10.0.3.0/24)

Name        Location AddressSpace
----        -------- ------------
vnet-demo   eastasia 10.0.0.0/16

Name           AddressPrefix
----           -------------
snet-frontend  10.0.1.0/24
snet-backend   10.0.2.0/24
snet-data      10.0.3.0/24
```

可以看到，一个地址空间为 `10.0.0.0/16` 的虚拟网络已创建完成，内部包含三个独立的子网。每个子网最多可容纳 251 个可用 IP（扣除 Azure 保留的 5 个地址）。

## 配置网络安全组（NSG）

网络安全组（Network Security Group）是 Azure 中的软件防火墙，通过定义入站和出站规则来控制子网或网络接口级别的流量。在生产环境中，合理的 NSG 规则是保护应用安全的第一道防线。

下面演示如何创建 NSG 并配置常见的安全规则：允许 HTTP/HTTPS 入站、允许 SSH 仅来自特定 IP 段、拒绝所有其他入站流量。

```powershell
# 创建网络安全组
$nsgName = "nsg-frontend"
$nsg = New-AzNetworkSecurityGroup `
    -Name $nsgName `
    -ResourceGroupName $resourceGroup `
    -Location $location

# 允许 HTTP 入站（优先级 100）
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTP" `
    -Description "允许 HTTP 流量" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "10.0.1.0/24" `
    -DestinationPortRange 80

# 允许 HTTPS 入站（优先级 110）
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTPS" `
    -Description "允许 HTTPS 流量" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 110 `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "10.0.1.0/24" `
    -DestinationPortRange 443

# 允许 SSH 仅来自公司 IP 段（优先级 200）
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-SSH-Corp" `
    -Description "允许公司网段 SSH 访问" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix "203.0.113.0/24" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "10.0.1.0/24" `
    -DestinationPortRange 22

# 拒绝所有其他入站流量（优先级 4096）
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Deny-All-Inbound" `
    -Description "拒绝所有其他入站流量" `
    -Access Deny `
    -Protocol "*" `
    -Direction Inbound `
    -Priority 4096 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "*"

# 保存 NSG 配置
$nsg | Set-AzNetworkSecurityGroup

# 将 NSG 关联到前端子网
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
Set-AzVirtualNetworkSubnetConfig `
    -Name "snet-frontend" `
    -VirtualNetwork $vnet `
    -AddressPrefix "10.0.1.0/24" `
    -NetworkSecurityGroup $nsg

$vnet | Set-AzVirtualNetwork

# 查看生效的安全规则
$nsg.SecurityRules | Select-Object Name, Priority, Access, Direction, `
    @{N='Source';E={$_.SourceAddressPrefix}}, `
    @{N='DestPort';E={$_.DestinationPortRange}} |
    Sort-Object Priority |
    Format-Table -AutoSize
```

执行结果示例：

```
Name             Priority Access Direction Source       DestPort
----             -------- ------ --------- ------       --------
Allow-HTTP           100  Allow  Inbound   Internet     80
Allow-HTTPS          110  Allow  Inbound   Internet     443
Allow-SSH-Corp       200  Allow  Inbound   203.0.113.0/24  22
Deny-All-Inbound    4096  Deny   Inbound   *            *
```

NSG 规则按照优先级数字从小到大依次匹配，数字越小优先级越高。一旦匹配到允许或拒绝规则，后续规则不再评估。因此，将最常见的流量规则设为高优先级可以提升网络性能。

## 建立 VNet 对等连接

在实际项目中，不同团队或不同环境往往使用独立的虚拟网络。VNet 对等连接（Peering）允许两个虚拟网络直接通信，流量在 Azure 骨干网上传输，不经过公共互联网，既安全又高效。

下面的脚本在同一个区域内创建两个虚拟网络，并建立双向对等连接。

```powershell
# 创建第二个虚拟网络
$vnet2Name = "vnet-shared"
$vnet2Prefix = "10.1.0.0/16"
$snet2Name = "snet-shared-services"
$snet2Prefix = "10.1.1.0/24"

# 创建子网配置
$subnet2 = New-AzVirtualNetworkSubnetConfig `
    -Name $snet2Name `
    -AddressPrefix $snet2Prefix

# 创建第二个虚拟网络
$vnet2 = New-AzVirtualNetwork `
    -Name $vnet2Name `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AddressPrefix $vnet2Prefix `
    -Subnet $subnet2

Write-Host "已创建虚拟网络: $vnet2Name ($vnet2Prefix)"

# 重新获取两个 VNet 的最新对象
$vnet1 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$vnet2 = Get-AzVirtualNetwork -Name $vnet2Name -ResourceGroupName $resourceGroup

# 添加从 vnet-demo 到 vnet-shared 的对等连接
Add-AzVirtualNetworkPeering `
    -Name "peer-demo-to-shared" `
    -VirtualNetwork $vnet1 `
    -RemoteVirtualNetworkId $vnet2.Id `
    -AllowVirtualNetworkAccess `
    -AllowForwardedTraffic

# 添加从 vnet-shared 到 vnet-demo 的对等连接（双向）
Add-AzVirtualNetworkPeering `
    -Name "peer-shared-to-demo" `
    -VirtualNetwork $vnet2 `
    -RemoteVirtualNetworkId $vnet1.Id `
    -AllowVirtualNetworkAccess `
    -AllowForwardedTraffic

# 验证对等连接状态
$peerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $vnetName -ResourceGroupName $resourceGroup
foreach ($peering in $peerings) {
    Write-Host "对等名称: $($peering.Name)"
    Write-Host "  远程 VNet: $($peering.RemoteVirtualNetwork.Id.Split('/')[-1])"
    Write-Host "  连接状态: $($peering.PeeringState)"
    Write-Host ""
}
```

执行结果示例：

```
已创建虚拟网络: vnet-shared (10.1.0.0/16)

对等名称: peer-demo-to-shared
  远程 VNet: vnet-shared
  连接状态: Connected

对等名称: peer-shared-to-demo
  远程 VNet: vnet-demo
  连接状态: Connected
```

对等连接的状态为 `Connected` 表示双向连接已建立成功。对等连接是双向的，必须分别在两个 VNet 上各添加一条对等配置。如果只添加一端，状态会显示为 `Initiated`。

## 批量查询网络资源

在大型 Azure 环境中，定期审计网络配置是安全合规的重要环节。下面的脚本演示如何批量查询订阅中的所有虚拟网络、子网和 NSG，并生成一份网络拓扑摘要报告。

```powershell
# 获取当前订阅中所有虚拟网络
$vnets = Get-AzVirtualNetwork

$report = @()
foreach ($vnet in $vnets) {
    foreach ($subnet in $vnet.Subnets) {
        $nsgName = "无"
        if ($subnet.NetworkSecurityGroup) {
            $nsgName = $subnet.NetworkSecurityGroup.Id.Split('/')[-1]
        }

        $row = [PSCustomObject]@{
            VNet       = $vnet.Name
            Location   = $vnet.Location
            VNetPrefix = ($vnet.AddressSpace.AddressPrefixes -join ", ")
            Subnet     = $subnet.Name
            SubnetPrefix = $subnet.AddressPrefix
            NSG        = $nsgName
        }
        $report += $row
    }
}

# 按虚拟网络名称排序输出报告
$report | Sort-Object VNet, Subnet | Format-Table -AutoSize

# 统计摘要信息
Write-Host "`n--- 网络资源摘要 ---"
Write-Host "虚拟网络总数: $($vnets.Count)"
Write-Host "子网总数: $(($report).Count)"

# 检查未关联 NSG 的子网（潜在安全风险）
$noNsg = $report | Where-Object { $_.NSG -eq "无" }
if ($noNsg) {
    Write-Host "`n[警告] 以下子网未关联网络安全组:" -ForegroundColor Yellow
    foreach ($item in $noNsg) {
        Write-Host "  - $($item.VNet)/$($item.Subnet)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[OK] 所有子网均已关联网络安全组" -ForegroundColor Green
}
```

执行结果示例：

```
VNet       Location VNetPrefix  Subnet          SubnetPrefix NSG
----       -------- ----------  ------          ------------ ---
vnet-demo  eastasia 10.0.0.0/16 snet-frontend   10.0.1.0/24  nsg-frontend
vnet-demo  eastasia 10.0.0.0/16 snet-backend    10.0.2.0/24  无
vnet-demo  eastasia 10.0.0.0/16 snet-data       10.0.3.0/24  无
vnet-shared eastasia 10.1.0.0/16 snet-shared-services 10.1.1.0/24 无

--- 网络资源摘要 ---
虚拟网络总数: 2
子网总数: 4

[警告] 以下子网未关联网络安全组:
  - vnet-demo/snet-backend
  - vnet-demo/snet-data
  - vnet-shared/snet-shared-services
```

这个审计脚本可以快速发现未配置安全组的子网。在生产环境中，建议将此类脚本集成到定期巡检流程中，或配合 Azure Automation 定时执行。

## 清理示例资源

完成测试后，及时清理资源可以避免产生不必要的费用。以下命令会删除本文创建的所有资源。

```powershell
# 删除资源组及其中的所有资源
Remove-AzResourceGroup -Name $resourceGroup -Force -AsJob

# 查看删除任务状态
Get-Job | Select-Object Name, State
```

执行结果示例：

```
Name           State
----           -----
LongRunningJob Completed
```

`-AsJob` 参数使删除操作在后台执行，适合清理大量资源时使用。删除资源组是不可逆操作，请确保选择了正确的资源组。

## 注意事项

1. **地址空间规划**：创建 VNet 后虽然可以添加新的地址空间，但修改已有子网的地址前缀可能导致连接中断。建议在规划阶段预留足够的 IP 空间，考虑未来扩容需求。

2. **NSG 规则优先级**：Azure 按优先级数字从小到大匹配规则，范围是 100-4096。建议在规则之间预留间隔（如 100、200、300），方便后续插入新规则而无需调整现有优先级。

3. **对等连接不可传递**：如果 VNet A 与 VNet B 对等，VNet B 与 VNet C 对等，VNet A 和 VNet C 之间不会自动互通。需要三方之间各自建立对等连接，或者使用 Azure 防火墙 / VPN 网关进行路由。

4. **子网大小限制**：Azure 在每个子网中保留 5 个 IP 地址不可使用（前 4 个和最后 1 个）。因此一个 `/29` 子网最多只有 3 个可用 IP，规划子网大小时需要考虑这一限制。

5. **跨区域对等延迟**：虽然 VNet 对等连接支持跨区域（Global Peering），但跨区域流量会产生额外费用且延迟略高于同区域对等。对延迟敏感的应用建议部署在同一区域。

6. **幂等性脚本设计**：生产环境中的网络管理脚本应具备幂等性——即多次运行结果一致。在创建资源前先用 `Get-Az*` 检查是否已存在，避免重复创建导致报错。
