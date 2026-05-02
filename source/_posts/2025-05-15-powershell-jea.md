---
layout: post
date: 2025-05-15 08:00:00
updated: 2025-05-15 08:00:00
title: "PowerShell 技能连载 - Just Enough Administration (JEA)"
description: PowerTip of the Day - Just Enough Administration (JEA) in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- jea
- security
- constrained-endpoint
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在传统运维中，给某人"重启服务"的权限，往往意味着给他管理员权限——而管理员权限能做远不止于此。JEA（Just Enough Administration）是微软提供的安全技术，它允许你精确控制用户可以在远程会话中执行哪些命令，无需授予管理员权限。这对于外包团队、初级运维和审计合规场景尤为重要。

本文将讲解 JEA 的核心概念、如何创建和部署 JEA 端点、角色能力的定义，以及生产环境中的最佳实践。

## JEA 核心架构

JEA 由两个核心组件构成：

- **角色能力文件（Role Capability, .psrc）**：定义用户可以执行哪些命令
- **会话配置文件（Session Configuration, .pssc）**：将角色能力映射到用户/组，并定义会话限制

```powershell
# 检查系统是否支持 JEA
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "操作系统：$($os.Caption)"
Write-Host "PowerShell 版本：$($PSVersionTable.PSVersion)"

# 查看 JEA 相关模块
Get-Module -ListAvailable | Where-Object {
    $_.Name -match 'JEA|RoleCapability|SessionConfiguration'
} | Select-Object Name, Version

# 创建 JEA 配置目录
$jeaPath = "C:\JEA"
New-Item -Path "$jeaPath\RoleCapabilities" -ItemType Directory -Force
New-Item -Path "$jeaPath\SessionConfigurations" -ItemType Directory -Force
```

执行结果示例：

```
操作系统：Microsoft Windows Server 2022 Standard
PowerShell 版本：5.1.20348.1850

Name                    Version
----                    -------
JEA                     0.2.16.6
```

## 创建角色能力文件

角色能力文件定义了用户在 JEA 会话中可以执行的具体操作。每个角色对应一个 `.psrc` 文件：

```powershell
# 创建"服务运维"角色
$serviceOps = @{
    Author                  = 'Admin'
    Description             = '允许查看和重启指定服务'
    CompanyName             = 'Contoso'

    # 允许的 cmdlet
    VisibleCmdlets          = @(
        @{ Name = 'Get-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler','WinRM','W3SVC','MSSQLSERVER' } },
        @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler','WinRM','W3SVC' } },
        @{ Name = 'Stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler','W3SVC' } },
        'Get-Process',
        'Get-CimInstance'
    )

    # 允许的函数
    VisibleFunctions       = @('Get-SystemStatus')

    # 禁止的语言元素
    VisibleProviders       = @()

    # 脚本块执行限制
    VisibleExternalCommands = @()

    # 允许的变量
    VisibleVariables       = @('PSDefaultParameterValues')
}

New-PSRoleCapabilityFile -Path "$jeaPath\RoleCapabilities\ServiceMaintenance.psrc" @serviceOps
Write-Host "角色能力文件已创建：ServiceMaintenance.psrc" -ForegroundColor Green
```

执行结果示例：

```
角色能力文件已创建：ServiceMaintenance.psrc
```

> **注意**：`ValidateSet` 参数限制用户只能操作指定的服务名称，防止意外停止关键服务。这是 JEA 精细权限控制的核心能力。

## 创建会话配置文件

会话配置文件将角色能力与 Active Directory 用户/组绑定，并设置会话级别的安全限制：

```powershell
# 创建会话配置
$sessionConfig = @{
    Author                    = 'Admin'
    Description               = 'JEA 服务运维端点'
    SessionType               = 'RestrictedRemoteServer'
    RunAsVirtualAccount       = $true
    RunAsVirtualAccountGroups = @('Administrators')

    # 角色映射
    RoleDefinitions           = @{
        'CONTOSO\ServiceOps'   = @{ RoleCapabilities = 'ServiceMaintenance' }
        'CONTOSO\Monitoring'   = @{ RoleCapabilities = 'ReadOnlyMonitor' }
    }

    # 目录查找路径
    RoleCapabilityPaths       = @("$jeaPath\RoleCapabilities")

    # 语言模式
    LanguageMode               = 'NoLanguage'

    # 执行策略
    ExecutionPolicy            = 'Restricted'
}

New-PSSessionConfigurationFile -Path "$jeaPath\SessionConfigurations\ServiceOps.pssc" @sessionConfig
Write-Host "会话配置文件已创建：ServiceOps.pssc" -ForegroundColor Green
```

