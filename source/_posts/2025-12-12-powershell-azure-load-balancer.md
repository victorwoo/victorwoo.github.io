---
layout: post
date: 2025-12-12 08:00:00
updated: 2025-12-12 08:00:00
title: "PowerShell 技能连载 - Azure 负载均衡器管理"
description: PowerTip of the Day - Azure Load Balancer Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- load-balancer
- networking
- high-availability
---

_适用于 PowerShell 5.1 及以上版本_

在云原生架构中，负载均衡器是保障服务高可用的核心组件。Azure 负载均衡器（Azure Load Balancer）作为 L4 层负载均衡服务，能够在多个虚拟机或实例之间分发入站和出站流量，确保应用在高峰期依然稳定运行。无论是面向互联网的公共服务，还是内部微服务间的通信，负载均衡器都扮演着不可替代的角色。

对于运维工程师而言，手动在 Azure 门户中配置负载均衡器不仅耗时，而且容易出错。通过 PowerShell 的 Az 模块，我们可以将负载均衡器的创建、规则配置、健康探测以及后端池管理全部自动化。这种方式不仅提升了效率，还能将配置纳入版本控制，实现基础设施即代码（IaC）的最佳实践。

本文将围绕 Azure 负载均衡器的日常管理场景，介绍如何使用 PowerShell 完成从创建到监控的完整操作流程，帮助你构建可重复、可审计的负载均衡器管理方案。

## 创建负载均衡器及其前端 IP 配置

在创建负载均衡器之前，需要先准备好资源组和公共 IP 地址。以下代码展示了如何通过 PowerShell 一步到位地创建一个标准 SKU 的负载均衡器，并配置前端 IP 池和后端地址池。

```powershell
# 定义变量
$rgName = "myResourceGroup"
$location = "EastAsia"
$publicIpName = "myLoadBalancerPublicIP"
$lbName = "myLoadBalancer"

# 创建资源组
New-AzResourceGroup -Name $rgName -Location $location

# 创建公共 IP 地址
$publicIp = New-AzPublicIpAddress `
    -ResourceGroupName $rgName `
    -Name $publicIpName `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard

# 创建前端 IP 配置
$frontendIp = New-AzLoadBalancerFrontendIpConfig `
    -Name "myFrontendPool" `
    -PublicIpAddress $publicIp

# 创建后端地址池
$backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
    -Name "myBackendPool"

# 创建负载均衡器
$lb = New-AzLoadBalancer `
    -ResourceGroupName $rgName `
    -Name $lbName `
    -Location $location `
    -Sku Standard `
    -FrontendIpConfiguration $frontendIp `
    -BackendAddressPool $backendPool

Write-Host "负载均衡器 '$lbName' 创建完成"
Write-Host "前端 IP: $($publicIp.IpAddress)"
```

执行结果示例：

```
ResourceGroupName : myResourceGroup
Location          : eastasia
ProvisioningState : Succeeded
Sku               : Standard
Name              : myLoadBalancer

负载均衡器 'myLoadBalancer' 创建完成
前端 IP: 20.205.12.34
```

创建完成后，负载均衡器还只是一个空壳。接下来需要添加健康探测和负载均衡规则，才能真正开始分发流量。

## 配置健康探测与负载均衡规则

健康探测（Health Probe）用于定期检测后端实例的可用性。只有通过探测的实例才会接收流量。负载均衡规则则定义了前端端口到后端端口的映射关系以及分发策略。

```powershell
$rgName = "myResourceGroup"
$lbName = "myLoadBalancer"
$lb = Get-AzLoadBalancer -ResourceGroupName $rgName -Name $lbName

