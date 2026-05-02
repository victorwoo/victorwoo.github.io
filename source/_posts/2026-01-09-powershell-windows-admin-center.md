---
layout: post
date: 2026-01-09 08:00:00
updated: 2026-01-09 08:00:00
title: "PowerShell 技能连载 - Windows Admin Center 自动化"
description: PowerTip of the Day - Windows Admin Center Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows-admin-center
- gui
- management
- automation
---

_适用于 PowerShell 5.1 及以上版本_

Windows Admin Center（WAC）是微软推出的基于 Web 的服务器管理平台，通过浏览器即可完成对 Windows Server 的日常运维操作。与传统的远程桌面管理不同，WAC 采用网关架构，运维人员只需要在一个入口就能管理数据中心内的多台服务器和集群，涵盖事件日志、性能监视、证书管理、文件服务、Hyper-V 虚拟机等核心功能模块。

在企业实际部署中，WAC 网关的安装、证书配置、角色权限设置以及受管节点的批量导入，往往需要在多台服务器上重复执行。纯手工配置不仅耗时，还容易遗漏关键步骤。通过 PowerShell 脚本化这些部署和管理流程，可以确保环境的一致性，也方便在灾难恢复或扩容场景中快速重建管理平台。

本文将从三个维度介绍 WAC 的自动化实践：首先是网关的安装与初始配置，其次是受管连接的批量管理与分组，最后是 WAC 扩展开发的入门知识，帮助你掌握将 WAC 深度集成到运维体系中的方法。

<!-- more -->

## WAC 安装与网关配置

在生产环境中部署 WAC 时，需要完成软件安装、SSL 证书绑定、端口配置以及访问权限设置等一系列步骤。以下脚本将这些操作封装为可重复执行的自动化流程。

```powershell
# 定义 WAC 安装参数
$wacInstallerPath = "C:\Install\WindowsAdminCenterPreview.msi"
$gatewayPort = 443
$certThumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"
$smiEnabled = $true

# 检查 WAC 是否已安装
$wacProduct = Get-WmiObject -Class Win32_Product |
    Where-Object { $_.Name -like "*Windows Admin Center*" }

if ($null -eq $wacProduct) {
    Write-Output "正在安装 Windows Admin Center..."

    # 构建 MSI 安装参数
    $msiArgs = @(
        "/i", $wacInstallerPath
        "/qn"
        "SME_PORT=$gatewayPort"
        "SSL_CERTIFICATE_OPTION=installed"
        "THUMBPRINT=$certThumbprint"
        "SME_INCLUDE_MANAGEMENT_TOOLS=$smiEnabled"
    )

    # 执行静默安装
    $process = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList $msiArgs `
        -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Output "WAC 安装成功"
    } else {
        Write-Error "WAC 安装失败，退出代码：$($process.ExitCode)"
    }
} else {
    Write-Output "WAC 已安装，版本：$($wacProduct.Version)"
}

# 验证网关服务状态
$service = Get-Service -Name "ServerManagementGateway" -ErrorAction SilentlyContinue

if ($service.Status -eq "Running") {
    Write-Output "WAC 网关服务运行正常（端口：$gatewayPort）"
} else {
    Write-Output "正在启动 WAC 网关服务..."
    Start-Service -Name "ServerManagementGateway"
}

# 配置角色权限（将安全组映射到 WAC 管理角色）
$gatewayServer = $env:COMPUTERNAME
$adminGroup = "CONTOSO\WAC-Admins"
$userGroup = "CONTOSO\WAC-Users"

# 使用 WAC 的配置命令行工具设置访问权限
$configTool = "${env:ProgramFiles}\Windows Admin Center\ConfigureWAC.exe"

if (Test-Path $configTool) {
    # 设置管理员组（完整权限）
    $null = & $configTool setRole `
        -Role Administrators `
        -Group $adminGroup 2>&1

    # 设置只读用户组
    $null = & $configTool setRole `
        -Role Users `
        -Group $userGroup 2>&1

    Write-Output "角色权限配置完成"
    Write-Output "  管理员组：$adminGroup"
    Write-Output "  只读用户组：$userGroup"
}

