---
layout: post
date: 2025-07-29 08:00:00
updated: 2025-07-29 08:00:00
title: "PowerShell 技能连载 - 模板引擎与代码生成"
description: PowerTip of the Day - Template Engine and Code Generation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- tooling
---

_适用于 PowerShell 5.1 及以上版本_

代码生成是提高效率的利器——从配置文件模板、项目脚手架、API 客户端，到重复性的 CRUD 代码，都可以用模板引擎自动生成。PowerShell 的字符串插值和 Here-String 天然适合模板渲染，结合哈希表的对象展开能力，可以构建灵活的模板引擎。无论是生成批量配置文件、搭建项目骨架，还是生成重复性代码，模板引擎都能大幅减少手工劳动。

本文将讲解 PowerShell 中的模板引擎技术和代码生成实践。

<!-- more -->

## 基础模板渲染

```powershell
# 简单变量替换
function Expand-Template {
    param(
        [Parameter(Mandatory)]
        [string]$Template,

        [hashtable]$Variables
    )

    $result = $Template
    foreach ($key in $Variables.Keys) {
        $result = $result -replace "\{\{$key\}\}", $Variables[$key]
    }
    return $result
}

$configTemplate = @"
server {
    listen {{port}};
    server_name {{hostname}};

    location / {
        proxy_pass http://{{backend_host}}:{{backend_port}};
        proxy_set_header Host `$host;
    }

    access_log /var/log/nginx/{{hostname}}.access.log;
}
"@

$nginxConfig = Expand-Template -Template $configTemplate -Variables @{
    port        = "8080"
    hostname    = "api.example.com"
    backend_host = "127.0.0.1"
    backend_port = "3000"
}

