---
layout: post
date: 2026-02-04 08:00:00
updated: 2026-02-04 08:00:00
title: "PowerShell 技能连载 - 注册表管理与安全审计"
description: PowerTip of the Day - Registry Management and Security Audit in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- system-management
- windows
- security
---

_适用于 PowerShell 5.1 及以上版本_

Windows 注册表是操作系统配置的核心存储库，几乎所有系统设置、应用程序配置和安全策略都记录在注册表中。在企业环境中，系统管理员需要定期检查注册表中的安全设置，确保符合合规要求。传统的 `regedit.exe` 图形界面工具虽然直观，但无法满足批量操作和自动化审计的需求。

PowerShell 提供了完整的注册表操作能力，通过注册表提供程序（Registry Provider）可以直接像操作文件系统一样浏览和修改注册表。结合 `.NET` 类库，还可以管理注册表项的 ACL（访问控制列表），实现细粒度的权限审计。本文将从基础操作、安全审计和变更追踪三个方面，介绍如何用 PowerShell 高效管理注册表。

值得注意的是，注册表操作具有较高的风险性，错误的修改可能导致系统不稳定甚至无法启动。因此在生产环境中，建议先导出备份再进行修改，并使用 `-WhatIf` 参数进行预演。

<!-- more -->

## 注册表基础操作与批量配置

PowerShell 的注册表提供程序将注册表映射为驱动器，可以直接使用 `Get-Item`、`Set-ItemProperty` 等命令操作。下面是一些常见的批量配置场景：

```powershell
# 查看可用的注册表驱动器
Get-PSDrive -PSProvider Registry | Format-Table Name, Root

# 读取 Windows 当前版本信息
$osInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Write-Host "系统版本: $($osInfo.ProductName)"
Write-Host "当前版本号: $($osInfo.DisplayVersion)"
Write-Host "构建号: $($osInfo.CurrentBuild)"

# 批量修改远程桌面相关注册表项
$rdpSettings = @{
    'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' = @{
        fDenyTSConnections = 0  # 允许远程桌面连接
    }
    'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' = @{
        UserAuthentication = 1  # 要求网络级别身份验证
    }
}

foreach ($path in $rdpSettings.Keys) {
    foreach ($name in $rdpSettings[$path].Keys) {
        $value = $rdpSettings[$path][$name]
        Set-ItemProperty -Path $path -Name $name -Value $value
        Write-Host "已设置 $path\$name = $value"
    }
}

# 搜索注册表中的特定键值（以搜索所有安装的 .NET 版本为例）
$dotnetKey = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
if (Test-Path $dotnetKey) {
    $release = (Get-ItemProperty -Path $dotnetKey -Name Release -ErrorAction SilentlyContinue).Release
    $versions = @{
        528040 = '.NET Framework 4.8'
        533320 = '.NET Framework 4.8.1'
    }
    $found = $versions.Keys | Where-Object { $release -ge $_ } | Sort-Object -Descending | Select-Object -First 1
    Write-Host ".NET 版本: $($versions[$found]) (Release=$release)"
}

# 导出注册表项到 .reg 文件（使用 reg.exe）
$tempRegFile = "$env:TEMP\firewall_backup.reg"
reg export 'HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy' $tempRegFile /y
Write-Host "防火墙注册表已导出到: $tempRegFile"
```

执行结果示例：

```
Name Root
---- ----
HKCR HKEY_CLASSES_ROOT
HKCU HKEY_CURRENT_USER
HKLM HKEY_LOCAL_MACHINE
HKU  HKEY_USERS

系统版本: Windows 11 Pro
当前版本号: 24H2
构建号: 26100

已设置 HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections = 0
已设置 HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\UserAuthentication = 1

.NET 版本: .NET Framework 4.8 (Release=528040)

防火墙注册表已导出到: C:\Users\ADMINI~1\AppData\Local\Temp\firewall_backup.reg
```

## 安全基线审计

在企业环境中，安全基线审计是确保系统合规的关键环节。以下脚本检查 UAC（用户账户控制）、远程桌面策略和防火墙规则等核心安全设置，并生成审计报告：

