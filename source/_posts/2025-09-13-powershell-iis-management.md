---
layout: post
date: 2025-09-13 08:00:00
updated: 2025-09-13 08:00:00
title: "PowerShell 技能连载 - IIS 管理自动化"
description: PowerTip of the Day - IIS Management Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- iis
- web-server
- site-management
---

_适用于 PowerShell 5.1 及以上版本（Windows），需要 WebAdministration 模块_

IIS（Internet Information Services）是 Windows Server 上的 Web 服务器角色，承载着企业内部的 Web 应用、API 服务和外部网站。在多站点环境中，手动管理 IIS 配置既繁琐又容易出错——创建网站、配置绑定、管理应用池、设置 SSL 证书，每个操作都需要反复点击 IIS 管理器。PowerShell 的 `WebAdministration` 模块将所有这些操作变成了可脚本化的命令，让 IIS 管理实现真正的自动化。

本文将介绍 IIS 的常用管理操作和批量自动化方案。

<!-- more -->

## 站点与应用池管理

```powershell
Import-Module WebAdministration

# 查询所有网站状态
Get-Website | Select-Object Name, State,
    @{N='Bindings'; E={ ($_.Bindings.Collection | ForEach-Object { $_.Protocol + "://" + $_.BindingInformation }) -join ", " }},
    @{N='AppPool'; E={ $_.ApplicationPool }},
    PhysicalPath |
    Format-Table -AutoSize

# 查询应用池状态
Get-IISAppPool | Select-Object Name, State,
    @{N='Runtime'; E={ $_.ManagedRuntimeVersion }},
    @{N='Pipeline'; E={ $_.ManagedPipelineMode }},
    @{N='Identity'; E={ $_.ProcessModel.IdentityType }} |
    Format-Table -AutoSize

# 创建新网站（含应用池）
function New-IISWebSite {
    param(
        [Parameter(Mandatory)]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [string]$PhysicalPath,

        [int]$Port = 80,
        [string]$HostHeader = "",
        [string]$RuntimeVersion = "v4.0"
    )

    # 创建物理目录
    if (-not (Test-Path $PhysicalPath)) {
        New-Item $PhysicalPath -ItemType Directory -Force | Out-Null
    }

    # 创建应用池
    $appPoolName = "${SiteName}_Pool"
    if (-not (Get-IISAppPool -Name $appPoolName -ErrorAction SilentlyContinue)) {
        New-WebAppPool -Name $appPoolName
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedRuntimeVersion -Value $RuntimeVersion
        Write-Host "已创建应用池：$appPoolName" -ForegroundColor Green
    }

    # 创建网站
    $bindingInfo = "*:${Port}:${HostHeader}"
    if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
        New-Website -Name $SiteName -PhysicalPath $PhysicalPath `
            -ApplicationPool $appPoolName -Port $Port -HostHeader $HostHeader -Force
        Write-Host "已创建网站：$SiteName（端口 $Port）" -ForegroundColor Green
    }

    # 设置默认文档
    Add-WebConfiguration "system.webServer/defaultDocument/files" -Value "index.html" -PSPath "IIS:\Sites\$SiteName" -ErrorAction SilentlyContinue
}

New-IISWebSite -SiteName "MyApp" -PhysicalPath "C:\inetpub\MyApp" -Port 8080 -HostHeader "myapp.local"

# 启动/停止/回收
Start-Website -Name "MyApp"
# Stop-Website -Name "MyApp"
# Restart-WebAppPool -Name "MyApp_Pool"
```

执行结果示例：

```
Name        State Bindings                  AppPool     PhysicalPath
----        ----- --------                  -------     ------------
Default Web Site Started http://*:80          DefaultAppPool C:\inetpub\wwwroot
MyApp       Started http://*:8080:myapp.local MyApp_Pool    C:\inetpub\MyApp

已创建应用池：MyApp_Pool
已创建网站：MyApp（端口 8080）
```

## SSL 证书与绑定

```powershell
# 为网站配置 HTTPS 绑定
function Add-IISHttpsBinding {
    param(
        [Parameter(Mandatory)]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [int]$Port = 443,

        [string]$CertStore = "WebHosting"
    )

    # 查找证书
    $cert = Get-ChildItem "Cert:\LocalMachine\$CertStore" |
        Where-Object { $_.Subject -match $Domain -and $_.NotAfter -gt (Get-Date) } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1

    if (-not $cert) {
        Write-Host "未找到 $Domain 的有效证书" -ForegroundColor Red
        return
    }

    Write-Host "使用证书：$($cert.Subject)（过期：$($cert.NotAfter.ToString('yyyy-MM-dd'))）" -ForegroundColor Cyan

    # 添加 HTTPS 绑定
    New-WebBinding -Name $SiteName -Protocol "https" -Port $Port -HostHeader $Domain
    $binding = Get-WebBinding -Name $SiteName -Protocol "https" -Port $Port -HostHeader $Domain
    $binding.AddSslCertificate($cert.Thumbprint, $certStore)

    Write-Host "HTTPS 绑定已添加：$Domain`:$Port" -ForegroundColor Green
}

# 证书到期检查
function Get-IISCertExpiryReport {
    $certs = Get-ChildItem "Cert:\LocalMachine\My" |
        Where-Object { $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) }

    $report = foreach ($cert in $certs) {
        $daysLeft = ($cert.NotAfter - (Get-Date)).Days

        [PSCustomObject]@{
            Subject   = $cert.Subject
            Issuer    = $cert.Issuer
            Expires   = $cert.NotAfter.ToString('yyyy-MM-dd')
            DaysLeft  = $daysLeft
            Thumbprint = $cert.Thumbprint.Substring(0, 16) + "..."
            Status    = if ($daysLeft -le 30) { "CRITICAL" } elseif ($daysLeft -le 90) { "WARNING" } else { "OK" }
        }
    }

    $report | Sort-Object DaysLeft | Format-Table -AutoSize

    $critical = $report | Where-Object { $_.Status -eq "CRITICAL" }
    if ($critical) {
        Write-Host "$($critical.Count) 个证书即将过期！" -ForegroundColor Red
    }
}