# 输出网关访问地址
$fqdn = [System.Net.Dns]::GetHostEntry($gatewayServer).HostName
Write-Output "网关访问地址：https://$fqdn"
```

执行结果示例：

```
正在安装 Windows Admin Center...
WAC 安装成功
WAC 网关服务运行正常（端口：443）
角色权限配置完成
  管理员组：CONTOSO\WAC-Admins
  只读用户组：CONTOSO\WAC-Users
网关访问地址：https://SRV-MGMT01.contoso.com
```

这段脚本涵盖了 WAC 部署的完整流程：首先检查是否已安装以避免重复操作，然后通过 `msiexec` 静默安装并传入端口、证书指纹等参数。安装完成后验证网关服务状态，并通过配置工具将 Active Directory 安全组映射到 WAC 的内置角色。将此脚本纳入服务器初始化流水线后，新建的管理服务器可以在几分钟内完成 WAC 的部署和配置。

## 管理 WAC 连接与批量导入

WAC 网关部署完成后，下一步是将需要管理的服务器注册到网关中。在大型环境中可能有数百台服务器需要纳入管理，手动逐台添加显然不现实。以下脚本演示如何从不同数据源批量导入服务器连接，并按业务分组进行组织。

```powershell
# WAC 网关地址
$gateway = "https://wac.contoso.com"

# 方法一：从 Active Directory 获取服务器列表
Import-Module ActiveDirectory

$serverOUs = @{
    "域控制器" = "OU=Domain Controllers,DC=contoso,DC=com"
    "文件服务器" = "OU=File Servers,OU=Servers,DC=contoso,DC=com"
    "Web 服务器" = "OU=Web Servers,OU=Servers,DC=contoso,DC=com"
    "数据库服务器" = "OU=DB Servers,OU=Servers,DC=contoso,DC=com"
}

$allConnections = @()

foreach ($ouName in $serverOUs.Keys) {
    $ouPath = $serverOUs[$ouName]

    # 查询 OU 下启用的计算机账户
    $computers = Get-ADComputer -Filter { Enabled -eq $true } `
        -SearchBase $ouPath `
        -Properties Name, DNSHostName, OperatingSystem

    foreach ($computer in $computers) {
        $allConnections += [PSCustomObject]@{
            Name     = $computer.Name
            FQDN     = $computer.DNSHostName
            Type     = "Server"
            Group    = $ouName
            OS       = $computer.OperatingSystem
        }
    }
}

Write-Output "从 AD 发现 $($allConnections.Count) 台服务器"

# 方法二：从 CSV 文件补充导入（适用于工作组服务器）
$csvPath = "C:\Config\WorkgroupServers.csv"

if (Test-Path $csvPath) {
    $csvServers = Import-Csv -Path $csvPath -Encoding UTF8

    foreach ($srv in $csvServers) {
        $allConnections += [PSCustomObject]@{
            Name  = $srv.Name
            FQDN  = $srv.IPAddress
            Type  = "Server"
            Group = $srv.Group
            OS    = "Workgroup Server"
        }
    }

    Write-Output "从 CSV 补充导入 $($csvServers.Count) 台工作组服务器"
}

# 批量添加连接到 WAC 网关
$addedCount = 0
$failedCount = 0

foreach ($conn in $allConnections) {
    try {
        # 构造连接添加请求
        $body = @{
            name   = $conn.Name
            type   = $conn.Type
            group  = $conn.Group
            target = $conn.FQDN
        } | ConvertTo-Json

        $uri = "$gateway/api/connections"
        $null = Invoke-RestMethod -Uri $uri -Method Post `
            -Body $body -ContentType "application/json" `
            -UseDefaultCredentials -SkipCertificateCheck

        $addedCount++
    } catch {
        Write-Warning "添加失败：$($conn.Name) - $($_.Exception.Message)"
        $failedCount++
    }
}

Write-Output "`n导入结果汇总："
Write-Output "  成功：$addedCount 台"
Write-Output "  失败：$failedCount 台"
Write-Output "  总计：$($allConnections.Count) 台"

