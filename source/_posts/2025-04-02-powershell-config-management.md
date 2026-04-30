---
layout: post
date: 2025-04-02 08:00:00
title: "PowerShell 技能连载 - JSON 与 YAML 配置管理"
description: PowerTip of the Day - JSON and YAML Configuration Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- devops
---
在 DevOps 和基础设施即代码的实践中，配置文件管理是核心能力。PowerShell 原生支持 JSON，配合第三方模块也能处理 YAML。本文介绍配置文件的读取、转换、验证和模板化。

## JSON 配置操作

```powershell
function Get-JsonConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Sections
    )

    $json = Get-Content $Path -Raw | ConvertFrom-Json

    if ($Sections) {
        $result = $json
        foreach ($section in $Sections) {
            $result = $result.$section
        }
        return $result
    }

    return $json
}

function Set-JsonConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Properties,

        [switch]$Backup
    )

    if ($Backup) {
        Copy-Item $Path "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    $json = Get-Content $Path -Raw | ConvertFrom-Json

    foreach ($key in $Properties.Keys) {
        $parts = $key -split '\.'
        $obj = $json
        for ($i = 0; $i -lt $parts.Count - 1; $i++) {
            $obj = $obj.$($parts[$i])
        }
        $obj.$($parts[-1]) = $Properties[$key]
    }

    $json | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}
```

## YAML 支持

```powershell
# 安装 YAML 模块
# Install-Module -Name powershell-yaml -Scope CurrentUser

function Get-YamlConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Warning "需要安装 powershell-yaml 模块: Install-Module powershell-yaml"
        return $null
    }

    Import-Module powershell-yaml
    $content = Get-Content $Path -Raw
    return $content | ConvertFrom-Yaml
}

# 读取 Kubernetes 风格的 YAML（多文档）
function Get-YamlMultiDocument {
    param([Parameter(Mandatory)][string]$Path)

    Import-Module powershell-yaml
    $content = Get-Content $Path -Raw

    # 按 --- 分割多文档
    $documents = $content -split '(?m)^---\s*$' | Where-Object { $_.Trim() }

    foreach ($doc in $documents) {
        $yaml = $doc | ConvertFrom-Yaml
        [PSCustomObject]@{
            Kind     = $yaml.kind
            Name     = $yaml.metadata.name
            Namespace = $yaml.metadata.namespace
            Content  = $yaml
        }
    }
}
```

## 配置验证

```powershell
function Test-ConfigSchema {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory)]
        [hashtable]$Schema
    )

    $errors = @()

    foreach ($rule in $Schema.GetEnumerator()) {
        $key = $rule.Key
        $constraints = $rule.Value
        $value = $Config.$key

        if ($constraints.Required -and -not $value) {
            $errors += "缺少必填字段: $key"
            continue
        }

        if ($null -ne $value) {
            if ($constraints.Type -and $value.GetType().Name -ne $constraints.Type) {
                $errors += "$key 类型错误: 期望 $($constraints.Type), 实际 $($value.GetType().Name)"
            }

            if ($constraints.MinLength -and $value.Length -lt $constraints.MinLength) {
                $errors += "$key 长度不足: 最小 $($constraints.MinLength)"
            }

            if ($constraints.AllowedValues -and $value -notin $constraints.AllowedValues) {
                $errors += "$key 值非法: $value, 允许值: $($constraints.AllowedValues -join ', ')"
            }

            if ($constraints.Pattern -and $value -notmatch $constraints.Pattern) {
                $errors += "$key 格式不匹配: $($constraints.Pattern)"
            }
        }
    }

    if ($errors) {
        Write-Host "配置验证失败:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        return $false
    }

    Write-Host "配置验证通过" -ForegroundColor Green
    return $true
}

# 使用示例
$schema = @{
    serverName   = @{ Required = $true; Type = "String"; MinLength = 3 }
    port         = @{ Required = $true; Type = "Int32" }
    environment  = @{ Required = $true; AllowedValues = @("dev", "staging", "prod") }
    database     = @{ Required = $true; Type = "String"; Pattern = "^[a-z][a-z0-9_]+$" }
    maxRetries   = @{ Type = "Int32" }
}

$config = [PSCustomObject]@{
    serverName  = "prod-sql-01"
    port        = 1433
    environment = "prod"
    database    = "app_db"
    maxRetries  = 3
}

Test-ConfigSchema -Config $config -Schema $schema
```

## 配置模板渲染

```powershell
function Resolve-ConfigTemplate {
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath,

        [Parameter(Mandatory)]
        [hashtable]$Variables,

        [string]$OutputPath
    )

    $template = Get-Content $TemplatePath -Raw

    foreach ($var in $Variables.GetEnumerator()) {
        $template = $template -replace "\{\{$($var.Key)\}\}", $var.Value
    }

    # 处理条件块 {{#if VAR}}...{{/if}}
    $template = [regex]::Replace($template, '\{\{#if\s+(\w+)\}\}(.*?)\{\{/if\}\}', {
        param($m)
        if ($Variables[$m.Groups[1].Value]) { $m.Groups[2].Value } else { "" }
    }, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($OutputPath) {
        $template | Set-Content $OutputPath -Encoding UTF8
        Write-Host "配置已渲染: $OutputPath"
    }

    return $template
}

# 示例：渲染 Nginx 配置
$template = @"
server {
    listen {{PORT}};
    server_name {{HOST}};
    {{#if SSL}}listen 443 ssl;
    ssl_certificate {{SSL_CERT}};{{/if}}
    location / {
        proxy_pass http://{{BACKEND}};
    }
}
"@

$template | Set-Content "$env:TEMP\nginx.tpl"
Resolve-ConfigTemplate -TemplatePath "$env:TEMP\nginx.tpl" `
    -Variables @{
        PORT     = "8080"
        HOST     = "app.example.com"
        SSL      = $true
        SSL_CERT = "/etc/ssl/cert.pem"
        BACKEND  = "127.0.0.1:3000"
    } `
    -OutputPath ".\nginx.conf"
```

## 环境配置切换

```powershell
function Switch-AppEnvironment {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("dev", "staging", "prod")]
        [string]$Environment,

        [string]$ConfigDir = ".\config"
    )

    $configFile = Join-Path $ConfigDir "$Environment.json"

    if (-not (Test-Path $configFile)) {
        throw "配置文件不存在: $configFile"
    }

    $config = Get-JsonConfig -Path $configFile

    # 导出为环境变量
    foreach ($prop in $config.PSObject.Properties) {
        [Environment]::SetEnvironmentVariable("APP_$($prop.Name.ToUpper())", $prop.Value, "Process")
    }

    # 写入当前环境标记
    [Environment]::SetEnvironmentVariable("APP_ENV", $Environment, "Process")

    Write-Host "已切换到 $Environment 环境" -ForegroundColor Green
    return $config
}
```

管理配置文件时，建议将敏感信息（密码、密钥）从配置文件中分离，使用环境变量或密钥管理服务替代。模板渲染前务必做 Schema 验证，避免无效配置上线。
