---
layout: post
date: 2025-10-28 08:00:00
updated: 2025-10-28 08:00:00
title: "PowerShell 技能连载 - DSC v3 配置管理"
description: PowerTip of the Day - DSC v3 Configuration Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dsc
- desired-state
- configuration
- devops
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

Desired State Configuration（DSC）一直是 Windows 生态中基础设施即代码（IaC）的重要支柱。从 DSC v1 基于 MOF 的推送模式，到 DSC v2 引入的拉取服务，再到如今全新的 DSC v3，微软对配置管理的理念发生了根本性的转变。DSC v3 完全抛弃了对 WMF（Windows Management Framework）的依赖，转而成为一个独立的跨平台工具，支持 Windows、Linux 甚至 macOS。

DSC v3 的核心变化在于它不再绑定 PowerShell 作为运行时。新的 DSC 引擎（`dsc`）是原生可执行文件，配置文档采用 YAML 或 JSON 格式编写，资源可以通过任何语言实现（不再局限于 PowerShell 模块）。这使得 DSC v3 能够更好地融入现代 DevOps 流水线，与 Ansible、Chef、Terraform 等工具协同工作。同时，DSC v3 还引入了基于 JSON Schema 的配置验证机制，在应用配置之前就能捕获语法和结构错误。

对于 PowerShell 用户而言，DSC v3 带来的好消息是你仍然可以用 PowerShell 编写自定义 DSC 资源，同时享受新版引擎带来的性能提升和更好的错误报告。下面我们通过几个实际示例来体验 DSC v3 的核心用法。

<!-- more -->

## 安装 DSC v3

DSC v3 是独立发布的工具，不随 PowerShell 自带。你可以通过多种方式安装。

```powershell
# 使用 winget 安装 DSC v3（Windows）
winget install Microsoft.DSC v3

# 或者手动下载安装
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/DSC/releases/latest'
$asset = $release.assets | Where-Object { $_.name -like '*-x64*' -and $_.name -like '*.msi' }
$downloadPath = Join-Path $env:TEMP $asset.name
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath
Write-Host "已下载到: $downloadPath"

# 验证安装
dsc --version
```

安装完成后，可以通过以下输出确认版本信息：

```
3.0.0
```

## 编写 YAML 配置文档

DSC v3 采用声明式的配置文档，用 YAML 或 JSON 描述期望状态。下面是一个典型的操作系统配置文档，涵盖文件管理、环境变量和软件包安装。

```powershell
# 创建 DSC v3 配置文档
$configContent = @"
schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json
resources:
  - name: Ensure temp directory
    type: Microsoft.DSC/File
    properties:
      destinationPath: /tmp/dsc-demo
      ensure: present
      attributes:
        - directory

  - name: Set editor environment variable
    type: Microsoft.DSC/Environment
    properties:
      name: EDITOR
      value: code
      ensure: present

  - name: Install Git
    type: Microsoft.DSC/Package
    properties:
      name: git
      ensure: present
"@

$configPath = Join-Path $env:TEMP 'dsc-config.dsc.yaml'
$configContent | Set-Content -Path $configPath -Encoding UTF8
Write-Host "配置文档已写入: $configPath"
```

执行结果示例：

```
配置文档已写入: /tmp/dsc-config.dsc.yaml
```

## 验证和测试配置

在真正应用配置之前，先用 `dsc config test` 检查当前系统是否已经符合期望状态。这是一个安全且不会产生副作用的操作。

```powershell
# 验证配置文档的语法正确性
dsc config validate --path $configPath

# 测试当前系统状态与期望配置的差异
$testResult = dsc config test --path $configPath 2>&1
$resultObj = $testResult | ConvertFrom-Json

foreach ($resource in $resultObj.results) {
    $status = if ($resource.inDesiredState) { '符合' } else { '不符合' }
    Write-Host ("资源 [{0}] 状态: {1}" -f $resource.name, $status)
}
```

执行结果示例：

```
资源 [Ensure temp directory] 状态: 不符合
资源 [Set editor environment variable] 状态: 不符合
资源 [Install Git] 状态: 符合
```

## 应用配置并获取状态

确认测试结果后，使用 `dsc config set` 将系统推进到期望状态，再用 `dsc config get` 确认最终结果。

```powershell
# 应用配置（将系统设置为期望状态）
$setResult = dsc config set --path $configPath 2>&1
$setObj = $setResult | ConvertFrom-Json

foreach ($op in $setObj.operations) {
    Write-Host ("操作: {0} -> {1}" -f $op.resourceName, $op.operation)
}

Write-Host "`n--- 获取当前配置状态 ---"

# 获取当前系统的实际状态
$getResult = dsc config get --path $configPath 2>&1
$getObj = $getResult | ConvertFrom-Json

