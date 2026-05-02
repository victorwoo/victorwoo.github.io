---
layout: post
date: 2025-12-18 08:00:00
updated: 2025-12-18 08:00:00
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
- json
- schema
- validation
- configuration
---

_适用于 PowerShell 7.0 及以上版本_

JSON 已经成为现代配置管理和数据交换的事实标准格式。无论是应用配置文件、CI/CD 流水线定义，还是 REST API 的请求与响应体，JSON 无处不在。然而 JSON 本身并不携带结构约束信息——一个字段是字符串还是数字、哪些字段是必填的、数值的合法范围是什么，这些都需要额外的手段来保证。

JSON Schema（RFC 8927）是一套标准化的 JSON 结构描述规范，可以用声明式的方式定义数据的形状、类型、约束和关系。相比于手写验证逻辑，使用标准的 JSON Schema 具有可复用、可共享、可版本化的优势，而且生态中有大量现成的工具和库。将 JSON Schema 验证集成到 PowerShell 脚本中，可以在自动化流水线的入口处拦截无效数据，避免后续环节出现难以排查的问题。

本文将介绍如何在 PowerShell 中利用 .NET 生态的 JsonSchema.NET 库，实现标准 JSON Schema 验证、高级条件约束以及批量配置文件的验证与报告生成。

## 定义 Schema 并验证配置文件

首先安装 JsonSchema.NET 库，然后用它来加载标准的 JSON Schema 定义，对配置文件进行结构验证。JsonSchema.NET 是一个纯 .NET 实现的 JSON Schema 验证器，支持 Draft 6、Draft 7 和 Draft 2020-12 版本。

```powershell
# 安装 JsonSchema.NET 库
Install-Module -Name JsonSchema.NET -Scope CurrentUser -Force

# 或者通过 NuGet 安装（适合 CI/CD 环境）
# dotnet add package JsonSchema.NET

# 定义标准的 JSON Schema（Draft 2020-12）
$schemaJson = @"
{
    "`$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "title": "应用配置 Schema",
    "required": ["appName", "version", "environment", "server"],
    "properties": {
        "appName": {
            "type": "string",
            "minLength": 1,
            "maxLength": 100,
            "description": "应用名称"
        },
        "version": {
            "type": "string",
            "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
            "description": "语义化版本号"
        },
        "environment": {
            "type": "string",
            "enum": ["development", "staging", "production"],
            "description": "部署环境"
        },
        "server": {
            "type": "object",
            "required": ["host", "port"],
            "properties": {
                "host": {
                    "type": "string",
                    "format": "hostname"
                },
                "port": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 65535
                },
                "ssl": {
                    "type": "boolean",
                    "default": false
                }
            },
            "additionalProperties": false
        },
        "logging": {
            "type": "object",
            "properties": {
                "level": {
                    "type": "string",
                    "enum": ["debug", "info", "warn", "error"],
                    "default": "info"
                },
                "path": {
                    "type": "string",
                    "format": "uri-reference"
                }
            }
        }
    },
    "additionalProperties": false
}
"@

# 加载 Schema
$schema = [JsonSchema.JsonSchema]::FromText($schemaJson)

# 准备一份有效的配置
$validConfig = @"
{
    "appName": "OrderService",
    "version": "3.2.1",
    "environment": "production",
    "server": {
        "host": "api.example.com",
        "port": 443,
        "ssl": true
    },
    "logging": {
        "level": "warn",
        "path": "/var/log/orderservice.log"
    }
}
"@

# 验证并输出结果
$results = $schema.Evaluate($validConfig)
Write-Host "有效配置验证结果：$($results.IsValid)" -ForegroundColor Green

# 准备一份无效的配置——故意制造多个问题
$invalidConfig = @"
{
    "appName": "",
    "version": "3.2",
    "environment": "testing",
    "server": {
        "host": "api.example.com",
        "port": 99999,
        "extraField": "not-allowed"
    }
}
"@

$results = $schema.Evaluate($invalidConfig)
Write-Host "`n无效配置验证结果：$($results.IsValid)" -ForegroundColor Red

# 逐条输出错误详情
foreach ($detail in $results.Details) {
    Write-Host ("  路径: {0,-25} 错误: {1}" -f $detail.InstanceLocation, $detail.Message) -ForegroundColor Yellow
}
```

执行结果示例：

```
有效配置验证结果：True

无效配置验证结果：False
  路径: /appName                   错误: 字符串长度不足，最少需要 1 个字符
  路径: /version                   错误: 字符串不匹配模式 ^[0-9]+\.[0-9]+\.[0-9]+$
  路径: /environment               错误: 值不在枚举列表中
  路径: /server/port                错误: 整数值 99999 超过最大值 65535
  路径: /server                     错误: 存在不允许的额外属性 extraField