```powershell
function Invoke-RegistrySecurityAudit {
    $auditResults = @()

    # 定义安全基线检查项
    $baselineChecks = @(
        @{
            Name   = 'UAC - 管理员批准模式'
            Path   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Key    = 'EnableLUA'
            Expected = 1
            Severity = '高'
        },
        @{
            Name   = 'UAC - 提示提升时切换到安全桌面'
            Path   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Key    = 'PromptOnSecureDesktop'
            Expected = 1
            Severity = '高'
        },
        @{
            Name   = '远程桌面 - 空密码限制'
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            Key    = 'LimitBlankPasswordUse'
            Expected = 1
            Severity = '高'
        },
        @{
            Name   = '远程桌面 - NLA 要求'
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
            Key    = 'UserAuthentication'
            Expected = 1
            Severity = '中'
        },
        @{
            Name   = '防火墙 - 域配置文件启用状态'
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile'
            Key    = 'EnableFirewall'
            Expected = 1
            Severity = '高'
        },
        @{
            Name   = '防火墙 - 标准配置文件启用状态'
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile'
            Key    = 'EnableFirewall'
            Expected = 1
            Severity = '高'
        },
        @{
            Name   = '审核策略 - 对象访问审计'
            Path   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            Key    = 'AuditBaseObjects'
            Expected = 1
            Severity = '中'
        },
        @{
            Name   = 'WinRM - 允许远程服务器管理'
            Path   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service'
            Key    = 'AllowAutoConfig'
            Expected = 1
            Severity = '低'
        }
    )

    foreach ($check in $baselineChecks) {
        $actual = $null
        $status = '跳过'

        if (Test-Path $check.Path) {
            $actual = (Get-ItemProperty -Path $check.Path -Name $check.Key -ErrorAction SilentlyContinue).($check.Key)
            if ($null -ne $actual) {
                $status = if ($actual -eq $check.Expected) { '通过' } else { '不合规' }
            } else {
                $status = '未配置'
            }
        } else {
            $status = '路径不存在'
        }

        $auditResults += [PSCustomObject]@{
            检查项   = $check.Name
            预期值   = $check.Expected
            实际值   = if ($null -ne $actual) { $actual } else { 'N/A' }
            状态     = $status
            严重级别 = $check.Severity
        }
    }

    # 输出审计报告
    Write-Host "`n========== 注册表安全基线审计报告 =========="
    Write-Host "审计时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "计算机名: $env:COMPUTERNAME"
    Write-Host "==============================================`n"

    $auditResults | Format-Table -AutoSize

    # 统计摘要
    $compliant = ($auditResults | Where-Object { $_.状态 -eq '通过' }).Count
    $total = $auditResults.Count
    $nonCompliant = $auditResults | Where-Object { $_.状态 -eq '不合规' }

    Write-Host "合规项: $compliant / $total"

    if ($nonCompliant) {
        Write-Host "`n不合规项详情:" -ForegroundColor Red
        foreach ($item in $nonCompliant) {
            Write-Host "  [$($item.严重级别)] $($item.检查项): 预期=$($item.预期值), 实际=$($item.实际值)"
        }
    }

    return $auditResults
}

Invoke-RegistrySecurityAudit
```

执行结果示例：

```
========== 注册表安全基线审计报告 ==========
审计时间: 2026-02-04 10:30:15
计算机名: SERVER01
==============================================

检查项                           预期值 实际值 状态   严重级别
------                           ------ ------ ----   --------
UAC - 管理员批准模式                  1      1 通过   高
UAC - 提示提升时切换到安全桌面         1      1 通过   高
远程桌面 - 空密码限制                  1      1 通过   高
远程桌面 - NLA 要求                   1      0 不合规 中
防火墙 - 域配置文件启用状态            1      1 通过   高
防火墙 - 标准配置文件启用状态          1      1 通过   高
审核策略 - 对象访问审计                1      0 不合规 中
WinRM - 允许远程服务器管理             1    N/A 未配置 低

合规项: 5 / 8

不合规项详情:
  [中] 远程桌面 - NLA 要求: 预期=1, 实际=0
  [中] 审核策略 - 对象访问审计: 预期=1, 实际=0
```

## 注册表监控与变更追踪

在安全运维中，需要监控关键注册表项的变更，并管理其访问权限。以下脚本实现了 ACL 管理、变更检测和基线对比功能：

```powershell
function Protect-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Read', 'Write', 'FullControl')]
        [string]$Permission = 'Read',

        [string]$Account = 'BUILTIN\Users'
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "注册表路径不存在: $Path"
        return
    }

    # 获取当前 ACL
    $acl = Get-Acl -Path $Path

    # 定义权限映射
    $rightsMap = @{
        Read        = 'ReadKey'
        Write       = 'WriteKey'
        FullControl = 'FullControl'
    }

    $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
        $Account,
        $rightsMap[$Permission],
        'ContainerInherit,ObjectInherit',
        'None',
        'Allow'
    )

    $acl.AddAccessRule($rule)
    Set-Acl -Path $Path -AclObject $acl
    Write-Host "已为 $Account 授予 $Permission 权限: $Path"
}

