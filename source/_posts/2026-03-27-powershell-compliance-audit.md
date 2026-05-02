---
layout: post
date: 2026-03-27 08:00:00
updated: 2026-03-27 08:00:00
title: "PowerShell 技能连载 - 合规审计自动化"
description: PowerTip of the Day - Compliance Audit Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- compliance
- audit
- security
- reporting
---

_适用于 PowerShell 5.1 及以上版本_

在企业 IT 管理中，合规审计是一项持续性工作。无论是为了满足 CIS Benchmarks、ISO 27001 还是行业监管要求，安全团队都需要定期检查系统配置是否符合既定的安全基线。手动逐项检查不仅耗时巨大，而且容易出现遗漏和标准不一致的问题，尤其是在服务器数量较多的环境中。

PowerShell 凭借其对 Windows 系统的深度访问能力，可以从密码策略、账户策略、审核策略到注册表配置、防火墙规则、文件权限等维度全面采集安全配置信息。将审计规则标准化为可执行脚本后，每次审计都能以完全一致的检查项和判定逻辑运行，确保结果的可重复性和可比性。

本文将构建一套完整的合规审计自动化方案，涵盖安全基线检查、系统配置审计和合规报告生成三个核心模块，帮助企业将审计周期从数天缩短到数分钟，并输出结构化的 HTML 报告供管理层审阅。

<!-- more -->

## 安全基线检查

安全基线检查是合规审计的基础。我们将密码策略、账户策略、审核策略和用户权限分配四项关键检查整合到一个函数中，每项检查都映射到 CIS Benchmark 的具体控制项，并给出合规/不合规的判定结果。

