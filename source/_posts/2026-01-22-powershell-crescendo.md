---
layout: post
date: 2026-01-22 08:00:00
updated: 2026-01-22 08:00:00
title: "PowerShell 技能连载 - Crescendo 命令包装框架"
description: PowerTip of the Day - Crescendo Command Wrapping Framework in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- crescendo
- cli
- wrapper
- module-development
---

_适用于 PowerShell 7.0 及以上版本_

在日常运维中，我们经常需要调用 `kubectl`、`docker`、`az`、`terraform` 等命令行工具。这些工具虽然功能强大，但在 PowerShell 中使用时只能以字符串拼接的方式构造命令——没有参数补全、没有输入验证、输出是纯文本而非结构化对象，也无法通过管道传递数据。这种体验与 PowerShell 原生 cmdlet 的使用方式截然不同。

PowerShell Crescendo 是微软推出的命令包装框架，它的核心理念是"配置即代码"。通过编写一份 JSON 配置文件，你可以将任意 CLI 工具包装成符合 PowerShell 规范的高级函数：支持参数验证、管道绑定、结构化对象输出以及完整的帮助文档，而无需手写大量模板代码。

Cresceno 特别适合那些需要在团队中标准化 CLI 工具调用方式的场景。包装后的模块可以发布到 PowerShell Gallery，团队成员只需 `Install-Module` 即可获得一致的 PowerShell 体验。本文将从配置基础、输出处理到完整模块发布三个阶段，带你掌握 Crescendo 的核心用法。

<!-- more -->

## Crescendo 配置基础

Crescendo 的起点是一份 JSON 配置文件，它定义了目标 CLI 工具的路径、参数映射以及输出处理规则。从 PowerShell 7.4 开始，Crescendo 使用 `.crescendo.json` 扩展名，并遵循标准的 JSON Schema。

以下是一个将 `curl` 包装为 `Invoke-WebRequest` 风格命令的配置示例：

```powershell
# 安装 Crescendo 模块
Install-Module -Name Crescendo -Force

# 创建一个 Crescendo 配置
$config = @{
    '$schema'        = 'https://aka.ms/PowerShell/Crescendo/Schemas/2024-11'
    Information      = @{
        Name        = 'CurlWrapper'
        Description = '将 curl 包装为 PowerShell 原生函数'
        Version     = '1.0.0'
    }
    Commands         = @(
        @{
            Verb        = 'Invoke'
            Noun        = 'CurlRequest'
            OriginalName = 'curl'
            OriginalCommandElements = @()
            Parameters  = @(
                @{
                    Name        = 'Url'
                    OriginalName = ''
                    ParameterType = 'string'
                    Mandatory   = $true
                    Position    = 0
                    Description = '目标 URL'
                }
                @{
                    Name        = 'Method'
                    OriginalName = '-X'
                    ParameterType = 'string'
                    DefaultValue = 'GET'
                    Description = 'HTTP 方法'
                    ValidateSet = @('GET', 'POST', 'PUT', 'DELETE', 'PATCH')
                }
                @{
                    Name        = 'Header'
                    OriginalName = '-H'
                    ParameterType = 'string[]'
                    Description = '自定义请求头'
                }
                @{
                    Name        = 'Data'
                    OriginalName = '-d'
                    ParameterType = 'string'
                    Description = '请求体数据'
                }
                @{
                    Name        = 'Insecure'
                    OriginalName = '-k'
                    ParameterType = 'switch'
                    Description = '跳过 SSL 证书验证'
                }
                @{
                    Name        = 'Silent'
                    OriginalName = '-s'
                    ParameterType = 'switch'
                    DefaultValue = $true
                    Description = '静默模式（默认启用）'
                }
            )
            Help = @{
                Synopsis    = '使用 curl 发送 HTTP 请求'
                Description = '将 curl 命令包装为 PowerShell 函数，支持参数补全和验证。'
                Examples    = @(
                    @{
                        Command     = 'Invoke-CurlRequest -Url "https://api.github.com/repos"'
                        Description = '获取 GitHub 仓库列表'
                    }
                )
            }
        }
    )
}

# 保存配置到文件
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath './CurlWrapper.crescendo.json'
```

执行上述脚本后，当前目录会生成一份 `CurlWrapper.crescendo.json` 配置文件，这就是 Crescendo 模块的蓝图：

```
    Directory: /home/user/projects/CurlWrapper

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          1/22/2026  10:00 AM           2847 CurlWrapper.crescendo.json
```

## 输出处理与对象转换

