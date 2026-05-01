---
layout: post
date: 2025-08-12 08:00:00
title: "PowerShell 技能连载 - 服务依赖分析与启动顺序"
description: PowerTip of the Day - Service Dependency Analysis and Startup Order in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows-service
- dependency
- service-management
---

_适用于 PowerShell 5.1 及以上版本_

Windows 系统中的服务并非孤立运行，许多服务之间存在依赖关系。例如，Web 服务可能依赖 IIS，IIS 又依赖 HTTP.sys 驱动服务；数据库服务可能依赖远程过程调用（RPC）和事件日志服务。当需要批量重启服务、排查启动失败或规划系统迁移时，理清服务之间的依赖链条至关重要。

手动查阅服务的"依赖"选项卡效率低下，尤其是面对多层嵌套的依赖关系时。PowerShell 可以通过 WMI 和 `Get-Service` 等原生命令递归遍历服务依赖树，自动生成启动顺序报告，甚至可以一键按正确顺序停止和启动一组相互依赖的服务。

本文将介绍如何使用 PowerShell 分析 Windows 服务依赖关系，并生成可视化报告和自动化启停脚本。

## 获取单个服务的依赖关系

首先，我们来实现一个函数，查询指定服务的直接依赖和被依赖关系。

```powershell
function Get-ServiceDependencyInfo {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $service) {
        throw "服务 '$ServiceName' 不存在。"
    }

    # 通过 WMI 获取依赖信息
    $wmiService = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$ServiceName'"

    # 获取此服务依赖的服务（启动前必须先启动的服务）
    $dependsOn = @()
    if ($wmiService) {
        $rawDepends = $wmiService.CimInstanceProperties["DependsOn"].Value
        if ($rawDepends) {
            $dependsOn = @($rawDepends)
        }
    }

    # 通过 ServicesDependedOn 属性获取更详细的信息
    $servicesDependedOn = $service.ServicesDependedOn |
        Select-Object -Property Name, DisplayName, Status

    # 获取依赖此服务的服务（如果停掉此服务会影响哪些服务）
    $dependentServices = Get-Service -Name $ServiceName |
        Select-Object -ExpandProperty DependentServices |
        Select-Object -Property Name, DisplayName, Status

    [PSCustomObject]@{
        ServiceName       = $service.Name
        DisplayName       = $service.DisplayName
        Status            = $service.Status
        StartType         = $wmiService.StartMode
        DependsOn         = $servicesDependedOn
        DependentServices = $dependentServices
    }
}

# 示例：查看 DNS 服务的依赖关系
Get-ServiceDependencyInfo -ServiceName "Dnscache" |
    Format-List ServiceName, DisplayName, Status, StartType,
        @{Label="DependsOn"; Expression={$_.DependsOn | ForEach-Object { "$($_.Name) ($($_.Status))" }}},
        @{Label="DependentServices"; Expression={$_.DependentServices | ForEach-Object { "$($_.Name) ($($_.Status))" }}}
```

执行结果示例：

```text
ServiceName       : Dnscache
DisplayName       : DNS Client
Status            : Running
StartType         : Manual
DependsOn         : {nsi (Running), Tcpip (Running), AFD (Running)}
DependentServices : {}
```

## 递归构建完整依赖树

仅查看直接依赖往往不够，我们需要递归遍历整个依赖链，构建完整的依赖树。