```powershell
function Invoke-SecurityBaselineCheck {
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $results = @()

    # 密码策略检查
    $passwordPolicy = net accounts |
        Select-String -Pattern 'Minimum password length|Maximum password age|Minimum password age|Password history length'

    $passwordLengthLine = $passwordPolicy | Where-Object { $_ -match 'Minimum password length' }
    $minLength = if ($passwordLengthLine -match '(\d+)') { [int]$Matches[1] } else { 0 }

    $results += [PSCustomObject]@{
        Category = '密码策略'
        CheckItem = '最小密码长度'
        Expected  = '>= 14 字符 (CIS 1.1.1)'
        Actual    = "$minLength 字符"
        Status    = if ($minLength -ge 14) { 'Compliant' } else { 'Non-Compliant' }
        Severity  = 'High'
    }

    $maxAgeLine = $passwordPolicy | Where-Object { $_ -match 'Maximum password age' }
    $maxAge = if ($maxAgeLine -match '(\d+)') { [int]$Matches[1] } else { 0 }

    $results += [PSCustomObject]@{
        Category = '密码策略'
        CheckItem = '密码最大使用期限'
        Expected  = '<= 60 天 (CIS 1.1.3)'
        Actual    = "$maxAge 天"
        Status    = if ($maxAge -gt 0 -and $maxAge -le 60) { 'Compliant' } else { 'Non-Compliant' }
        Severity  = 'Medium'
    }

    # 账户策略检查
    $lockoutPolicy = net accounts |
        Select-String -Pattern 'Lockout threshold|Lockout duration|Lockout observation'

    $lockoutLine = $lockoutPolicy | Where-Object { $_ -match 'Lockout threshold' }
    $lockoutThreshold = if ($lockoutLine -match '(\d+)') { [int]$Matches[1] } else { 0 }

    $results += [PSCustomObject]@{
        Category = '账户策略'
        CheckItem = '账户锁定阈值'
        Expected  = '<= 5 次失败尝试 (CIS 1.2.1)'
        Actual    = if ($lockoutThreshold -eq 0) { 'Never' } else { "$lockoutThreshold 次" }
        Status    = if ($lockoutThreshold -gt 0 -and $lockoutThreshold -le 5) { 'Compliant' } else { 'Non-Compliant' }
        Severity  = 'High'
    }

    # 审核策略检查
    $auditPolicies = auditpol /get /category:* /r 2>$null |
        ConvertFrom-Csv |
        Where-Object { $_.'Inclusion Setting' -eq 'No Auditing' -and $_.'Subcategory' -ne '' }

    $criticalAuditCategories = @(
        'Logon',
        'Logoff',
        'Special Logon',
        'User Account Management',
        'Security State Change'
    )

    foreach ($critical in $criticalAuditCategories) {
        $found = $auditPolicies | Where-Object { $_.'Subcategory' -eq $critical }
        $results += [PSCustomObject]@{
            Category = '审核策略'
            CheckItem = "审核: $critical"
            Expected  = 'Success and Failure (CIS 17.x)'
            Actual    = if ($found) { 'No Auditing' } else { '已配置' }
            Status    = if ($found) { 'Non-Compliant' } else { 'Compliant' }
            Severity  = 'High'
        }
    }

    # 用户权限检查 - 检查敏感权限的分配情况
    $sensitivePrivileges = @{
        'SeDebugPrivilege'      = '调试程序'
        'SeTakeOwnershipPrivilege' = '取得文件所有权'
        'SeLoadDriverPrivilege' = '加载和卸载设备驱动程序'
    }

    foreach ($privilege in $sensitivePrivileges.GetEnumerator()) {
        $privOutput = secedit /export /cfg "$env:TEMP\secedit.cfg" 2>$null
        $privLine = Get-Content "$env:TEMP\secedit.cfg" |
            Select-String -Pattern $privilege.Key
        $assignedTo = if ($privLine) {
            ($privLine.Line -split '=')[1].Trim()
        } else {
            '未找到'
        }

        $isAdminOnly = $assignedTo -match 'Administrators' -and
                       $assignedTo -notmatch 'Everyone|Users|Authenticated'

        $results += [PSCustomObject]@{
            Category = '用户权限'
            CheckItem = $privilege.Value
            Expected  = '仅 Administrators (CIS 2.x)'
            Actual    = $assignedTo
            Status    = if ($isAdminOnly) { 'Compliant' } else { 'Non-Compliant' }
            Severity  = 'Critical'
        }
    }

    Remove-Item "$env:TEMP\secedit.cfg" -ErrorAction SilentlyContinue

    $results | Sort-Object Severity, Category, CheckItem
}
```

运行基线检查后，可以看到各项安全策略的合规状态：

```
Category  CheckItem              Expected                    Actual         Status          Severity
-------  ----------              --------                    ------         ------          --------
密码策略  最小密码长度            >= 14 字符 (CIS 1.1.1)      8 字符         Non-Compliant   High
密码策略  密码最大使用期限        <= 60 天 (CIS 1.1.3)        90 天          Non-Compliant   Medium
账户策略  账户锁定阈值            <= 5 次失败尝试 (CIS 1.2.1) 5 次           Compliant       High
审核策略  审核: Logon            Success and Failure (CIS)   已配置         Compliant       High
审核策略  审核: User Account Management Success and Failure (CIS) No Auditing Non-Compliant   High
用户权限  调试程序               仅 Administrators (CIS 2.x) Administrators Compliant       Critical
用户权限  取得文件所有权         仅 Administrators (CIS 2.x) Administrators Compliant       Critical
```

## 系统配置审计

安全基线只覆盖了策略层面的检查，实际运行环境中的服务、防火墙、注册表和文件系统同样需要审计。下面这个函数对系统配置进行全面扫描，检查每项配置是否满足 CIS 和 ISO 27001 的要求。

