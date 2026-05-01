---
layout: post
date: 2025-11-03 08:00:00
title: "PowerShell 技能连载 - Azure Functions 无服务器"
description: PowerTip of the Day - Azure Functions Serverless in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure-functions
- serverless
- cloud
- automation
---

_适用于 PowerShell 7.0 及以上版本_

无服务器架构（Serverless）正在改变企业自动化的交付方式。Azure Functions 作为微软云平台的核心计算服务，支持 PowerShell 作为一等公民运行时——这意味着你可以直接用 PowerShell 脚本响应 HTTP 请求、处理队列消息、定时执行任务，而无需管理任何虚拟机或容器。Azure 负责底层基础设施的扩缩容、补丁更新和高可用，你只需关注业务逻辑本身。

对于 PowerShell 运维人员来说，Azure Functions 打开了全新的可能性。传统的计划任务、Windows 服务、甚至本地脚本，都可以迁移到云端，获得天然的高可用性和按需付费的优势。2025 年，Azure Functions 已全面支持 PowerShell 7.4 运行时，并且与 Azure Managed Identity、Key Vault 等安全组件深度集成，让云端自动化脚本既安全又易维护。本文将从实战角度出发，带你完成 Azure Functions 的项目创建、本地调试和云端部署全流程。

## 场景一：使用 PowerShell 创建 Azure Functions 项目

Azure Functions Core Tools 提供了完整的命令行开发体验。下面的脚本会自动初始化一个 PowerShell Azure Functions 项目，并创建两个常用触发器函数——HTTP 触发器和定时触发器，让你快速搭建起自动化骨架。

```powershell
function New-AzureFunctionsProject {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,

        [string]$Location = 'eastasia',
        [string]$Runtime = 'powershell',
        [string]$RootPath = $PWD.Path
    )

    $projectDir = Join-Path $RootPath $ProjectName

    if (Test-Path $projectDir) {
        Write-Output "项目目录已存在: $projectDir"
        return
    }

    Write-Output "=== 创建 Azure Functions 项目 ==="
    Write-Output "项目名称: $ProjectName"
    Write-Output "运行时:   $Runtime"
    Write-Output "区域:     $Location"
    Write-Output ""

    # 初始化 Functions 项目
    $null = New-Item -Path $projectDir -ItemType Directory -Force
    Push-Location $projectDir

    try {
        # 初始化项目（相当于 func init）
        $hostJson = @{
            version = '2.0'
            logging = @{
                applicationInsights = @{
                    samplingSettings = @{
                        isEnabled = $false
                    }
                }
            }
            extensionBundle = @{
                id      = 'Microsoft.Azure.Functions.ExtensionBundle'
                version = '[4.*, 5.0.0)'
            }
        }
        $hostJson | ConvertTo-Json -Depth 5 |
            Out-File -FilePath 'host.json' -Encoding UTF8

        # 创建 local.settings.json
        $localSettings = @{
            IsEncrypted               = $false
            Values                    = @{
                AzureWebJobsStorage           = 'UseDevelopmentStorage=true'
                FUNCTIONS_WORKER_RUNTIME      = 'powershell'
                FUNCTIONS_WORKER_RUNTIME_VERSION = '~7'
            }
        }
        $localSettings | ConvertTo-Json -Depth 5 |
            Out-File -FilePath 'local.settings.json' -Encoding UTF8

        # 创建 profile.ps1（模块加载和托管身份初始化）
        $profileContent = @'
# Azure Functions Profile
# 此文件在每次函数调用前自动执行

if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity
}
'@
        $profileContent | Out-File -FilePath 'profile.ps1' -Encoding UTF8

        # 创建 requirements.psd1（PowerShell 模块依赖）
        $requirementsContent = @'
# 此文件声明函数所需的 PowerShell 模块
# Azure Functions 会在部署时自动安装这些模块
@{
    'Az' = '13.*'
    'Az.TableModule' = '0.*'
}
'@
        $requirementsContent | Out-File -FilePath 'requirements.psd1' -Encoding UTF8

        # 创建 HTTP 触发器函数
        $httpDir = Join-Path $projectDir 'Get-SystemStatus'
        $null = New-Item -Path $httpDir -ItemType Directory -Force

        $functionJson = @{
            bindings = @(
                @{
                    authLevel = 'function'
                    type      = 'httpTrigger'
                    direction = 'in'
                    name      = 'Request'
                    methods   = @('get')
                }
                @{
                    type      = 'http'
                    direction = 'out'
                    name      = 'Response'
                }
            )
        }
        $functionJson | ConvertTo-Json -Depth 5 |
            Out-File -FilePath (Join-Path $httpDir 'function.json') -Encoding UTF8

        $runPs1 = @'
using namespace System.Net

param($Request, $TriggerMetadata)

$status = [PSCustomObject]@{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Machine   = $env:COMPUTERNAME
    Runtime   = $PSVersionTable.PSVersion.ToString()
    Platform  = $PSVersionTable.Platform
    Status    = 'Healthy'
}

Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = ($status | ConvertTo-Json)
        ContentType = 'application/json'
    }
)
'@
        $runPs1 | Out-File -FilePath (Join-Path $httpDir 'run.ps1') -Encoding UTF8

        # 创建定时触发器函数（每天早上 8 点执行）
        $timerDir = Join-Path $projectDir 'DailyHealthCheck'
        $null = New-Item -Path $timerDir -ItemType Directory -Force

        $timerJson = @{
            bindings = @(
                @{
                    type       = 'timerTrigger'
                    direction  = 'in'
                    name       = 'TimerInfo'
                    schedule   = '0 0 8 * * *'
                }
            )
        }
        $timerJson | ConvertTo-Json -Depth 5 |
            Out-File -FilePath (Join-Path $timerDir 'function.json') -Encoding UTF8

        $timerRun = @'
param($TimerInfo)

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Output "[$timestamp] 每日健康检查开始执行"

# 模拟检查逻辑
$checks = @(
    @{ Name = '存储账户连接'; Status = 'OK'; Detail = '响应时间 45ms' }
    @{ Name = '数据库可用性'; Status = 'OK'; Detail = '延迟 12ms' }
    @{ Name = 'API 网关状态'; Status = 'OK'; Detail = '成功率 99.97%' }
)

foreach ($check in $checks) {
    Write-Output "  [$($check.Status)] $($check.Name) - $($check.Detail)"
}

Write-Output "[$timestamp] 每日健康检查完成"
'@
        $timerRun | Out-File -FilePath (Join-Path $timerDir 'run.ps1') -Encoding UTF8

        # 列出项目结构
        Write-Output ""
        Write-Output "=== 项目结构 ==="
        $files = Get-ChildItem -Path $projectDir -Recurse -File
        foreach ($file in $files) {
            $relativePath = $file.FullName.Replace("$projectDir\", '')
            Write-Output "  $relativePath"
        }
        Write-Output ""
        Write-Output "项目创建完成: $projectDir"
    }
    finally {
        Pop-Location
    }
}

New-AzureFunctionsProject -ProjectName 'MyServerlessAutomation'
```

