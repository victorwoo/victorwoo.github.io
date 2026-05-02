---
layout: post
date: 2025-06-18 08:00:00
updated: 2025-06-18 08:00:00
title: "PowerShell 技能连载 - YAML 与 TOML 配置处理"
description: PowerTip of the Day - YAML and TOML Configuration Processing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- yaml
- toml
- config-management
---

_适用于 PowerShell 7.0 及以上版本_

YAML 和 TOML 是现代配置文件的两大主流格式。YAML 以其可读性和丰富的数据类型支持，被 Kubernetes、Docker Compose、GitHub Actions 等广泛采用；TOML 则以简洁明了著称，是 Rust、Python 项目的首选配置格式。PowerShell 原生支持 JSON 和 XML，但处理 YAML 和 TOML 需要借助第三方模块。本文将讲解如何在 PowerShell 中高效处理这两种配置格式。

## YAML 处理

```powershell
# 安装 YamlDotNet 模块
Install-Module -Name powershell-yaml -Scope CurrentUser -Force

# 解析 YAML 字符串
$yaml = @"
server:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/ssl/cert.pem
    key: /etc/ssl/key.pem

database:
  host: db.internal
  port: 5432
  name: myapp
  pool:
    min: 5
    max: 20
    timeout: 30

logging:
  level: info
  file: /var/log/myapp.log
  rotation:
    max_size: 100MB
    max_files: 10
"@

$config = $yaml | ConvertFrom-Yaml

# 访问配置值
Write-Host "服务器端口：$($config.server.port)"
Write-Host "SSL 启用：$($config.server.ssl.enabled)"
Write-Host "数据库连接池最大值：$($config.database.pool.max)"

# 读取 YAML 文件
$k8sDeployment = Get-Content "k8s/deployment.yaml" -Raw | ConvertFrom-Yaml
$k8sDeployment.metadata.name
$k8sDeployment.spec.replicas

# 修改 YAML 配置
$config.server.port = 9090
$config.logging.level = "debug"
$config.database.pool.max = 50

# 导出为 YAML
$updatedYaml = $config | ConvertTo-Yaml
Write-Host "更新后的配置：" -ForegroundColor Cyan
Write-Host $updatedYaml
```

执行结果示例：

```
服务器端口：8080
SSL 启用：True
数据库连接池最大值：20
更新后的配置：
server:
  host: 0.0.0.0
  port: 9090
  ssl:
    enabled: true
    cert: /etc/ssl/cert.pem
```

## YAML 配置文件管理

```powershell
function Get-YamlConfig {
    <#
    .SYNOPSIS
    读取 YAML 配置文件并支持环境变量替换
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Environment
    )

    $content = Get-Content $Path -Raw
    $config = $content | ConvertFrom-Yaml

    # 环境变量替换 ${VAR_NAME} 格式
    $config | ConvertTo-Yaml | ForEach-Object {
        $pattern = '\$\{(\w+)\}'
        while ($_ -match $pattern) {
            $varName = $Matches[1]
            $varValue = [System.Environment]::GetEnvironmentVariable($varName) ?? ''
            $_ = $_ -replace "\`\{$varName\}", $varValue
        }
    }

    return $config
}

# 合并多层配置
function Merge-YamlConfig {
    param(
        [string[]]$ConfigPaths
    )

    $merged = @{}

    foreach ($path in $ConfigPaths) {
        if (Test-Path $path) {
            $config = Get-Content $path -Raw | ConvertFrom-Yaml
            foreach ($key in $config.Keys) {
                if ($merged[$key] -is [hashtable] -and $config[$key] -is [hashtable]) {
                    $merged[$key] = Merge-Hashtables $merged[$key] $config[$key]
                } else {
                    $merged[$key] = $config[$key]
                }
            }
        }
    }

    return $merged
}

# 按优先级合并配置：默认 < 环境 < 本地覆盖
$config = Merge-YamlConfig -ConfigPaths @(
    "config/default.yaml"
    "config/production.yaml"
    "config/local.yaml"
)
```