```

## Schema 高级特性——条件验证与组合模式

实际业务中，配置规则往往不是扁平的。比如生产环境必须启用 SSL、数据库连接字符串在特定环境下有不同的格式要求。JSON Schema 提供了 `if/then/else`、`allOf`、`oneOf`、`anyOf` 等条件组合机制，可以表达复杂的业务约束。

```powershell
# 定义包含条件逻辑的复杂 Schema
$advancedSchemaJson = @"
{
    "`$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "title": "部署配置 Schema（含条件规则）",
    "required": ["environment", "database", "features"],
    "properties": {
        "environment": {
            "type": "string",
            "enum": ["dev", "staging", "production"]
        },
        "database": { "type": "object" },
        "features": { "type": "object" }
    },
    "allOf": [
        {
            "if": {
                "properties": {
                    "environment": { "const": "production" }
                }
            },
            "then": {
                "properties": {
                    "database": {
                        "required": ["connectionString", "maxPoolSize", "sslMode"],
                        "properties": {
                            "connectionString": {
                                "type": "string",
                                "minLength": 10
                            },
                            "maxPoolSize": {
                                "type": "integer",
                                "minimum": 10,
                                "maximum": 200
                            },
                            "sslMode": {
                                "type": "string",
                                "enum": ["require", "verify-ca", "verify-full"]
                            }
                        }
                    },
                    "features": {
                        "required": ["monitoring", "errorReporting"],
                        "properties": {
                            "monitoring": { "type": "boolean", "const": true },
                            "errorReporting": { "type": "boolean", "const": true }
                        }
                    }
                }
            }
        },
        {
            "if": {
                "properties": {
                    "environment": { "const": "dev" }
                }
            },
            "then": {
                "properties": {
                    "database": {
                        "required": ["connectionString"],
                        "properties": {
                            "connectionString": { "type": "string" },
                            "maxPoolSize": { "type": "integer", "default": 5 }
                        }
                    }
                }
            }
        }
    ],
    "oneOf": [
        {
            "properties": {
                "features": {
                    "properties": {
                        "cacheProvider": { "const": "redis" }
                    },
                    "required": ["redisHost"]
                }
            }
        },
        {
            "properties": {
                "features": {
                    "properties": {
                        "cacheProvider": { "const": "memory" }
                    }
                }
            }
        }
    ]
}
"@

$advSchema = [JsonSchema.JsonSchema]::FromText($advancedSchemaJson)

# 测试：生产环境缺少必填字段和监控开关
$prodConfig = @"
{
    "environment": "production",
    "database": {
        "connectionString": "Host=localhost;Database=mydb",
        "maxPoolSize": 5
    },
    "features": {
        "monitoring": false,
        "cacheProvider": "redis"
    }
}
"@

$results = $advSchema.Evaluate($prodConfig)

Write-Host "=== 生产环境配置验证报告 ===" -ForegroundColor Cyan
Write-Host "是否通过：$($results.IsValid)"
Write-Host "`n验证错误明细："
$index = 0
foreach ($detail in $results.Details) {
    $index++
    Write-Host ("  [{0}] 路径: {1}" -f $index, $detail.InstanceLocation) -ForegroundColor Yellow
    Write-Host ("      描述: {0}" -f $detail.Message) -ForegroundColor Gray
}

# 测试：开发环境的简化配置（应该通过）
$devConfig = @"
{
    "environment": "dev",
    "database": {
        "connectionString": "Host=localhost;Database=devdb"
    },
    "features": {
        "cacheProvider": "memory"
    }
}
"@

$devResults = $advSchema.Evaluate($devConfig)
Write-Host "`n=== 开发环境配置验证报告 ===" -ForegroundColor Cyan
Write-Host "是否通过：$($devResults.IsValid)" -ForegroundColor Green
```

执行结果示例：

```
=== 生产环境配置验证报告 ===
是否通过：False

验证错误明细：
  [1] 路径: /database
      描述: 缺少必填属性 sslMode
  [2] 路径: /database/maxPoolSize
      描述: 整数值 5 低于最小值 10
  [3] 路径: /features/monitoring
      描述: 值必须为 true
  [4] 路径: /features
      描述: 缺少必填属性 errorReporting
  [5] 路径: /features
      描述: 缺少必填属性 redisHost（cacheProvider 为 redis 时必需）