# 添加 HTTP 健康探测
$probe = Add-AzLoadBalancerProbeConfig `
    -LoadBalancer $lb `
    -Name "httpProbe" `
    -Protocol Http `
    -Port 80 `
    -RequestPath "/" `
    -IntervalInSeconds 15 `
    -ProbeCount 2

# 添加 TCP 负载均衡规则（将前端 80 端口映射到后端 80 端口）
$rule = Add-AzLoadBalancerRuleConfig `
    -LoadBalancer $lb `
    -Name "httpRule" `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 80 `
    -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
    -BackendAddressPool $lb.BackendAddressPools[0] `
    -Probe $lb.Probes[0] `
    -LoadDistribution Default `
    -IdleTimeoutInMinutes 4 `
    -EnableFloatingIp $false

# 将配置写入 Azure
Set-AzLoadBalancer -LoadBalancer $lb

Write-Host "健康探测和负载均衡规则配置完成"
```

执行结果示例：

```
Name              : myLoadBalancer
ResourceGroupName : myResourceGroup
Probes            : {httpProbe}
LoadBalancingRules: {httpRule}
ProvisioningState : Succeeded

健康探测和负载均衡规则配置完成
```

这里有几个关键参数值得注意：`IntervalInSeconds` 设置为 15 秒表示每 15 秒探测一次；`ProbeCount` 设为 2 意味着连续两次探测失败后才会将实例标记为不健康。`LoadDistribution` 使用 `Default` 表示五元组哈希分发策略，适合大多数 Web 场景。

## 管理后端池与监控实例健康状态

后端池的管理是日常运维中最常见的操作。下面展示如何将虚拟机添加到后端池，以及如何查询各实例的健康状态。

```powershell
$rgName = "myResourceGroup"
$lbName = "myLoadBalancer"
$lb = Get-AzLoadBalancer -ResourceGroupName $rgName -Name $lbName

# 获取要加入后端池的虚拟机网络接口
$vmNames = @("myVM01", "myVM02", "myVM03")
$backendPool = $lb.BackendAddressPools[0]

foreach ($vmName in $vmNames) {
    $nic = Get-AzNetworkInterface |
        Where-Object { $_.VirtualMachine.Id -like "*$vmName*" }

    if ($nic) {
        $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $backendPool
        Set-AzNetworkInterface -NetworkInterface $nic
        Write-Host "已将 '$vmName' 加入后端池"
    } else {
        Write-Host "警告: 未找到虚拟机 '$vmName' 的网络接口" -ForegroundColor Yellow
    }
}

# 查询负载均衡器后端健康状态
$health = Get-AzLoadBalancerBackendAddressPool `
    -ResourceGroupName $rgName `
    -LoadBalancerName $lbName `
    -Name "myBackendPool"

Write-Host "`n后端池当前配置:"
Write-Host "名称: $($health.Name)"
Write-Host "关联的网络接口数: $($health.NetworkInterfaces.Count)"
```

执行结果示例：

```
已将 'myVM01' 加入后端池
已将 'myVM02' 加入后端池
已将 'myVM03' 加入后端池

后端池当前配置:
名称: myBackendPool
关联的网络接口数: 3
```

通过 `foreach` 循环批量操作，可以轻松管理后端池中的实例。在生产环境中，建议将这段逻辑封装为可参数化的函数，方便在扩容或缩容时快速调用。

## 查询负载均衡器指标与运行状态

除了配置管理，监控负载均衡器的运行指标同样重要。以下代码通过 `Get-AzMetric` cmdlet 查询负载均衡器的流量指标，帮助你了解流量分布是否均匀。

```powershell
$rgName = "myResourceGroup"
$lbName = "myLoadBalancer"

$lb = Get-AzLoadBalancer -ResourceGroupName $rgName -Name $lbName

# 查询过去 1 小时的 SYN 计数（新建连接数）指标
$endTime = Get-Date
$startTime = $endTime.AddHours(-1)

$metrics = Get-AzMetric `
    -ResourceId $lb.Id `
    -MetricName "SynCount" `
    -StartTime $startTime `
    -EndTime $endTime `
    -TimeGrain 00:05:00 `
    -AggregationType Total