```powershell
function Invoke-SystemConfigAudit {
    [CmdletBinding()]
    param(
        [string[]]$CriticalRegistryKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
            'HKLM:\SYSTEM\CurrentControlSet\Services\LDAP',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
        )
    )

    $auditResults = @()

    # 服务配置检查
    $insecureServices = @{
        'SysMain'         = 'SuperFetch/SysMain 可能导致信息泄露'
        'RemoteRegistry'  = '远程注册表访问应被禁用'
        'XblAuthManager'  = 'Xbox 服务不应存在于服务器'
        'WSearch'         = 'Windows Search 在服务器上应禁用'
    }

    foreach ($svc in $insecureServices.GetEnumerator()) {
        $service = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
        $startType = try {
            (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Key)" -ErrorAction Stop).Start
        } catch { 4 }

        $isDisabled = $service.Status -eq 'Stopped' -and $startType -eq 4

        $auditResults += [PSCustomObject]@{
            Category = '服务配置'
            CheckItem = "服务: $($svc.Key)"
            Expected  = '已禁用 (CIS 9.x)'
            Actual    = "状态: $($service.Status), 启动类型: $(if($startType -eq 4){'Disabled'}elseif($startType -eq 3){'Manual'}else{'Auto'})"
            Status    = if ($isDisabled) { 'Compliant' } else { 'Non-Compliant' }
            Severity  = 'Medium'
            Remediation = "Set-Service -Name $($svc.Key) -StartupType Disabled; Stop-Service -Name $($svc.Key) -Force"
        }
    }

    # 防火墙规则审计
    $firewallProfiles = Get-NetFirewallProfile |
        Select-Object Name, Enabled

    foreach ($profile in $firewallProfiles) {
        $auditResults += [PSCustomObject]@{
            Category = '防火墙'
            CheckItem = "防火墙配置文件: $($profile.Name)"
            Expected  = '已启用 (CIS 9.1.x)'
            Actual    = "Enabled: $($profile.Enabled)"
            Status    = if ($profile.Enabled) { 'Compliant' } else { 'Non-Compliant' }
            Severity  = 'Critical'
            Remediation = "Set-NetFirewallProfile -Name $($profile.Name) -Enabled True"
        }
    }

    # 危险入站规则检查
    $dangerousRules = Get-NetFirewallRule |
        Where-Object {
            $_.Direction -eq 'Inbound' -and
            $_.Action -eq 'Allow' -and
            $_.Enabled -eq 'True'
        } | Get-NetFirewallPortFilter |
        Where-Object { $_.LocalPort -in @('3389', '22', '445', '139') }

    $rdpExposed = $dangerousRules |
        Where-Object { $_.LocalPort -eq '3389' }

    if ($rdpExposed) {
        $auditResults += [PSCustomObject]@{
            Category = '防火墙'
            CheckItem = 'RDP (3389) 入站规则'
            Expected  = '不应公开暴露 (CIS 9.2.x)'
            Actual    = '存在允许的入站规则'
            Status    = 'Non-Compliant'
            Severity  = 'Critical'
            Remediation = '限制 RDP 访问源 IP 范围，或通过 VPN 隧道访问'
        }
    }

    # 注册表安全审计
    $regChecks = @(
        @{
            Path   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Name   = 'EnableLUA'
            Expected = 1
            Desc   = 'UAC 必须启用 (CIS 2.3.17.3)'
            Severity = 'Critical'
        },
        @{
            Path   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Name   = 'ConsentPromptBehaviorAdmin'
            Expected = 2
            Desc   = 'UAC 提示级别应为"始终通知" (CIS 2.3.17.5)'
            Severity = 'Medium'
        },
        @{
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg'
            Name   = 'RemoteAllowed'
            Expected = 1
            Desc   = '远程注册表访问应受限制 (CIS 2.3.10.3)'
            Severity = 'High'
        }
    )

    foreach ($check in $regChecks) {
        $actualValue = try {
            (Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction Stop).($check.Name)
        } catch { $null }

        $auditResults += [PSCustomObject]@{
            Category = '注册表安全'
            CheckItem = $check.Desc
            Expected  = "值 = $($check.Expected)"
            Actual    = if ($null -ne $actualValue) { "值 = $actualValue" } else { '键值不存在' }
            Status    = if ($actualValue -eq $check.Expected) { 'Compliant' } else { 'Non-Compliant' }
            Severity  = $check.Severity
            Remediation = "Set-ItemProperty -Path '$($check.Path)' -Name $($check.Name) -Value $($check.Expected)"
        }
    }

    # 关键目录权限审计
    $sensitivePaths = @(
        @{ Path = 'C:\Windows\System32\config'; ExpectedOwner = 'BUILTIN\Administrators'; Desc = 'SAM/SYSTEM 文件目录' },
        @{ Path = 'C:\ProgramData'; ExpectedOwner = 'BUILTIN\Administrators'; Desc = '公共程序数据目录' }
    )

    foreach ($sp in $sensitivePaths) {
        if (Test-Path $sp.Path) {
            $acl = Get-Acl -Path $sp.Path
            $owner = $acl.Owner

            $auditResults += [PSCustomObject]@{
                Category = '文件权限'
                CheckItem = "目录所有者: $($sp.Desc)"
                Expected  = "所有者 = $($sp.ExpectedOwner) (CIS 13.x)"
                Actual    = "所有者 = $owner"
                Status    = if ($owner -match 'Administrators') { 'Compliant' } else { 'Non-Compliant' }
                Severity  = 'High'
                Remediation = "手动检查并修复 $sp.Path 的 NTFS 权限"
            }
        }
    }

    $auditResults | Sort-Object Severity, Category, CheckItem
}
```