# 按分组统计
$allConnections | Group-Object -Property Group |
    ForEach-Object {
        [PSCustomObject]@{
            分组 = $_.Name
            数量 = $_.Count
        }
    } | Format-Table -AutoSize
```

执行结果示例：

```
从 AD 发现 23 台服务器
从 CSV 补充导入 5 台工作组服务器

导入结果汇总：
  成功：27 台
  失败：1 台
  总计：28 台

分组          数量
----          ----
域控制器         3
文件服务器       6
Web 服务器      8
数据库服务器     6
外围服务器       5
```

脚本展示了两种服务器数据源的整合方式：Active Directory OU 查询适合域内服务器，CSV 导入适合工作组或云端服务器。所有服务器信息统一汇总后，通过 REST API 批量注册到 WAC 网关，并按业务归属进行分组。这种分组方式在 WAC 界面中会以树形结构呈现，运维人员可以快速定位到特定业务线下的所有服务器。

## WAC 扩展开发基础

WAC 支持通过扩展来增强其功能。扩展本质上是一个基于 Angular 框架的 Web 应用，通过 WAC 提供的 SDK 与网关后端通信。以下示例演示如何使用 PowerShell 辅助创建 WAC 扩展项目，并调用 WAC 的 REST API 实现自定义管理功能。

```powershell
# 第一步：准备扩展开发环境
$extensionName = "custom-disk-monitor"
$extensionDir = "C:\WACExtensions\$extensionName"

# 创建扩展项目目录结构
$directories = @(
    "$extensionDir\src"
    "$extensionDir\src\components"
    "$extensionDir\src\assets"
    "$extensionDir\manifest"
)

foreach ($dir in $directories) {
    $null = New-Item -Path $dir -ItemType Directory -Force
}

Write-Output "扩展项目目录已创建：$extensionDir"

# 生成扩展清单文件
$manifest = @{
    name           = $extensionName
    displayName    = "自定义磁盘监控"
    description    = "可视化展示服务器磁盘使用趋势"
    version        = "1.0.0"
    entryPoint     = "src/main.js"
    icon           = "assets/icon.svg"
    targetVersions = @("2.0", "2.1", "2.2")
} | ConvertTo-Json -Depth 3

$manifest | Set-Content -Path "$extensionDir\manifest\manifest.json" -Encoding UTF8
Write-Output "清单文件已生成"

# 第二步：封装 WAC REST API 调用函数
function Invoke-WacDiskQuery {
    param(
        [Parameter(Mandatory)]
        [string]$GatewayEndpoint,

        [Parameter(Mandatory)]
        [string]$ServerName,

        [int]$WarningThreshold = 80
    )

    $queryScript = @(
        "Get-CimInstance -ClassName Win32_LogicalDisk |"
        " Where-Object { `$_.DriveType -eq 3 } |"
        " ForEach-Object {"
        "   $pct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)"
        "   $used = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 1)"
        "   $total = [math]::Round($_.Size / 1GB, 1)"
        "   [PSCustomObject]@{"
        "     Drive = $_.DeviceID"
        "     UsedGB = $used"
        "     TotalGB = $total"
        "     FreePct = $pct"
        "     Status = if ((100 - $pct) -gt $WarningThreshold)"
        "              { 'Warning' } else { 'OK' }"
        "   }"
        " }"
    ) -join "`n"

    $body = @{ command = $queryScript } | ConvertTo-Json

    $uri = "$GatewayEndpoint/api/connections/$ServerName/powershell"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post `
            -Body $body -ContentType "application/json" `
            -UseDefaultCredentials -SkipCertificateCheck

        return $response.value
    } catch {
        Write-Error "查询 $ServerName 磁盘信息失败：$($_.Exception.Message)"
        return $null
    }
}

# 第三步：批量查询并生成 JSON 数据供扩展使用
$servers = @("SRV-FILE01", "SRV-WEB01", "SRV-DB01")
$diskData = @()

