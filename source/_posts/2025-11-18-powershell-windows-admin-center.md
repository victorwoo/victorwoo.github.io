---
layout: post
date: 2025-11-18 08:00:00
updated: 2025-11-18 08:00:00
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
- wac
- server-management
- automation
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows Admin Center（简称 WAC）是微软推出的基于浏览器的服务器管理工具，它将传统的服务器管理器、故障排除工具和 PowerShell 集成到一个统一的 Web 界面中。对于管理本地数据中心或混合云环境的运维人员来说，WAC 提供了直观的图形化操作体验，覆盖从单台服务器到 Hyper-V 集群的全方位管理场景，包括事件查看、性能监控、文件服务、远程桌面等核心功能。

虽然 WAC 本身是图形界面工具，但它的底层大量调用 PowerShell 命令，并且提供了 REST API 和 PowerShell 模块来支持自动化操作。这意味着我们可以将 WAC 的能力嵌入到脚本流水线中，实现服务器批量配置、状态巡检、证书更新等重复性任务的自动化。尤其对于管理数十甚至上百台服务器的团队来说，通过 PowerShell 调用 WAC API 能够显著提升运维效率，减少手动操作的出错风险。

本文将介绍如何通过 PowerShell 与 Windows Admin Center 交互，涵盖连接管理、节点状态查询、批量操作以及通过 REST API 实现高级自动化场景，帮助你构建基于 WAC 的自动化运维工作流。

<!-- more -->

## 安装和连接 Windows Admin Center

在开始自动化操作之前，需要确保 WAC 的 PowerShell 模块已正确安装。WAC 本身以网关服务的形式运行在 Windows Server 上，客户端通过 HTTPS 访问。以下是安装模块和建立连接的基本操作。

```powershell
# 安装 Windows Admin Center 的 PowerShell 模块
# 注意：模块名称可能随版本更新变化，请以官方文档为准
Install-Module -Name WindowsAdminCenter -Scope CurrentUser -Force

# 定义 WAC 网关地址
$gateway = "https://wac.contoso.com"

# 获取网关信息，验证连通性
$gatewayInfo = Get-WacGateway -Endpoint $gateway

# 列出当前网关注册的所有服务器连接
$connections = Get-WacConnection -Endpoint $gateway

foreach ($conn in $connections) {
    [PSCustomObject]@{
        Name   = $conn.Name
        Type   = $conn.Type
        Status = $conn.ConnectionStatus
    }
}
```

执行结果示例：

```
Name            Type        Status
----            ----        ------
SRV-DC01        Server      Connected
SRV-FILE01      Server      Connected
SRV-WEB01       Server      Connected
HV-CLUSTER01    Cluster     Connected
```

`Get-WacGateway` 用于检查网关服务是否可达，而 `Get-WacConnection` 则返回网关上注册的所有受管节点。通过遍历连接列表，运维人员可以快速掌握当前管理范围内的所有服务器和集群资源。如果某些节点显示 `Disconnected`，则需要排查网络或凭据问题。

## 查询服务器节点状态

连接建立后，最常见的需求是批量查询服务器的运行状态，包括操作系统版本、启动时间、CPU 和内存使用情况等。以下脚本演示如何通过 WAC 批量获取服务器信息。

```powershell
# 定义目标服务器列表
$servers = @("SRV-DC01", "SRV-FILE01", "SRV-WEB01", "SRV-DB01")

# 存储结果
$results = @()

foreach ($server in $servers) {
    # 通过 WAC 获取单台服务器的系统信息
    $info = Invoke-WacCommand -Endpoint $gateway `
        -ConnectionName $server `
        -Command "Get-ComputerInfo" `
        -ErrorAction SilentlyContinue

    if ($null -ne $info) {
        $results += [PSCustomObject]@{
            ServerName  = $server
            OSVersion   = $info.WindowsProductName
            LastBoot    = $info.OsLastBootUpTime
            UptimeHours = [math]::Round(
                ((Get-Date) - $info.OsLastBootUpTime).TotalHours, 1
            )
        }
    } else {
        $results += [PSCustomObject]@{
            ServerName  = $server
            OSVersion   = "N/A"
            LastBoot    = "N/A"
            UptimeHours = "N/A"
        }
    }
}