执行结果示例：

```text
=== 创建 Azure Functions 项目 ===
项目名称: MyServerlessAutomation
运行时:   powershell
区域:     eastasia

=== 项目结构 ===
  host.json
  local.settings.json
  profile.ps1
  requirements.psd1
  Get-SystemStatus\function.json
  Get-SystemStatus\run.ps1
  DailyHealthCheck\function.json
  DailyHealthCheck\run.ps1

项目创建完成: /Users/dev/MyServerlessAutomation
```

脚本创建了一个完整的 Azure Functions 项目结构，包含两个函数：`Get-SystemStatus` 是一个 HTTP 触发器，返回当前运行环境的状态信息；`DailyHealthCheck` 是一个定时触发器，每天早上 8 点自动执行健康检查。`requirements.psd1` 声明了模块依赖，部署时 Azure 会自动安装。`profile.ps1` 处理了托管身份认证，让函数在云端运行时自动获取 Azure 资源的访问令牌。

## 场景二：本地调试与测试

在推送到 Azure 之前，建议先在本地完成调试。Azure Functions Core Tools 提供了本地运行时环境，可以模拟 HTTP 触发和定时触发。下面的脚本演示如何在本地启动函数运行时，并对 HTTP 函数进行集成测试。

```powershell
function Test-AzureFunctionsLocally {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [int]$Port = 7071
    )

    Write-Output "=== 本地测试 Azure Functions ==="
    Write-Output "项目路径: $ProjectPath"
    Write-Output "监听端口: $Port"
    Write-Output ""

    # 检查 func CLI 是否安装
    $funcCli = Get-Command 'func' -ErrorAction SilentlyContinue
    if (-not $funcCli) {
        Write-Output "[错误] 未找到 Azure Functions Core Tools"
        Write-Output "安装方式: npm install -g azure-functions-core-tools@4"
        return
    }

    Write-Output "Core Tools 版本: $($funcCli.Version)"
    Write-Output ""

    # 模拟发送 HTTP 请求到本地函数
    $baseUrl = "http://localhost:$Port"
    $testResults = [System.Text.StringBuilder]::new()

    $null = $testResults.AppendLine("=== 集成测试结果 ===")
    $null = $testResults.AppendLine("测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $testResults.AppendLine()

    # 测试一：调用 Get-SystemStatus 函数
    $null = $testResults.AppendLine("[测试 1] HTTP 触发器 - Get-SystemStatus")
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Get-SystemStatus" -Method Get `
            -ErrorAction Stop
        $null = $testResults.AppendLine("  状态码: 200 OK")
        $null = $testResults.AppendLine("  响应体:")
        $formattedJson = $response | ConvertTo-Json -Depth 3
        foreach ($line in $formattedJson.Split("`n")) {
            $null = $testResults.AppendLine("    $($line.Trim())")
        }
        $null = $testResults.AppendLine("  结果: PASS")
    }
    catch {
        $null = $testResults.AppendLine("  结果: FAIL - $($_.Exception.Message)")
    }
    $null = $testResults.AppendLine()

    # 测试二：验证函数配置文件完整性
    $null = $testResults.AppendLine("[测试 2] 项目配置验证")
    $configChecks = @(
        @{ File = 'host.json'; Desc = '主机配置' },
        @{ File = 'local.settings.json'; Desc = '本地设置' },
        @{ File = 'profile.ps1'; Desc = 'PowerShell 配置文件' },
        @{ File = 'requirements.psd1'; Desc = '模块依赖' }
    )

    foreach ($check in $configChecks) {
        $filePath = Join-Path $ProjectPath $check.File
        if (Test-Path $filePath) {
            $null = $testResults.AppendLine("  [OK] $($check.Desc) ($($check.File))")
        }
        else {
            $null = $testResults.AppendLine("  [MISSING] $($check.Desc) ($($check.File))")
        }
    }
    $null = $testResults.AppendLine()

    # 测试三：验证函数目录结构
    $null = $testResults.AppendLine("[测试 3] 函数目录验证")
    $functionDirs = Get-ChildItem -Path $ProjectPath -Directory |
        Where-Object {
            Test-Path (Join-Path $_.FullName 'function.json')
        }

    foreach ($dir in $functionDirs) {
        $hasRun = Test-Path (Join-Path $dir.FullName 'run.ps1')
        $hasConfig = Test-Path (Join-Path $dir.FullName 'function.json')
        $status = if ($hasRun -and $hasConfig) { 'OK' } else { 'INCOMPLETE' }
        $null = $testResults.AppendLine(
            "  [$status] $($dir.Name) - run.ps1: $hasRun, function.json: $hasConfig"
        )
    }
    $null = $testResults.AppendLine()

    # 测试四：检查模块依赖是否可解析
    $null = $testResults.AppendLine("[测试 4] 模块依赖检查")
    $reqPath = Join-Path $ProjectPath 'requirements.psd1'
    if (Test-Path $reqPath) {
        $requirements = Import-PowerShellDataFile -Path $reqPath -ErrorAction Stop
        foreach ($module in $requirements.GetEnumerator()) {
            $installed = Get-Module -Name $module.Key -ListAvailable -ErrorAction SilentlyContinue
            if ($installed) {
                $null = $testResults.AppendLine(
                    "  [OK] $($module.Key) - 本地版本: $($installed[0].Version)"
                )
            }
            else {
                $null = $testResults.AppendLine(
                    "  [PENDING] $($module.Key) $($module.Value) - 部署时自动安装"
                )
            }
        }
    }
    $null = $testResults.AppendLine()
    $null = $testResults.AppendLine("=== 测试完成 ===")

    Write-Output $testResults.ToString()
}

