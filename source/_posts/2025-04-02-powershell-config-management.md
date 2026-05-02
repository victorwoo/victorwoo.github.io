---
layout: post
date: 2025-04-02 08:00:00
updated: 2025-04-02 08:00:00
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
- data-format
- config-management
- devops
---
_适用于 PowerShell 7.0 及以上版本_

在 DevOps 和基础设施即代码的实践中，配置文件管理是核心能力。无论是应用部署、容器编排还是 CI/CD 流水线，JSON 和 YAML 格式的配置文件无处不在。PowerShell 原生支持 JSON 的读写与转换，配合 `powershell-yaml` 模块也能轻松处理 YAML，包括 Kubernetes 风格的多文档格式。

本文将从实际场景出发，逐步介绍如何用 PowerShell 完成 JSON 配置读取与修改、YAML 解析、Schema 验证、模板渲染以及环境配置切换。

<!-- more -->

## 读取 JSON 配置

日常运维中，我们经常需要从 JSON 文件中提取特定的配置项。PowerShell 的 `ConvertFrom-Json` 可以将 JSON 文本转换为对象，然后用属性访问语法直接取值。下面封装了一个通用函数，支持按层级路径读取指定区段。

```powershell
# 读取 JSON 配置文件，支持按层级路径提取指定区段
function Get-JsonConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Sections
    )

    # 读取原始内容并转换为 PowerShell 对象
    $json = Get-Content $Path -Raw | ConvertFrom-Json

    # 如果指定了区段路径，逐层深入取值
    if ($Sections) {
        $result = $json
        foreach ($section in $Sections) {
            $result = $result.$section
        }
        return $result
    }

    return $json
}
```

假设我们有一个应用配置文件 `appsettings.json`，内容如下：

```json
{
  "server": {
    "host": "0.0.0.0",
    "port": 8080
  },
  "database": {
    "host": "db.internal",
    "port": 5432,
    "name": "app_prod"
  },
  "logging": {
    "level": "INFO",
    "path": "/var/log/app.log"
  }
}
```

读取整个配置或某个区段：

```powershell
# 读取完整配置
$config = Get-JsonConfig -Path ".\appsettings.json"
$config.database.host

# 只读取数据库区段
$dbConfig = Get-JsonConfig -Path ".\appsettings.json" -Sections "database"
$dbConfig
```

执行结果示例：

```
db.internal

host   port  name
----   ----  ----
db.internal  5432  app_prod
```

## 修改 JSON 配置

读取只是第一步，更多时候我们需要修改配置项并写回文件。下面的函数支持用点号分隔的路径（如 `database.host`）来定位嵌套属性，并可选地在修改前备份原文件。

```powershell
# 修改 JSON 配置，支持点号路径定位嵌套属性
function Set-JsonConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Properties,

        [switch]$Backup
    )

    # 可选：修改前备份原文件
    if ($Backup) {
        Copy-Item $Path "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    $json = Get-Content $Path -Raw | ConvertFrom-Json

    # 遍历每个要修改的属性
    foreach ($key in $Properties.Keys) {
        $parts = $key -split '\.'
        $obj = $json
        # 逐层导航到父对象
        for ($i = 0; $i -lt $parts.Count - 1; $i++) {
            $obj = $obj.$($parts[$i])
        }
        # 设置最终属性值
        $obj.$($parts[-1]) = $Properties[$key]
    }

    # 写回文件，深度设为 10 层以覆盖大多数嵌套结构
    $json | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}
```

将数据库主机和日志级别修改为新值：

```powershell
Set-JsonConfig -Path ".\appsettings.json" -Backup -Properties @{
    "database.host" = "db-new.internal"
    "logging.level" = "DEBUG"
}
```

执行结果示例：

```
# 原文件已备份为 appsettings.json.bak.20250402100000
# appsettings.json 中的值已更新
Get-Content .\appsettings.json | ConvertFrom-Json | Select-Object -ExpandProperty database

host          port  name
----          ----  ----
db-new.internal  5432  app_prod
```

