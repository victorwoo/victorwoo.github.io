---
layout: post
date: 2025-09-16 08:00:00
title: "PowerShell 技能连载 - Azure 虚拟机管理"
description: PowerTip of the Day - Azure Virtual Machine Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- virtual-machine
- cloud
---

_适用于 PowerShell 5.1 及以上版本_

Azure 虚拟机是云端基础设施的核心服务之一，运维团队日常需要频繁执行创建、启停、扩容和监控等操作。通过 Azure PowerShell 模块（`Az.Compute`），我们可以将这些操作脚本化，实现批量管理和自动化运维，大幅减少手动在门户点击的时间成本。

在生产环境中，虚拟机的生命周期管理远不止简单的开关机。你可能需要根据业务负载动态调整 VM 大小、批量检查所有虚拟机的运行状态、定期清理已解除分配的资源以节省费用。PowerShell 的管道机制和对象模型让这些批量操作变得异常简洁。

本文将演示如何使用 PowerShell 完成 Azure 虚拟机的创建、状态查询、规格调整和批量管理等常见任务，帮助你建立一套可复用的云端运维脚本库。

## 连接 Azure 并选择订阅

在操作虚拟机之前，首先需要连接到 Azure 账户并选择正确的订阅。`Connect-AzAccount` 支持交互式登录和设备码认证，在无浏览器环境（如 CI/CD Runner）中也能正常工作。

```powershell
# 连接 Azure 账户
Connect-AzAccount

# 列出所有可用订阅
$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    Write-Host "名称: $($sub.Name) | ID: $($sub.Id) | 状态: $($sub.State)"
}

# 选择目标订阅
Select-AzSubscription -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

执行结果示例：

```
警告: Interactive authentication is not supported in this session. Please use device code authentication.
请打开浏览器，访问 https://microsoft.com/devicelogin 并输入代码 A1B2C3D4 进行认证。

名称: Visual Studio Enterprise | ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890 | 状态: Enabled
名称: My Production Subscription | ID: 11111111-2222-3333-4444-555555555555 | 状态: Enabled
名称: Free Trial | ID: 99999999-8888-7777-6666-555555555555 | 状态: Disabled

订阅已设置为: My Production Subscription
```

## 创建虚拟机

使用 `New-AzVM` 可以一站式完成虚拟机的创建，包括资源组、网络接口和公共 IP 等配套资源。通过参数可以精确控制 VM 规格、镜像版本和网络配置。

```powershell
# 定义变量
$resourceGroup = "demo-rg"
$location = "eastasia"
$vmName = "demo-vm-001"

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location

# 创建虚拟机
$vmParams = @{
    ResourceGroupName = $resourceGroup
    Name              = $vmName
    Location          = $location
    VirtualNetworkName = "$vmName-vnet"
    SubnetName        = "$vmName-subnet"
    SecurityGroupName = "$vmName-nsg"
    PublicIpAddressName = "$vmName-pip"
    OpenPorts         = 22, 80, 443
    Image             = "Ubuntu2204"
    Size              = "Standard_B2s"
    Credential        = (Get-Credential -UserName "adminuser" -Message "请输入 VM 密码")
}
New-AzVM @vmParams
```

执行结果示例：

```
ResourceGroupName : demo-rg
Location          : eastasia
Name              : demo-vm-001
Type              : Microsoft.Compute/virtualMachines
Tags              : {}
HardwareProfile   : {VmSize}
NetworkProfile    : {NetworkInterfaces}
OSProfile         : {ComputerName, AdminUsername, LinuxConfiguration}
ProvisioningState : Succeeded
Id                : /subscriptions/.../providers/Microsoft.Compute/virtualMachines/demo-vm-001
```

## 查询虚拟机状态

运维中最常见的操作之一是批量查询虚拟机的运行状态。`Get-AzVM` 配合 `-Status` 参数可以获取详细的电源状态信息，方便快速巡检。

```powershell
# 查询单个虚拟机的详细状态
$vm = Get-AzVM -ResourceGroupName "demo-rg" -Name "demo-vm-001" -Status
$powerState = $vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }
Write-Host "虚拟机 demo-vm-001 当前状态: $($powerState.DisplayStatus)"