系统配置审计的输出结果示例如下：

```
Category  CheckItem                              Expected                              Actual           Status          Severity
--------  ----------                              --------                              ------           ------          --------
注册表安全  UAC 必须启用 (CIS 2.3.17.3)            值 = 1                                值 = 1           Compliant       Critical
防火墙    防火墙配置文件: Domain                   已启用 (CIS 9.1.x)                    Enabled: True    Compliant       Critical
防火墙    RDP (3389) 入站规则                      不应公开暴露 (CIS 9.2.x)              存在允许的入站规则 Non-Compliant  Critical
注册表安全  远程注册表访问应受限制 (CIS 2.3.10.3)   值 = 1                                值 = 1           Compliant       High
文件权限   目录所有者: SAM/SYSTEM 文件目录          所有者 = BUILTIN\Administrators (CIS)  所有者 = ...     Compliant       High
服务配置   服务: RemoteRegistry                    已禁用 (CIS 9.x)                      状态: Running    Non-Compliant   Medium
注册表安全  UAC 提示级别应为"始终通知" (CIS 2.3.17.5) 值 = 2                              值 = 5           Non-Compliant   Medium
```

## 合规报告生成

审计数据的最终价值体现在报告上。下面的函数将前面两个模块的检查结果汇总，生成一份结构化的 HTML 报告，包含合规率统计、风险等级分布、各检查项的详细状态，以及每个不合规项的具体修复建议。