执行结果示例：

```
会话配置文件已创建：ServiceOps.pssc
```

## 创建只读监控角色

除了运维操作，JEA 也非常适合创建只读监控角色：

```powershell
# 创建只读监控角色能力文件
$readOnlyMonitor = @{
    Author           = 'Admin'
    Description      = '只读系统监控'
    VisibleCmdlets   = @(
        @{ Name = 'Get-Service' },
        @{ Name = 'Get-Process' },
        @{ Name = 'Get-CimInstance'; Parameters = @{ ClassName = 'Win32_OperatingSystem','Win32_LogicalDisk','Win32_Processor' } },
        @{ Name = 'Get-EventLog'; Parameters = @{ Name = 'LogName'; ValidateSet = 'System','Application' }, @{ Name = 'Newest' } },
        'Get-Counter',
        'Get-WinEvent'
    )
    VisibleFunctions = @()
    VisibleProviders = @()
}

New-PSRoleCapabilityFile -Path "$jeaPath\RoleCapabilities\ReadOnlyMonitor.psrc" @readOnlyMonitor

# 更新会话配置，添加只读角色
$sessionConfig = @{
    Author                    = 'Admin'
    Description               = 'JEA 服务运维端点（含只读监控）'
    SessionType               = 'RestrictedRemoteServer'
    RunAsVirtualAccount       = $true
    RunAsVirtualAccountGroups = @('Administrators')
    RoleDefinitions           = @{
        'CONTOSO\ServiceOps'   = @{ RoleCapabilities = 'ServiceMaintenance' }
        'CONTOSO\Monitoring'   = @{ RoleCapabilities = 'ReadOnlyMonitor' }
    }
    RoleCapabilityPaths       = @("$jeaPath\RoleCapabilities")
    LanguageMode               = 'NoLanguage'
    TranscriptDirectory        = 'C:\JEA\Transcripts'
    RunAsVirtualAccount        = $true
}

New-PSSessionConfigurationFile -Path "$jeaPath\SessionConfigurations\ServiceOps.pssc" @sessionConfig
Write-Host "已更新会话配置" -ForegroundColor Green
```

执行结果示例：

```
已更新会话配置
```

## 注册和测试 JEA 端点

创建配置文件后，需要在目标机器上注册端点才能使用：

```powershell
# 注册 JEA 端点
Register-PSSessionConfiguration -Path "$jeaPath\SessionConfigurations\ServiceOps.pssc" `
    -Name "JEA_ServiceOps" -Force

# 验证端点已注册
Get-PSSessionConfiguration | Where-Object Name -eq "JEA_ServiceOps" |
    Format-List Name, ConfiguredBy, Description

# 测试连接（使用服务运维账户）
$cred = Get-Credential CONTOSO\opsuser
$session = New-PSSession -ComputerName localhost -ConfigurationName "JEA_ServiceOps" -Credential $cred

# 在 JEA 会话中执行允许的命令
Invoke-Command -Session $session -ScriptBlock {
    Get-Service -Name WinRM
}

# 尝试执行不允许的命令（应该失败）
Invoke-Command -Session $session -ScriptBlock {
    Get-Service -Name WinRM | Stop-Service
}

# 清理
Remove-PSSession $session
```

执行结果示例：

```
Name            : JEA_ServiceOps
ConfiguredBy    : CONTOSO\Admin
Description     : JEA 服务运维端点（含只读监控）

Status  Name  DisplayName
------  ----  -----------
Running WinRM Windows Remote Management (WS-Management)

The term 'Stop-Service' is not recognized as the name of a cmdlet, function, script file, or
operable program.
```

> **注意**：JEA 的 `NoLanguage` 模式禁止使用变量、循环、条件语句等语言元素。如果需要更灵活的操作，可以使用 `ConstrainedLanguage` 模式。

## 审计与转录

JEA 自动记录所有会话操作，用于审计和合规：

```powershell
# 配置转录目录
$transcriptDir = "C:\JEA\Transcripts"
New-Item -Path $transcriptDir -ItemType Directory -Force