foreach ($server in $servers) {
    $disks = Invoke-WacDiskQuery -GatewayEndpoint $gateway `
        -ServerName $server -WarningThreshold 80

    if ($null -ne $disks) {
        foreach ($disk in $disks) {
            $diskData += [PSCustomObject]@{
                Server   = $server
                Drive    = $disk.Drive
                UsedGB   = $disk.UsedGB
                TotalGB  = $disk.TotalGB
                FreePct  = $disk.FreePct
                Status   = $disk.Status
            }
        }
    }
}

# 输出查询结果
$diskData | Format-Table -AutoSize

# 将数据序列化为 JSON 供前端扩展消费
$dataPath = "$extensionDir\src\assets\disk-data.json"
$diskData | ConvertTo-Json -Depth 3 |
    Set-Content -Path $dataPath -Encoding UTF8

Write-Output "磁盘数据已导出至：$dataPath"

# 将扩展注册到 WAC 网关
$registerBody = @{
    name    = $extensionName
    path    = $extensionDir
    enabled = $true
} | ConvertTo-Json

$null = Invoke-RestMethod -Uri "$gateway/api/extensions" `
    -Method Post -Body $registerBody `
    -ContentType "application/json" `
    -UseDefaultCredentials -SkipCertificateCheck

Write-Output "扩展已注册到 WAC 网关"
```

执行结果示例：

```
扩展项目目录已创建：C:\WACExtensions\custom-disk-monitor
清单文件已生成

Server     Drive UsedGB TotalGB FreePct Status
------     ----- ------ ------- ------- ------
SRV-FILE01 C:       85.3   100.0    14.7 Warning
SRV-FILE01 D:      450.2   500.0    10.0 Warning
SRV-WEB01  C:       62.1   100.0    37.9 OK
SRV-WEB01  E:      120.5   200.0    39.8 OK
SRV-DB01   C:       45.8   100.0    54.2 OK
SRV-DB01   F:      780.3  1000.0    22.0 OK
SRV-DB01   G:      920.1  1000.0     8.0 Warning

磁盘数据已导出至：C:\WACExtensions\custom-disk-monitor\src\assets\disk-data.json
扩展已注册到 WAC 网关
```

这段脚本展示了 WAC 扩展开发的辅助流程。首先创建扩展的项目结构和清单文件，然后封装了一个可复用的 `Invoke-WacDiskQuery` 函数，通过 WAC REST API 远程执行磁盘查询。查询结果以 JSON 格式输出，供前端 Angular 组件直接消费。通过这种方式，团队可以将自定义的监控面板、运维工具或审批流程以扩展的形式嵌入到 WAC 界面中，形成统一的管理入口。

## 注意事项

1. **安装前置条件**：WAC 网关要求运行在 Windows Server 2016 及以上版本，且需要安装 .NET Framework 4.6 或更高版本。部署前应通过 `Get-WindowsFeature` 确认必要组件已启用，避免安装过程中因缺少依赖而失败。

2. **证书管理策略**：WAC 强制要求 HTTPS，生产环境中应使用企业 CA 或公共 CA 签发的证书，并在证书即将过期前通过自动化脚本完成续签和绑定。脚本中使用的证书指纹必须在本地计算机证书存储中存在。

3. **连接批量导入的幂等性**：重复执行导入脚本时，应先检查连接是否已存在再决定是否添加。忽略幂等性检查会导致 WAC 数据库中出现重复条目，影响管理界面的展示效果。

4. **扩展开发的技术栈要求**：WAC 扩展基于 Angular 框架，前端代码需要使用 TypeScript 编写。PowerShell 主要用于后端数据准备和 API 调用封装，实际的 UI 交互逻辑仍需前端开发工具链支持。

5. **API 调用的身份传递**：WAC REST API 支持 Windows 集成认证（Kerberos/NTLM）。在跨域场景中，需要配置 CredSSP 或 Kerberos 约束委派，确保用户凭据能从 WAC 网关正确传递到目标服务器。

6. **扩展版本兼容性**：WAC 每次大版本升级可能导致扩展 API 变更。在清单文件的 `targetVersions` 字段中明确声明支持的 WAC 版本范围，并在升级前在测试环境验证扩展的兼容性，避免升级后扩展功能异常。