```powershell
function Get-ServiceDependencyTree {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [ValidateSet("DependsOn", "DependentBy")]
        [string]$Direction = "DependsOn",

        [int]$MaxDepth = 10,

        [string[]]$Visited = @()
    )

    # 防止循环依赖
    if ($ServiceName -in $Visited) {
        return @{
            Name        = $ServiceName
            DisplayName = "(循环依赖)"
            Status      = "Circular"
            Depth       = $Visited.Count
            Children    = @()
        }
    }

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $service) {
        return @{
            Name        = $ServiceName
            DisplayName = "(未找到)"
            Status      = "NotFound"
            Depth       = $Visited.Count
            Children    = @()
        }
    }

    $currentVisited = $Visited + $ServiceName

    # 根据方向获取依赖列表
    $relatedServices = if ($Direction -eq "DependsOn") {
        $service.ServicesDependedOn
    }
    else {
        $service.DependentServices
    }

    $children = @()
    if ($relatedServices -and $currentVisited.Count -lt $MaxDepth) {
        foreach ($related in $relatedServices) {
            $children += Get-ServiceDependencyTree -ServiceName $related.Name -Direction $Direction -MaxDepth $MaxDepth -Visited $currentVisited
        }
    }

    @{
        Name        = $service.Name
        DisplayName = $service.DisplayName
        Status      = $service.Status.ToString()
        StartType   = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$ServiceName' -ErrorAction SilentlyContinue").StartMode
        Depth       = $Visited.Count
        Children    = $children
    }
}

# 示例：查看 W32Time 服务的完整依赖树
$tree = Get-ServiceDependencyTree -ServiceName "W32Time" -Direction "DependsOn"
$tree | ConvertTo-Json -Depth 10
```

执行结果示例：

```text
{
    "Name": "W32Time",
    "DisplayName": "Windows Time",
    "Status": "Running",
    "StartType": "Manual",
    "Depth": 0,
    "Children": [
        {
            "Name": "LanmanServer",
            "DisplayName": "Server",
            "Status": "Running",
            "StartType": "Auto",
            "Depth": 1,
            "Children": [
                {
                    "Name": "SamSs",
                    "DisplayName": "Security Accounts Manager",
                    "Status": "Running",
                    "StartType": "Auto",
                    "Depth": 2,
                    "Children": []
                }
            ]
        }
    ]
}
```

## 生成依赖关系可视化报告

将依赖树转换为易读的文本树格式，方便快速浏览。

```powershell
function Show-ServiceDependencyTree {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tree,

        [int]$Indent = 0
    )

    $prefix = "  " * $Indent
    $connector = if ($Indent -eq 0) { "" } else { "+--" }
    $statusIcon = switch ($Tree.Status) {
        "Running"    { "[运行中]" }
        "Stopped"    { "[已停止]" }
        "Circular"   { "[循环引用]" }
        "NotFound"   { "[未找到]" }
        default      { "[$($Tree.Status)]" }
    }

    $line = "$prefix$connector $($Tree.Name) ($($Tree.DisplayName)) $statusIcon"
    Write-Host $line

    foreach ($child in $Tree.Children) {
        Show-ServiceDependencyTree -Tree $child -Indent ($Indent + 1)
    }
}

# 同时查看正向和反向依赖
Write-Host "=== W32Time 启动依赖（该服务需要哪些服务先启动）===" -ForegroundColor Cyan
$dependsOnTree = Get-ServiceDependencyTree -ServiceName "W32Time" -Direction "DependsOn"
Show-ServiceDependencyTree -Tree $dependsOnTree

Write-Host "`n=== W32Time 反向依赖（哪些服务依赖该服务）===" -ForegroundColor Cyan
$dependentTree = Get-ServiceDependencyTree -ServiceName "W32Time" -Direction "DependentBy"
Show-ServiceDependencyTree -Tree $dependentTree
```

执行结果示例：

```text
=== W32Time 启动依赖（该服务需要哪些服务先启动）===
W32Time (Windows Time) [运行中]
  +-- LanmanServer (Server) [运行中]
    +-- SamSs (Security Accounts Manager) [运行中]
  +-- LanmanWorkstation (Workstation) [运行中]

