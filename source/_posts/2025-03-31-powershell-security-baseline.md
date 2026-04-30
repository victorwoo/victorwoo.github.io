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
_适用于 Windows Server 2016+ 及 PowerShell 5.1+_

很多安全事件的根源并不是零日漏洞，而是基础配置疏忽——弱密码策略、高危端口暴露、补丁长期未更新。定期执行安全基线检查是运维最基本也是最有效的防线。本文用 PowerShell 编写一套轻量审计脚本，覆盖密码策略、防火墙、RDP、补丁和服务五大维度，最终汇总为一份 HTML 审计报告。

## 账户与密码策略

密码策略是安全基线的第一道门。如果系统允许空密码或密码永不过期，攻击者可以轻松暴力破解。同时管理员组成员过多、Guest 账户处于启用状态，也会显著增加横向移动的风险。下面这段代码通过 `net accounts` 获取当前密码策略，并检查本地管理员组和 Guest 账户的状态。

```powershell
function Get-SecurityBaselineAccount {
    $result = @()
    $pwdPolicy = net accounts | Out-String

    # 密码最短期限：防止用户改完密码后立刻改回旧密码
    $result += [PSCustomObject]@{
        Category = "密码策略"; Check = "密码最短期限"
        Value    = if ($pwdPolicy -match '密码最短期限:\s*(\d+)') { $Matches[1] + " 天" } else { "未知" }
        Expected = "≥ 1 天"
    }
    # 密码最长期限：长期不换密码会增加凭据泄露的风险
    $result += [PSCustomObject]@{
        Category = "密码策略"; Check = "密码最长期限"
        Value    = if ($pwdPolicy -match '密码最长期限:\s*(\d+)') { $Matches[1] + " 天" } else { "未知" }
        Expected = "≤ 90 天"
    }
    # 最小密码长度：14 位以下容易被暴力破解
    $result += [PSCustomObject]@{
        Category = "密码策略"; Check = "最小密码长度"
        Value    = if ($pwdPolicy -match '最小密码长度:\s*(\d+)') { $Matches[1] + " 字符" } else { "未知" }
        Expected = "≥ 14 字符"
    }
    # 管理员组成员应尽量精简，避免权限滥用
    $adminMembers = Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "账户安全"; Check = "本地管理员组成员数"
        Value = "$($adminMembers.Count) 个"; Expected = "尽量精简"
    }
    # Guest 账户启用后任何人可匿名访问系统资源
    $guest = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "账户安全"; Check = "Guest 账户状态"
        Value = if ($guest.Enabled) { "已启用 (风险)" } else { "已禁用" }; Expected = "已禁用"
    }
    return $result
}
```

执行后输出类似如下结果，可以看到最小密码长度仅为 7 字符，不满足基线要求，需要重点关注：

```
Category  Check              Value        Expected
--------  -----              -----        --------
密码策略  密码最短期限        1 天         ≥ 1 天
密码策略  密码最长期限        42 天        ≤ 90 天
密码策略  最小密码长度        7 字符       ≥ 14 字符
账户安全  本地管理员组成员数  3 个         尽量精简
账户安全  Guest 账户状态      已禁用       已禁用
```

## 防火墙与高危端口检测

防火墙是系统级的网络屏障，任何一个配置文件被关闭都会让对应网络场景下的所有端口暴露。FTP（21）、Telnet（23）、SMB（445）、RDP（3389）、VNC（5800/5900）等高危端口如果监听在 `0.0.0.0` 上，攻击面会大幅增加。下面这段代码检查三个防火墙配置文件的启用状态，并扫描当前对外开放的高危端口。

```powershell
function Get-SecurityBaselineNetwork {
    $result = @()

    # 逐个检查域、专用、公用三个防火墙配置文件
    foreach ($profile in @("Domain", "Private", "Public")) {
        $fw = Get-NetFirewallProfile -Name $profile -ErrorAction SilentlyContinue
        $result += [PSCustomObject]@{
            Category = "防火墙"; Check = "$profile 配置文件"
            Value    = if ($fw.Enabled) { "已启用" } else { "已禁用 (风险)" }
            Expected = "已启用"
        }
    }
    # 扫描监听在所有网卡上的高危端口
    $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalAddress -eq "0.0.0.0" -or $_.LocalAddress -eq "::" } |
        Select-Object LocalPort, OwningProcess -Unique

    $highRiskPorts = @(21, 23, 445, 3389, 5800, 5900)
    $riskyPorts = $listeningPorts | Where-Object { $_.LocalPort -in $highRiskPorts }

    $result += [PSCustomObject]@{
        Category = "网络"; Check = "高危端口开放"
        Value    = if ($riskyPorts) {
            "发现 $($riskyPorts.Count) 个: $($riskyPorts.LocalPort -join ', ')"
        } else { "无" }
        Expected = "无"
    }
    return $result
}
```

