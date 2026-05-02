---
layout: post
date: 2025-06-11 08:00:00
updated: 2025-06-11 08:00:00
title: "PowerShell 技能连载 - IIS Web 服务器管理"
description: PowerTip of the Day - IIS Web Server Management in PowerShell
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

_适用于 Windows Server 2016 及以上版本，需安装 IIS 管理工具_

Internet Information Services（IIS）是 Windows 上最流行的 Web 服务器，广泛用于托管 ASP.NET 应用、静态网站和反向代理。IIS 管理器（GUI）虽然直观，但在管理多台服务器或执行批量操作时效率极低。PowerShell 的 `WebAdministration` 模块提供了完整的 IIS 管理能力，可以实现网站创建、应用池管理、绑定配置和性能调优的全面自动化。

本文将讲解 IIS 的 PowerShell 管理技巧，涵盖日常运维的各个场景。

<!-- more -->

## IIS 管理环境准备

```powershell
# 安装 IIS 和管理工具（Windows Server）
Install-WindowsFeature -Name Web-Server, Web-Mgmt-Tools, Web-Scripting-Tools

# 导入 WebAdministration 模块
Import-Module WebAdministration

# 查看 IIS 站点列表
Get-Website | Select-Object Name, State, PhysicalPath,
    @{N='绑定'; E={($_.bindings.Collection | ForEach-Object { $_.protocol + '://' + $_.bindingInformation }) -join ', '}} |
    Format-Table -AutoSize

# 查看应用池
Get-IISAppPool | Select-Object Name, State,
    @{N='.NET版本'; E={$_.managedRuntimeVersion}},
    @{N='管线模式'; E={$_.managedPipelineMode}} |
    Format-Table -AutoSize
```

执行结果示例：

```
Name       State   PhysicalPath               绑定
----       -----   ------------               ----
Default    Started C:\inetpub\wwwroot         http://*:80:
MyApp      Started D:\Apps\MyApp              http://*:8080:, https://*:443:

Name           State   .NET版本  管线模式
----           -----   --------  --------
DefaultAppPool Started v4.0      Integrated
MyAppPool      Started v4.0      Integrated
```

## 网站与应用池管理

```powershell
# 创建新的应用池
New-IISAppPool -Name "NewAppPool" -managedRuntimeVersion "v4.0"
Set-ItemProperty IIS:\AppPools\NewAppPool -Name processModel.identityType -Value ApplicationPoolIdentity
Set-ItemProperty IIS:\AppPools\NewAppPool -Name recycling.periodicRestart.time -Value "00:00:00"
Write-Host "应用池已创建：NewAppPool" -ForegroundColor Green

# 创建新网站
$siteParams = @{
    Name         = "MyNewSite"
    PhysicalPath = "D:\Apps\MyNewSite"
    Port         = 8090
    ApplicationPool = "NewAppPool"
}
New-IISSite @siteParams
Write-Host "网站已创建：MyNewSite" -ForegroundColor Green

# 配置 HTTPS 绑定
$cert = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -match 'myapp.contoso.com' } |
    Select-Object -First 1

New-IISSiteBinding -Name "MyNewSite" -BindingInformation "*:443:myapp.contoso.com" `
    -Protocol https -CertificateThumbPrint $cert.Thumbprint -CertStoreLocation "Cert:\LocalMachine\My"

# 启动/停止/重启网站
Start-Website -Name "MyNewSite"
Stop-Website -Name "MyNewSite"
Restart-WebAppPool -Name "NewAppPool"