Write-Host "负载均衡器 SYN 计数（过去 1 小时，每 5 分钟采样）:"
Write-Host ("{0,-25} {1,15}" -f "时间", "SYN 计数")
Write-Host ("{0,-25} {1,15}" -f "----", "--------")

foreach ($ts in $metrics.Data) {
    $timeStr = $ts.TimeStamp.ToString("yyyy-MM-dd HH:mm:ss")
    $synCount = if ($ts.Total) { [math]::Round($ts.Total, 0) } else { 0 }
    Write-Host ("{0,-25} {1,15}" -f $timeStr, $synCount)
}

# 获取 NAT 规则列表
$lb = Get-AzLoadBalancer -ResourceGroupName $rgName -Name $lbName
$inboundNatRules = $lb.InboundNatRules

if ($inboundNatRules) {
    Write-Host "`n入站 NAT 规则:"
    foreach ($rule in $inboundNatRules) {
        Write-Host "  规则名称: $($rule.Name)"
        Write-Host "  前端端口: $($rule.FrontendPort) -> 后端端口: $($rule.BackendPort)"
        Write-Host "  协议: $($rule.Protocol)"
        Write-Host ""
    }
} else {
    Write-Host "`n当前未配置入站 NAT 规则"
}
```

执行结果示例：

```
负载均衡器 SYN 计数（过去 1 小时，每 5 分钟采样）:
时间                           SYN 计数
----                           --------
2025-12-12 07:00:00                  142
2025-12-12 07:05:00                  158
2025-12-12 07:10:00                  163
2025-12-12 07:15:00                  151
2025-12-12 07:20:00                  147
2025-12-12 07:25:00                  172
2025-12-12 07:30:00                  189
2025-12-12 07:35:00                  195
2025-12-12 07:40:00                  210
2025-12-12 07:45:00                  198
2025-12-12 07:50:00                  183
2025-12-12 07:55:00                  176

当前未配置入站 NAT 规则
```

通过定期采集这些指标数据，你可以建立流量基线，在流量异常时及时发现并响应。结合 Azure Monitor 告警规则，还可以实现自动化的运维通知。

## 注意事项

1. **SKU 选择**：Azure 负载均衡器有 Basic 和 Standard 两种 SKU。生产环境务必使用 Standard SKU，它支持可用性区域、更高的 SLA（99.99%）以及更精细的安全控制。Basic SKU 已不推荐用于生产环境。

2. **健康探测参数调优**：`IntervalInSeconds` 和 `ProbeCount` 的组合决定了故障检测的灵敏度。过于激进的配置（如间隔 5 秒、计数 1）可能导致瞬时抖动误判；过于保守的配置（如间隔 30 秒、计数 5）则会让故障实例长时间接收流量。建议从 15 秒间隔、2 次失败阈值开始，根据业务特点调整。

3. **负载分发策略**：`LoadDistribution` 参数有三种取值：`Default`（五元组哈希）、`SourceIP`（二元组哈希）、`SourceIPProtocol`（三元组哈希）。对于需要会话保持的场景（如 WebSocket 长连接），考虑使用 `SourceIPProtocol`；对于一般 Web 流量，`Default` 即可。

4. **后端池操作幂等性**：修改后端池配置时，`Set-AzLoadBalancer` 会整体替换配置。务必先 `Get-AzLoadBalancer` 获取最新状态，在现有对象上修改后再写回，避免覆盖其他并发的配置变更。

5. **公共 IP 与 SKU 匹配**：Standard SKU 的负载均衡器必须搭配 Standard SKU 的公共 IP 地址。如果尝试使用 Basic SKU 的公共 IP，创建时会报错。这一点在脚本变量初始化阶段就要确保一致。

6. **权限与模块版本**：运行本文中的脚本需要安装 `Az.Network` 模块（4.0 或更高版本），且当前账户需要在资源组上拥有 `Network Contributor` 或更高权限。使用 `Get-InstalledModule -Name Az.Network` 检查模块版本，必要时通过 `Update-Module Az.Network` 升级。