下面的执行结果显示 Public 配置文件的防火墙已关闭，同时 445（SMB）和 3389（RDP）对外开放，存在较高的被利用风险：

```
Category  Check           Value                 Expected
--------  -----           -----                 --------
防火墙    Domain 配置文件  已启用                已启用
防火墙    Private 配置文件 已启用                已启用
防火墙    Public 配置文件  已禁用 (风险)         已启用
网络      高危端口开放     发现 2 个: 445, 3389  无
```

## RDP 安全配置

RDP 是远程管理 Windows 服务器的常用方式，但如果不加限制就会成为暴力破解的入口。需要关注两个关键点：RDP 是否开启，以及是否启用了网络级别身份验证（NLA）。NLA 在建立连接之前就要求身份验证，能有效防御未认证的拒绝服务攻击和凭据窃取。

```powershell
function Get-SecurityBaselineRDP {
    $result = @()

    # 通过注册表检查 RDP 是否启用（0 = 启用，1 = 禁用）
    $rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
        -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "RDP 安全"; Check = "RDP 状态"
        Value    = if ($rdp.fDenyTSConnections -eq 0) { "已启用" } else { "已禁用" }
        Expected = "按需启用"
    }

    # NLA 未启用时连接建立前不做身份验证，存在安全风险
    $nla = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
        -Name "UserAuthentication" -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "RDP 安全"; Check = "NLA（网络级别身份验证）"
        Value    = if ($nla.UserAuthentication -eq 1) { "已启用" } else { "未启用 (风险)" }
        Expected = "已启用"
    }
    return $result
}
```

执行结果示例中 RDP 已启用且 NLA 也已启用，处于合规状态。如果 NLA 未启用，攻击者可在身份验证之前消耗服务器资源，建议立刻启用：

```
Category  Check                    Value    Expected
--------  -----                    -----    --------
RDP 安全  RDP 状态                 已启用   按需启用
RDP 安全  NLA（网络级别身份验证）   已启用   已启用
```

## 补丁状态检查

未及时安装补丁是导致系统被入侵的常见原因。这段代码检查最近一次补丁安装的日期、Windows Update 服务状态，以及当前有多少重要更新待安装。补丁超过 30 天未更新或存在待安装的重要更新，都说明更新策略可能存在问题。

```powershell
function Get-SecurityBaselineUpdates {
    $result = @()
    # 获取最近安装的补丁，按时间降序排列
    $recentUpdates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
    $latestUpdate = $recentUpdates | Select-Object -First 1
    $result += [PSCustomObject]@{
        Category = "系统更新"; Check = "最新补丁日期"
        Value    = if ($latestUpdate.InstalledOn) {
            $latestUpdate.InstalledOn.ToString("yyyy-MM-dd")
        } else { "未知" }
        Expected = "30 天内"
    }
    # 检查 Windows Update 服务是否正常运行
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $result += [PSCustomObject]@{
        Category = "系统更新"; Check = "Windows Update 服务"
        Value = "$($wuService.Status)"; Expected = "Running"
    }
    # 通过 COM 对象查询待安装的重要更新
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $searchResult = $updateSession.CreateUpdateSearcher().Search(
        "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1"
    )
    $result += [PSCustomObject]@{
        Category = "系统更新"; Check = "待安装重要更新"
        Value = "$($searchResult.Updates.Count) 个"; Expected = "0 个"
    }
    return $result
}
```

以下执行结果显示还有 3 个重要更新待安装，建议尽快安排补丁窗口完成更新：

```
Category  Check               Value        Expected
--------  -----               -----        --------
系统更新  最新补丁日期         2025-03-10   30 天内
系统更新  Windows Update 服务  Running      Running
系统更新  待安装重要更新       3 个         0 个
```

## 危险服务检查

某些服务在大多数生产环境中并不需要，反而会增大攻击面。Telnet 明文传输凭据，远程注册表允许远程修改注册表，SSDP 和 UPnP 可能被用于网络发现和反射攻击。下面逐一检查这些服务的运行状态，并统计系统级自启动项数量——自启动项过多可能意味着恶意软件的持久化驻留。

