---
layout: post
date: 2026-03-13 08:00:00
updated: 2026-03-13 08:00:00
title: "PowerShell 技能连载 - Azure Virtual Desktop 管理"
description: PowerTip of the Day - Azure Virtual Desktop Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- avd
- virtual-desktop
- remote-desktop
---

_适用于 PowerShell 7.0 及以上版本，需要 Az.DesktopVirtualization 模块_

## 背景

Azure Virtual Desktop（AVD）是微软在 Azure 上托管的桌面和应用虚拟化服务，为企业提供了集中管理、弹性扩展的远程办公解决方案。随着混合办公模式的普及，越来越多的企业选择 AVD 来统一管理员工桌面环境，降低终端设备运维成本，同时满足数据安全与合规要求。

对于 IT 运维团队来说，AVD 的日常管理涉及主机池创建、会话主机扩缩容、用户会话监控与故障排查等多个环节。虽然 Azure Portal 提供了图形界面，但在批量操作、自动化流水线和 CI/CD 场景中，PowerShell 脚本依然是最高效的手段。微软提供的 `Az.DesktopVirtualization` 模块覆盖了 AVD 几乎全部管理操作，让我们可以用脚本实现从创建到运维的全生命周期管理。

本文将介绍三个典型的 AVD 管理场景：主机池与工作区配置、会话主机扩缩容、以及用户会话管理与诊断。每个场景都附带可直接运行的 PowerShell 脚本示例。

## AVD 主机池与工作区管理

主机池（Host Pool）是 AVD 的核心资源，定义了一组提供桌面或远程应用的虚拟机。工作区（Workspace）则是将应用组呈现给用户的逻辑容器。下面的脚本演示如何一步到位地创建主机池、配置应用组，并将其注册到工作区。

```powershell
# 安装并导入 AVD 管理模块
Install-Module -Name Az.DesktopVirtualization -Force -Scope CurrentUser
Import-Module Az.DesktopVirtualization

# 连接到 Azure 账户
Connect-AzAccount

# 定义变量
$ResourceGroup = "rg-avd-prod"
$Location      = "eastasia"
$HostPoolName  = "hp-desktop-prod"
$WorkspaceName = "ws-prod"

# 确保资源组存在
$rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
    Write-Host "已创建资源组: $ResourceGroup"
}

# 创建主机池（池化桌面，深度优先负载均衡）
$hostPool = New-AzWvdHostPool `
    -ResourceGroupName $ResourceGroup `
    -Name $HostPoolName `
    -Location $Location `
    -HostPoolType Pooled `
    -LoadBalancerType DepthFirst `
    -PreferredAppGroupType Desktop `
    -MaxSessionLimit 10 `
    -ValidationEnv:$false

Write-Host "主机池已创建: $($hostPool.Name)"

# 创建桌面应用组（自动随主机池创建）
$appGroup = Get-AzWvdDesktop -ResourceGroupName $ResourceGroup `
    -HostPoolName $HostPoolName

# 创建工作区并注册桌面应用组
$workspace = New-AzWvdWorkspace `
    -ResourceGroupName $ResourceGroup `
    -Name $WorkspaceName `
    -Location $Location

Register-AzWvdApplicationGroup `
    -ResourceGroupName $ResourceGroup `
    -WorkspaceName $WorkspaceName `
    -ApplicationGroupPath $appGroup.Id

Write-Host "工作区已创建并注册桌面应用组: $($workspace.Name)"
```

执行结果示例：

```
已创建资源组: rg-avd-prod
主机池已创建: hp-desktop-prod
工作区已创建并注册桌面应用组: ws-prod
```

创建完成后，可以在 Azure Portal 中看到主机池和工作区已关联。用户通过 AVD 客户端登录时，工作区中的应用组会自动呈现为可用的桌面会话。

## 会话主机管理与扩缩容

主机池创建后，需要向其中添加会话主机（Session Host）——也就是实际运行用户桌面的 Azure 虚拟机。在生产环境中，根据负载自动扩缩容是控制成本的关键。以下脚本展示了手动添加会话主机以及配置自动扩缩方案。

```powershell
# 查看当前主机池中的会话主机
$ResourceGroup = "rg-avd-prod"
$HostPoolName  = "hp-desktop-prod"

$sessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroup `
    -HostPoolName $HostPoolName

$sessionHosts | Format-Table Name, Status, Sessions, AllowNewSession -AutoSize

# 为会话主机开启 Drain 模式（禁止新会话接入，便于维护）
$drainHost = "hp-desktop-prod/avd-vm-001"
Update-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroup `
    -HostPoolName $HostPoolName `
    -Name $drainHost `
    -AllowNewSession:$false

Write-Host "已对 $drainHost 启用 Drain 模式"

# 配置自动扩缩计划（基于时间段调整最大/最小主机数）
$scalingPlan = New-AzWvdScalingPlan `
    -ResourceGroupName $ResourceGroup `
    -Name "scaling-weekday" `
    -Location "eastasia" `
    -TimeZone "China Standard Time" `
    -Schedule @(
        @{
            name                         = "weekday-workhours"
            daysOfWeek                   = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
            rampUpStartTime              = @{ hour = 8; minute = 0 }
            rampUpLoadBalancingAlgorithm = "BreadthFirst"
            rampUpMinimumHostsPct        = 30
            rampUpCapacityThresholdPct   = 60
            peakStartTime                = @{ hour = 9; minute = 0 }
            peakLoadBalancingAlgorithm   = "DepthFirst"
            rampDownStartTime            = @{ hour = 18; minute = 0 }
            rampDownLoadBalancingAlgorithm = "DepthFirst"
            rampDownMinimumHostsPct      = 10
            rampDownCapacityThresholdPct = 90
            rampDownForceLogoffUsers     = $false
            offPeakStartTime             = @{ hour = 20; minute = 0 }
            offPeakLoadBalancingAlgorithm = "DepthFirst"
        }
    )

# 将扩缩计划关联到主机池
$hostPool = Update-AzWvdHostPool `
    -ResourceGroupName $ResourceGroup `
    -Name $HostPoolName `
    -ScalingPlanId $scalingPlan.Id

Write-Host "自动扩缩计划已关联到主机池: $HostPoolName"
```

执行结果示例：

```
Name                                            Status  Sessions AllowNewSession
----                                            ------  -------- ---------------
hp-desktop-prod/avd-vm-001                      Available 3       True
hp-desktop-prod/avd-vm-002                      Available 5       True
hp-desktop-prod/avd-vm-003                      Available 2       True

已对 hp-desktop-prod/avd-vm-001 启用 Drain 模式
自动扩缩计划已关联到主机池: hp-desktop-prod
```

Drain 模式是维护窗口的必备操作——开启后该主机不再接受新会话，但已连接的用户不受影响。运维人员可以等待现有会话自然结束，或通知用户保存工作后手动注销，再对虚拟机执行补丁更新。自动扩缩计划则根据工作时间段自动调整主机数量，避免夜间空闲虚拟机持续产生费用。

## 用户会话管理与故障排查

当用户报告远程桌面连接异常时，快速定位问题是运维效率的关键。`Az.DesktopVirtualization` 模块提供了会话查询、断开连接、强制注销等操作，结合诊断功能可以大幅缩短故障响应时间。

```powershell
# 查看主机池中所有活跃会话
$ResourceGroup = "rg-avd-prod"
$HostPoolName  = "hp-desktop-prod"

$userSessions = Get-AzWvdUserSession `
    -ResourceGroupName $ResourceGroup `
    -HostPoolName $HostPoolName

$userSessions | Format-Table `
    @{N="用户";E={$_.ActiveDirectoryUserName}}, `
    @{N="会话主机";E={($_.Name -split "/")[1]}}, `
    @{N="会话状态";E={$_.SessionState}}, `
    @{N="创建时间";E={$_.CreateTime}} `
    -AutoSize

# 查找特定用户的会话
$targetUser = "user01@vichamp.com"
$targetSession = $userSessions | Where-Object {
    $_.ActiveDirectoryUserName -eq $targetUser
}

if ($targetSession) {
    Write-Host "找到用户会话: $($targetSession.Name)"

    # 断开用户会话（不注销，用户可重新连接）
    Remove-AzWvdUserSession `
        -ResourceGroupName $ResourceGroup `
        -HostPoolName $HostPoolName `
        -SessionHostName ($targetSession.Name -split "/")[1] `
        -Id ($targetSession.Name -split "/")[2] `
        -Force

    Write-Host "已断开用户 $targetUser 的会话"
} else {
    Write-Host "未找到用户 $targetUser 的活跃会话"
}

