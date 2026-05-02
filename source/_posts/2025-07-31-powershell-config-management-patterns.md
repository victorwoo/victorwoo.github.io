---
layout: post
date: 2025-07-31 08:00:00
updated: 2025-07-31 08:00:00
title: "PowerShell 技能连载 - 配置管理模式"
description: PowerTip of the Day - Configuration Management Patterns in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- configuration
- config-management
- settings
---

_适用于 PowerShell 5.1 及以上版本_

几乎所有脚本都涉及配置管理——数据库连接字符串、API 端点、超时设置、日志级别。如何存储、加载、验证、合并配置，直接影响脚本的可维护性和灵活性。硬编码的配置难以适应不同环境，缺少验证的配置导致运行时错误，没有合并机制的配置无法覆盖默认值。

本文将讲解 PowerShell 中的配置管理模式，从简单的配置文件到多层配置合并。

<!-- more -->

## 配置文件格式

```powershell
# 方式 1：JSON 配置文件
$jsonConfig = @"
{
    "appName": "MyApp",
    "version": "2.5.0",
    "database": {
        "server": "prod-db01",
        "port": 5432,
        "name": "myapp_production",
        "timeout": 30
    },
    "logging": {
        "level": "Warning",
        "path": "C:\\Logs\\MyApp",
        "maxSizeMB": 100
    },
    "features": {
        "enableCache": true,
        "enableMetrics": true,
        "maxRetries": 3
    }
}
"@

$jsonConfig | Set-Content "C:\MyApp\config.json" -Encoding UTF8

# 加载 JSON 配置
$config = Get-Content "C:\MyApp\config.json" -Raw | ConvertFrom-Json
Write-Host "应用名：$($config.appName)"
Write-Host "数据库：$($config.database.server):$($config.database.port)"
Write-Host "日志级别：$($config.logging.level)"

# 方式 2：PSD1 配置文件（PowerShell 数据文件）
$psd1Config = @"
@{
    AppName  = 'MyApp'
    Version  = '2.5.0'
    Database = @{
        Server  = 'prod-db01'
        Port    = 5432
        Name    = 'myapp_production'
        Timeout = 30
    }
    Logging  = @{
        Level     = 'Warning'
        Path      = 'C:\Logs\MyApp'
        MaxSizeMB = 100
    }
}
"@

$psd1Config | Set-Content "C:\MyApp\config.psd1" -Encoding UTF8

# 加载 PSD1 配置
$psd1Data = Invoke-Expression (Get-Content "C:\MyApp\config.psd1" -Raw)
Write-Host "`nPSD1 数据库配置：$($psd1Data.Database.Server)"

# 方式 3：环境变量配置
$env:MYAPP_DB_SERVER = "prod-db01"
$env:MYAPP_DB_PORT = "5432"
$env:MYAPP_LOG_LEVEL = "Debug"
Write-Host "环境变量配置：$env:MYAPP_DB_SERVER`:$env:MYAPP_DB_PORT"
```

执行结果示例：

```
应用名：MyApp
数据库：prod-db01:5432
日志级别：Warning

PSD1 数据库配置：prod-db01
环境变量配置：prod-db01:5432
```

## 多层配置合并

```powershell
# 多层配置：默认值 < 配置文件 < 环境变量 < 命令行参数
function Get-ApplicationConfig {
    param(
        [string]$ConfigPath = "C:\MyApp\config.json",
        [string]$Environment = "production"
    )

    # 第一层：默认配置
    $defaults = @{
        appName  = "MyApp"
        version  = "1.0.0"
        database = @{
            server  = "localhost"
            port    = 5432
            name    = "myapp"
            timeout = 30
        }
        logging  = @{
            level     = "Info"
            path      = "C:\Logs\MyApp"
            maxSizeMB = 50
        }
        features = @{
            enableCache   = $true
            enableMetrics = $false
            maxRetries    = 3
        }
    }

    # 第二层：配置文件
    if (Test-Path $ConfigPath) {
        $fileConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $defaults = Merge-Config $defaults (ConvertTo-Hashtable $fileConfig)
        Write-Host "已加载配置文件：$ConfigPath" -ForegroundColor Green
    }

    # 第三层：环境特定配置
    $envConfigPath = $ConfigPath -replace '\.json$', ".$Environment.json"
    if (Test-Path $envConfigPath) {
        $envConfig = Get-Content $envConfigPath -Raw | ConvertFrom-Json
        $defaults = Merge-Config $defaults (ConvertTo-Hashtable $envConfig)
        Write-Host "已加载环境配置：$envConfigPath" -ForegroundColor Green
    }

    # 第四层：环境变量覆盖
    $envPrefix = "MYAPP_"
    Get-ChildItem Env: | Where-Object { $_.Name -like "$envPrefix*" } | ForEach-Object {
        $key = $_.Name.Substring($envPrefix.Length).Replace("_", ".")
        Set-NestedValue -Config $defaults -Path $key -Value $_.Value
    }

    return $defaults
}

