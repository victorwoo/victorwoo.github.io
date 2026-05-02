---
layout: post
date: 2025-08-15 08:00:00
updated: 2025-08-15 08:00:00
title: "PowerShell 技能连载 - JSON Schema 验证"
description: PowerTip of the Day - JSON Schema Validation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- data-format
- testing
---

_适用于 PowerShell 7.0 及以上版本_

JSON 已经成为配置文件和 API 数据交换的事实标准，但 JSON 本身不包含类型和结构约束——一个字段应该是字符串还是数字、一个数组至少有几项、哪些字段是必填的，这些都需要额外的验证。JSON Schema 是一套标准的 JSON 结构描述语言，可以精确验证 JSON 数据的格式和内容。结合 PowerShell 的 JSON 处理能力，可以构建可靠的配置验证系统。

本文将讲解如何在 PowerShell 中实现 JSON Schema 验证和实用的数据校验工具。

<!-- more -->

## 手动验证

```powershell
# 不使用外部库的基础验证
function Test-JsonStructure {
    param(
        [Parameter(Mandatory)]
        $Data,

        [Parameter(Mandatory)]
        [hashtable]$Schema
    )

    $errors = @()

    # 检查必填字段
    if ($Schema.required) {
        foreach ($field in $Schema.required) {
            if (-not ($Data.PSObject.Properties.Name -contains $field)) {
                $errors += "缺少必填字段：$field"
            }
        }
    }

    # 检查字段类型
    if ($Schema.properties) {
        foreach ($prop in $Schema.properties.GetEnumerator()) {
            $name = $prop.Key
            $rules = $prop.Value

            if (-not ($Data.PSObject.Properties.Name -contains $name)) { continue }

            $value = $Data.$name

            # 类型检查
            if ($rules.type) {
                $typeOk = switch ($rules.type) {
                    "string"  { $value -is [string] }
                    "integer" { $value -is [int] -or $value -is [long] }
                    "number"  { $value -is [double] -or $value -is [int] }
                    "boolean" { $value -is [bool] }
                    "array"   { $value -is [array] }
                    "object"  { $value -is [System.Management.Automation.PSCustomObject] }
                }
                if (-not $typeOk) {
                    $errors += "$name 类型错误：期望 $($rules.type)，实际 $($value.GetType().Name)"
                }
            }

            # 字符串长度
            if ($rules.minLength -and $value.Length -lt $rules.minLength) {
                $errors += "$name 长度不足：最少 $($rules.minLength) 字符"
            }

            # 数字范围
            if ($rules.minimum -and $value -lt $rules.minimum) {
                $errors += "$name 值 $value 小于最小值 $($rules.minimum)"
            }
            if ($rules.maximum -and $value -gt $rules.maximum) {
                $errors += "$name 值 $value 大于最大值 $($rules.maximum)"
            }

            # 枚举值
            if ($rules.enum -and $value -notin $rules.enum) {
                $errors += "$name 值 '$value' 不在允许列表中"
            }

            # 正则匹配
            if ($rules.pattern -and $value -notmatch $rules.pattern) {
                $errors += "$name 值 '$value' 不匹配模式"
            }
        }
    }

    if ($errors) {
        Write-Host "验证失败（$($errors.Count) 个问题）：" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        return $false
    }

    Write-Host "验证通过" -ForegroundColor Green
    return $true
}

# 定义 Schema 并验证
$json = '{"name":"MyApp","version":"2.5.0","port":8080,"debug":false}'
$data = $json | ConvertFrom-Json

$schema = @{
    required = @("name", "version", "port")
    properties = @{
        name    = @{ type = "string"; minLength = 1 }
        version = @{ type = "string"; pattern = "^\d+\.\d+\.\d+$" }
        port    = @{ type = "integer"; minimum = 1; maximum = 65535 }
        debug   = @{ type = "boolean" }
    }
}

Test-JsonStructure -Data $data -Schema $schema
```

执行结果示例：

```
验证通过
```

## 嵌套结构验证