Get-IISCertExpiryReport

# HTTP 到 HTTPS 重定向
$configPath = "IIS:\Sites\MyApp"
Add-WebConfigurationProperty -PSPath $configPath -Filter "system.webServer/rewrite/rules" -Name "." -Value @{
    name = "HTTP to HTTPS"
    stopProcessing = $true
} -ErrorAction SilentlyContinue
```

执行结果示例：

```
使用证书：CN=myapp.local（过期：2026-03-15）
HTTPS 绑定已添加：myapp.local:443
Subject              Issuer               Expires    DaysLeft Thumbprint     Status
-------              -----               -------    -------- ----------     ------
CN=myapp.local       CN=MyCA              2026-03-15      192 a1b2c3d4e5f6... OK
CN=api.contoso.com   CN=Let's Encrypt     2025-11-20       76 f1e2d3c4b5a6... WARNING
CN=old.contoso.com   CN=MyCA              2025-10-01        6 b2c3d4e5f6a1... CRITICAL
1 个证书即将过期！
```

## 批量部署与监控

```powershell
# 批量部署网站
function Deploy-WebApplications {
    param(
        [string[]]$Servers = @("SRV01", "SRV02"),
        [string]$ConfigPath = "C:\Config\webapps.json"
    )

    $apps = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    foreach ($server in $Servers) {
        Write-Host "`n--- 部署到 $server ---" -ForegroundColor Cyan

        Invoke-Command -ComputerName $server -ScriptBlock {
            param($appList)

            Import-Module WebAdministration

            foreach ($app in $appList) {
                $siteName = $app.SiteName
                $appPool  = "${siteName}_Pool"
                $path     = $app.PhysicalPath

                # 确保目录存在
                if (-not (Test-Path $path)) {
                    New-Item $path -ItemType Directory -Force | Out-Null
                }

                # 创建或更新应用池
                if (-not (Get-IISAppPool -Name $appPool -ErrorAction SilentlyContinue)) {
                    New-WebAppPool -Name $appPool
                }
                Set-ItemProperty "IIS:\AppPools\$appPool" -Name managedRuntimeVersion -Value $app.Runtime

                # 创建或更新网站
                if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
                    Set-ItemProperty "IIS:\Sites\$siteName" -Name physicalPath -Value $path
                    Write-Host "  已更新：$siteName" -ForegroundColor Yellow
                } else {
                    New-Website -Name $siteName -PhysicalPath $path `
                        -ApplicationPool $appPool -Port $app.Port -Force
                    Write-Host "  已创建：$siteName" -ForegroundColor Green
                }
            }

        } -ArgumentList (,$apps) -ErrorAction Stop
    }
}

# IIS 健康检查
function Get-IISHealthReport {
    $sites = Get-Website
    $pools = Get-IISAppPool

    $siteReport = foreach ($site in $sites) {
        [PSCustomObject]@{
            Site     = $site.Name
            State    = $site.State
            AppPool  = $site.ApplicationPool
            Requests = (Get-Counter "\Web Service($($site.Name))\Total Method Requests/sec" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        }
    }

    $poolReport = foreach ($pool in $pools) {
        $workerProcesses = Get-Process -Name "w3wp" -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowTitle -match $pool.Name }

        [PSCustomObject]@{
            AppPool  = $pool.Name
            State    = $pool.State
            Runtime  = $pool.ManagedRuntimeVersion
            MemoryMB = if ($workerProcesses) { [math]::Round(($workerProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2) } else { 0 }
        }
    }

    Write-Host "=== 网站状态 ===" -ForegroundColor Cyan
    $siteReport | Format-Table -AutoSize

    Write-Host "=== 应用池状态 ===" -ForegroundColor Cyan
    $poolReport | Format-Table -AutoSize

    $stopped = $sites | Where-Object { $_.State -ne "Started" }
    if ($stopped) {
        Write-Host "警告：$($stopped.Count) 个网站未运行" -ForegroundColor Red
    }
}

Get-IISHealthReport
```

执行结果示例：

```
=== 网站状态 ===
Site              State   AppPool      Requests
----              -----   -------      --------
Default Web Site  Started DefaultAppPool     2.5
MyApp             Started MyApp_Pool        12.3

=== 应用池状态 ===
AppPool         State   Runtime MemoryMB
-------         -----   ------- --------
DefaultAppPool  Started v4.0        45.6
MyApp_Pool      Started v4.0       128.3
```

## 注意事项

1. **权限要求**：IIS 管理操作需要管理员权限，远程管理还需启用 WinRM 和 IIS 远程管理服务
2. **应用池隔离**：不同应用使用独立的应用池，避免一个应用崩溃影响其他应用
3. **配置备份**：修改 IIS 配置前使用 `%windir%\system32\inetsrv\appcmd.exe add backup` 创建备份
4. **日志管理**：IIS 日志文件增长迅速，应配置日志滚动和定期清理策略
5. **绑定冲突**：同一端口和主机头的绑定只能有一个，部署前检查绑定冲突
6. **回收策略**：应用池默认 29 小时回收一次，可根据应用特点调整或禁用（配合健康检查）
