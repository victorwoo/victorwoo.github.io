---
layout: post
date: 2025-03-31 08:00:00
title: "PowerShell 技能连载 - Windows 安全基线审计"
description: PowerTip of the Day - Windows Security Baseline Auditing with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
---
定期对 Windows 系统进行安全基线检查是运维的基本功。本文用 PowerShell 实现一套轻量的安全审计脚本，覆盖账户策略、防火墙、补丁状态、服务配置等关键检查项。

## 账户与密码策略

```powershell
function Get-SecurityBaselineAccount {
    $result = @()

    # 密码策略
    $pwdPolicy = net accounts | Out-String
    $result += [PSCustomObject]@{
        Category = "密码策略"
        Check    = "密码最短期限"
        Value    = if ($pwdPolicy -match '密码最短期限:\s*(\d+)') { $Matches[1] + " 天" } else { "未知" }
        Expected = "≥ 1 天"
    }
    $result += [PSCustomObject]@{
        Category = "密码策略"
        Check    = "密码最长期限"
        Value    = if ($pwdPolicy -match '密码最长期限:\s*(\d+)') { $Matches[1] + " 天" } else { "未知" }
        Expected = "≤ 90 天"
    }
    $result += [PSCustomObject]@{
        Category = "密码策略"
        Check    = "最小密码长度"
        Value    = if ($pwdPolicy -match '最小密码长度:\s*(\d+)') { $Matches[1] + " 字符" } else { "未知" }
        Expected = "≥ 14 字符"
    }

    # 检查管理员组中非预期的成员
    $adminMembers = Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty PrincipalSource
    $result += [PSCustomObject]@{
        Category = "账户安全"
        Check    = "本地管理员组成员数"
        Value    = "$($adminMembers.Count) 个"
        Expected = "尽量精简"
    }

    # 检查禁用的来宾账户
    $guest = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "账户安全"
        Check    = "Guest 账户状态"
        Value    = if ($guest.Enabled) { "已启用 (风险)" } else { "已禁用" }
        Expected = "已禁用"
    }

    return $result
}
```

## 防火墙与网络

```powershell
function Get-SecurityBaselineNetwork {
    $result = @()

    # 防火墙状态
    foreach ($profile in @("Domain", "Private", "Public")) {
        $fw = Get-NetFirewallProfile -Name $profile -ErrorAction SilentlyContinue
        $result += [PSCustomObject]@{
            Category = "防火墙"
            Check    = "$profile 配置文件"
            Value    = if ($fw.Enabled) { "已启用" } else { "已禁用 (风险)" }
            Expected = "已启用"
        }
    }

    # 开放的高危端口
    $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalAddress -eq "0.0.0.0" -or $_.LocalAddress -eq "::" } |
        Select-Object LocalPort, OwningProcess -Unique

    $highRiskPorts = @(21, 23, 445, 3389, 5800, 5900)
    $riskyPorts = $listeningPorts | Where-Object { $_.LocalPort -in $highRiskPorts }

    $result += [PSCustomObject]@{
        Category = "网络"
        Check    = "高危端口开放"
        Value    = if ($riskyPorts) { "发现 $($riskyPorts.Count) 个: $($riskyPorts.LocalPort -join ', ')" } else { "无" }
        Expected = "无"
    }

    # RDP 配置
    $rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "远程访问"
        Check    = "RDP 状态"
        Value    = if ($rdp.fDenyTSConnections -eq 0) { "已启用" } else { "已禁用" }
        Expected = "按需，启用时需配合 NLA"
    }

    $nla = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "远程访问"
        Check    = "RDP 网络级别身份验证"
        Value    = if ($nla.UserAuthentication -eq 1) { "已启用" } else { "未启用 (风险)" }
        Expected = "已启用"
    }

    return $result
}
```

## 补丁与系统更新

```powershell
function Get-SecurityBaselineUpdates {
    $result = @()

    # 最近安装的更新
    $recentUpdates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
    $latestUpdate = $recentUpdates | Select-Object -First 1

    $result += [PSCustomObject]@{
        Category = "系统更新"
        Check    = "最新补丁日期"
        Value    = if ($latestUpdate.InstalledOn) { $latestUpdate.InstalledOn.ToString("yyyy-MM-dd") } else { "未知" }
        Expected = "30 天内"
    }

    # 检查 Windows Update 服务状态
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "系统更新"
        Check    = "Windows Update 服务"
        Value    = $wuService.Status
        Expected = "Running"
    }

    # 待安装的重要更新数
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1")

    $result += [PSCustomObject]@{
        Category = "系统更新"
        Check    = "待安装重要更新"
        Value    = "$($searchResult.Updates.Count) 个"
        Expected = "0 个"
    }

    return $result
}
```

## 服务与启动项

```powershell
function Get-SecurityBaselineServices {
    $result = @()

    # 检查危险服务
    $dangerousServices = @{
        "Telnet"          = "tlntsvr"
        "RemoteRegistry"  = "RemoteRegistry"
        "SSDPSRV"         = "ssdpsrv"
        "upnphost"        = "upnphost"
    }

    foreach ($svc in $dangerousServices.GetEnumerator()) {
        $service = Get-Service -Name $svc.Value -ErrorAction SilentlyContinue
        $result += [PSCustomObject]@{
            Category = "服务检查"
            Check    = "$($svc.Key) ($($svc.Value))"
            Value    = if ($service) { "$($service.Status), 启动类型: $($service.StartType)" } else { "未安装" }
            Expected = "未安装或已禁用"
        }
    }

    # 自启动项数量
    $startupItems = Get-CimInstance -ClassName Win32_StartupCommand |
        Where-Object { $_.Location -eq "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" }

    $result += [PSCustomObject]@{
        Category = "启动项"
        Check    = "系统级自启动项"
        Value    = "$($startupItems.Count) 个"
        Expected = "审查后保留必要项"
    }

    return $result
}
```

## 生成审计报告

```powershell
function New-SecurityBaselineReport {
    param(
        [string]$OutputPath = ".\SecurityBaseline_$(Get-Date -Format 'yyyyMMdd').html"
    )

    $allChecks = @()
    $allChecks += Get-SecurityBaselineAccount
    $allChecks += Get-SecurityBaselineNetwork
    $allChecks += Get-SecurityBaselineUpdates
    $allChecks += Get-SecurityBaselineServices

    $totalChecks = $allChecks.Count
    $riskItems = ($allChecks | Where-Object { $_.Value -match "风险|FAIL|未启用" }).Count

    $html = @"
<!DOCTYPE html>
<html>
<head><title>安全基线审计报告 - $(Get-Date -Format 'yyyy-MM-dd')</title>
<style>
body { font-family: Microsoft YaHei; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; }
.risk { background-color: #ffcccc; }
.summary { font-size: 18px; margin: 20px 0; }
</style></head>
<body>
<h1>安全基线审计报告</h1>
<p class="summary">检查项: $totalChecks | 风险项: <span style="color:red">$riskItems</span></p>
<table><tr><th>类别</th><th>检查项</th><th>当前值</th><th>期望值</th></tr>
"@

    foreach ($item in $allChecks) {
        $class = if ($item.Value -match "风险|FAIL|未启用") { ' class="risk"' } else { "" }
        $html += "<tr$class><td>$($item.Category)</td><td>$($item.Check)</td><td>$($item.Value)</td><td>$($item.Expected)</td></tr>"
    }

    $html += "</table></body></html>"
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "报告已生成: $OutputPath"
}
```

运行 `New-SecurityBaselineReport` 即可一键生成 HTML 审计报告。建议定期执行，对比历次报告跟踪风险项变化。
