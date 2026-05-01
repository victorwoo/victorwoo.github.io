---
layout: post
date: 2025-05-02 08:00:00
title: "PowerShell 技能连载 - Desired State Configuration"
description: PowerTip of the Day - Desired State Configuration (DSC) in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dsc
- configuration-management
- devops
---

_适用于 PowerShell 5.1 及以上版本（Windows），PowerShell 7 需安装 PSDesiredStateConfiguration 模块_

在运维领域，"配置漂移"是一个永恒的痛点——服务器的实际状态随时间推移逐渐偏离预期配置，导致难以排查的故障和安全隐患。微软的 Desired State Configuration（DSC）正是为解决这个问题而设计的声明式配置管理框架。与 Ansible、Chef、Puppet 类似，DSC 让你用代码定义服务器"应该是什么样"，然后由系统自动确保配置一致。

本文将介绍 DSC 的核心概念、如何编写配置脚本、推拉两种工作模式，以及在 PowerShell 7 中使用 DSC 的注意事项。

## DSC 核心概念

DSC 的核心思想是声明式配置——你只需描述期望的最终状态，而不必关心如何达到该状态。DSC 由三个核心组件构成：

- **配置（Configuration）**：定义期望状态的 PowerShell 脚本，类似于 Ansible 的 Playbook
- **资源（Resource）**：实现具体配置逻辑的模块，如管理文件、服务、注册表等
- **本地配置管理器（LCM）**：运行在目标节点上的引擎，负责应用和维持配置

内置资源包括：`File`、`Service`、`Registry`、`User`、`Group`、`WindowsFeature`、`Package`、`Environment`、`Script` 等。

```powershell
# 查看系统可用的 DSC 资源
Get-DscResource | Select-Object Name, Module, Properties | Format-Table -AutoSize

# 查看特定资源的详细信息
Get-DscResource -Name File | Select-Object -ExpandProperty Properties
```

执行结果示例：

```
Name            Module             Properties
----            ------             ----------
File            PSDesiredStateC... {DestinationPath, Attributes, Checksum...
Service         PSDesiredStateC... {Name, BuiltInAccount, Credential, Dep...
Registry        PSDesiredStateC... {Key, ValueName, Force, Hex...
WindowsFeature  PSDesiredStateC... {Name, Credential, DependsOn, Ensure...
```

## 编写第一个 DSC 配置

DSC 配置使用特殊的 PowerShell 语法，看起来像函数，但实际生成的是 MOF（Managed Object Format）文件。下面是一个配置 Web 服务器的完整示例：

```powershell
configuration WebServerSetup {
    param(
        [string[]]$NodeName = 'localhost',
        [string]$WebsitePath = 'C:\inetpub\MyApp'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $NodeName {
        # 确保 IIS Web-Server 角色已安装
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # 确保应用程序目录存在
        File AppDirectory {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $WebsitePath
            DependsOn       = '[WindowsFeature]IIS'
        }

        # 确保网站默认页面存在
        File DefaultPage {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$WebsitePath\index.html"
            Contents        = @'
<!DOCTYPE html>
<html>
<head><title>My App</title></head>
<body><h1>Hello from DSC!</h1></body>
</html>
'@
            DependsOn       = '[File]AppDirectory'
        }

        # 确保 IIS 服务正在运行
        Service W3SVC {
            Ensure = 'Present'
            Name   = 'W3SVC'
            State  = 'Running'
            DependsOn = '[WindowsFeature]IIS'
        }
    }
}

# 编译配置，生成 MOF 文件
WebServerSetup -OutputPath "C:\DSC\WebServerConfig"

# 查看 MOF 文件
Get-ChildItem "C:\DSC\WebServerConfig" -Filter *.mof
```

执行结果示例：

```
    Directory: C:\DSC\WebServerConfig

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         5/2/2025  10:00 AM           3456 localhost.mof
```

> **注意**：MOF 文件包含配置的完整定义，不能手动编辑。每次修改配置后需要重新编译。

## 应用配置（推送模式）

DSC 支持两种模式：推送（Push）和拉取（Pull）。推送模式下，管理员手动将配置应用到目标节点：