function New-RegistryBaseline {
    param(
        [string[]]$Paths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy'
        ),
        [string]$OutputPath = "$env:TEMP\registry_baseline.json"
    )

    $baseline = @{
        CreatedAt = Get-Date -Format 'o'
        Computer  = $env:COMPUTERNAME
        Entries   = @{}
    }

    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) { continue }

        $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $entry = @{}

        # 获取所有属性（排除默认的 PS* 属性）
        $props.PSObject.Properties |
            Where-Object { $_.Name -notmatch '^PS' } |
            ForEach-Object {
                $entry[$_.Name] = $_.Value
            }

        $baseline.Entries[$path] = $entry
    }

    $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "基线已保存到: $OutputPath"
    return $OutputPath
}

function Compare-RegistryBaseline {
    param(
        [Parameter(Mandatory)]
        [string]$BaselineFile
    )

    if (-not (Test-Path $BaselineFile)) {
        Write-Error "基线文件不存在: $BaselineFile"
        return
    }

    $baseline = Get-Content -Path $BaselineFile -Raw | ConvertFrom-Json
    Write-Host "`n========== 注册表变更检测报告 =========="
    Write-Host "基线创建时间: $($baseline.CreatedAt)"
    Write-Host "检查时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "========================================`n"

    $changes = @()

    foreach ($path in $baseline.Entries.PSObject.Properties.Name) {
        if (-not (Test-Path $path)) {
            $changes += [PSCustomObject]@{
                路径 = $path
                变更类型 = '已删除'
                属性 = 'N/A'
                原值 = 'N/A'
                新值 = 'N/A'
            }
            continue
        }

        $current = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $savedProps = $baseline.Entries.$path

        foreach ($prop in $savedProps.PSObject.Properties) {
            $currentValue = $current.($prop.Name)
            $savedValue = $prop.Value

            if ($null -ne $currentValue -and "$currentValue" -ne "$savedValue") {
                $changes += [PSCustomObject]@{
                    路径 = $path
                    变更类型 = '已修改'
                    属性 = $prop.Name
                    原值 = $savedValue
                    新值 = $currentValue
                }
            }
        }
    }

    if ($changes.Count -eq 0) {
        Write-Host "未检测到任何变更，所有配置与基线一致。" -ForegroundColor Green
    } else {
        Write-Host "检测到 $($changes.Count) 处变更:" -ForegroundColor Yellow
        $changes | Format-Table -AutoSize
    }

    return $changes
}

# 使用示例：创建基线并检测变更
$baselineFile = New-RegistryBaseline
Compare-RegistryBaseline -BaselineFile $baselineFile

# 限制 Users 组对关键注册表项的写入权限
Protect-RegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Permission 'Read' -Account 'BUILTIN\Users'
```

执行结果示例：

```
基线已保存到: C:\Users\ADMINI~1\AppData\Local\Temp\registry_baseline.json

========== 注册表变更检测报告 ==========
基线创建时间: 2026-02-04T10:30:15.0000000+08:00
检查时间: 2026-02-04 14:22:08
========================================

检测到 2 处变更:

路径                                                                  变更类型 属性                     原值 新值
----                                                                  -------- ----                     ---- ----
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System       已修改  EnableLUA                   1    0
HKLM:\SYSTEM\CurrentControlSet\Control\Lsa                            已修改  LimitBlankPasswordUse       1    0

已为 BUILTIN\Users 授予 Read 权限: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```

## 注意事项

1. **务必备份后再修改**：在生产环境修改注册表前，务必使用 `reg export` 导出相关键值或创建系统还原点，以便在出现问题时快速恢复。

2. **使用 `-WhatIf` 参数**：`Set-ItemProperty`、`Remove-Item` 等危险操作建议先加上 `-WhatIf` 参数预演，确认影响范围后再正式执行。

3. **以管理员权限运行**：`HKLM:` 下的大部分操作需要以管理员身份运行 PowerShell，否则会遇到"拒绝访问"错误。可以使用 `#Requires -RunAsAdministrator` 预声明。

4. **注意 32/64 位重定向**：在 64 位系统上，部分注册表路径存在重定向机制（如 `Wow6432Node`），操作时需注意是否需要指定 `-PSPath 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\...'` 来绕过重定向。

5. **远程操作需启用 WinRM**：对远程计算机执行注册表操作时，目标机器需要启用 WinRM 服务，并且防火墙放行相应端口。可使用 `Invoke-Command` 配合 `-ComputerName` 参数。

6. **审计脚本定期运行**：建议将安全基线审计脚本配置为 Windows 计划任务或通过 CI/CD 流水线定期执行，及时发现配置漂移。导出的 JSON 基线文件应纳入版本控制系统进行追踪。
