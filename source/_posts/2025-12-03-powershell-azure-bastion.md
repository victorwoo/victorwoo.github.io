---
layout: post
date: 2025-12-03 08:00:00
updated: 2025-12-03 08:00:00
title: "PowerShell 技能连载 - Azure Bastion 远程连接"
description: PowerTip of the Day - Azure Bastion Remote Connections in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure-bastion
- remote-access
- ssh
- security
---

_适用于 PowerShell 5.1 及以上版本_

Azure Bastion 是微软在 Azure 平台上提供的全托管 PaaS 服务，它通过 SSL/TLS 隧道为虚拟机提供安全的 RDP 和 SSH 连接，无需在虚拟机上暴露公共 IP 地址或开放入站端口。在企业混合云环境中，Bastion 充当了"跳板机"的安全替代方案，所有远程会话流量都经过加密且不经过公网，从根本上降低了暴力破解和端口扫描的风险。

传统的远程连接方式要求运维人员先通过 VPN 或跳板机接入内网，再使用 RDP/SSH 客户端连接目标虚拟机。这种方式不仅配置复杂，而且跳板机本身也面临安全威胁。Azure Bastion 将这一流程简化为浏览器直连或 CLI 命令行操作，同时与企业目录服务（Entra ID）深度集成，支持条件访问策略和多因素认证（MFA）。

本文将介绍如何通过 PowerShell 和 Azure CLI 管理 Azure Bastion 资源，包括部署 Bastion 主机、建立远程会话、查看连接会话日志以及批量审计 Bastion 配置。每个场景都提供可执行的代码示例和输出演示。

## 部署 Azure Bastion 主机

Azure Bastion 需要部署在专门的子网（`AzureBastionSubnet`）中，并且要求关联一个 Standard SKU 的公共 IP 地址。以下代码演示了如何通过 PowerShell 在现有虚拟网络中部署 Bastion 主机，包括前置条件的检查和资源创建的完整流程。

```powershell
# 定义变量
$resourceGroup = 'rg-bastion-demo'
$location = 'eastasia'
$vnetName = 'vnet-demo'
$bastionName = 'bastion-demo'
$publicIpName = 'pip-bastion-demo'

# 确保虚拟网络中存在 AzureBastionSubnet 子网
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup

$bastionSubnet = $vnet.Subnets | Where-Object { $_.Name -eq 'AzureBastionSubnet' }

if (-not $bastionSubnet) {
    # Bastion 子网要求至少 /26 的地址空间
    $subnetConfig = Add-AzVirtualNetworkSubnetConfig `
        -Name 'AzureBastionSubnet' `
        -AddressPrefix '10.0.1.0/26' `
        -VirtualNetwork $vnet

    $vnet | Set-AzVirtualNetwork | Out-Null
    Write-Host "已创建 AzureBastionSubnet 子网"
} else {
    Write-Host "AzureBastionSubnet 子网已存在，跳过创建"
}

# 创建 Standard SKU 公共 IP
$publicIp = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroup `
    -Name $publicIpName `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard

Write-Host "公共 IP 已创建: $($publicIp.IpAddress)"

# 创建 Bastion 主机
$bastion = New-AzBastion `
    -ResourceGroupName $resourceGroup `
    -Name $bastionName `
    -PublicIpAddressRgName $resourceGroup `
    -PublicIpAddressName $publicIpName `
    -VirtualNetworkRgName $resourceGroup `
    -VirtualNetworkName $vnetName

Write-Host "Bastion 主机部署完成"
Write-Host "名称: $($bastion.Name)"
Write-Host "SKU: $($bastion.Sku.Text)"
Write-Host "状态: $($bastion.ProvisioningState)"
```

Azure Bastion 的子网名称必须是 `AzureBastionSubnet`，这是一个硬性要求，不能自定义。子网的最小地址空间为 `/26`（64 个地址），因为 Azure 会预留部分地址用于内部服务。Bastion 主机的 SKU 分为 Basic、Standard 和 Developer 三种，Standard 和 Developer SKU 支持自定义端口和原生 SSH 客户端连接。

执行结果示例：

```
AzureBastionSubnet 子网已存在，跳过创建
公共 IP 已创建: 20.205.83.47
Bastion 主机部署完成
名称: bastion-demo
SKU: Standard
状态: Succeeded
```

## 通过 Bastion 建立 SSH 远程会话

Standard 和 Developer SKU 的 Azure Bastion 支持原生 SSH 客户端连接，这意味着可以直接在 PowerShell 终端中发起 SSH 会话，无需打开浏览器。Azure CLI 提供了 `az network bastion ssh` 命令来实现这一功能，以下代码演示了如何封装调用逻辑并管理连接过程。

```powershell
function Connect-BastionSsh {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroup,

        [Parameter(Mandatory)]
        [string]$BastionName,

        [Parameter(Mandatory)]
        [string]$VmName,

        [ValidateSet('aad', 'password', 'ssh-key')]
        [string]$AuthType = 'ssh-key',

        [string]$Username = 'azureuser',

        [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
    )

    Write-Host "正在通过 Bastion 建立 SSH 连接..."
    Write-Host "  Bastion: $BastionName"
    Write-Host "  目标 VM: $VmName"
    Write-Host "  认证方式: $AuthType"

    $commonArgs = @(
        'network', 'bastion', 'ssh',
        '--resource-group', $ResourceGroup,
        '--name', $BastionName,
        '--target-resource-id',
        "/subscriptions/$(Get-AzContext).Subscription.Id/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$VmName",
        '--auth-type', $AuthType,
        '--username', $Username
    )

    if ($AuthType -eq 'ssh-key') {
        $commonArgs += @('--ssh-key', $SshKeyPath)
    }

    # 启动交互式 SSH 会话
    & az @commonArgs
}