Test-AzureFunctionsLocally -ProjectPath '/Users/dev/MyServerlessAutomation'
```

执行结果示例：

```text
=== 本地测试 Azure Functions ===
项目路径: /Users/dev/MyServerlessAutomation
监听端口: 7071

Core Tools 版本: 4.0.6610

=== 集成测试结果 ===
测试时间: 2025-11-03 10:15:30

[测试 1] HTTP 触发器 - Get-SystemStatus
  状态码: 200 OK
  响应体:
    {
      "Timestamp": "2025-11-03 10:15:31",
      "Machine": "localhost",
      "Runtime": "7.4.6",
      "Platform": "Unix",
      "Status": "Healthy"
    }
  结果: PASS

[测试 2] 项目配置验证
  [OK] 主机配置 (host.json)
  [OK] 本地设置 (local.settings.json)
  [OK] PowerShell 配置文件 (profile.ps1)
  [OK] 模块依赖 (requirements.psd1)

[测试 3] 函数目录验证
  [OK] Get-SystemStatus - run.ps1: True, function.json: True
  [OK] DailyHealthCheck - run.ps1: True, function.json: True

[测试 4] 模块依赖检查
  [OK] Az - 本地版本: 13.2.0
  [PENDING] Az.TableModule 0.* - 部署时自动安装