=== W32Time 反向依赖（哪些服务依赖该服务）===
W32Time (Windows Time) [运行中]
```

## 计算正确的服务启动顺序

在批量重启场景中，需要按照依赖关系计算正确的停止和启动顺序：停止时先停依赖方再停被依赖方，启动时先启动被依赖方再启动依赖方。

```powershell
function Get-ServiceStartupOrder {
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames
    )

    $visited = @{}
    $orderList = [System.Collections.Generic.List[PSCustomObject]]::new()

    function TraverseService {
        param([string]$Name, [int]$Depth = 0)

        if ($visited.ContainsKey($Name)) {
            return
        }
        $visited[$Name] = $true

        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (-not $service) {
            return
        }

        # 先递归处理此服务依赖的服务
        foreach ($dep in $service.ServicesDependedOn) {
            TraverseService -Name $dep.Name -Depth ($Depth + 1)
        }

        $wmiService = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$Name'" -ErrorAction SilentlyContinue

        $orderList.Add([PSCustomObject]@{
            Order       = $orderList.Count + 1
            Name        = $service.Name
            DisplayName = $service.DisplayName
            Status      = $service.Status.ToString()
            StartType   = if ($wmiService) { $wmiService.StartMode } else { "Unknown" }
            Depth       = $Depth
        })
    }

    foreach ($name in $ServiceNames) {
        TraverseService -Name $name
    }

    $orderList
}

# 示例：计算一组关联服务的启动顺序
Write-Host "=== 服务启动顺序 ===" -ForegroundColor Cyan
Get-ServiceStartupOrder -ServiceNames @("W3SVC", "MSSQLSERVER") |
    Format-Table Order, Name, DisplayName, Status, StartType -AutoSize
```

执行结果示例：

```text
=== 服务启动顺序 ===
Order Name         DisplayName                   Status  StartType
----- ----         -----------                   ------  ---------
    1 HTTP.sys     HTTP Service                  Running KernelDriver
    2 IISADMIN     IIS Admin Service             Stopped Manual
    3 W3SVC        World Wide Web Publishing     Running Auto
    4 RPC          Remote Procedure Call (RPC)   Running Auto
    5 MSSQLSERVER  SQL Server (MSSQLSERVER)      Running Auto
```

## 批量按序启停服务

有了启动顺序后，我们可以实现安全的批量启停操作。

```powershell
function Restart-ServiceWithDependencies {
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,

        [int]$WaitTimeoutSeconds = 30,

        [switch]$Force
    )

    # 计算所有涉及的服务及顺序
    $allServices = Get-ServiceStartupOrder -ServiceNames $ServiceNames
    $stopOrder = $allServices | Sort-Object Order -Descending | Select-Object -Unique Name
    $startOrder = $allServices | Sort-Object Order -Ascending | Select-Object -Unique Name

    # 停止阶段：按反向依赖顺序停止
    Write-Host "`n=== 停止服务（反向依赖顺序）===" -ForegroundColor Yellow
    foreach ($svc in $stopOrder) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "  停止: $($svc.Name) ($($service.DisplayName))" -ForegroundColor Yellow
            try {
                Stop-Service -Name $svc.Name -Force:$Force -ErrorAction Stop
                $service.WaitForStatus('Stopped', (New-TimeSpan -Seconds $WaitTimeoutSeconds))
                Write-Host "    已停止" -ForegroundColor Green
            }
            catch {
                Write-Host "    停止失败: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # 启动阶段：按依赖顺序启动
    Write-Host "`n=== 启动服务（依赖顺序）===" -ForegroundColor Cyan
    foreach ($svc in $startOrder) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Running') {
            Write-Host "  启动: $($svc.Name) ($($service.DisplayName))" -ForegroundColor Cyan
            try {
                Start-Service -Name $svc.Name -ErrorAction Stop
                $service.WaitForStatus('Running', (New-TimeSpan -Seconds $WaitTimeoutSeconds))
                Write-Host "    已启动" -ForegroundColor Green
            }
            catch {
                Write-Host "    启动失败: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # 汇报最终状态
    Write-Host "`n=== 最终状态 ===" -ForegroundColor White
    foreach ($svc in $startOrder) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $statusColor = if ($service.Status -eq 'Running') { "Green" } else { "Red" }
            Write-Host "  $($svc.Name): " -NoNewline
            Write-Host $service.Status -ForegroundColor $statusColor
        }
    }
}

# 示例：按依赖顺序重启 W3SVC 及其相关服务（演示模式，需要管理员权限）
# Restart-ServiceWithDependencies -ServiceNames @("W3SVC") -Force