foreach ($resource in $getObj.results) {
    $state = if ($resource.inDesiredState) { 'OK' } else { 'DRIFT' }
    Write-Host ("{0}: {1}" -f $resource.name, $state)
}
```

执行结果示例：

```
操作: Ensure temp directory -> set
操作: Set editor environment variable -> set

--- 获取当前配置状态 ---
Ensure temp directory: OK
Set editor environment variable: OK
Install Git: OK
```

## 编写基于 PowerShell 的自定义 DSC 资源

DSC v3 的一大改进是自定义资源不再需要实现复杂的 Cmdlet 类。你只需要提供一个导出 JSON 清单的 PowerShell 脚本，然后实现 `get`、`set`、`test` 三个操作即可。

```powershell
# 创建自定义 DSC 资源的目录结构
$resourceDir = Join-Path $env:TEMP 'DSCResources/MyCustomService'
New-Item -ItemType Directory -Path $resourceDir -Force | Out-Null

# 资源清单文件 (resource.manifest.json)
$manifest = @{
    schemaVersion    = '2024/04'
    type             = 'MyCustom/Service'
    version          = '1.0.0'
    description      = '管理 Windows 服务的自定义 DSC 资源'
    capabilities     = @('get', 'set', 'test')
    filePath         = './service-resource.ps1'
} | ConvertTo-Json -Depth 5

$manifest | Set-Content (Join-Path $resourceDir 'resource.manifest.json')

# 资源实现脚本 (service-resource.ps1)
$scriptContent = @'
param(
    [string]$Operation,
    [string]$InputData
)

$config = $InputData | ConvertFrom-Json

switch ($Operation) {
    'get' {
        $service = Get-Service -Name $config.name -ErrorAction SilentlyContinue
        if ($service) {
            @{ name = $config.name; status = $service.Status; startType = $service.StartType } |
                ConvertTo-Json -Compress
        } else {
            @{ name = $config.name; status = 'NotFound'; startType = 'Unknown' } |
                ConvertTo-Json -Compress
        }
    }
    'test' {
        $service = Get-Service -Name $config.name -ErrorAction SilentlyContinue
        $desiredState = $config.ensure -eq 'present'
        $actualState = ($null -ne $service -and $service.Status -eq 'Running')
        @{ inDesiredState = ($desiredState -eq $actualState) } |
            ConvertTo-Json -Compress
    }
    'set' {
        if ($config.ensure -eq 'present') {
            Set-Service -Name $config.name -StartupType Automatic
            Start-Service -Name $config.name
        } else {
            Stop-Service -Name $config.name -Force
            Set-Service -Name $config.name -StartupType Disabled
        }
        @{ changed = $true } | ConvertTo-Json -Compress
    }
}
'@

$scriptContent | Set-Content (Join-Path $resourceDir 'service-resource.ps1')
Write-Host "自定义资源已创建于: $resourceDir"
Write-Host "清单文件: resource.manifest.json"
Write-Host "实现脚本: service-resource.ps1"
```

执行结果示例：

```
自定义资源已创建于: /tmp/DSCResources/MyCustomService
清单文件: resource.manifest.json
实现脚本: service-resource.ps1
```

## 注意事项

1. **DSC v3 与旧版不兼容**：DSC v3 使用全新的配置格式（YAML/JSON），无法直接复用 DSC v1/v2 的 MOF 配置。迁移时需要重写配置文档，但资源逻辑通常可以保留。

2. **资源清单是必须的**：每个自定义资源都必须提供 `resource.manifest.json`，其中声明资源类型、版本、支持的操作（`get`、`set`、`test`、`delete`）以及入口脚本的路径。缺少清单会导致 DSC 引擎无法发现该资源。

3. **跨平台差异**：虽然 DSC v3 支持多平台，但并非所有内置资源在每个操作系统上都可用。例如 `Microsoft.DSC/Package` 在 Linux 上使用系统包管理器（apt/yum），在 Windows 上则使用 winget 或 MSI。编写配置时要注意目标平台。

4. **幂等性是关键**：`set` 操作必须是幂等的——多次执行 `set` 不应产生副作用。确保你的 `test` 操作能准确检测当前状态，`set` 操作只在需要变更时才执行修改。

5. **JSON 输出格式**：自定义资源的 PowerShell 脚本必须输出有效的 JSON（使用 `ConvertTo-Json`），且不能有多余的控制台输出（Write-Host 等），否则会导致 DSC 引擎解析失败。调试时可以重定向到文件。

6. **Schema 验证要先于部署**：始终先运行 `dsc config validate` 检查配置文档的语法和结构，再执行 `test` 和 `set`。这可以在早期捕获拼写错误和结构问题，避免运行时意外。