```powershell
function New-ComplianceReport {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$env:USERPROFILE\Desktop\ComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",
        [string]$Organization = 'IT 安全团队'
    )

    Write-Host "正在执行安全基线检查..." -ForegroundColor Cyan
    $baselineResults = Invoke-SecurityBaselineCheck

    Write-Host "正在执行系统配置审计..." -ForegroundColor Cyan
    $configResults = Invoke-SystemConfigAudit

    $allResults = @($baselineResults) + @($configResults)
    $totalCount = $allResults.Count
    $compliantCount = ($allResults | Where-Object { $_.Status -eq 'Compliant' }).Count
    $complianceRate = [math]::Round(($compliantCount / $totalCount) * 100, 1)

    # 按严重等级统计
    $severityStats = $allResults |
        Group-Object Severity |
        Select-Object Name, Count

    # 按类别统计合规率
    $categoryStats = $allResults |
        Group-Object Category |
        ForEach-Object {
            $compliant = ($_.Group | Where-Object { $_.Status -eq 'Compliant' }).Count
            [PSCustomObject]@{
                Category       = $_.Name
                Total          = $_.Count
                Compliant      = $compliant
                NonCompliant   = $_.Count - $compliant
                ComplianceRate = [math]::Round(($compliant / $_.Count) * 100, 1)
            }
        }

    # 修复建议汇总
    $remediations = $allResults |
        Where-Object { $_.Status -eq 'Non-Compliant' -and $_.Remediation } |
        Select-Object CheckItem, Severity, Remediation |
        Sort-Object Severity

    Write-Host "正在生成 HTML 报告..." -ForegroundColor Cyan

    $severityColorMap = @{
        'Critical' = '#dc3545'
        'High'     = '#fd7e14'
        'Medium'   = '#ffc107'
        'Low'      = '#28a745'
    }

    # 构建 HTML 报告
    $htmlSections = @()
    $htmlSections += '<!DOCTYPE html><html lang="zh-CN"><head>'
    $htmlSections += '<meta charset="UTF-8">'
    $htmlSections += '<title>合规审计报告</title>'
    $htmlSections += '<style>'
    $htmlSections += 'body { font-family: "Microsoft YaHei", sans-serif; margin: 20px; background: #f5f5f5; }'
    $htmlSections += 'h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }'
    $htmlSections += '.summary { display: flex; gap: 20px; margin: 20px 0; }'
    $htmlSections += '.card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); flex: 1; text-align: center; }'
    $htmlSections += '.rate { font-size: 48px; font-weight: bold; }'
    $htmlSections += 'table { width: 100%; border-collapse: collapse; background: white; margin: 10px 0; }'
    $htmlSections += 'th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }'
    $htmlSections += 'th { background: #007bff; color: white; }'
    $htmlSections += '.compliant { color: #28a745; font-weight: bold; }'
    $htmlSections += '.non-compliant { color: #dc3545; font-weight: bold; }'
    $htmlSections += '</style></head><body>'
    $htmlSections += "<h1>合规审计报告</h1>"
    $htmlSections += "<p>组织: $Organization | 生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | 计算机: $env:COMPUTERNAME</p>"

    # 概览卡片
    $rateColor = if ($complianceRate -ge 80) { '#28a745' } elseif ($complianceRate -ge 60) { '#ffc107' } else { '#dc3545' }
    $htmlSections += '<div class="summary">'
    $htmlSections += "<div class='card'><div class='rate' style='color:$rateColor'>$complianceRate%</div><div>总体合规率</div></div>"
    $htmlSections += "<div class='card'><div class='rate' style='color:#333'>$compliantCount / $totalCount</div><div>合规项 / 总检查项</div></div>"

    $criticalCount = ($severityStats | Where-Object { $_.Name -eq 'Critical' }).Count
    $htmlSections += "<div class='card'><div class='rate' style='color:#dc3545'>$criticalCount</div><div>Critical 不合规项</div></div>"
    $htmlSections += '</div>'

    # 类别合规率表格
    $htmlSections += '<h2>分类合规率</h2><table><tr><th>类别</th><th>总数</th><th>合规</th><th>不合规</th><th>合规率</th></tr>'
    foreach ($cat in $categoryStats) {
        $catRateColor = if ($cat.ComplianceRate -ge 80) { 'compliant' } else { 'non-compliant' }
        $htmlSections += "<tr><td>$($cat.Category)</td><td>$($cat.Total)</td><td>$($cat.Compliant)</td><td>$($cat.NonCompliant)</td><td class='$catRateColor'>$($cat.ComplianceRate)%</td></tr>"
    }
    $htmlSections += '</table>'

    # 详细结果表格
    $htmlSections += '<h2>详细检查结果</h2><table><tr><th>类别</th><th>检查项</th><th>期望值</th><th>实际值</th><th>状态</th><th>严重等级</th></tr>'
    foreach ($item in ($allResults | Sort-Object Severity, Category)) {
        $statusClass = if ($item.Status -eq 'Compliant') { 'compliant' } else { 'non-compliant' }
        $sevColor = $severityColorMap[$item.Severity]
        $htmlSections += "<tr><td>$($item.Category)</td><td>$($item.CheckItem)</td><td>$($item.Expected)</td><td>$($item.Actual)</td><td class='$statusClass'>$($item.Status)</td><td style='color:$sevColor'>$($item.Severity)</td></tr>"
    }
    $htmlSections += '</table>'

    # 修复建议
    if ($remediations) {
        $htmlSections += '<h2>修复建议</h2><table><tr><th>检查项</th><th>严重等级</th><th>修复命令</th></tr>'
        foreach ($rem in $remediations) {
            $remSevColor = $severityColorMap[$rem.Severity]
            $htmlSections += "<tr><td>$($rem.CheckItem)</td><td style='color:$remSevColor'>$($rem.Severity)</td><td><code>$($rem.Remediation)</code></td></tr>"
        }
        $htmlSections += '</table>'
    }

    $htmlSections += '</body></html>'

    $htmlSections -join "`n" | Out-File -FilePath $OutputPath -Encoding UTF8

    # 控制台输出汇总
    [PSCustomObject]@{
        ReportPath      = $OutputPath
        TotalChecks     = $totalCount
        CompliantItems  = $compliantCount
        NonCompliantItems = $totalCount - $compliantCount
        ComplianceRate  = "$complianceRate%"
        CriticalIssues  = $criticalCount
        GeneratedAt     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}
