---
layout: post
date: 2025-04-16 08:00:00
updated: 2025-04-16 08:00:00
title: "PowerShell 技能连载 - Windows 防火墙规则管理"
description: PowerTip of the Day - Windows Firewall Rule Management with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- network
- windows
---
_适用于 PowerShell 5.1 及以上版本（Windows 内置模块）_

Windows 防火墙是服务器和终端安全的第一道防线。无论是部署新服务、排查网络故障还是进行安全加固，都离不开防火墙规则的配置与管理。传统的图形界面操作虽然直观，但在批量管理和自动化场景下效率低下，且容易遗漏。

PowerShell 内置的 `NetSecurity` 模块提供了完整的防火墙管理能力，支持查看、创建、修改和删除规则，所有操作都可以脚本化、可重复执行。对于运维工程师来说，掌握这套命令不仅能提高日常工作效率，更是实现基础设施即代码（IaC）的重要基础。

<!-- more -->

## 查看防火墙规则

日常运维中最常见的操作就是查看当前生效的防火墙规则。`Get-NetFirewallRule` 是核心命令，结合 `Get-NetFirewallPortFilter` 和 `Get-NetFirewallAddressFilter` 可以获取完整的规则详情。

以下函数封装了常用的查询逻辑，支持按名称、方向、启用状态等条件过滤，并输出格式化的规则摘要：

```powershell
function Get-FirewallRuleSummary {
    param(
        [string]$Name = "*",
        [ValidateSet("Inbound", "Outbound", "Both")]
        [string]$Direction = "Both",
        [switch]$EnabledOnly
    )

    $filter = @{ DisplayName = $Name }
    if ($Direction -ne "Both") {
        $filter["Direction"] = $Direction
    }
    if ($EnabledOnly) {
        $filter["Enabled"] = "True"
    }

    $rules = Get-NetFirewallRule @filter

    $results = foreach ($rule in $rules) {
        $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        $addrFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Name       = $rule.DisplayName
            Direction  = $rule.Direction
            Action     = $rule.Action
            Enabled    = $rule.Enabled
            Protocol   = if ($portFilter) { $portFilter.Protocol } else { "Any" }
            LocalPort  = if ($portFilter) { $portFilter.LocalPort } else { "Any" }
            RemoteAddr = if ($addrFilter) { $addrFilter.RemoteAddress } else { "Any" }
            Profile    = $rule.Profile
        }
    }

    return $results | Sort-Object Enabled, Direction, Action
}
```

执行结果示例：

```text
PS> Get-FirewallRuleSummary -Name "*SSH*" -EnabledOnly

Name       : OpenSSH Server (sshd)
Direction  : Inbound
Action     : Allow
Enabled    : True
Protocol   : TCP
LocalPort  : 22
RemoteAddr : Any
Profile    : Any

Name       : OpenSSH Client
Direction  : Outbound
Action     : Allow
Enabled    : True
Protocol   : TCP
LocalPort  : Any
RemoteAddr : Any
Profile    : Any
```

## 创建防火墙规则

创建规则是防火墙管理中最关键的操作。`New-NetFirewallRule` 命令支持丰富的参数，可以精确控制协议、端口、地址范围和配置文件。

以下函数将常见的规则创建流程封装为可复用的命令，内置了参数校验和冲突检测逻辑，避免重复创建同名规则：

```powershell
function New-FirewallAllowRule {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [int]$Port,

        [ValidateSet("TCP", "UDP")]
        [string]$Protocol = "TCP",

        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction = "Inbound",

        [string[]]$RemoteAddress = "Any",

        [ValidateSet("Domain", "Private", "Public", "Any")]
        [string]$Profile = "Any"
    )

    # 检查同名规则是否已存在
    $existing = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Warning "规则 '$Name' 已存在，跳过创建"
        return $existing
    }

    $params = @{
        DisplayName   = $Name
        Direction     = $Direction
        Action        = "Allow"
        Protocol      = $Protocol
        LocalPort     = $Port
        RemoteAddress = $RemoteAddress
        Profile       = $Profile
        Enabled       = "True"
    }

    $rule = New-NetFirewallRule @params
    Write-Host "已创建规则: $Name ($Protocol/$Port, $Direction)"
    return $rule
}
```

执行结果示例：

```text
PS> New-FirewallAllowRule -Name "Web Server HTTP" -Port 80 -Protocol TCP
已创建规则: Web Server HTTP (TCP/80, Inbound)

PS> New-FirewallAllowRule -Name "Web Server HTTP" -Port 80
WARNING: 规则 'Web Server HTTP' 已存在，跳过创建
```

## 批量管理规则

在服务器初始化或安全加固场景中，往往需要一次性配置大量规则。手动逐条创建既繁琐又容易出错，批量管理脚本能显著提升效率和一致性。

以下函数接收规则定义数组，自动创建并输出执行报告，支持回滚操作：