```powershell
# 应用配置到本机
Start-DscConfiguration -Path "C:\DSC\WebServerConfig" -Wait -Verbose -Force

# 应用配置到远程节点
Start-DscConfiguration -Path "C:\DSC\WebServerConfig" -ComputerName SERVER01, SERVER02 -Wait -Verbose

# 检查配置状态
Test-DscConfiguration
```

执行结果示例：

```
LCM starting to apply configuration...
[VERBOSE] Performing operation "Set" on Target "IIS"
[VERBOSE] Performing operation "Set" on Target "AppDirectory"
[VERBOSE] Performing operation "Set" on Target "W3SVC"
Configuration was applied successfully.

PSComputerName  ResourcesInDesiredState  ResourcesNotInDesiredState  InDesiredState
--------------  -----------------------  --------------------------  --------------
localhost       4                        0                           True
```

## 查看和监控配置状态

应用配置后，可以随时检查节点的当前状态是否与期望配置一致：

```powershell
# 获取当前配置状态详情
Get-DscConfigurationStatus | Select-Object StartDate, Type, Mode, RebootRequested, Status

# 获取各个资源的详细状态
Get-DscConfiguration

# 查看未按预期配置的资源
Get-DscConfiguration | Where-Object { $_.ResourceId } |
    ForEach-Object {
        $resource = $_
        $desired = Get-DscConfiguration |
            Where-Object { $_.ConfigurationName -eq $resource.ConfigurationName }
        [PSCustomObject]@{
            Resource  = $resource.ResourceId
            InDesired = $null -ne $desired
        }
    }
```

执行结果示例：

```
StartDate            Type       Mode  RebootRequested Status
---------            ----       ----  --------------- ------
5/2/2025 10:00:15 AM Consistency Push           False  Success

ConfigurationName    ResourceId        InDesired
-----------------    ----------        ---------
WebServerSetup       [WindowsFeature]  True
WebServerSetup       [File]AppDir      True
WebServerSetup       [File]DefaultPage True
WebServerSetup       [Service]         True
```

## 使用参数化配置管理多环境

在实际运维中，开发、测试、生产环境的配置通常不同。通过参数化 DSC 配置，可以复用同一份配置脚本：

```powershell
configuration AppDeployment {
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Nodes,

        [Parameter(Mandatory)]
        [string]$AppVersion,

        [string]$SourcePath = "\\fileserver\releases\$AppVersion"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $Nodes {
        # 从节点数据读取角色
        $nodeData = $Nodes | Where-Object { $_.NodeName -eq $NodeName }

        File AppFiles {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $nodeData.AppPath
            SourcePath      = $SourcePath
            Recurse         = $true
            Checksum        = 'SHA256'
            Force           = $true
        }

        Registry AppVersion {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\MyApp'
            ValueName = 'Version'
            ValueData = $AppVersion
            ValueType = 'String'
            DependsOn = '[File]AppFiles'
        }

        Service AppService {
            Ensure  = 'Present'
            Name    = $nodeData.ServiceName
            State   = 'Running'
            DependsOn = '[File]AppFiles'
        }
    }
}

# 为不同环境准备配置数据
$configData = @(
    @{ NodeName = 'DEV-WEB01';  AppPath = 'C:\Apps\MyApp'; ServiceName = 'MyAppDev' }
    @{ NodeName = 'PROD-WEB01'; AppPath = 'D:\Apps\MyApp'; ServiceName = 'MyAppProd' }
    @{ NodeName = 'PROD-WEB02'; AppPath = 'D:\Apps\MyApp'; ServiceName = 'MyAppProd' }
)

# 编译并部署到生产环境
AppDeployment -Nodes $configData -AppVersion "2.5.0" -OutputPath "C:\DSC\ProdDeploy"
```

执行结果示例：

```
    Directory: C:\DSC\ProdDeploy

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         5/2/2025  10:15 AM           3789 DEV-WEB01.mof
-a----         5/2/2025  10:15 AM           3789 PROD-WEB01.mof
-a----         5/2/2025  10:15 AM           3789 PROD-WEB02.mof
```

## 使用 Script 资源处理复杂逻辑

当内置资源无法满足需求时，可以使用 `Script` 资源编写自定义逻辑。`Script` 资源需要提供 `GetScript`、`TestScript` 和 `SetScript` 三个脚本块：