# 使用 SSH 密钥认证连接 Linux 虚拟机
Connect-BastionSsh `
    -ResourceGroup 'rg-bastion-demo' `
    -BastionName 'bastion-demo' `
    -VmName 'vm-linux-01' `
    -AuthType 'ssh-key' `
    -Username 'azureuser'
```

这段代码封装了 `Connect-BastionSsh` 函数，支持三种认证方式：Entra ID（AAD）认证、密码认证和 SSH 密钥认证。函数内部通过 Azure CLI 的 `az network bastion ssh` 命令建立隧道，使用 `&` 调用运算符将控制权交给 SSH 客户端，用户可以在交互式会话中执行远程命令。对于 Windows 虚拟机，只需将 `ssh` 替换为 `rdp` 即可通过 RDP 协议连接。

执行结果示例：

```
正在通过 Bastion 建立 SSH 连接...
  Bastion: bastion-demo
  目标 VM: vm-linux-01
  认证方式: ssh-key
Opening SSH session to vm-linux-01 via Bastion bastion-demo...

Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-1019-azure x86_64)

Last login: Wed Dec  3 06:22:15 2025 from 10.0.1.4
azureuser@vm-linux-01:~$
```

## 查看 Bastion 会话日志与连接审计

Azure Bastion 的 Standard 和 Developer SKU 支持将远程会话日志导出到存储账户，这在安全合规场景中非常重要。以下代码演示了如何查询 Bastion 的活跃会话、导出会话日志以及生成连接审计报告。

```powershell
function Get-BastionSessionReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroup,

        [Parameter(Mandatory)]
        [string]$BastionName
    )

    # 获取 Bastion 资源详情
    $bastion = Get-AzBastion -ResourceGroupName $ResourceGroup -Name $BastionName

    $report = [ordered]@{
        BastionName    = $bastion.Name
        Location       = $bastion.Location
        Sku            = $bastion.Sku.Text
        Provisioning   = $bastion.ProvisioningState
        EnableTunneling = $bastion.EnableTunneling
        EnableIpConnect = $bastion.EnableIpConnect
        EnableShareableLink = $bastion.EnableShareableLink
        DnsName        = $bastion.DnsName
    }

    Write-Host "`n===== Bastion 配置报告 ====="
    foreach ($key in $report.Keys) {
        Write-Host ("{0,-25} : {1}" -f $key, $report[$key])
    }

    # 获取 Bastion 关联的虚拟网络信息
    $vnetId = $bastion.IpConfigurations.Subnet.Id -replace '/subnets/.*$', ''
    $vnetName = ($vnetId -split '/')[-1]
    $vnetRg = (($vnetId -split '/')[4])

    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRg
    $bastionSubnet = $vnet.Subnets | Where-Object { $_.Name -eq 'AzureBastionSubnet' }

    Write-Host "`n===== 网络配置 ====="
    Write-Host ("{0,-25} : {1}" -f '关联虚拟网络', $vnetName)
    Write-Host ("{0,-25} : {1}" -f '子网地址范围', $bastionSubnet.AddressPrefix)

    # 列出同一虚拟网络中所有可连接的虚拟机
    $connectedVms = @()
    $allSubnets = $vnet.Subnets | Where-Object { $_.Name -ne 'AzureBastionSubnet' }

    foreach ($subnet in $allSubnets) {
        $nicIds = $subnet.IpConfigurations.Id | ForEach-Object {
            ($_ -split '/ipConfigurations/')[0]
        } | Select-Object -Unique

        foreach ($nicId in $nicIds) {
            $nicName = ($nicId -split '/')[-1]
            $nicRg = (($nicId -split '/')[4])
            $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $nicRg -ErrorAction SilentlyContinue

            if ($nic -and $nic.VirtualMachine) {
                $vmName = ($nic.VirtualMachine.Id -split '/')[-1]
                $vmRg = (($nic.VirtualMachine.Id -split '/')[4])
                $vm = Get-AzVM -Name $vmName -ResourceGroupName $vmRg -ErrorAction SilentlyContinue

                if ($vm) {
                    $osType = if ($vm.StorageProfile.OSDisk.OSType -eq 'Windows') { 'Windows/RDP' } else { 'Linux/SSH' }
                    $connectedVms += [PSCustomObject]@{
                        VmName  = $vmName
                        OsType  = $osType
                        Subnet  = $subnet.Name
                        PrivateIp = ($nic.IpConfigurations | Where-Object { $_.PrivateIpAddress }).PrivateIpAddress
                    }
                }
            }
        }
    }

    Write-Host "`n===== 可连接的虚拟机 ====="
    Write-Host ("{0,-20} {1,-15} {2,-20} {3}" -f 'VM 名称', '操作系统/协议', '子网', '私有 IP')
    Write-Host ('-' * 75)

    foreach ($vm in $connectedVms) {
        Write-Host ("{0,-20} {1,-15} {2,-20} {3}" -f $vm.VmName, $vm.OsType, $vm.Subnet, $vm.PrivateIp)
    }

    return $connectedVms
}