```

运行报告生成函数后，控制台输出汇总信息，同时在桌面生成 HTML 报告文件：

```
正在执行安全基线检查...
正在执行系统配置审计...
正在生成 HTML 报告...

ReportPath       : C:\Users\Admin\Desktop\ComplianceReport_20260327_100530.html
TotalChecks      : 24
CompliantItems   : 17
NonCompliantItems: 7
ComplianceRate   : 70.8%
CriticalIssues   : 2
GeneratedAt      : 2026-03-27 10:05:30
```

## 注意事项

1. **管理员权限要求**：安全基线检查和系统配置审计需要以管理员身份运行 PowerShell。账户策略、审核策略和注册表部分操作均涉及系统级配置，普通用户权限无法获取完整信息。

2. **CIS Benchmark 版本对应**：本文中的检查项基于 CIS Microsoft Windows Server Benchmark v3.0 编写。不同版本的 Benchmark 可能存在差异，建议根据实际部署的基线版本调整 `Expected` 字段中的判定标准。

3. **生产环境慎用修复命令**：报告中给出的修复命令（`Remediation` 字段）仅供参考。直接在生产环境中执行这些命令可能导致服务中断（如禁用 RemoteRegistry 可能影响远程管理工具），务必先在测试环境验证。

4. **远程审计扩展**：上述函数目前仅审计本地计算机。如需批量审计多台服务器，可以结合 `Invoke-Command -ComputerName $servers -ScriptBlock { ... }` 实现，但需注意 WinRM 服务的连通性和防火墙配置。

5. **HTML 报告编码问题**：`Out-File -Encoding UTF8` 在 Windows PowerShell 5.1 中会生成带 BOM 的 UTF-8 文件，在浏览器中通常能正确显示。如果遇到中文乱码，可尝试使用 `[System.IO.File]::WriteAllText($OutputPath, $htmlContent, [System.Text.Encoding]::UTF8)` 替代。

6. **定期审计与趋势跟踪**：建议将合规审计脚本纳入计划任务（`schtasks`），每周或每月自动执行一次，并将报告归档保存。通过对比不同时期的合规率变化，可以追踪安全态势的改善趋势，为管理层的合规决策提供数据支撑。