## 读取 YAML 配置

YAML 在 Kubernetes、CI/CD 等场景中广泛使用。PowerShell 本身不支持 YAML，但 `powershell-yaml` 模块弥补了这个缺口。下面的函数封装了 YAML 读取逻辑，并在模块缺失时给出友好提示。

```powershell
# 读取 YAML 配置文件（需先安装 powershell-yaml 模块）
function Get-YamlConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # 检查模块是否已安装
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Warning "需要安装 powershell-yaml 模块: Install-Module powershell-yaml -Scope CurrentUser"
        return $null
    }

    Import-Module powershell-yaml
    $content = Get-Content $Path -Raw
    return $content | ConvertFrom-Yaml
}
```

使用方式很简单：

```powershell
# 首次使用前安装模块（只需执行一次）
# Install-Module -Name powershell-yaml -Scope CurrentUser

# 读取 YAML 配置
$config = Get-YamlConfig -Path ".\config.yaml"
$config.server.host
```

执行结果示例：

```
0.0.0.0
```

## 解析 Kubernetes 多文档 YAML

Kubernetes 的资源清单文件通常包含多个文档，用 `---` 分隔。标准的 YAML 解析器只处理第一个文档，因此需要先分割再逐一解析。下面的函数会将每个文档提取出 `kind`、`name`、`namespace` 等关键信息。

```powershell
# 读取 Kubernetes 风格的多文档 YAML，提取每个资源的元数据
function Get-YamlMultiDocument {
    param([Parameter(Mandatory)][string]$Path)

    Import-Module powershell-yaml
    $content = Get-Content $Path -Raw

    # 按 --- 分割多文档，过滤空行
    $documents = $content -split '(?m)^---\s*$' | Where-Object { $_.Trim() }

    foreach ($doc in $documents) {
        $yaml = $doc | ConvertFrom-Yaml
        [PSCustomObject]@{
            Kind      = $yaml.kind
            Name      = $yaml.metadata.name
            Namespace = $yaml.metadata.namespace
            Content   = $yaml
        }
    }
}
```

假设有一个 `deploy.yaml` 包含 Namespace 和 Deployment 两个资源：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: my-app
spec:
  replicas: 3
