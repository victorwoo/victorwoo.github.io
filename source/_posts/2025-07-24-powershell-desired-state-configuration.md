---
layout: post
date: 2025-07-24 08:00:00
updated: 2025-07-24 08:00:00
title: "PowerShell 技能连载 - Desired State Configuration 实战"
description: PowerTip of the Day - DSC (Desired State Configuration) in Practice
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- config-management
- devops
---

_适用于 PowerShell 5.1 及以上版本（Windows），DSC 需要 Windows 管理框架_

Desired State Configuration（DSC）是 PowerShell 的声明式配置管理框架——你定义系统"应该是什么状态"，DSC 负责将系统调整到目标状态。与命令式脚本（"执行这些步骤"）不同，DSC 声明期望结果（"安装这些角色、创建这些文件、启动这些服务"），引擎自动判断需要做什么。这使得配置管理具有幂等性和可审计性。

本文将讲解 DSC 的核心概念、配置编写，以及实用的服务器配置场景。

<!-- more -->

## DSC 配置基础

```powershell
# DSC 配置块
Configuration WebServerSetup {
    param([string[]]$MachineName = "localhost")

    Node $MachineName {
        # 安装 IIS 角色
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
            IncludeAllSubFeature = $true
        }

        # 确保 Web 管理工具安装
        WindowsFeature WebMgmtTools {
            Ensure = "Present"
            Name   = "Web-Mgmt-Tools"
            DependsOn = "[WindowsFeature]IIS"
        }

        # 创建网站目录
        File WebsiteRoot {
            Ensure          = "Present"
            DestinationPath = "C:\inetpub\MyApp"
            Type            = "Directory"
        }

        # 复制默认页面
        File DefaultPage {
            Ensure          = "Present"
            DestinationPath = "C:\inetpub\MyApp\default.htm"
            Contents        = @"
<!DOCTYPE html>
<html>
<head><title>MyApp</title></head>
<body><h1>MyApp Running</h1><p>DSC Configured</p></body>
</html>
"@
            DependsOn       = "[File]WebsiteRoot"
        }

        # 启动 W3SVC 服务
        Service W3SVC {
            Name        = "W3SVC"
            State       = "Running"
            StartupType = "Automatic"
            DependsOn   = "[WindowsFeature]IIS"
        }
    }
}

# 编译配置（生成 MOF 文件）
WebServerSetup -OutputPath "C:\DSC\WebServer"

Write-Host "配置已编译，MOF 文件位于 C:\DSC\WebServer" -ForegroundColor Green
```

执行结果示例：

```
配置已编译，MOF 文件位于 C:\DSC\WebServer
    Directory: C:\DSC\WebServer

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----          2025-07-24  08:30:15           3456 localhost.mof
```

## 应用与测试配置

```powershell
# 应用 DSC 配置（推送模式）
Start-DscConfiguration -Path "C:\DSC\WebServer" -Wait -Verbose -Force

# 检查配置状态
Test-DscConfiguration -Path "C:\DSC\WebServer"

# 查看当前配置状态详情
Get-DscConfigurationStatus |
    Select-Object Status, StartDate, Type, Mode |
    Format-List

# 获取当前 DSC 配置的实际值
Get-DscConfiguration |
    Select-Object ConfigurationName, ResourceInstanceName, ResourceModuleName |
    Format-Table -AutoSize
```

执行结果示例：

```
PSComputerName  ResourceName  InDesiredState
localhost       WindowsFeature     True
localhost       WindowsFeature     True
localhost       File               True
localhost       File               True
localhost       Service            True

Status    : Success
StartDate : 2025-07-24 08:30:15
Type      : Initial
Mode      : Push
```

## 完整服务器配置