# 生成 Bastion 会话审计报告
Get-BastionSessionReport `
    -ResourceGroup 'rg-bastion-demo' `
    -BastionName 'bastion-demo'
```

这段代码通过 `Get-AzBastion` 获取 Bastion 主机的配置详情，然后遍历关联虚拟网络中除 `AzureBastionSubnet` 以外的所有子网，查找关联的虚拟机并列出其网络信息。通过审计报告可以快速了解哪些虚拟机可以通过 Bastion 访问，以及每台虚拟机的连接协议类型。

执行结果示例：

```
===== Bastion 配置报告 =====
BastionName              : bastion-demo
Location                 : eastasia
Sku                      : Standard
Provisioning             : Succeeded
EnableTunneling          : True
EnableIpConnect          : True
EnableShareableLink      : False
DnsName                  : bst-7a3b2c1d-0001.bastion.azure.com

===== 网络配置 =====
关联虚拟网络             : vnet-demo
子网地址范围             : 10.0.1.0/26

===== 可连接的虚拟机 =====
VM 名称              操作系统/协议   子网                 私有 IP
---------------------------------------------------------------------------
vm-linux-01           Linux/SSH       subnet-workload      10.0.0.4
vm-linux-02           Linux/SSH       subnet-workload      10.0.0.5
vm-win-sql01          Windows/RDP     subnet-database      10.0.2.4
```

## 批量审计多个 Bastion 实例的配置合规性

在大型企业环境中，可能有多个 Azure 订阅和资源组中部署了 Bastion 实例。安全团队需要定期审计所有 Bastion 实例的配置，确保符合企业安全基线。以下代码演示了如何批量检查所有 Bastion 实例的关键配置项。

```powershell
function Test-BastionCompliance {
    [CmdletBinding()]
    param(
        [string[]]$ResourceGroups
    )

    $results = @()

    # 如果未指定资源组，扫描当前订阅中所有 Bastion 实例
    if (-not $ResourceGroups) {
        $allBastions = Get-AzBastion
    } else {
        $allBastions = @()
        foreach ($rg in $ResourceGroups) {
            $allBastions += Get-AzBastion -ResourceGroupName $rg -ErrorAction SilentlyContinue
        }
    }

    Write-Host "发现 $($allBastions.Count) 个 Bastion 实例，开始合规性检查...`n"

    foreach ($bastion in $allBastions) {
        $compliance = [ordered]@{
            Name            = $bastion.Name
            ResourceGroup   = $bastion.ResourceGroupName
            Location        = $bastion.Location
            Sku             = $bastion.Sku.Text
        }

        # 检查项 1: SKU 是否为 Standard 或 Developer
        $skuOk = $bastion.Sku.Text -in @('Standard', 'Developer')
        $compliance['SKU 检查'] = if ($skuOk) { 'PASS' } else { 'WARN: Basic SKU' }

        # 检查项 2: 是否启用隧道模式（支持原生客户端）
        $tunnelOk = $bastion.EnableTunneling -eq $true
        $compliance['原生客户端'] = if ($tunnelOk) { 'PASS' } else { 'WARN: 未启用' }

        # 检查项 3: 是否启用 IP 连接（通过 IP 地址直连）
        $ipConnectOk = $bastion.EnableIpConnect -eq $true
        $compliance['IP 连接'] = if ($ipConnectOk) { 'PASS' } else { 'WARN: 未启用' }

        # 检查项 4: 是否禁用可共享链接（安全考虑）
        $shareOk = $bastion.EnableShareableLink -ne $true
        $compliance['共享链接'] = if ($shareOk) { 'PASS' } else { 'WARN: 已启用' }

        $results += [PSCustomObject]$compliance
    }

    # 输出汇总表格
    Write-Host "===== Bastion 配置合规性报告 ====="
    Write-Host "扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "实例总数: $($results.Count)`n"

    foreach ($item in $results) {
        Write-Host "--- $($item.Name) ($($item.ResourceGroup)) ---"
        Write-Host "  位置: $($item.Location)"
        Write-Host "  SKU: $($item.Sku)"
        Write-Host "  SKU 检查: $($item.'SKU 检查')"
        Write-Host "  原生客户端: $($item.'原生客户端')"
        Write-Host "  IP 连接: $($item.'IP 连接')"
        Write-Host "  共享链接: $($item.'共享链接')"
        Write-Host ""
    }

    # 统计合规率
    $passCount = ($results | Where-Object {
        $_.'SKU 检查' -eq 'PASS' -and
        $_.'原生客户端' -eq 'PASS' -and
        $_.'IP 连接' -eq 'PASS' -and
        $_.'共享链接' -eq 'PASS'
    }).Count

    $total = $results.Count
    $complianceRate = if ($total -gt 0) { [math]::Round(($passCount / $total) * 100, 1) } else { 0 }

    Write-Host "===== 汇总 ====="
    Write-Host "完全合规实例: $passCount / $total"
    Write-Host "合规率: $complianceRate%"

    return $results
}

# 审计指定资源组中的 Bastion 实例
Test-BastionCompliance -ResourceGroups @('rg-bastion-demo', 'rg-prod-network')
```

这段代码定义了 `Test-BastionCompliance` 函数，对每个 Bastion 实例执行四项合规性检查：SKU 级别是否符合要求、是否启用原生客户端隧道、是否启用 IP 直连以及是否禁用了可共享链接。函数输出详细的逐项检查结果和整体合规率统计，方便安全团队快速定位不合规的实例。

执行结果示例：

```
发现 2 个 Bastion 实例，开始合规性检查...

===== Bastion 配置合规性报告 =====
扫描时间: 2025-12-03 10:30:00
实例总数: 2

--- bastion-demo (rg-bastion-demo) ---
  位置: eastasia
  SKU: Standard
  SKU 检查: PASS
  原生客户端: PASS
  IP 连接: PASS
  共享链接: PASS

--- bastion-prod (rg-prod-network) ---
  位置: eastasia
  SKU: Basic
  SKU 检查: WARN: Basic SKU
  原生客户端: WARN: 未启用
  IP 连接: WARN: 未启用
  共享链接: PASS

===== 汇总 =====
完全合规实例: 1 / 2
合规率: 50.0%
```

## 注意事项

- **子网命名不可更改**：Azure Bastion 要求子网名称必须严格为 `AzureBastionSubnet`，且最小地址空间为 `/26`。部署后不能重命名子网，如需调整必须删除并重新创建 Bastion 资源。
- **SKU 功能差异**：Basic SKU 仅支持通过 Azure 门户浏览器连接，不支持原生 SSH 客户端、隧道模式和 IP 连接。建议生产环境使用 Standard 或 Developer SKU，以获得完整的 CLI 自动化能力。
- **部署时间较长**：Bastion 主机的创建通常需要 5-10 分钟，不要在自动化脚本中假设它是即时可用的。建议在部署后通过轮询 `ProvisioningState` 确认资源就绪再发起连接。
- **SSH 密钥路径兼容性**：在 Windows 上默认 SSH 密钥路径为 `$env:USERPROFILE\.ssh\id_rsa`，在 Linux/macOS 上为 `$env:HOME/.ssh/id_rsa`。跨平台脚本中应使用 `Join-Path` 拼接路径，避免硬编码分隔符。
- **会话超时与断连**：Bastion 的浏览器会话有非活动超时限制（通常为 10-20 分钟），原生 SSH 客户端连接则遵循 SSH 协议自身的 `ServerAliveInterval` 设置。建议在 SSH 配置中添加 `ServerAliveInterval 60` 保持连接活跃。
- **成本控制**：Bastion 按小时计费（Standard SKU 约 $0.19/小时，各区域价格不同），无论是否有活跃会话。开发测试环境建议使用 Developer SKU（免费但限制并发连接数），或在不使用时删除 Bastion 资源以节省成本。