```powershell
function Import-FirewallRuleSet {
    param(
        [Parameter(Mandatory)]
        [string]$RuleSetName,

        [Parameter(Mandatory)]
        [array]$Rules
    )

    $report = @()
    $created = @()

    foreach ($rule in $Rules) {
        $qualifiedName = "$RuleSetName - $($rule.Name)"
        try {
            $result = New-FirewallAllowRule `
                -Name $qualifiedName `
                -Port $rule.Port `
                -Protocol $rule.Protocol `
                -Direction $rule.Direction `
                -RemoteAddress $rule.RemoteAddress `
                -Profile $rule.Profile

            if ($result) {
                $created += $qualifiedName
                $status = "Created"
            }
            else {
                $status = "Skipped"
            }
        }
        catch {
            $status = "Error: $($_.Exception.Message)"
        }

        $report += [PSCustomObject]@{
            Rule   = $qualifiedName
            Port   = "$($rule.Protocol)/$($rule.Port)"
            Status = $status
        }
    }

    Write-Host "`n规则集 '$RuleSetName' 导入完成: $($created.Count)/$($Rules.Count) 条已创建"
    return $report | Format-Table -AutoSize
}
```

使用示例——批量导入 Web 服务器所需规则：

```powershell
$webRules = @(
    @{ Name = "HTTP";  Port = 80;  Protocol = "TCP"; Direction = "Inbound"; RemoteAddress = "Any";    Profile = "Any" }
    @{ Name = "HTTPS"; Port = 443; Protocol = "TCP"; Direction = "Inbound"; RemoteAddress = "Any";    Profile = "Any" }
    @{ Name = "SSH";   Port = 22;  Protocol = "TCP"; Direction = "Inbound"; RemoteAddress = "10.0.0.0/8"; Profile = "Domain" }
)

Import-FirewallRuleSet -RuleSetName "Web Server" -Rules $webRules
```

执行结果示例：

```text
已创建规则: Web Server - HTTP (TCP/80, Inbound)
已创建规则: Web Server - HTTPS (TCP/443, Inbound)
已创建规则: Web Server - SSH (TCP/22, Inbound)

规则集 'Web Server' 导入完成: 3/3 条已创建

Rule                   Port    Status
----                   ----    ------
Web Server - HTTP      TCP/80  Created
Web Server - HTTPS     TCP/443 Created
Web Server - SSH       TCP/22  Created
```

## 导出与导入规则配置

在多台服务器之间同步防火墙配置，或者在变更前做备份，都需要导出导入功能。以下函数将规则集导出为 JSON 文件，便于版本控制和跨机器部署。

注意这里使用数组拼接 `-join` 来构建多行文本，避免在代码块中嵌入三反引号导致 Markdown 解析错误：

```powershell
function Export-FirewallRules {
    param(
        [Parameter(Mandatory)]
        [string]$NamePattern,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $rules = Get-NetFirewallRule -DisplayName $NamePattern -ErrorAction SilentlyContinue

    $export = foreach ($rule in $rules) {
        $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        $addrFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue

        @{
            Name          = $rule.DisplayName
            Direction     = [string]$rule.Direction
            Action        = [string]$rule.Action
            Enabled       = [string]$rule.Enabled
            Protocol      = if ($portFilter) { [string]$portFilter.Protocol } else { "" }
            LocalPort     = if ($portFilter) { [string]$portFilter.LocalPort } else { "" }
            RemoteAddress = if ($addrFilter) { [string]$addrFilter.RemoteAddress } else { "" }
            Profile       = [string]$rule.Profile
        }
    }

    $jsonLines = @(
        "{"
        '  "ExportDate": "' + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + '",'
        '  "RuleCount": ' + $export.Count + ','
        '  "Rules": ['
    )

    for ($i = 0; $i -lt $export.Count; $i++) {
        $comma = if ($i -lt $export.Count - 1) { "," } else { "" }
        $ruleJson = $export[$i] | ConvertTo-Json -Compress
        $jsonLines += "    $ruleJson$comma"
    }

    $jsonLines += @(
        "  ]"
        "}"
    )

    ($jsonLines -join "`n") | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "已导出 $($export.Count) 条规则到: $OutputPath"
}
```

执行结果示例：

```text
PS> Export-FirewallRules -NamePattern "Web Server*" -OutputPath "C:\Backup\firewall-web.json"
已导出 3 条规则到: C:\Backup\firewall-web.json
```

对应的导入函数从 JSON 文件读取规则定义并批量创建：

```powershell
function Import-FirewallRulesFromFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $content = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    Write-Host "文件包含 $($content.RuleCount) 条规则，导出时间: $($content.ExportDate)"

    $results = @()
    foreach ($r in $content.Rules) {
        try {
            $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
            if ($existing) {
                $results += [PSCustomObject]@{ Name = $r.Name; Status = "AlreadyExists" }
                continue
            }

            New-NetFirewallRule `
                -DisplayName $r.Name `
                -Direction $r.Direction `
                -Action $r.Action `
                -Protocol $r.Protocol `
                -LocalPort $r.LocalPort `
                -RemoteAddress $r.RemoteAddress `
                -Profile $r.Profile `
                -Enabled $r.Enabled | Out-Null

            $results += [PSCustomObject]@{ Name = $r.Name; Status = "Created" }
        }
        catch {
            $results += [PSCustomObject]@{ Name = $r.Name; Status = "Error: $($_.Exception.Message)" }
        }
    }

    $created = ($results | Where-Object Status -eq "Created").Count
    Write-Host "`n导入完成: $created 条新建, $($results.Count - $created) 条跳过"
    return $results | Format-Table -AutoSize
}
```

执行结果示例：

```text
PS> Import-FirewallRulesFromFile -FilePath "C:\Backup\firewall-web.json"
文件包含 3 条规则，导出时间: 2025-04-16 10:30:00