# 辅助函数：深度合并
function Merge-Config {
    param($Base, $Override)

    $result = @{}
    foreach ($key in $Base.Keys) { $result[$key] = $Base[$key] }

    foreach ($key in $Override.Keys) {
        if ($result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $result[$key] = Merge-Config $result[$key] $Override[$key]
        } else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

function ConvertTo-Hashtable {
    param([Parameter(Mandatory)][object]$InputObject)
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = @{}
        $InputObject.PSObject.Properties | ForEach-Object {
            $hash[$_.Name] = ConvertTo-Hashtable $_.Value
        }
        return $hash
    }
    return $InputObject
}

function Set-NestedValue {
    param($Config, [string]$Path, $Value)

    $keys = $Path -split '\.'
    $current = $Config
    for ($i = 0; $i -lt $keys.Count - 1; $i++) {
        if (-not $current[$keys[$i]]) {
            $current[$keys[$i]] = @{}
        }
        $current = $current[$keys[$i]]
    }
    # 尝试类型转换
    $lastKey = $keys[-1]
    if ($Value -match '^\d+$') { $Value = [int]$Value }
    elseif ($Value -match '^(true|false)$') { $Value = $Value -eq 'true' }
    $current[$lastKey] = $Value
}

# 使用多层配置
$config = Get-ApplicationConfig -ConfigPath "C:\MyApp\config.json" -Environment "production"
Write-Host "`n最终配置：" -ForegroundColor Cyan
Write-Host "  应用：$($config.appName) v$($config.version)"
Write-Host "  数据库：$($config.database.server):$($config.database.port)/$($config.database.name)"
Write-Host "  日志级别：$($config.logging.level)"
```

执行结果示例：

```
已加载配置文件：C:\MyApp\config.json
最终配置：
  应用：MyApp v2.5.0
  数据库：prod-db01:5432/myapp_production
  日志级别：Warning
```

## 配置验证

```powershell
# 配置验证器
function Test-ConfigSchema {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [hashtable]$Schema
    )

    $errors = @()

    foreach ($key in $Schema.Keys) {
        $rule = $Schema[$key]

        # 检查必填项
        if ($rule.Required -and -not $Config.ContainsKey($key)) {
            $errors += "缺少必填配置：$key"
            continue
        }

        if (-not $Config.ContainsKey($key)) { continue }

        $value = $Config[$key]

        # 类型检查
        if ($rule.Type -and $value -isnot $rule.Type) {
            $errors += "$key 类型错误：期望 $($rule.Type.Name)，实际 $($value.GetType().Name)"
        }

        # 范围检查
        if ($rule.Min -and $value -lt $rule.Min) {
            $errors += "$key 值 $value 小于最小值 $($rule.Min)"
        }
        if ($rule.Max -and $value -gt $rule.Max) {
            $errors += "$key 值 $value 大于最大值 $($rule.Max)"
        }

        # 枚举检查
        if ($rule.ValidValues -and $value -notin $rule.ValidValues) {
            $errors += "$key 值 '$value' 不在允许列表中：$($rule.ValidValues -join ', ')"
        }

        # 正则检查
        if ($rule.Pattern -and $value -notmatch $rule.Pattern) {
            $errors += "$key 值 '$value' 不匹配模式：$($rule.Pattern)"
        }
    }

    if ($errors) {
        Write-Host "配置验证失败：" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Red }
        return $false
    }

    Write-Host "配置验证通过" -ForegroundColor Green
    return $true
}

# 定义配置模式
$schema = @{
    appName = @{ Required = $true; Type = [string] }
    version = @{ Required = $true; Pattern = '^\d+\.\d+\.\d+$' }
    database = @{
        Required = $true
    }
    logging = @{
        Required = $false
    }
}

$validConfig = @{
    appName = "MyApp"
    version = "2.5.0"
    database = @{ server = "localhost" }
}

Test-ConfigSchema -Config $validConfig -Schema $schema

$invalidConfig = @{
    appName = 123
    version = "invalid"
}

Test-ConfigSchema -Config $invalidConfig -Schema $schema
```

执行结果示例：

```
配置验证通过
配置验证失败：
  ! appName 类型错误：期望 String，实际 Int32
  ! version 值 'invalid' 不匹配模式：^\d+\.\d+\.\d+$
  ! 缺少必填配置：database
```

## 注意事项

1. **敏感配置**：密码、Token 等敏感配置不应存储在配置文件中，使用环境变量或密钥管理服务
2. **配置优先级**：明确文档化配置层的优先级，让用户知道哪个配置源优先生效
3. **默认值**：所有配置都应有合理的默认值，确保脚本在缺少配置文件时仍能运行
4. **配置热加载**：长时间运行的服务应支持配置热加载，无需重启
5. **PSD1 安全**：`Invoke-Expression` 加载 PSD1 存在安全风险，生产环境使用 `Import-PowerShellDataFile`
6. **环境隔离**：不同环境（开发、测试、生产）的配置应完全独立，避免误操作