# 输出结果表格
$results | Format-Table -AutoSize
```

执行结果示例：

```
ServerName OSVersion                         LastBoot             UptimeHours
---------- ---------                         --------             -----------
SRV-DC01   Windows Server 2022 Datacenter    2025/11/10 06:30:00         192.5
SRV-FILE01 Windows Server 2022 Standard      2025/11/15 14:22:00          72.3
SRV-WEB01  Windows Server 2019 Datacenter    2025/11/01 09:00:00         407.0
SRV-DB01   N/A                               N/A                           N/A
```

脚本通过 `Invoke-WacCommand` 在远程服务器上执行 `Get-ComputerInfo`，然后提取操作系统版本和上次启动时间，并计算运行时长。对于无法连接的服务器（如 SRV-DB01），脚本不会中断，而是将对应字段标记为 `N/A`。这种容错设计在批量巡检场景中非常重要，可以确保单台服务器故障不影响整体任务。

## 通过 REST API 执行批量证书检查

除了使用专用 PowerShell 模块，WAC 还暴露了 REST API 接口，支持更灵活的集成方式。下面演示如何直接调用 WAC REST API 来批量检查服务器上即将过期的证书。

```powershell
# 配置 WAC REST API 参数
$gateway = "https://wac.contoso.com"
$token = Get-WacAccessToken -Endpoint $gateway

# 定义请求头
$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# 目标服务器列表
$servers = @("SRV-DC01", "SRV-WEB01", "SRV-DB01")

# 阈值：30 天内即将过期的证书
$warningDays = 30
$expiryThreshold = (Get-Date).AddDays($warningDays)

# 收集即将过期的证书信息
$expiringCerts = @()