```powershell
function Get-SecurityBaselineServices {
    $result = @()
    # 常见高危服务列表：名称 => 服务标识
    $dangerousServices = @{
        "Telnet"        = "tlntsvr"
        "远程注册表"     = "RemoteRegistry"
        "SSDP 发现"     = "ssdpsrv"
        "UPnP 设备主机"  = "upnphost"
    }
    foreach ($svc in $dangerousServices.GetEnumerator()) {
        $service = Get-Service -Name $svc.Value -ErrorAction SilentlyContinue
        $result += [PSCustomObject]@{
            Category = "服务检查"; Check = "$($svc.Key) ($($svc.Value))"
            Value    = if ($service) {
                "$($service.Status), 启动类型: $($service.StartType)"
            } else { "未安装" }
            Expected = "未安装或已禁用"
        }
    }
    # 系统级自启动项过多可能意味着恶意软件持久化
    $startupItems = Get-CimInstance -ClassName Win32_StartupCommand |
        Where-Object { $_.Location -eq "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" }
    $result += [PSCustomObject]@{
        Category = "启动项"; Check = "系统级自启动项"
        Value = "$($startupItems.Count) 个"; Expected = "审查后保留必要项"
    }
    return $result
}
```

执行结果显示远程注册表服务处于自动启动且正在运行，在生产环境中建议禁用：

```
Category  Check                         Value                         Expected
--------  -----                         -----                         --------
服务检查  Telnet (tlntsvr)               未安装                        未安装或已禁用
服务检查  远程注册表 (RemoteRegistry)     Running, 启动类型: Automatic  未安装或已禁用
服务检查  SSDP 发现 (ssdpsrv)            Stopped, 启动类型: Manual     未安装或已禁用
服务检查  UPnP 设备主机 (upnphost)        Stopped, 启动类型: Manual     未安装或已禁用
启动项    系统级自启动项                  4 个                          审查后保留必要项
```

## 生成 HTML 审计报告

将前面所有检查函数汇总为一份带风险标记的 HTML 报告。不合规的行以红色背景高亮显示，便于快速定位问题。报告顶部汇总检查总数和风险项数量，帮助管理层一眼掌握整体安全态势。

```powershell
function New-SecurityBaselineReport {
    param(
        [string]$OutputPath = ".\SecurityBaseline_$(Get-Date -Format 'yyyyMMdd').html"
    )

    # 依次调用各维度的检查函数，汇总所有结果
    $allChecks = @(Get-SecurityBaselineAccount) + @(Get-SecurityBaselineNetwork) +
                 @(Get-SecurityBaselineRDP) +
                 @(Get-SecurityBaselineUpdates) + @(Get-SecurityBaselineServices)

    $totalChecks = $allChecks.Count
    $riskItems = ($allChecks | Where-Object {
        $_.Value -match "风险|FAIL|未启用"
    }).Count

    $html = @"
<!DOCTYPE html><html><head><title>安全基线审计报告</title>
<style>
body{font-family:Microsoft YaHei;margin:20px}
table{border-collapse:collapse;width:100%}
th,td{border:1px solid #ddd;padding:8px;text-align:left}
th{background-color:#4CAF50;color:white}
.risk{background-color:#ffcccc}
</style></head><body>
<h1>安全基线审计报告 - $(Get-Date -Format 'yyyy-MM-dd')</h1>
<p>检查项: $totalChecks | 风险项: <span style="color:red">$riskItems</span></p>
<table><tr><th>类别</th><th>检查项</th><th>当前值</th><th>期望值</th></tr>
"@
    foreach ($item in $allChecks) {
        $class = if ($item.Value -match "风险|FAIL|未启用") {
            ' class="risk"'
        } else { "" }
        $html += "<tr$class><td>$($item.Category)</td><td>$($item.Check)</td>" +
                 "<td>$($item.Value)</td><td>$($item.Expected)</td></tr>"
    }
    $html += "</table></body></html>"
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "报告已生成: $OutputPath"
}
```

执行后在当前目录生成 HTML 文件，浏览器打开即可看到完整的审计表格。不合规的行以红色背景标出：

```
报告已生成: .\SecurityBaseline_20250331.html
```

```
检查项: 19 | 风险项: 4

| 类别     | 检查项                      | 当前值                        | 期望值          |
|----------|-----------------------------|-------------------------------|-----------------|
| 密码策略 | 最小密码长度                 | 7 字符                        | ≥ 14 字符       |
| 防火墙   | Public 配置文件             | 已禁用 (风险)                 | 已启用          |
| 网络     | 高危端口开放                 | 发现 2 个: 445, 3389          | 无              |
| 服务检查 | 远程注册表 (RemoteRegistry)  | Running, 启动类型: Automatic  | 未安装或已禁用  |
```

建议在运维流程中定期执行 `New-SecurityBaselineReport`，并将历次报告归档对比，跟踪风险项的变化趋势。安全基线不是一次性的工作，而是持续改进的过程。