```powershell
configuration CustomAppSetup {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {
        Script DownloadAppPackage {
            GetScript  = {
                @{
                    Result = (Test-Path 'C:\Downloads\app-v2.5.0.zip')
                }
            }
            TestScript = {
                if (Test-Path 'C:\Downloads\app-v2.5.0.zip') {
                    $hash = (Get-FileHash 'C:\Downloads\app-v2.5.0.zip' -Algorithm SHA256).Hash
                    if ($hash -eq 'ABC123DEF456...') {
                        Write-Verbose "文件已存在且校验通过"
                        return $true
                    }
                }
                Write-Verbose "需要下载应用包"
                return $false
            }
            SetScript  = {
                $url = 'https://releases.example.com/app/v2.5.0/app.zip'
                $out = 'C:\Downloads\app-v2.5.0.zip'
                Invoke-WebRequest -Uri $url -OutFile $out
                Write-Verbose "下载完成：$out"
            }
        }

        Script ExtractAndInstall {
            DependsOn  = '[Script]DownloadAppPackage'
            GetScript  = {
                @{ Result = (Test-Path 'C:\Apps\MyApp\app.exe') }
            }
            TestScript = {
                (Test-Path 'C:\Apps\MyApp\app.exe')
            }
            SetScript  = {
                Expand-Archive -Path 'C:\Downloads\app-v2.5.0.zip' -DestinationPath 'C:\Apps\MyApp' -Force
                Write-Verbose "解压安装完成"
            }
        }
    }
}

CustomAppSetup -OutputPath "C:\DSC\CustomSetup"
Start-DscConfiguration -Path "C:\DSC\CustomSetup" -Wait -Verbose
```

执行结果示例：

```
VERBOSE: 需要下载应用包
VERBOSE: 下载完成：C:\Downloads\app-v2.5.0.zip
VERBOSE: 解压安装完成
Configuration was applied successfully.
```

## PowerShell 7 中的 DSC

PowerShell 7 默认不包含 DSC 命令，需要手动安装。微软推荐使用新的 `PSDesiredStateConfiguration` 模块（v2.x）：

```powershell
# 在 PowerShell 7 中安装 DSC 模块
Install-Module -Name PSDesiredStateConfiguration -Force -AllowClobber

# 验证安装
Get-Command -Module PSDesiredStateConfiguration

# 检查版本
Get-Module PSDesiredStateConfiguration -ListAvailable |
    Select-Object Name, Version
```

执行结果示例：

```
Name                           Version
----                           -------
PSDesiredStateConfiguration    2.0.7

CommandType     Name                          Version    Source
-----------     ----                          -------    ------
Function        Configuration                 2.0.7      PSDesiredStateConfiguration
Function        Get-DscConfiguration          2.0.7      PSDesiredStateConfiguration
Function        Start-DscConfiguration        2.0.7      PSDesiredStateConfiguration
Cmdlet          Test-DscConfiguration         2.0.7      PSDesiredStateConfiguration
```

> **注意**：DSC v3 已作为独立项目发布，采用全新的架构，不再依赖 MOF 文件，而是使用 JSON 配置文档。但目前 v2 仍是生产环境的主流选择。

## 注意事项

1. **MOF 文件安全**：MOF 文件可能包含凭据等敏感信息，应用后应妥善保管或删除，避免明文泄露
2. **LCM 配置**：使用 `Set-DscLocalConfigurationManager` 配置 LCM 的刷新模式、频率等参数，拉取模式需配置 Pull Server
3. **依赖关系**：合理使用 `DependsOn` 建立资源间的执行顺序，避免因执行顺序不当导致配置失败
4. **幂等性**：所有 DSC 资源必须是幂等的——多次执行结果相同。`TestScript` 返回 `$true` 时 `SetScript` 不应执行
5. **凭据加密**：配置中使用的凭据必须通过证书加密，使用 `ConfigurationData` 中的 `CertificateFile` 和 `Thumbprint` 参数
6. **DSC v3 趋势**：微软正在推进 DSC v3，新项目建议关注 DSC v3 的进展，但生产环境仍以 v2 为主