Write-Host $nginxConfig
```

执行结果示例：

```
server {
    listen 8080;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
    }

    access_log /var/log/nginx/api.example.com.access.log;
}
```

## 高级模板引擎

```powershell
# 支持条件判断和循环的模板引擎
function Invoke-TemplateEngine {
    param(
        [Parameter(Mandatory)]
        [string]$Template,

        [Parameter(Mandatory)]
        [hashtable]$Context
    )

    # 处理条件块 {{#if variable}}...{{/if}}
    $Template = [regex]::Replace($Template, '\{\{#if\s+(\w+)\}\}(.*?)\{\{/if\}\}', {
        param($m)
        $varName = $m.Groups[1].Value
        $content = $m.Groups[2].Value
        if ($Context[$varName]) { $content } else { "" }
    }, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # 处理循环 {{#each items}}...{{/each}}
    $Template = [regex]::Replace($Template, '\{\{#each\s+(\w+)\}\}(.*?)\{\{/each\}\}', {
        param($m)
        $varName = $m.Groups[1].Value
        $body = $m.Groups[2].Value
        $items = $Context[$varName]
        if ($items -is [array]) {
            ($items | ForEach-Object {
                $item = $_
                $result = $body
                if ($item -is [hashtable]) {
                    foreach ($key in $item.Keys) {
                        $result = $result -replace "\{\{this\.$key\}\}", $item[$key]
                    }
                }
                $result -replace '\{\{this\}\}', $item
            }) -join ''
        } else { "" }
    }, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # 处理简单变量
    foreach ($key in $Context.Keys) {
        if ($Context[$key] -isnot [array] -and $Context[$key] -isnot [hashtable]) {
            $Template = $template -replace "\{\{$key\}\}", $Context[$key]
        }
    }

    return $Template
}

# 使用高级模板
$dockerComposeTemplate = @"
version: '3.8'
services:
  webapp:
    image: {{registry}}/{{app_name}}:{{version}}
    ports:
      - "{{port}}:80"
    environment:
      - ASPNETCORE_ENVIRONMENT={{environment}}
{{#if debug}}
      - ASPNETCORE_DETAILEDERRORS=true
{{/if}}
    depends_on:{{#each services}}
      - {{this.name}}
{{/each}}
"@

$composed = Invoke-TemplateEngine -Template $dockerComposeTemplate -Context @{
    registry   = "registry.example.com"
    app_name   = "myapp"
    version    = "2.5.0"
    port       = "8080"
    environment = "production"
    debug      = $false
    services   = @(
        @{ name = "redis" },
        @{ name = "postgres" },
        @{ name = "rabbitmq" }
    )
}

Write-Host $composed
```

执行结果示例：

```
version: '3.8'
services:
  webapp:
    image: registry.example.com/myapp:2.5.0
    ports:
      - "8080:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=production

    depends_on:
      - redis
      - postgres
      - rabbitmq
```

## 项目脚手架生成器

```powershell
# 项目脚手架生成器
function New-ProjectScaffold {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,

        [string]$BasePath = ".",

        [string]$Author = $env:USERNAME,

        [string]$Description = "PowerShell module project"
    )

    $projectDir = Join-Path $BasePath $ProjectName
    $context = @{
        ProjectName   = $ProjectName
        Author        = $Author
        Description   = $Description
        Year          = (Get-Date).Year
        Version       = "0.1.0"
        Guid          = [guid]::NewGuid().ToString()
    }

    Write-Host "创建项目：$ProjectName" -ForegroundColor Cyan

    # 创建目录结构
    $dirs = @(
        "source",
        "source\Public",
        "source\Private",
        "tests",
        "docs",
        "examples"
    )

    foreach ($dir in $dirs) {
        $fullPath = Join-Path $projectDir $dir
        New-Item $fullPath -ItemType Directory -Force | Out-Null
        Write-Host "  创建目录：$dir" -ForegroundColor DarkGray
    }

    # 生成模块清单
    $manifest = @"
@{
    RootModule        = '$ProjectName.psm1'
    ModuleVersion     = '$($context.Version)'
    GUID              = '$($context.Guid)'
    Author            = '$($context.Author)'
    Description       = '$($context.Description)'
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('$ProjectName')
            ProjectUri = 'https://github.com/user/$ProjectName'
        }
    }
}
"@
    $manifest | Set-Content (Join-Path $projectDir "source\$ProjectName.psd1") -Encoding UTF8

    # 生成模块入口
    $module = @"
# 导入公共函数
`$public = Get-ChildItem -Path "`$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach (`$func in `$public) {
    . `$func.FullName
    Export-ModuleMember -Function `$func.BaseName
}

# 导入私有函数
`$private = Get-ChildItem -Path "`$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach (`$func in `$private) {
    . `$func.FullName
}

Write-Host '$ProjectName 模块已加载' -ForegroundColor Green
"@
    $module | Set-Content (Join-Path $projectDir "source\$ProjectName.psm1") -Encoding UTF8

    # 生成 README
    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("# $ProjectName")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine($context.Description)
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## 安装")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("``````powershell")
    $null = $sb.AppendLine("Install-Module $ProjectName -Scope CurrentUser")
    $null = $sb.AppendLine("``````")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## 使用")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("``````powershell")
    $null = $sb.AppendLine("Import-Module $ProjectName")
    $null = $sb.AppendLine("``````")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## 许可证")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("MIT License - $($context.Author)")
    $sb.ToString() | Set-Content (Join-Path $projectDir "README.md") -Encoding UTF8

    Write-Host "`n项目脚手架已生成：$projectDir" -ForegroundColor Green
    Write-Host "  目录：$($dirs.Count) 个" -ForegroundColor Cyan
    Write-Host "  文件：3 个（psd1, psm1, README.md）" -ForegroundColor Cyan
}

New-ProjectScaffold -ProjectName "MyUtils" -Description "实用的 PowerShell 工具函数模块"
```

执行结果示例：

```
创建项目：MyUtils
  创建目录：source
  创建目录：source\Public
  创建目录：source\Private
  创建目录：tests
  创建目录：docs
  创建目录：examples

项目脚手架已生成：.\MyUtils
  目录：6 个
  文件：3 个（psd1, psm1, README.md）
```

## 批量配置文件生成

```powershell
# 从 CSV 数据批量生成配置文件
function New-ConfigFromTemplate {
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath,

        [Parameter(Mandatory)]
        [string]$DataPath,

        [Parameter(Mandatory)]
        [string]$OutputDir
    )

    $template = Get-Content $TemplatePath -Raw
    $data = Import-Csv $DataPath -Encoding UTF8

    New-Item $OutputDir -ItemType Directory -Force | Out-Null

    foreach ($row in $data) {
        $context = @{}
        $row.PSObject.Properties | ForEach-Object { $context[$_.Name] = $_.Value }

        $output = Invoke-TemplateEngine -Template $template -Context $context
        $fileName = "$($row.Name -replace '\s', '-').config"
        $outputPath = Join-Path $OutputDir $fileName

        $output | Set-Content $outputPath -Encoding UTF8
        Write-Host "已生成：$fileName" -ForegroundColor Green
    }

    Write-Host "`n批量生成完成：$($data.Count) 个文件" -ForegroundColor Cyan
}

# 使用模板批量生成 Nginx 配置
$nginxTemplate = @"
server {
    listen {{port}};
    server_name {{domain}};

    root /var/www/{{name}};
    index index.html;

    location / {
        try_files `$uri `$uri/ =404;
    }

    access_log /var/log/nginx/{{name}}.log;
}
"@

$nginxTemplate | Set-Content "C:\Templates\nginx.txt" -Encoding UTF8

$sites = @"
Name,Domain,Port
site1,api.example.com,443
site2,web.example.com,80
site3,docs.example.com,8080
"@ | ConvertFrom-Csv

$sites | Export-Csv "C:\Data\sites.csv" -NoTypeInformation -Encoding UTF8
New-ConfigFromTemplate -TemplatePath "C:\Templates\nginx.txt" -DataPath "C:\Data\sites.csv" -OutputDir "C:\Output\nginx"
```

执行结果示例：

```
已生成：site1.config
已生成：site2.config
已生成：site3.config

批量生成完成：3 个文件
```

## 注意事项

1. **转义字符**：模板中包含 PowerShell 特殊字符（`$`、反引号）时需要正确转义
2. **安全性**：不要用 `Invoke-Expression` 渲染模板，存在代码注入风险。使用字符串替换或正则
3. **编码**：生成的文件始终指定 UTF-8 编码，避免中文乱码
4. **幂等性**：脚手架生成器应该可以重复执行，已存在的文件不覆盖或提示用户
5. **模板来源**：模板可以存储在文件、数据库或远程仓库中，方便版本管理
6. **复杂逻辑**：如果模板需要复杂条件判断，考虑使用专门的模板引擎模块（如 `PSTemplates`）