# 删除网站和应用池
Remove-IISSite -Name "MyNewSite" -Confirm:$false
Remove-IISAppPool -Name "NewAppPool" -Confirm:$false
```

执行结果示例：

```
应用池已创建：NewAppPool
网站已创建：MyNewSite
```

## 应用池健康监控

```powershell
function Get-AppPoolHealthReport {
    <#
    .SYNOPSIS
    生成 IIS 应用池健康报告
    #>

    $appPools = Get-IISAppPool
    $report = foreach ($pool in $appPools) {
        $workerProcesses = Get-Process -Name w3wp -ErrorAction SilentlyContinue |
            Where-Object { $_.AppPoolName -eq $pool.Name }

        $totalMemory = 0
        $totalCPU = 0
        $wpCount = 0

        foreach ($wp in $workerProcesses) {
            $totalMemory += $wp.WorkingSet64
            $totalCPU += $wp.CPU
            $wpCount++
        }

        [PSCustomObject]@{
            名称       = $pool.Name
            状态       = $pool.State
            工作进程   = $wpCount
            内存MB     = [math]::Round($totalMemory / 1MB, 2)
            运行时     = $pool.managedRuntimeVersion
            身份       = $pool.processModel.identityType
            上次回收   = (Get-ItemProperty "IIS:\AppPools\$($pool.Name)" -Name recycling.logEventOnRecycle -ErrorAction SilentlyContinue).Value
        }
    }

    $report | Format-Table -AutoSize
}

Get-AppPoolHealthReport
```

执行结果示例：

```
名称            状态   工作进程 内存MB   运行时 身份
----            ----   -------- ------   ------ ----
DefaultAppPool  Started        1   85.32  v4.0   ApplicationPoolIdentity
MyAppPool       Started        2  345.67  v4.0   NetworkService
```

## IIS 配置导出与迁移

```powershell
# 导出 IIS 配置
function Export-IISConfig {
    param([string]$OutputPath = "C:\Config\IIS-Backup")

    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

    # 导出应用池配置
    Get-IISAppPool | Export-Clixml -Path "$OutputPath\AppPools.xml"

    # 导出网站配置
    Get-Website | Export-Clixml -Path "$OutputPath\Websites.xml"

    # 导出 IIS 配置文件
    Copy-Item "$env:windir\System32\inetsrv\config\applicationHost.config" `
        "$OutputPath\applicationHost.config.bak"

    Write-Host "IIS 配置已导出到：$OutputPath" -ForegroundColor Green
}

# 查看 IIS 日志
function Get-IISLogSummary {
    param(
        [string]$SiteName = "Default Web Site",
        [int]$TopUrls = 10
    )

    $logPath = (Get-Website -Name $SiteName).logfile.directory
    $logPath = $logPath -replace '%SystemDrive%', $env:SystemDrive

    $latestLog = Get-ChildItem $logPath -Filter "*.log" -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    Write-Host "分析日志：$($latestLog.FullName)" -ForegroundColor Cyan

    # 解析 W3C 格式日志
    $header = Get-Content $latestLog.FullName |
        Where-Object { $_ -match '^#Fields:' } |
        Select-Object -First 1

    $fields = ($header -replace '^#Fields:\s*', '') -split '\s+'

    $entries = Get-Content $latestLog.FullName -Tail 10000 |
        Where-Object { $_ -notmatch '^#' -and $_.Trim() } |
        ConvertFrom-Csv -Delimiter ' ' -Header $fields

    $entries | Group-Object 'cs-uri-stem' |
        Sort-Object Count -Descending |
        Select-Object -First $TopUrls Count, Name |
        Format-Table -AutoSize
}

Get-IISLogSummary -SiteName "MyApp" -TopUrls 10
```

执行结果示例：

```
IIS 配置已导出到：C:\Config\IIS-Backup

分析日志：C:\inetpub\logs\LogFiles\W3SVC2\ex250611.log

Count Name
----- ----
 2345 /api/users
 1876 /api/products
  987 /static/css/main.css
  654 /api/orders
```

## 注意事项

1. **应用池回收**：配置合理的回收间隔。默认 29 小时回收一次可能导致请求中断，建议在低峰期回收
2. **权限配置**：应用池的 Identity 账户需要对网站目录有读取权限
3. **HTTPS 证书**：使用 Let's Encrypt 或组织内部 CA 证书时，确保证书自动续期机制正常
4. **日志管理**：IIS 日志增长很快，配置日志轮转和定期归档清理
5. **Web.config 继承**：子目录的 web.config 会继承父目录的配置，可能导致冲突。使用 `<location>` 标签控制继承范围
6. **32位应用**：如果应用需要 32 位模式，在应用池中设置 `enable32BitAppOnWin64` 为 `true`