# 在会话配置中启用转录
$sessionConfig = @{
    Author                    = 'Admin'
    SessionType               = 'RestrictedRemoteServer'
    RunAsVirtualAccount       = $true
    RunAsVirtualAccountGroups = @('Administrators')
    RoleDefinitions           = @{
        'CONTOSO\ServiceOps'   = @{ RoleCapabilities = 'ServiceMaintenance' }
    }
    RoleCapabilityPaths       = @("$jeaPath\RoleCapabilities")
    LanguageMode               = 'NoLanguage'
    TranscriptDirectory        = $transcriptDir
}

New-PSSessionConfigurationFile -Path "$jeaPath\SessionConfigurations\ServiceOps.pssc" @sessionConfig

# 查看 JEA 转录日志
Get-ChildItem $transcriptDir -Filter *.txt |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 Name, Length, LastWriteTime

# 读取特定转录
$latestLog = Get-ChildItem $transcriptDir -Filter *.txt |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $latestLog.FullName -Head 30
```

执行结果示例：

```
Name                          Length LastWriteTime
----                          ------ -------------
Transcript-20250515-083015...   4521 2025-05-15 08:30:15
Transcript-20250515-081500...   3245 2025-05-15 08:15:00

**********************
Windows PowerShell transcript start
Start time: 20250515083015
Username: CONTOSO\opsuser
RunAs User: WinRM Virtual Users\JEA_ServiceOps
Machine: SERVER01 (Microsoft Windows Server 2022)
**********************
```

## 部署到多台服务器

JEA 配置需要部署到每台目标服务器。使用 DSC 或 CI/CD 管道可以自动化部署：

```powershell
# 导出 JEA 配置为可传输的模块
$modulePath = "$jeaPath\JEAConfigModule"
New-Item -Path "$modulePath\RoleCapabilities" -ItemType Directory -Force

# 复制角色能力文件到模块目录
Copy-Item "$jeaPath\RoleCapabilities\*.psrc" "$modulePath\RoleCapabilities\"
Copy-Item "$jeaPath\SessionConfigurations\*.pssc" $modulePath

# 创建模块清单
$moduleManifest = @{
    Path              = "$modulePath\JEAConfigModule.psd1"
    RootModule        = 'JEAConfigModule.psm1'
    ModuleVersion     = '1.0.0'
    Description       = 'JEA 端点配置模块'
    FunctionsToExport = @('Install-JEAEndpoint')
}
New-ModuleManifest @moduleManifest

# 创建安装脚本
$installScript = @'
function Install-JEAEndpoint {
    param([string]$ConfigPath = $PSScriptRoot)

    $psscFile = Get-ChildItem $ConfigPath -Filter *.pssc | Select-Object -First 1
    Register-PSSessionConfiguration -Path $psscFile.FullName -Name "JEA_ServiceOps" -Force
    Write-Host "JEA 端点已注册" -ForegroundColor Green
}
'@
Set-Content -Path "$modulePath\JEAConfigModule.psm1" -Value $installScript

Write-Host "JEA 配置模块已创建：$modulePath" -ForegroundColor Green
```

执行结果示例：

```
JEA 配置模块已创建：C:\JEA\JEAConfigModule
```

## 注意事项

1. **虚拟账户**：JEA 使用虚拟账户执行操作，该账户在会话结束后消失。虚拟账户默认属于本地管理员组，可通过 `RunAsVirtualAccountGroups` 自定义
2. **组托管服务账户（gMSA）**：如果 JEA 需要访问网络资源，使用 gMSA 代替虚拟账户，因为虚拟账户无法进行网络认证
3. **语言模式**：`NoLanguage` 最安全但限制最多，`ConstrainedLanguage` 允许基本语言结构但仍限制可疑操作
4. **转录审计**：始终配置 `TranscriptDirectory`，确保所有 JEA 会话操作可追溯
5. **定期审查**：定期检查角色能力定义，确保权限未过度膨胀
6. **测试验证**：部署前以目标用户的身份测试所有允许的命令，确认白名单完整且拒绝策略有效