```

解析结果如下：

```powershell
Get-YamlMultiDocument -Path ".\deploy.yaml" | Format-Table Kind, Name, Namespace
```

执行结果示例：

```
Kind       Name        Namespace
----       ----        ---------
Namespace  my-app
Deployment web-server  my-app
```

## Schema 验证

配置项的错误往往在运行时才暴露，提前做 Schema 验证可以有效减少故障。下面的函数支持必填检查、类型校验、长度限制、枚举值和正则匹配等规则。

```powershell
# 对配置对象执行 Schema 验证
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

        # 必填检查
        if ($constraints.Required -and -not $value) {
            $errors += "缺少必填字段: $key"
            continue
        }

        if ($null -ne $value) {
            # 类型检查
            if ($constraints.Type -and $value.GetType().Name -ne $constraints.Type) {
                $errors += "$key 类型错误: 期望 $($constraints.Type), 实际 $($value.GetType().Name)"
            }
            # 最小长度检查
            if ($constraints.MinLength -and $value.Length -lt $constraints.MinLength) {
                $errors += "$key 长度不足: 最小 $($constraints.MinLength)"
            }
            # 枚举值检查
            if ($constraints.AllowedValues -and $value -notin $constraints.AllowedValues) {
                $errors += "$key 值非法: $value, 允许值: $($constraints.AllowedValues -join ', ')"
            }
            # 正则匹配检查
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
```

定义验证规则并执行检查：

```powershell
# 定义 Schema 规则
$schema = @{
    serverName  = @{ Required = $true; Type = "String"; MinLength = 3 }
    port        = @{ Required = $true; Type = "Int32" }
    environment = @{ Required = $true; AllowedValues = @("dev", "staging", "prod") }
    database    = @{ Required = $true; Pattern = "^[a-z][a-z0-9_]+$" }
}

# 构造配置对象（这里故意写错 environment 值）
$config = [PSCustomObject]@{
    serverName  = "prod-sql-01"
    port        = 1433
    environment = "production"
    database    = "app_db"
}

Test-ConfigSchema -Config $config -Schema $schema
```

执行结果示例：

```
配置验证失败:
  - environment 值非法: production, 允许值: dev, staging, prod
False
```

## 模板渲染

在管理 Nginx、HAProxy 等配置时，硬编码不利于多环境复用。模板渲染可以将占位符替换为实际值，还支持条件块来控制内容是否输出。

```powershell
# 渲染配置模板，支持变量替换和条件块
function Resolve-ConfigTemplate {
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath,

        [Parameter(Mandatory)]
        [hashtable]$Variables,

        [string]$OutputPath
    )

    $template = Get-Content $TemplatePath -Raw

    # 替换 {{变量名}} 占位符
    foreach ($var in $Variables.GetEnumerator()) {
        $template = $template -replace "\{\{$($var.Key)\}\}", $var.Value
    }

    # 处理条件块 {{#if VAR}}...{{/if}}
    $template = [regex]::Replace(
        $template,
        '\{\{#if\s+(\w+)\}\}(.*?)\{\{/if\}\}',
        {
            param($m)
            if ($Variables[$m.Groups[1].Value]) { $m.Groups[2].Value } else { "" }
        },
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    # 输出到文件或返回渲染结果
    if ($OutputPath) {
        $template | Set-Content $OutputPath -Encoding UTF8
        Write-Host "配置已渲染: $OutputPath"
    }

    return $template
}
```

准备一个 Nginx 配置模板：

```powershell
# 创建 Nginx 配置模板
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

# 渲染模板：启用 SSL 的生产环境
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

执行结果示例：

```
配置已渲染: .\nginx.conf

# 生成的 nginx.conf 内容：
server {
    listen 8080;
    server_name app.example.com;
    listen 443 ssl;
    ssl_certificate /etc/ssl/cert.pem;
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

## 环境配置切换

在不同环境（开发、预发布、生产）之间切换时，需要加载对应的配置并注入到环境变量中。下面的函数根据环境名称查找对应配置文件，将所有配置项导出为以 `APP_` 为前缀的环境变量。

```powershell
# 切换应用环境，加载对应配置并导出为环境变量
function Switch-AppEnvironment {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("dev", "staging", "prod")]
        [string]$Environment,

        [string]$ConfigDir = ".\config"
    )

    # 查找对应环境的配置文件
    $configFile = Join-Path $ConfigDir "$Environment.json"

    if (-not (Test-Path $configFile)) {
        throw "配置文件不存在: $configFile"
    }

    $config = Get-JsonConfig -Path $configFile

    # 将每个配置项导出为环境变量
    foreach ($prop in $config.PSObject.Properties) {
        [Environment]::SetEnvironmentVariable(
            "APP_$($prop.Name.ToUpper())", $prop.Value, "Process"
        )
    }

    # 写入当前环境标记
    [Environment]::SetEnvironmentVariable("APP_ENV", $Environment, "Process")

    Write-Host "已切换到 $Environment 环境" -ForegroundColor Green
    return $config
}
```

在开发环境与生产环境之间切换：

```powershell
# 切换到开发环境
Switch-AppEnvironment -Environment dev -ConfigDir ".\config"

# 查看加载的环境变量
$env:APP_ENV
$env:APP_SERVER_HOST
```

执行结果示例：

```
已切换到 dev 环境

dev
127.0.0.1
```

管理配置文件时，建议将敏感信息（密码、密钥）从配置文件中分离，使用环境变量或密钥管理服务替代。模板渲染前务必做 Schema 验证，避免无效配置上线。通过本文介绍的工具函数，你可以构建一套完整的配置管理流程：读取配置、Schema 校验、模板渲染、环境切换，覆盖从开发到生产的全链路。