# 批量查询订阅中所有虚拟机的状态
$allVMs = Get-AzVM -Status
foreach ($machine in $allVMs) {
    $state = $machine.Statuses | Where-Object { $_.Code -like "PowerState/*" }
    $statusText = if ($state) { $state.DisplayStatus } else { "未知" }
    $size = $machine.HardwareProfile.VmSize
    $location = $machine.Location
    Write-Host ("{0,-25} {1,-20} {2,-18} {3}" -f $machine.Name, $statusText, $size, $location)
}
```

执行结果示例：

```
虚拟机 demo-vm-001 当前状态: VM 正在运行

demo-vm-001               VM 正在运行          Standard_B2s       eastasia
web-prod-01               VM 正在运行          Standard_D4s_v3    eastasia
web-prod-02               VM 已解除分配        Standard_D4s_v3    eastasia
db-staging-01              VM 正在运行          Standard_E4s_v3    southeastasia
dev-test-01                VM 已停止            Standard_B2ms      eastus
```

## 调整虚拟机规格

当业务负载发生变化时，需要动态调整虚拟机的 CPU 和内存配置。先停止虚拟机，修改 `HardwareProfile.VmSize`，再更新并重新启动即可。注意某些尺寸变更可能需要先解除分配（Deallocate）。

```powershell
$vmName = "demo-vm-001"
$resourceGroup = "demo-rg"
$newSize = "Standard_D4s_v3"

# 停止并解除分配虚拟机（必须先解除分配才能更改某些规格）
Write-Host "正在停止虚拟机 $vmName ..."
Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force -NoWait

# 等待解除分配完成
$timeout = 300
$elapsed = 0
while ($elapsed -lt $timeout) {
    $status = (Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Status).Statuses
    $powerCode = $status | Where-Object { $_.Code -eq "PowerState/deallocated" }
    if ($powerCode) {
        Write-Host "虚拟机已解除分配"
        break
    }
    Start-Sleep -Seconds 10
    $elapsed += 10
}

# 更新虚拟机规格
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
$oldSize = $vm.HardwareProfile.VmSize
$vm.HardwareProfile.VmSize = $newSize
Update-AzVM -ResourceGroupName $resourceGroup -VM $vm

Write-Host "规格已从 $oldSize 变更为 $newSize"

# 重新启动虚拟机
Start-AzVM -ResourceGroupName $resourceGroup -Name $vmName
```

执行结果示例：

```
正在停止虚拟机 demo-vm-001 ...
虚拟机已解除分配
RequestId IsSuccessStatusCode StatusCode ReasonPhrase
--------- ------------------- ---------- ------------
True      True                OK         OK
规格已从 Standard_B2s 变更为 Standard_D4s_v3

RequestId IsSuccessStatusCode StatusCode ReasonPhrase
--------- ------------------- ---------- ------------
True      True                OK         OK

虚拟机 demo-vm-001 已启动完成
```

## 批量启停虚拟机

在非生产环境或测试环境中，经常需要在下班后批量关闭虚拟机以节省费用，第二天再批量启动。下面的脚本演示如何按标签筛选并执行批量操作。

```powershell
# 批量停止所有带有 Environment: Dev 标签的虚拟机
$devVMs = Get-AzVM | Where-Object {
    $_.Tags.Environment -eq "Dev"
}

Write-Host "找到 $($devVMs.Count) 台开发环境虚拟机"
foreach ($machine in $devVMs) {
    $vmStatus = (Get-AzVM -ResourceGroupName $machine.ResourceGroupName -Name $machine.Name -Status).Statuses
    $isRunning = $vmStatus | Where-Object { $_.Code -eq "PowerState/running" }

    if ($isRunning) {
        Write-Host "正在停止: $($machine.Name)"
        Stop-AzVM -ResourceGroupName $machine.ResourceGroupName -Name $machine.Name -Force -NoWait
    }
    else {
        Write-Host "跳过（未运行）: $($machine.Name)"
    }
}

# 批量启动所有带有 Environment: Dev 标签的虚拟机
foreach ($machine in $devVMs) {
    Write-Host "正在启动: $($machine.Name)"
    Start-AzVM -ResourceGroupName $machine.ResourceGroupName -Name $machine.Name -NoWait
}

Write-Host "`n批量操作已提交，各虚拟机正在后台处理中"
```

执行结果示例：

```
找到 4 台开发环境虚拟机
正在停止: dev-api-01
正在停止: dev-web-01
正在停止: dev-worker-01
跳过（未运行）: dev-db-01