# 获取主机池诊断信息
$diagnostic = Get-AzWvdHostPool `
    -ResourceGroupName $ResourceGroup `
    -Name $HostPoolName

# 检查各会话主机的运行状态
foreach ($host in (Get-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroup `
    -HostPoolName $HostPoolName)) {

    $vmName = ($host.Name -split "/")[1]
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $vmName -Status

    $powerState = ($vm.Statuses | Where-Object {
        $_.Code -match "PowerState"
    }).DisplayStatus

    Write-Host ("{0,-25} AVD状态: {1,-12} VM电源: {2,-12} 会话数: {3}" -f `
        $vmName, $host.Status, $powerState, $host.Sessions)
}
```

执行结果示例：

```
用户                      会话主机         会话状态  创建时间
----                      ----         --------  --------
user01@vichamp.com        avd-vm-001   Active    2026-03-13T09:15:22Z
user02@vichamp.com        avd-vm-001   Active    2026-03-13T09:32:45Z
user03@vichamp.com        avd-vm-002   Active    2026-03-13T10:01:33Z

找到用户会话: hp-desktop-prod/avd-vm-001/user01@vichamp.com
已断开用户 user01@vichamp.com 的会话

avd-vm-001                AVD状态: Available  VM电源: VM running    会话数: 4
avd-vm-002                AVD状态: Available  VM电源: VM running    会话数: 6
avd-vm-003                AVD状态: Available  VM电源: VM running    会话数: 2
```

会话查询和诊断是排查 AVD 问题的第一步。当用户反馈桌面卡顿或无法连接时，先检查会话状态和主机负载，再决定是断开会话、注销用户还是扩容主机池，形成标准化的故障处理流程。

## 注意事项

1. **模块版本兼容性**：`Az.DesktopVirtualization` 模块更新频繁，建议定期执行 `Update-Module Az.DesktopVirtualization` 获取最新功能和修复。部分 cmdlet 在不同版本间参数名称可能有变化，升级后需回归测试现有脚本。

2. **权限要求**：执行 AVD 管理操作需要 Azure RBAC 角色授权。推荐使用"Desktop Virtualization Contributor"内置角色，而非 Owner，以遵循最小权限原则。生产环境中应通过 Azure PIM（Privileged Identity Management）实现即时提权。

3. **Drain 模式使用时机**：在执行安全补丁、应用更新或故障排查前，务必先开启 Drain 模式。注意 `AllowNewSession:$false` 只阻止新连接，不会断开已有会话。如需强制迁移用户，应先通知用户保存工作，再使用 `Remove-AzWvdUserSession` 注销。

4. **自动扩缩计划配置**：扩缩计划的 `rampUpMinimumHostsPct` 参数决定了启动阶段最少开启的主机百分比，设置过低会导致用户在高峰时段排队等待；设置过高则增加闲置成本。建议根据历史负载数据调优，并利用 AVD Insights 监控仪表盘持续观察效果。

5. **会话主机网络要求**：AVD 会话主机必须加入 Azure AD（或 Microsoft Entra ID）域，并开通到 AVD 控制平面的出站 HTTPS（443 端口）连接。如果使用自定义 VNet，需确保 DNS 解析和网络安全组规则正确配置，否则主机注册会失败。

6. **诊断日志**：建议在主机池上启用 Azure Monitor 诊断设置，将连接日志、错误日志、管理日志发送到 Log Analytics 工作区。结合 KQL 查询可以实现连接失败告警、用户登录趋势分析等高级运维场景，大幅缩短 MTTR（平均恢复时间）。