=== 测试完成 ===
```

本地测试通过后，可以确信函数逻辑和配置文件都正确无误。`Az` 模块已在本地安装，而 `Az.TableModule` 将在部署时由 Azure Functions 自动安装——这就是 `requirements.psd1` 的作用。测试脚本还验证了每个函数目录下都有完整的 `run.ps1` 和 `function.json` 文件对，这是 Azure Functions 加载函数的必要条件。

## 场景三：自动化部署到 Azure 云端

项目经过本地测试后，下一步是部署到 Azure。下面的脚本将创建所需的云资源（资源组、存储账户、Function App），并完成代码部署。整个过程完全自动化，无需手动操作 Azure Portal。

```powershell
function Publish-AzureFunctionsProject {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [string]$AppName,

        [string]$ResourceGroupName = "rg-$AppName",
        [string]$Location = 'eastasia',
        [string]$Sku = 'Y1'
    )

    Write-Output "=== 部署 Azure Functions 到云端 ==="
    Write-Output "应用名称:  $AppName"
    Write-Output "资源组:    $ResourceGroupName"
    Write-Output "区域:      $Location"
    Write-Output ""

    $deployLog = [System.Text.StringBuilder]::new()
    $null = $deployLog.AppendLine("部署开始: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

    # 步骤一：创建资源组
    $null = $deployLog.AppendLine("[1/5] 创建资源组...")
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        $null = $deployLog.AppendLine("  已创建资源组: $ResourceGroupName ($Location)")
    }
    else {
        $null = $deployLog.AppendLine("  资源组已存在: $ResourceGroupName")
    }

    # 步骤二：创建存储账户（Functions 运行时必需）
    $null = $deployLog.AppendLine("[2/5] 创建存储账户...")
    $storageName = "st$($AppName -replace '-','').Substring(0, [Math]::Min(19, ($AppName -replace '-','').Length))"
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName `
        -Name $storageName -ErrorAction SilentlyContinue

    if (-not $storageAccount) {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
            -Name $storageName -Location $Location `
            -SkuName 'Standard_LRS' -Kind 'StorageV2'
        $null = $deployLog.AppendLine("  已创建存储账户: $storageName")
    }
    else {
        $null = $deployLog.AppendLine("  存储账户已存在: $storageName")
    }

    # 步骤三：创建 Function App（消费计划）
    $null = $deployLog.AppendLine("[3/5] 创建 Function App...")
    $funcApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName `
        -Name $AppName -ErrorAction SilentlyContinue

    if (-not $funcApp) {
        $planName = "plan-$AppName"
        $null = New-AzFunctionApp -ResourceGroupName $ResourceGroupName `
            -Name $AppName `
            -StorageAccountName $storageName `
            -Runtime 'PowerShell' `
            -RuntimeVersion '7.4' `
            -PlanName $planName `
            -OSType 'Windows' `
            -Location $Location `
            -FunctionsVersion '4'

        $null = $deployLog.AppendLine("  已创建 Function App: $AppName")
        $null = $deployLog.AppendLine("  运行时: PowerShell 7.4")
        $null = $deployLog.AppendLine("  计划类型: 消费 (Serverless)")
    }
    else {
        $null = $deployLog.AppendLine("  Function App 已存在: $AppName")
    }

    # 步骤四：配置应用设置
    $null = $deployLog.AppendLine("[4/5] 配置应用设置...")
    $appSettings = @{
        FUNCTIONS_WORKER_RUNTIME_VERSION = '~7'
        PowerShellModuleVersion          = '7.4'
    }

    # 启用 Managed Identity
    $identity = Get-AzWebApp -ResourceGroupName $ResourceGroupName `
        -Name $AppName -ErrorAction SilentlyContinue
    if ($identity -and -not $identity.Identity.Type) {
        $null = Set-AzWebApp -ResourceGroupName $ResourceGroupName `
            -Name $AppName -AssignIdentity $true
        $null = $deployLog.AppendLine("  已启用系统分配的托管身份")
    }
    else {
        $null = $deployLog.AppendLine("  托管身份已配置")
    }

    # 步骤五：部署函数代码
    $null = $deployLog.AppendLine("[5/5] 部署函数代码...")
    $publishResult = Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
        -Name $AppName -ArchivePath $ProjectPath -Force

    if ($publishResult) {
        $null = $deployLog.AppendLine("  代码部署成功")
    }

    $null = $deployLog.AppendLine()
    $null = $deployLog.AppendLine("=== 部署摘要 ===")
    $null = $deployLog.AppendLine("Function App:  $AppName")
    $null = $deployLog.AppendLine("资源组:        $ResourceGroupName")
    $null = $deployLog.AppendLine("存储账户:      $storageName")
    $null = $deployLog.AppendLine("运行时:        PowerShell 7.4")
    $null = $deployLog.AppendLine("访问地址:      https://$AppName.azurewebsites.net")
    $null = $deployLog.AppendLine()
    $null = $deployLog.AppendLine("部署完成: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

    Write-Output $deployLog.ToString()
}

Publish-AzureFunctionsProject `
    -ProjectPath '/Users/dev/MyServerlessAutomation' `
    -AppName 'my-serverless-auto'
```

执行结果示例：

```text
=== 部署 Azure Functions 到云端 ===
应用名称:  my-serverless-auto
资源组:    rg-my-serverless-auto
区域:      eastasia

部署开始: 2025-11-03 11:02:45

[1/5] 创建资源组...
  已创建资源组: rg-my-serverless-auto (eastasia)
[2/5] 创建存储账户...
  已创建存储账户: stmyserverlessauto
[3/5] 创建 Function App...
  已创建 Function App: my-serverless-auto
  运行时: PowerShell 7.4
  计划类型: 消费 (Serverless)
[4/5] 配置应用设置...
  已启用系统分配的托管身份
[5/5] 部署函数代码...
  代码部署成功

=== 部署摘要 ===
Function App:  my-serverless-auto
资源组:        rg-my-serverless-auto
存储账户:      stmyserverlessauto
运行时:        PowerShell 7.4
访问地址:      https://my-serverless-auto.azurewebsites.net

部署完成: 2025-11-03 11:05:18
```

整个部署过程耗时约 3 分钟，从零开始创建了资源组、存储账户和 Function App。使用消费计划（Consumption Plan）意味着只有在函数实际执行时才计费，空闲时不产生任何费用。系统分配的托管身份让函数可以安全访问其他 Azure 资源（如存储、数据库、Key Vault），无需在代码中硬编码密码或密钥。

## 注意事项

1. **PowerShell 运行时版本**：Azure Functions 对 PowerShell 7.x 的支持有明确的版本窗口。建议在创建 Function App 时指定 `-RuntimeVersion '7.4'`，并在 `local.settings.json` 和 `requirements.psd1` 中保持版本一致。避免使用过旧的 5.1 运行时（仅限 Windows），新项目应统一使用 PowerShell 7。

2. **冷启动延迟**：消费计划的 Function App 在首次请求或长时间空闲后会经历冷启动，PowerShell 函数的冷启动时间通常在 5-15 秒。如果对响应延迟敏感，可以考虑使用高级计划（Premium Plan）并设置最小实例数（minimum instance count）为 1，保持至少一个实例始终预热。

3. **模块管理策略**：`requirements.psd1` 中声明的模块会在部署时自动安装，但大型模块（如 `Az`）会增加部署时间和冷启动开销。建议只声明实际使用的子模块（如 `Az.Storage`、`Az.KeyVault`），而不是整个 `Az` 模块。单个函数的模块加载应控制在 30 秒以内。

4. **触发器选择**：不同触发器类型适用于不同场景——HTTP 触发器适合 API 和 Webhook，定时触发器适合周期性任务，队列触发器适合异步处理，Blob 触发器适合文件处理。避免用定时触发器轮询外部服务，应该使用事件驱动的触发器（如 Event Grid）来降低延迟和成本。

5. **敏感信息处理**：连接字符串、API 密钥等敏感信息绝不能写在代码或 `local.settings.json` 中。生产环境应使用 Azure Key Vault 结合 Managed Identity 来安全读取密钥。`local.settings.json` 应添加到 `.gitignore`，防止意外提交到代码仓库。

6. **日志与监控**：Azure Functions 默认集成 Application Insights，会自动收集执行日志、异常信息和性能指标。建议在 `host.json` 中合理配置日志级别（Information 用于常规日志，Warning 以上用于生产告警），并在关键业务函数中加入结构化日志输出，方便后续在 Application Insights 中查询和分析。