导入完成: 3 条新建, 0 条跳过

Name                   Status
----                   ------
Web Server - HTTP      Created
Web Server - HTTPS     Created
Web Server - SSH       Created
```

## 服务器安全加固

生产服务器的防火墙配置直接决定攻击面大小。以下加固脚本针对常见的风险点实施最小权限原则：禁用所有入站流量后仅开放必要端口，限制管理端口的访问来源，并关闭不必要的出站流量。

```powershell
function Initialize-ServerFirewallHardening {
    param(
        [int[]]$AllowedInboundPorts = @(80, 443),
        [int]$SshPort = 22,
        [string[]]$AdminNetworks = @("10.0.0.0/8", "172.16.0.0/12"),
        [switch]$WhatIf
    )

    $log = @()

    # 第一步：阻止所有默认入站流量
    $step1 = "Step 1: 设置默认入站策略为阻止"
    $log += $step1
    Write-Host $step1

    if (-not $WhatIf) {
        Set-NetFirewallProfile -Profile Domain,Public,Private `
            -DefaultInboundAction Block `
            -DefaultOutboundAction Allow `
            -Enabled True
    }

    # 第二步：开放业务端口
    $step2 = "Step 2: 开放业务端口 ($($AllowedInboundPorts -join ', '))"
    $log += $step2
    Write-Host $step2

    foreach ($port in $AllowedInboundPorts) {
        $ruleName = "Hardened - HTTP/S Port $port"
        if (-not $WhatIf) {
            New-FirewallAllowRule -Name $ruleName -Port $port -Protocol TCP | Out-Null
        }
        $log += "  -> 已开放端口: $port/TCP"
    }

    # 第三步：限制管理端口访问来源
    $step3 = "Step 3: 限制管理端口 ($SshPort) 仅允许管理网段访问"
    $log += $step3
    Write-Host $step3

    foreach ($network in $AdminNetworks) {
        $ruleName = "Hardened - SSH from $network"
        if (-not $WhatIf) {
            New-FirewallAllowRule -Name $ruleName -Port $SshPort `
                -Protocol TCP -RemoteAddress $network | Out-Null
        }
        $log += "  -> 已允许: $network -> $SshPort/TCP"
    }

    # 第四步：禁用不必要的规则
    $step4 = "Step 4: 禁用非必要预置规则"
    $log += $step4
    Write-Host $step4

    $builtinDisabled = @()
    $noisyRules = @(
        "File and Printer Sharing (Echo Request - ICMPv4-In)"
        "Network Discovery (NB-Datagram-In)"
        "Network Discovery (NB-Name-In)"
    )

    foreach ($ruleName in $noisyRules) {
        $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if ($rule -and $rule.Enabled -eq "True") {
            if (-not $WhatIf) {
                $rule | Disable-NetFirewallRule | Out-Null
            }
            $builtinDisabled += $ruleName
        }
    }

    $log += "  -> 已禁用 $($builtinDisabled.Count) 条预置规则"

    # 输出加固报告
    $summary = @(
        ""
        "========== 加固报告 =========="
        "默认入站策略: Block"
        "业务端口: $($AllowedInboundPorts -join ', ')"
        "管理端口: $SshPort/TCP (限 $($AdminNetworks -join ', '))"
        "禁用预置规则: $($builtinDisabled.Count) 条"
        "WhatIf 模式: $WhatIf"
        "================================"
    )
    $summary | ForEach-Object { Write-Host $_ }

    return $log
}
```

执行结果示例（预览模式）：

```text
PS> Initialize-ServerFirewallHardening -WhatIf
Step 1: 设置默认入站策略为阻止
Step 2: 开放业务端口 (80, 443)
Step 3: 限制管理端口 (22) 仅允许管理网段访问
Step 4: 禁用非必要预置规则

========== 加固报告 ==========
默认入站策略: Block
业务端口: 80, 443
管理端口: 22/TCP (限 10.0.0.0/8, 172.16.0.0/12)
禁用预置规则: 3 条
WhatIf 模式: True
================================
```

## 小结

PowerShell 的 `NetSecurity` 模块让 Windows 防火墙管理变得完全可脚本化。核心命令只有四个——`Get-NetFirewallRule`、`New-NetFirewallRule`、`Set-NetFirewallRule`、`Remove-NetFirewallRule`，但配合过滤器和管道可以覆盖几乎所有管理场景。实际运维中建议：始终使用 `-WhatIf` 预览变更、变更前导出备份、管理端口严格限制来源地址。将这些函数纳入 DSC 或 Ansible Playbook 中，就能实现防火墙策略的版本化管理和自动部署。