```powershell
# 综合服务器配置 DSC
Configuration ProductionWebServer {
    param(
        [string[]]$NodeName = "localhost",
        [string]$WebsitePath = "C:\inetpub\MyApp",
        [string]$LogPath = "C:\Logs\MyApp"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xWebAdministration

    Node $NodeName {
        # Windows 功能
        WindowsFeature WebServer {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        WindowsFeature NetFramework {
            Ensure = "Present"
            Name   = "NET-Framework-45-Core"
        }

        # 目录结构
        File WebsiteDir {
            Ensure          = "Present"
            DestinationPath = $WebsitePath
            Type            = "Directory"
        }

        File LogDir {
            Ensure          = "Present"
            DestinationPath = $LogPath
            Type            = "Directory"
        }

        # 注册表设置
        Registry MaxUrlLength {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
            ValueName = "UrlSegmentMaxLength"
            ValueData = "0"
            ValueType = "Dword"
        }

        # Windows 防火墙规则
        Script FirewallRuleHTTP {
            GetScript  = { @{ Result = (Get-NetFirewallRule -DisplayName "HTTP" -ErrorAction SilentlyContinue).DisplayName } }
            SetScript  = { New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow }
            TestScript = { (Get-NetFirewallRule -DisplayName "HTTP" -ErrorAction SilentlyContinue) -ne $null }
        }

        # 服务配置
        Service W3SVC {
            Name        = "W3SVC"
            State       = "Running"
            StartupType = "Automatic"
        }

        Service WAS {
            Name        = "WAS"
            State       = "Running"
            StartupType = "Automatic"
        }

        # 本地配置管理器设置
        LocalConfigurationManager {
            ConfigurationMode = "ApplyAndAutoCorrect"
            ConfigurationModeFrequencyMins = 30
            RefreshMode = "Push"
            RebootNodeIfNeeded = $true
        }
    }
}

# 编译
ProductionWebServer -OutputPath "C:\DSC\ProductionWeb" -NodeName "SRV-WEB-01"

# 应用
Start-DscConfiguration -Path "C:\DSC\ProductionWeb" -Wait -Force

Write-Host "生产服务器配置已应用" -ForegroundColor Green
```

执行结果示例：

```
生产服务器配置已应用
```

## 配置漂移检测

```powershell
# 定期检查配置漂移
function Test-DscDrift {
    param([string]$ComputerName = "localhost")

    $result = Test-DscConfiguration -ComputerName $ComputerName -Detailed

    $inDesired = ($result.ResourcesInDesiredState | Measure-Object).Count
    $notInDesired = ($result.ResourcesNotInDesiredState | Measure-Object).Count

    $report = [PSCustomObject]@{
        Computer   = $ComputerName
        Timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        InDesired  = $inDesired
        NotInDesired = $notInDesired
        Compliant  = $notInDesired -eq 0
    }

    if ($notInDesired -gt 0) {
        Write-Host "[$($report.Timestamp)] $ComputerName : 漂移！$notInDesired 项不符合" -ForegroundColor Red
        $result.ResourcesNotInDesiredState | ForEach-Object {
            Write-Host "  - $($_.ResourceId)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[$($report.Timestamp)] $ComputerName : 合规（$inDesired 项）" -ForegroundColor Green
    }

    return $report
}

# 批量检查
$servers = @("SRV-WEB-01", "SRV-WEB-02", "SRV-WEB-03")
$reports = foreach ($server in $servers) {
    Test-DscDrift -ComputerName $server
}

$reports | Format-Table Computer, InDesired, NotInDesired, Compliant -AutoSize
```

执行结果示例：

```
[2025-07-24 09:00:00] SRV-WEB-01 : 合规（8 项）
[2025-07-24 09:00:02] SRV-WEB-02 : 漂移！2 项不符合
  - [Service]W3SVC
  - [File]DefaultPage
[2025-07-24 09:00:04] SRV-WEB-03 : 合规（8 项）

Computer    InDesired NotInDesired Compliant
--------    --------- ------------ ---------
SRV-WEB-01         8            0      True
SRV-WEB-02         6            2     False
SRV-WEB-03         8            0      True
```

## 注意事项

1. **推送 vs 拉取**：推送模式（Push）适合小规模环境，拉取模式（Pull）适合大规模环境
2. **幂等性**：DSC 配置应该可以重复执行而不产生副作用，使用 `Test` 脚本检测当前状态
3. **MOF 文件**：MOF 文件可能包含敏感信息（密码），注意安全存储和传输
4. **依赖关系**：使用 `DependsOn` 控制资源配置顺序，避免依赖循环
5. **自定义资源**：内置资源不满足需求时，可以创建自定义 DSC 资源模块
6. **AutoCorrect 模式**：`ApplyAndAutoCorrect` 模式会自动修复漂移，`ApplyOnly` 模式只检测不修复