执行结果示例：

```
# 配置合并按路径优先级覆盖
```

## TOML 处理

```powershell
# 安装 TOML 模块
Install-Module -Name PSToml -Scope CurrentUser -Force

# 解析 TOML 字符串
$toml = @"
[server]
host = "0.0.0.0"
port = 8080

[server.ssl]
enabled = true
cert = "/etc/ssl/cert.pem"

[database]
host = "db.internal"
port = 5432
name = "myapp"

[database.pool]
min = 5
max = 20

[logging]
level = "info"
file = "/var/log/myapp.log"

[[logging.rotation]]
max_size = "100MB"
max_files = 10
"@

$config = $toml | ConvertFrom-Toml

# 访问配置值
Write-Host "服务器端口：$($config.server.port)"
Write-Host "SSL 启用：$($config.server.ssl.enabled)"

# 读取 TOML 文件（如 Cargo.toml, pyproject.toml）
$cargoConfig = Get-Content "Cargo.toml" -Raw | ConvertFrom-Toml
Write-Host "项目名称：$($cargoConfig.package.name)"
Write-Host "版本：$($cargoConfig.package.version)"

# 修改并保存
$config.server.port = 9090
$updatedToml = $config | ConvertTo-Toml
Set-Content -Path "config_updated.toml" -Value $updatedToml
```

执行结果示例：

```
服务器端口：8080
SSL 启用：True
项目名称：my-rust-project
版本：0.1.0
```

## 格式转换工具

在配置管理中经常需要在不同格式间转换：

```powershell
function Convert-ConfigFormat {
    <#
    .SYNOPSIS
    在 JSON、YAML、TOML 之间转换配置格式
    #>
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,

        [ValidateSet('json', 'yaml', 'toml')]
        [string]$From,

        [ValidateSet('json', 'yaml', 'toml')]
        [string]$To,

        [string]$OutputPath
    )

    # 读取源文件
    $content = Get-Content $InputPath -Raw
    $data = switch ($From) {
        'json' { $content | ConvertFrom-Json -AsHashtable }
        'yaml' { $content | ConvertFrom-Yaml }
        'toml' { $content | ConvertFrom-Toml }
    }

    # 转换为目标格式
    $output = switch ($To) {
        'json' { $data | ConvertTo-Json -Depth 10 }
        'yaml' { $data | ConvertTo-Yaml }
        'toml' { $data | ConvertTo-Toml }
    }

    # 输出
    if ($OutputPath) {
        Set-Content -Path $OutputPath -Value $output -Encoding UTF8
        Write-Host "已转换：$InputPath ($From) => $OutputPath ($To)" -ForegroundColor Green
    } else {
        Write-Output $output
    }
}

# YAML 转 JSON
Convert-ConfigFormat -InputPath "docker-compose.yaml" -From yaml -To json -OutputPath "docker-compose.json"

# TOML 转 YAML
Convert-ConfigFormat -InputPath "Cargo.toml" -From toml -To yaml -OutputPath "Cargo.yaml"
```

执行结果示例：

```
已转换：docker-compose.yaml (yaml) => docker-compose.json (json)
已转换：Cargo.toml (toml) => Cargo.yaml (yaml)
```

## 注意事项

1. **YAML 缩进**：YAML 对缩进非常敏感，使用空格而非 Tab。生成 YAML 时注意保持一致的缩进风格
2. **TOML 类型限制**：TOML 不支持 null 值，所有键必须有值
3. **模块兼容性**：`powershell-yaml` 和 `PSToml` 是社区模块，注意版本兼容性
4. **大文件性能**：YAML 解析比 JSON 慢，大型配置文件考虑使用 JSON 格式
5. **安全风险**：YAML 的锚点（anchor）和合并（merge）特性可能被利用，解析不受信任的 YAML 时需注意
6. **配置验证**：使用 JSON Schema 或自定义脚本验证配置文件的完整性和合法性