Crescendo 的真正威力在于输出处理（Output Handler）。CLI 工具的输出通常是纯文本或 JSON 字符串，Crescendo 可以通过配置自动将其转换为 PowerShell 对象，使输出可以直接通过管道传递给 `Where-Object`、`Select-Object` 等 cmdlet。

下面我们为之前的配置添加 JSON 输出处理和错误处理逻辑：

```powershell
# 在配置中添加 OutputHandler
$config.Commands[0].OutputHandlers = @(
    @{
        ParameterSetName = 'Default'
        Handler         = @'
$rawOutput = $__OUTPUT__
if ($rawOutput -match '^\s*[{[]') {
    try {
        $result = $rawOutput | ConvertFrom-Json -Depth 10
        # 如果返回的是数组，展开每一项
        if ($result -is [System.Array]) {
            $result | ForEach-Object {
                $_ | Add-Member -NotePropertyName '_RawOutput' `
                    -NotePropertyValue $rawOutput -PassThru -Force
            }
        } else {
            $result | Add-Member -NotePropertyName '_RawOutput' `
                -NotePropertyValue $rawOutput -PassThru -Force
        }
    } catch {
        Write-Warning "JSON 解析失败: $($_.Exception.Message)"
        $rawOutput
    }
} else {
    # 非 JSON 输出原样返回
    $rawOutput
}
'@
        HandlerType     = 'Inline'
    }
)

# 添加错误处理配置
$config.Commands[0].EmitErrorAction = 'Continue'
$config.Commands[0].ErrorHandler = @'
$errorText = $__ERROR_OUTPUT__
if ($errorText -match 'curl:\s*\((\d+)\)\s*(.+)') {
    $errorCode = $Matches[1]
    $errorMsg  = $Matches[2]
    Write-Error "curl 错误 [$errorCode]: $errorMsg"
} else {
    Write-Error "curl 执行失败: $errorText"
}
'@

# 更新配置文件
$config | ConvertTo-Json -Depth 10 |
    Out-File -FilePath './CurlWrapper.crescendo.json' -Force

# 导出为 PowerShell 模块
Export-CrescendoModule -ConfigurationFile './CurlWrapper.crescendo.json' `
    -Force

# 导入模块并测试
Import-Module './CurlWrapper.psm1' -Force
Invoke-CurlRequest -Url 'https://httpbin.org/json'
```

上面的 OutputHandler 会自动检测 CLI 输出是否为 JSON，如果是则解析为 PowerShell 对象并附加原始输出作为属性，方便调试。非 JSON 输出则原样返回。

```
slideshow    : @{author=Your Name; date=March 8, 2024; title=Sample Slide Show; slides=System.Object[]}
_RawOutput   : {
                 "slideshow": {
                   "author": "Your Name",
                   "date": "March 8, 2024",
                   "title": "Sample Slide Show",
                   "slides": [...]
                 }
               }

PS> Invoke-CurlRequest -Url 'https://httpbin.org/json' |
     Select-Object -ExpandProperty slideshow |
     Select-Object title, author

title            author
-----            ------
Sample Slide Show Your Name
```

## 完整模块实战：发布到 PowerShell Gallery

掌握基础配置和输出处理后，我们来完成一个端到端的实战：将 `nmap`（网络扫描工具）包装为 PowerShell 模块，并发布到 PowerShell Gallery 供团队使用。

```powershell
# 1. 定义多命令配置（一个模块包含多个命令）
$nmapConfig = @{
    '$schema'        = 'https://aka.ms/PowerShell/Crescendo/Schemas/2024-11'
    Information      = @{
        Name        = 'NmapWrapper'
        Description = '将 nmap 网络扫描工具包装为 PowerShell 原生命令'
        Version     = '1.0.0'
        Author      = 'YourName'
        CompanyName = 'YourCompany'
        Tags        = @('network', 'scan', 'nmap', 'security', 'crescendo')
        ProjectUri  = 'https://github.com/yourname/NmapWrapper'
        LicenseUri  = 'https://opensource.org/licenses/MIT'
    }
    Commands         = @(
        # 命令 1：端口扫描
        @{
            Verb        = 'Test'
            Noun        = 'NmapPort'
            OriginalName = 'nmap'
            DefaultParameterSetName = 'QuickScan'
            Parameters  = @(
                @{
                    Name        = 'Target'
                    ParameterType = 'string[]'
                    Mandatory   = $true
                    Position    = 0
                    Description = '目标主机（IP 或主机名）'
                }
                @{
                    Name        = 'Port'
                    OriginalName = '-p'
                    ParameterType = 'string'
                    Description = '指定端口范围（如 80,443 或 1-1024）'
                }
                @{
                    Name        = 'QuickScan'
                    OriginalName = '-T4'
                    ParameterType = 'switch'
                    ParameterSetName = 'QuickScan'
                    Description = '快速扫描模式'
                }
                @{
                    Name        = 'ServiceVersion'
                    OriginalName = '-sV'
                    ParameterType = 'switch'
                    ParameterSetName = 'ServiceScan'
                    Description = '探测服务版本信息'
                }
                @{
                    Name        = 'OperatingSystem'
                    OriginalName = '-O'
                    ParameterType = 'switch'
                    Description = '启用操作系统检测'
                }
            )
            OutputHandlers = @(
                @{
                    ParameterSetName = 'Default'
                    HandlerType      = 'Inline'
                    Handler          = @'
# 将 nmap 的文本输出包装为结构化对象
$__OUTPUT__
'@
                }
            )
        }
    )
}

# 2. 保存并构建模块
$nmapConfig | ConvertTo-Json -Depth 10 |
    Out-File -FilePath './NmapWrapper.crescendo.json' -Force

# 导出为模块
Export-CrescendoModule -ConfigurationFile './NmapWrapper.crescendo.json' `
    -ModuleName './NmapWrapper' -Force

# 3. 创建模块清单（用于发布）
$moduleManifest = @{
    Path          = './NmapWrapper/NmapWrapper.psd1'
    RootModule    = 'NmapWrapper.psm1'
    ModuleVersion = '1.0.0'
    Author        = 'YourName'
    Description   = 'PowerShell Crescendo wrapper for nmap'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Test-NmapPort')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData   = @{
        PSData = @{
            Tags       = @('network', 'nmap', 'security', 'crescendo')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/yourname/NmapWrapper'
        }
    }
}
New-ModuleManifest @moduleManifest

# 4. 测试模块
Import-Module './NmapWrapper' -Force
Get-Command -Module NmapWrapper

# 5. 发布到 PowerShell Gallery（需要 API Key）
# Publish-Module -Path './NmapWrapper' -NuGetApiKey $apiKey
```

执行构建和导入后，可以验证模块是否正确导出了命令：

```
CommandType     Name                Version    Source
-----------     ----                -------    ------
Function        Test-NmapPort       1.0.0      NmapWrapper

PS> Get-Help Test-NmapPort

NAME
    Test-NmapPort

SYNOPSIS
    将 nmap 网络扫描工具包装为 PowerShell 原生命令

SYNTAX
    Test-NmapPort [-Target] <string[]> [-Port <string>] [-QuickScan] [<CommonParameters>]
    Test-NmapPort [-Target] <string[]> [-Port <string>] [-ServiceVersion] [<CommonParameters>]

PARAMETERS
    -Target <string[]>
        目标主机（IP 或主机名）

    -Port <string>
        指定端口范围（如 80,443 或 1-1024）

    -QuickScan
        快速扫描模式
```

## 注意事项

1. **CLI 工具必须已安装**：Crescendo 只是生成包装函数，运行时仍然依赖目标 CLI 工具。建议在模块的 `#Requires` 中明确声明依赖，或在导入时用 `Get-Command` 检测目标工具是否可用。

2. **OriginalName 可以是完整路径**：如果目标工具不在系统 PATH 中，可以在配置中指定完整路径，如 `OriginalName = '/usr/local/bin/mytool'`，确保跨环境兼容。

3. **OutputHandler 中使用 `$__OUTPUT__` 和 `$__ERROR_OUTPUT__`**：这两个变量是 Crescendo 内置的占位符，分别代表 CLI 的标准输出和标准错误。Handler 脚本块必须使用这两个变量来处理输出，不要尝试自己调用原始命令。

4. **JSON 配置的深度问题**：Crescendo 配置结构嵌套较深，使用 `ConvertTo-Json` 时务必指定 `-Depth 10` 或更高，否则内层配置可能被截断为 `System.Object[]` 字符串。

5. **发布前务必测试多平台兼容性**：如果模块需要在 Windows 和 Linux 上使用，注意 CLI 工具在不同平台上的参数差异（如路径分隔符、大小写敏感性等），可以通过 `OriginalCommandElements` 按平台区分参数。

6. **善用 `Import-CrescendoModule` 快速迭代**：开发阶段可以用 `Import-CrescendoModule` 直接从配置文件导入，无需每次都导出为 `.psm1` 文件。调试完成后再用 `Export-CrescendoModule` 生成最终模块。