```powershell
# 支持嵌套 JSON 的验证
function Test-JsonDeep {
    param(
        [Parameter(Mandatory)]
        [object]$Data,

        [Parameter(Mandatory)]
        [hashtable]$Schema,

        [string]$Path = ""
    )

    $errors = @()

    if ($Schema.required) {
        foreach ($field in $Schema.required) {
            if (-not ($Data.PSObject.Properties.Name -contains $field)) {
                $errors += "${Path}.$field : 缺少必填字段"
            }
        }
    }

    if ($Schema.properties) {
        foreach ($prop in $Schema.properties.GetEnumerator()) {
            $name = $prop.Key
            $rules = $prop.Value
            $fullPath = if ($Path) { "$Path.$name" } else { $name }

            if (-not ($Data.PSObject.Properties.Name -contains $name)) { continue }
            $value = $Data.$name

            # 嵌套对象递归验证
            if ($rules.type -eq "object" -and $rules.properties -and $value -is [PSCustomObject]) {
                $nestedErrors = Test-JsonDeep -Data $value -Schema $rules -Path $fullPath
                $errors += $nestedErrors
                continue
            }

            # 数组元素验证
            if ($rules.type -eq "array" -and $value -is [array]) {
                if ($rules.minItems -and $value.Count -lt $rules.minItems) {
                    $errors += "$fullPath : 数组元素不足 $($rules.minItems) 个"
                }
                if ($rules.items -and $rules.items.type -eq "object") {
                    foreach ($item in $value) {
                        if ($item -is [PSCustomObject]) {
                            $nestedErrors = Test-JsonDeep -Data $item -Schema $rules.items -Path "$fullPath[]"
                            $errors += $nestedErrors
                        }
                    }
                }
            }

            # 基本类型验证
            if ($rules.type -eq "string" -and $rules.pattern -and $value -is [string]) {
                if ($value -notmatch $rules.pattern) {
                    $errors += "$fullPath : 值 '$value' 不匹配模式 $($rules.pattern)"
                }
            }

            if ($rules.type -eq "integer" -and $rules.minimum) {
                if ([int]$value -lt $rules.minimum) {
                    $errors += "$fullPath : 值 $value 小于最小值 $($rules.minimum)"
                }
            }
        }
    }

    return $errors
}

# 验证嵌套配置
$configJson = @"
{
    "app": {
        "name": "MyApp",
        "version": "2.5.0"
    },
    "database": {
        "host": "prod-db01",
        "port": 5432,
        "name": "myapp"
    },
    "servers": [
        { "name": "SRV01", "role": "web" },
        { "name": "SRV02", "role": "db" }
    ]
}
"@

$config = $configJson | ConvertFrom-Json

$configSchema = @{
    required = @("app", "database", "servers")
    properties = @{
        app = @{
            type = "object"
            required = @("name", "version")
            properties = @{
                name    = @{ type = "string" }
                version = @{ type = "string"; pattern = "^\d+\.\d+\.\d+$" }
            }
        }
        database = @{
            type = "object"
            required = @("host", "port")
            properties = @{
                host = @{ type = "string" }
                port = @{ type = "integer"; minimum = 1; maximum = 65535 }
            }
        }
        servers = @{
            type = "array"
            minItems = 1
            items = @{
                type = "object"
                required = @("name", "role")
                properties = @{
                    name = @{ type = "string" }
                    role = @{ type = "string" }
                }
            }
        }
    }
}

$errors = Test-JsonDeep -Data $config -Schema $configSchema
if ($errors) {
    Write-Host "验证错误：" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "配置验证通过" -ForegroundColor Green
}
```

执行结果示例：

```
配置验证通过
```

## 配置文件验证工具

```powershell
# 配置文件自动验证
function Protect-ConfigFile {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$SchemaPath,

        [switch]$FailFast
    )

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $schemaDef = Get-Content $SchemaPath -Raw | ConvertFrom-Json

    # 将 PSCustomObject Schema 转为哈希表
    function ConvertTo-SchemaHashtable {
        param($obj)
        $hash = @{}
        $obj.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [System.Management.Automation.PSCustomObject]) {
                $hash[$_.Name] = ConvertTo-SchemaHashtable $_.Value
            } elseif ($_.Value -is [array]) {
                $hash[$_.Name] = foreach ($item in $_.Value) {
                    if ($item -is [System.Management.Automation.PSCustomObject]) {
                        ConvertTo-SchemaHashtable $item
                    } else { $item }
                }
            } else {
                $hash[$_.Name] = $_.Value
            }
        }
        return $hash
    }

    $schemaHash = ConvertTo-SchemaHashtable $schemaDef
    $errors = Test-JsonDeep -Data $config -Schema $schemaHash

    if ($errors) {
        Write-Host "配置文件验证失败：$ConfigPath" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        if ($FailFast) { throw "配置验证失败" }
        return $false
    }

    Write-Host "配置文件验证通过：$ConfigPath" -ForegroundColor Green
    return $true
}

# 批量验证配置文件
$configDir = "C:\MyApp\Config"
$schemaFile = "C:\MyApp\Schemas\app-schema.json"

Get-ChildItem $configDir -Filter "*.json" | ForEach-Object {
    Protect-ConfigFile -ConfigPath $_.FullName -SchemaPath $schemaFile
}
```

执行结果示例：

```
配置文件验证通过：C:\MyApp\Config\app-dev.json
配置文件验证通过：C:\MyApp\Config\app-staging.json
配置文件验证通过：C:\MyApp\Config\app-prod.json
```

## 注意事项

1. **NuGet 包**：生产环境可以使用 `Newtonsoft.Json.Schema` 包获得完整的 JSON Schema Draft-07 支持
2. **Schema 版本**：JSON Schema 有多个版本（Draft-04、Draft-06、Draft-07、2020-12），注意兼容性
3. **错误信息**：手动验证的错误信息尽量包含字段路径和期望值，方便定位问题
4. **CI/CD 集成**：配置文件验证应在部署流水线的早期阶段执行，阻止无效配置上线
5. **Schema 即文档**：维护良好的 JSON Schema 可以同时作为配置文档使用
6. **性能**：大型 JSON 的深度验证可能较慢，关键路径上考虑只验证必要字段