正在启动: dev-api-01
正在启动: dev-web-01
正在启动: dev-worker-01
正在启动: dev-db-01

批量操作已提交，各虚拟机正在后台处理中
```

## 导出虚拟机清单

定期导出虚拟机清单是运维合规审计的基本要求。下面的脚本将所有虚拟机的关键信息整理为结构化数据，并导出为 CSV 文件供后续分析或汇报使用。

```powershell
$report = @()
$allVMs = Get-AzVM

foreach ($machine in $allVMs) {
    $vmStatus = (Get-AzVM -ResourceGroupName $machine.ResourceGroupName -Name $machine.Name -Status).Statuses
    $powerState = ($vmStatus | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

    $osType = $machine.StorageProfile.OsDisk.OsType
    $diskSizeGB = $machine.StorageProfile.OsDisk.DiskSizeGB
    $networkInterfaceId = $machine.NetworkProfile.NetworkInterfaces[0].Id
    $nicName = $networkInterfaceId.Split("/")[-1]
    $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $machine.ResourceGroupName
    $privateIp = $nic.IpConfigurations[0].PrivateIpAddress

    $report += [PSCustomObject]@{
        Name              = $machine.Name
        ResourceGroup     = $machine.ResourceGroupName
        Location          = $machine.Location
        Size              = $machine.HardwareProfile.VmSize
        OSType            = $osType
        OSDiskSizeGB      = $diskSizeGB
        PowerState        = $powerState
        PrivateIP         = $privateIp
        CreatedTime       = $machine.Tags.CreatedTime
        Environment       = $machine.Tags.Environment
        CostCenter        = $machine.Tags.CostCenter
    }
}

# 输出到控制台
$report | Format-Table -AutoSize

# 导出到 CSV
$exportPath = Join-Path $HOME "azure-vm-inventory-$(Get-Date -Format 'yyyyMMdd').csv"
$report | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
Write-Host "清单已导出到: $exportPath"
```

执行结果示例：

```
Name           ResourceGroup Location Size             OSType   OSDiskSizeGB PowerState       PrivateIP    Environment CostCenter
----           ------------- -------- ----             ------   ----------- ----------       ---------    ----------- ----------
demo-vm-001    demo-rg       eastasia Standard_D4s_v3  Linux             30 VM 正在运行     10.0.0.4     Dev         CC-001
web-prod-01    prod-rg       eastasia Standard_D4s_v3  Linux            128 VM 正在运行     10.1.0.4     Production  CC-100
db-staging-01  staging-rg    eastasia Standard_E4s_v3  Windows          512 VM 正在运行     10.2.0.10    Staging     CC-200
dev-api-01     dev-rg        eastus   Standard_B2s     Linux             30 VM 已解除分配   10.3.0.5     Dev         CC-001

清单已导出到: /home/user/azure-vm-inventory-20250916.csv
```

## 注意事项

1. **安装模块**：使用前需安装 `Az` 模块（`Install-Module -Name Az -Scope CurrentUser`），该模块体积较大，首次安装可能需要数分钟。如果只需虚拟机管理功能，可以单独安装 `Az.Compute`。

2. **权限管理**：操作虚拟机需要相应的 RBAC 权限，建议遵循最小权限原则，为不同运维角色分配 `Virtual Machine Contributor`、`Reader` 等细粒度角色，避免使用全局 Owner 权限。

3. **解除分配 vs 停止**：`Stop-AzVM` 默认执行的是"停止"操作，虚拟机仍占用硬件资源并继续计费。加上 `-Force` 参数会执行"解除分配（Deallocate）"，此时不再收取计算费用，仅存储和网络资源继续计费。

4. **规格变更限制**：并非所有 VM 大小之间都可以直接切换，某些硬件代际之间需要先迁移到中间规格。变更前建议用 `Get-AzVMSize -Location $location` 查询目标区域可用规格列表。

5. **脚本幂等性**：批量操作脚本应具备幂等性，即在虚拟机已停止的状态下再次执行停止命令不应报错。可以在执行前先检查当前状态，避免不必要的 API 调用和错误输出。

6. **成本监控**：云环境中最容易忽略的是闲置资源的持续费用。建议配合 `Get-AzConsumptionUsageDetail` 定期审查费用，并设置预算告警，防止测试环境虚拟机长期运行导致账单异常。