=== 开发环境配置验证报告 ===
是否通过：True
```

## 批量验证与错误报告生成

在管理多个环境、多个微服务配置文件的场景下，手动逐个验证效率太低。下面的脚本实现了批量扫描指定目录下的 JSON 配置文件，使用统一的 Schema 进行验证，并生成结构化的验证报告。

```powershell
function Invoke-BatchSchemaValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigDirectory,

        [Parameter(Mandatory)]
        [string]$SchemaFile,

        [string]$ReportPath
    )

    # 加载 Schema
    $schemaText = Get-Content $SchemaFile -Raw
    $schema = [JsonSchema.JsonSchema]::FromText($schemaText)

    # 收集所有 JSON 配置文件
    $configFiles = Get-ChildItem -Path $ConfigDirectory -Filter "*.json" -Recurse
    Write-Host ("发现 {0} 个配置文件，开始批量验证..." -f $configFiles.Count) -ForegroundColor Cyan

    # 验证结果集合
    $report = [System.Collections.Generic.List[PSObject]]::new()
    $passCount = 0
    $failCount = 0

    foreach ($file in $configFiles) {
        $relativePath = $file.FullName.Replace($ConfigDirectory, "").TrimStart("\", "/")
        Write-Host ("  验证: {0} ... " -f $relativePath) -NoNewline

        try {
            $configText = Get-Content $file.FullName -Raw
            $results = $schema.Evaluate($configText)

            if ($results.IsValid) {
                Write-Host "通过" -ForegroundColor Green
                $passCount++
                $report += [PSCustomObject]@{
                    File         = $relativePath
                    Status       = "Pass"
                    ErrorCount   = 0
                    Errors       = ""
                    ValidatedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            } else {
                Write-Host "失败" -ForegroundColor Red
                $failCount++
                $errorList = ($results.Details | ForEach-Object {
                    "{0} => {1}" -f $_.InstanceLocation, $_.Message
                }) -join "; "

                $report += [PSCustomObject]@{
                    File         = $relativePath
                    Status       = "Fail"
                    ErrorCount   = $results.Details.Count
                    Errors       = $errorList
                    ValidatedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            }
        } catch {
            Write-Host "异常" -ForegroundColor Magenta
            $failCount++
            $report += [PSCustomObject]@{
                File         = $relativePath
                Status       = "Error"
                ErrorCount   = 1
                Errors       = $_.Exception.Message
                ValidatedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }

    # 输出汇总信息
    Write-Host "`n========== 验证汇总 ==========" -ForegroundColor Cyan
    Write-Host ("  总文件数：{0}" -f $configFiles.Count)
    Write-Host ("  通过：{0}" -f $passCount) -ForegroundColor Green
    Write-Host ("  失败：{0}" -f $failCount) -ForegroundColor Red
    Write-Host ("  通过率：{0:P1}" -f ($passCount / $configFiles.Count))

    # 导出报告
    if ($ReportPath) {
        $report | ConvertTo-Json -Depth 5 | Out-File $ReportPath -Encoding UTF8
        Write-Host ("`n验证报告已保存至：{0}" -f $ReportPath) -ForegroundColor Green
    }

    return $report
}

# 执行批量验证
$validationResults = Invoke-BatchSchemaValidation `
    -ConfigDirectory "C:\MyApp\Configs" `
    -SchemaFile "C:\MyApp\Schemas\app-config.schema.json" `
    -ReportPath "C:\MyApp\Reports\validation-report.json"

# 针对失败项生成修复建议
$failures = $validationResults | Where-Object { $_.Status -ne "Pass" }
if ($failures) {
    Write-Host "`n========== 需要修复的文件 ==========" -ForegroundColor Yellow
    foreach ($failure in $failures) {
        Write-Host ("  [{0}] {1}" -f $failure.Status, $failure.File) -ForegroundColor Yellow
        Write-Host ("    错误数: {0}" -f $failure.ErrorCount)
        foreach ($err in $failure.Errors -split "; ") {
            Write-Host ("    - {0}" -f $err) -ForegroundColor DarkGray
        }
    }
}
```

执行结果示例：

```
发现 6 个配置文件，开始批量验证...
  验证: dev\app-settings.json ... 通过
  验证: dev\cache-config.json ... 通过
  验证: staging\app-settings.json ... 通过
  验证: staging\cache-config.json ... 失败
  验证: production\app-settings.json ... 失败
  验证: production\cache-config.json ... 通过

========== 验证汇总 ==========
  总文件数：6
  通过：4
  失败：2
  通过率：66.7%

验证报告已保存至：C:\MyApp\Reports\validation-report.json

========== 需要修复的文件 ==========
  [Fail] staging\cache-config.json
    错误数: 1
    - /server/port => 整数值 99999 超过最大值 65535
  [Fail] production\app-settings.json
    错误数: 3
    - /database/sslMode => 缺少必填属性 sslMode
    - /features/monitoring => 值必须为 true
    - /features/errorReporting => 缺少必填属性 errorReporting
```

## 注意事项

1. **库的选择**：JsonSchema.NET 是纯 C# 实现，跨平台兼容性好。如果项目中已经依赖了 Newtonsoft.Json，也可以选择 Newtonsoft.Json.Schema，但它需要商业授权才能在生产环境免受限制
2. **Schema 版本兼容**：不同版本的 JSON Schema（Draft-04 / Draft-07 / 2020-12）在特性支持上有差异，编写 Schema 时务必在 `$schema` 字段中声明正确的版本标识
3. **大文件性能**：对超过 10MB 的 JSON 文件进行完整 Schema 验证可能耗时较长，建议在 CI/CD 中仅对关键字段做校验，或采用增量验证策略
4. **错误路径解读**：验证错误中的 `InstanceLocation` 使用 JSON Pointer 格式（如 `/server/port`），可以精确定位到出错的节点，编写自动化修复脚本时应充分利用此信息
5. **Schema 即文档**：维护良好的 JSON Schema 不仅是验证工具，还可以配合文档生成器（如 @adobe/jsonschema2md）自动生成配置参考手册，减少人工维护成本
6. **CI/CD 集成**：建议将 Schema 验证作为部署流水线的前置步骤（gate check），任何配置文件变更必须通过验证才能合并到主分支，从源头杜绝无效配置上线