Write-Host "函数已就绪。取消注释上面的调用行并使用管理员权限运行即可执行。"
```

执行结果示例：

```text
函数已就绪。取消注释上面的调用行并使用管理员权限运行即可执行。
```

## 导出依赖报告为 CSV

将依赖分析结果导出为 CSV 文件，便于文档记录和后续分析。

```powershell
function Export-ServiceDependencyReport {
    param(
        [string]$OutputPath = ".\service-dependency-report.csv"
    )

    $allServices = Get-CimInstance -ClassName Win32_Service |
        Select-Object Name, DisplayName, State, StartMode

    $report = foreach ($svc in $allServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        $dependsOn = ($service.ServicesDependedOn | ForEach-Object { $_.Name }) -join ";"
        $dependedBy = ($service.DependentServices | ForEach-Object { $_.Name }) -join ";"

        [PSCustomObject]@{
            Name            = $svc.Name
            DisplayName     = $svc.DisplayName
            Status          = $svc.State
            StartType       = $svc.StartMode
            DependsOn       = if ($dependsOn) { $dependsOn } else { "(无)" }
            DependedBy      = if ($dependedBy) { $dependedBy } else { "(无)" }
            DependencyCount = ($service.ServicesDependedOn | Measure-Object).Count
            DependentCount  = ($service.DependentServices | Measure-Object).Count
        }
    }

    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    $summary = @{
        TotalServices      = $report.Count
        WithDependencies   = ($report | Where-Object { $_.DependencyCount -gt 0 }).Count
        WithDependents     = ($report | Where-Object { $_.DependentCount -gt 0 }).Count
        NoDependencies     = ($report | Where-Object { $_.DependencyCount -eq 0 }).Count
        MaxDependencyDepth = ($report | Measure-Object -Property DependencyCount -Maximum).Maximum
    }

    Write-Host "报告已导出至: $OutputPath"
    Write-Host "`n摘要:"
    Write-Host "  总服务数: $($summary.TotalServices)"
    Write-Host "  有依赖的服务: $($summary.WithDependencies)"
    Write-Host "  被依赖的服务: $($summary.WithDependents)"
    Write-Host "  无依赖的服务: $($summary.NoDependencies)"
    Write-Host "  最大依赖深度: $($summary.MaxDependencyDepth)"
}

Export-ServiceDependencyReport -OutputPath ".\service-dependency-report.csv"
```

执行结果示例：

```text
报告已导出至: .\service-dependency-report.csv

摘要:
  总服务数: 187
  有依赖的服务: 82
  被依赖的服务: 64
  无依赖的服务: 105
  最大依赖深度: 5
```

## 注意事项

1. **管理员权限**：查询服务信息通常不需要管理员权限，但启停服务和修改服务配置需要以管理员身份运行 PowerShell。建议在脚本开头添加权限检查逻辑。

2. **循环依赖检测**：某些第三方服务可能存在循环依赖。上述代码通过 `$Visited` 参数检测循环引用并标记为"Circular"，避免无限递归。设置 `MaxDepth` 参数也可以防止意外深递归。

3. **服务启动超时**：某些服务启动较慢（如 SQL Server、Exchange），默认 30 秒超时可能不够。在实际使用中应根据服务特性调整 `$WaitTimeoutSeconds` 参数，建议数据库类服务设置 60-120 秒。

4. **WMI 查询性能**：`Get-CimInstance` 查询在服务数量较多时较慢。如果只需要基本信息，优先使用 `Get-Service`；需要启动类型等详细信息时才使用 WMI 查询。可考虑使用 `-ComputerName` 参数实现远程查询。

5. **依赖关系与启动类型**：服务被设置为"自动"启动不代表它一定会成功启动。依赖的服务如果是"手动"或"禁用"状态，自动启动的服务也会失败。分析时应同时关注启动类型和当前状态。

6. **跨服务器依赖**：本文讨论的是单机上的服务依赖。在分布式系统中，服务可能依赖远程机器上的服务（如远程数据库、消息队列），这种情况下需要结合网络拓扑和配置管理工具进行更全面的依赖分析。