foreach ($server in $servers) {
    # 构造 PowerShell 命令，查询本地证书存储
    $script = "Get-ChildItem -Path Cert:\LocalMachine\My | " +
        "Where-Object { `$_.NotAfter -lt (Get-Date).AddDays($warningDays) } | " +
        "Select-Object Subject, NotAfter, Thumbprint"

    # 调用 WAC REST API 执行远程命令
    $body = @{
        command = $script
    } | ConvertTo-Json

    $uri = "$gateway/api/connections/$server/powershell"
    $response = Invoke-RestMethod -Uri $uri -Method Post `
        -Headers $headers -Body $body -SkipCertificateCheck

    # 解析返回结果
    foreach ($cert in $response.value) {
        $expiringCerts += [PSCustomObject]@{
            Server      = $server
            Subject     = $cert.Subject
            Expires     = [datetime]$cert.NotAfter
            Thumbprint  = $cert.Thumbprint
            DaysLeft    = [math]::Floor(
                ([datetime]$cert.NotAfter - (Get-Date)).TotalDays
            )
        }
    }
}

# 按剩余天数排序输出
$expiringCerts | Sort-Object DaysLeft | Format-Table -AutoSize

# 生成汇总报告
$reportPath = "C:\Reports\CertExpiryReport_$(Get-Date -Format 'yyyyMMdd').csv"
$expiringCerts | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
Write-Output "证书过期报告已保存至：$reportPath"
```

执行结果示例：

```
Server   Subject                 Expires              Thumbprint                           DaysLeft
------   -------                 -------              ----------                           --------
SRV-WEB01 CN=api.contoso.com     2025/11/25 00:00:00  1A2B3C4D5E6F...                      7
SRV-DC01 CN=wac.contoso.com      2025/12/10 00:00:00  7G8H9I0J1K2L...                     22
SRV-DB01 CN=db.contoso.com       2025/12/15 00:00:00  A1B2C3D4E5F6...                     27

证书过期报告已保存至：C:\Reports\CertExpiryReport_20251118.csv
```

这段脚本展示了 WAC REST API 的典型用法：先通过 `Get-WacAccessToken` 获取认证令牌，然后在循环中对每台服务器发起远程 PowerShell 命令调用。查询结果经过筛选和格式化后，既输出到控制台供即时查看，也导出为 CSV 文件用于存档或邮件通知。将此脚本配置为 Windows 计划任务，每天自动运行，就能实现证书过期的主动预警。

## 自动化服务器维护模式切换

在进行补丁安装或计划性维护时，通常需要将服务器置于维护模式以避免监控误报。以下脚本演示如何通过 WAC 批量管理服务器的维护状态。

```powershell
# 维护操作类型：Enable（进入维护）或 Disable（退出维护）
$action = "Enable"
$maintenanceTag = "UnderMaintenance"

# 获取所有服务器连接
$allServers = Get-WacConnection -Endpoint $gateway |
    Where-Object { $_.Type -eq "Server" }

# 选择需要维护的服务器（这里以名称包含 "WEB" 为例）
$targetServers = $allServers |
    Where-Object { $_.Name -match "WEB" }

foreach ($srv in $targetServers) {
    # 在注册表中写入维护标记
    $setCmd = "Set-ItemProperty -Path " +
        "'HKLM:\SOFTWARE\Operations\Maintenance' " +
        "-Name 'InMaintenance' -Value " +
        "$(if ($action -eq 'Enable') { '1' } else { '0' }) -Type DWord -Force"

    $null = Invoke-WacCommand -Endpoint $gateway `
        -ConnectionName $srv.Name `
        -Command $setCmd

    # 同时暂停 SCOM 监控（如果环境中有 SCOM）
    if ($action -eq "Enable") {
        Write-Output "[$($srv.Name)] 已进入维护模式"
    } else {
        Write-Output "[$($srv.Name)] 已退出维护模式"
    }
}

# 验证维护状态
Write-Output "`n--- 当前维护状态 ---"
foreach ($srv in $targetServers) {
    $checkCmd = "(Get-ItemProperty -Path " +
        "'HKLM:\SOFTWARE\Operations\Maintenance' " +
        "-Name 'InMaintenance' -ErrorAction SilentlyContinue).InMaintenance"

    $status = Invoke-WacCommand -Endpoint $gateway `
        -ConnectionName $srv.Name `
        -Command $checkCmd

    $state = if ($status -eq 1) { "维护中" } else { "正常" }
    Write-Output "  $($srv.Name): $state"
}
```

执行结果示例：

```
[SRV-WEB01] 已进入维护模式
[SRV-WEB02] 已进入维护模式
[SRV-WEB03] 已进入维护模式

--- 当前维护状态 ---
  SRV-WEB01: 维护中
  SRV-WEB02: 维护中
  SRV-WEB03: 维护中
```

该脚本的设计思路是通过注册表键值来标记服务器的维护状态。进入维护时写入标记，退出时清除。这种轻量级的标记机制可以与现有的监控系统（如 SCOM、Zabbix）集成，监控脚本读取该注册表值后自动跳过处于维护状态的服务器，避免产生无效告警。

## 注意事项

1. **网络与防火墙要求**：WAC 网关默认监听 HTTPS 端口（通常为 443 或自定义端口），确保执行 PowerShell 脚本的客户端与 WAC 网关之间网络畅通，且防火墙允许对应端口的入站和出站流量。

2. **身份认证配置**：WAC 支持 Active Directory、本地 Windows 认证和 Azure AD 等多种认证方式。自动化脚本建议使用受约束的委派（CredSSP）或 Group Managed Service Account（gMSA）来管理凭据，避免在脚本中硬编码密码。

3. **API 版本兼容性**：WAC 的 REST API 随版本迭代可能发生变化。在生产环境使用前，务必对照当前部署的 WAC 版本查阅官方 API 文档，避免因版本不匹配导致脚本执行失败。

4. **并发与限流**：批量操作大量服务器时，建议在循环中加入适当的间隔（如 `Start-Sleep -Seconds 2`），避免瞬间大量请求导致 WAC 网关服务过载或触发速率限制。

5. **错误处理与日志记录**：远程命令执行可能因网络波动、目标服务器离线或权限不足而失败。脚本中应使用 `try/catch` 块捕获异常，并将失败记录写入日志文件，便于事后排查。对于关键操作（如证书更新、服务重启），必须实现回滚机制。

6. **安全传输与证书验证**：WAC 必须使用 HTTPS 通信。自签名证书在测试环境可用，但生产环境应配置由企业 CA 或公共 CA 签发的正式证书。脚本中使用 `Invoke-RestMethod` 时注意 `SkipCertificateCheck` 参数仅用于测试环境，生产环境务必验证证书有效性。
