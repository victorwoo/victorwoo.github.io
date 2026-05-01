---
layout: post
date: 2025-05-09 08:00:00
title: "PowerShell 技能连载 - 网络编程与 REST API"
description: PowerTip of the Day - Network Programming and REST API in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- rest-api
- http
- web-request
---

_适用于 PowerShell 5.1 及以上版本_

在现代运维和自动化场景中，与 REST API 交互已成为 PowerShell 的核心能力之一——无论是调用云服务 API 管理 Azure/AWS 资源、与 GitHub/GitLab 交互管理代码仓库、对接企业内部的 ITSM 系统创建工单，还是查询第三方服务获取天气、汇率等数据，都离不开 HTTP 请求。PowerShell 内置的 `Invoke-RestMethod` 和 `Invoke-WebRequest` 提供了强大且易用的 HTTP 客户端功能。

本文将从基础 HTTP 请求讲起，逐步深入到认证、JSON 处理、分页请求和错误重试等进阶话题。

## 基础 HTTP 请求

PowerShell 提供两个主要的 HTTP 命令：`Invoke-RestMethod`（自动解析响应）和 `Invoke-WebRequest`（返回原始响应对象）：

```powershell
# GET 请求（Invoke-RestMethod 自动解析 JSON）
$response = Invoke-RestMethod -Uri 'https://jsonplaceholder.typicode.com/posts/1'
$response | Format-List

# GET 请求（Invoke-WebRequest 返回完整响应对象）
$webResponse = Invoke-WebRequest -Uri 'https://jsonplaceholder.typicode.com/posts/1'
Write-Host "状态码：$($webResponse.StatusCode)"
Write-Host "内容类型：$($webResponse.Headers.'Content-Type')"
Write-Host "内容长度：$($webResponse.Headers.'Content-Length') 字节"

# 将响应内容转换为 JSON 对象
$content = $webResponse.Content | ConvertFrom-Json
$content | Select-Object id, title
```

执行结果示例：

```
userId : 1
id     : 1
title  : sunt aut facere repellat provident occaecati excepturi optio
body   : quia et suscipit...

状态码：200
内容类型：application/json; charset=utf-8
内容长度：292 字节

id title
-- -----
 1 sunt aut facere repellat provident occaecati excepturi optio
```

## POST/PUT/DELETE 请求

REST API 的核心是 CRUD 操作——创建（POST）、读取（GET）、更新（PUT）、删除（DELETE）：

```powershell
# POST 请求（创建资源）
$newPost = @{
    title  = 'PowerShell REST API 指南'
    body   = '这是一篇关于 PowerShell 调用 REST API 的文章'
    userId = 1
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri 'https://jsonplaceholder.typicode.com/posts' `
    -Method Post `
    -Body $newPost `
    -ContentType 'application/json; charset=utf-8'

Write-Host "已创建文章，ID: $($created.id)"
$created | Format-List

# PUT 请求（更新资源）
$updateData = @{
    id     = 1
    title  = '更新后的标题'
    body   = '更新后的内容'
    userId = 1
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri 'https://jsonplaceholder.typicode.com/posts/1' `
    -Method Put `
    -Body $updateData `
    -ContentType 'application/json; charset=utf-8'

# DELETE 请求
$deleteResponse = Invoke-RestMethod -Uri 'https://jsonplaceholder.typicode.com/posts/1' `
    -Method Delete
Write-Host "删除状态码：$($deleteResponse.StatusCode)"
```

执行结果示例：

```
已创建文章，ID: 101

title  : PowerShell REST API 指南
body   : 这是一篇关于 PowerShell 调用 REST API 的文章
userId : 1
id     : 101
```

## 认证方式

大多数生产 API 需要认证。以下是常见的认证方式：

```powershell
# 方式一：Bearer Token 认证
$token = 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
$headers = @{
    Authorization = "Bearer $token"
    Accept        = 'application/vnd.github.v3+json'
}

$repos = Invoke-RestMethod -Uri 'https://api.github.com/user/repos' `
    -Headers $headers
$repos | Select-Object name, private, language, stargazers_count |
    Format-Table -AutoSize

# 方式二：API Key 作为查询参数
$apiKey = 'your-api-key'
$weather = Invoke-RestMethod -Uri "https://api.openweathermap.org/data/2.5/weather?q=Beijing&appid=$apiKey&units=metric"
Write-Host "北京当前温度：$($weather.main.temp)°C"
Write-Host "天气描述：$($weather.weather[0].description)"

# 方式三：基本认证
$cred = Get-Credential
Invoke-RestMethod -Uri 'https://api.example.com/data' `
    -Authentication Basic `
    -Credential $cred

# 方式四：OAuth2 客户端凭据流
$tokenResponse = Invoke-RestMethod -Uri 'https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token' `
    -Method Post `
    -Body @{
        client_id     = 'app-client-id'
        client_secret = 'app-client-secret'
        scope         = 'https://graph.microsoft.com/.default'
        grant_type    = 'client_credentials'
    }

$accessToken = $tokenResponse.access_token
Write-Host "获取到 Token，有效期：$($tokenResponse.expires_in) 秒"
```

执行结果示例：

```
name             private language stargazers_count
----             -------- -------- ----------------
my-project       False    PowerShell              12
internal-tools   True     C#                       5

北京当前温度：22.3°C
天气描述：晴

获取到 Token，有效期：3599 秒
```

## JSON 处理进阶

PowerShell 的 JSON 处理有一些常见的陷阱，了解它们可以避免很多调试时间：

```powershell
# ConvertTo-Json 的深度问题（默认只序列化 2 层）
$data = @{
    Level1 = @{
        Level2 = @{
            Level3 = '深层嵌套数据'
        }
    }
}

# 默认深度 2，Level3 会丢失
$json shallow = $data | ConvertTo-Json
Write-Host "默认深度：`n$jsonshallow"

# 设置深度为 10，保留完整结构
$jsonDeep = $data | ConvertTo-Json -Depth 10
Write-Host "`n深度 10：`n$jsonDeep"

# 处理数组中的空值
$arrayData = @(
    @{ Name = 'Item1'; Value = 100 }
    @{ Name = 'Item2'; Value = $null }
    @{ Name = 'Item3'; Value = 300 }
)

# 默认会忽略空值属性，使用 -EnumsAsStrings 保持完整
$jsonArray = $arrayData | ConvertTo-Json -Depth 5
Write-Host "`n数组 JSON：`n$jsonArray"

# 从 API 响应中提取嵌套数据
$response = Invoke-RestMethod -Uri 'https://jsonplaceholder.typicode.com/users'
$response | Select-Object name, email,
    @{N='城市'; E={$_.address.city}},
    @{N='公司'; E={$_.company.name}} |
    Format-Table -AutoSize
```

执行结果示例：

```
默认深度：
{
  "Level1": {
    "Level2": "System.Collections.Hashtable"
  }
}

深度 10：
{
  "Level1": {
    "Level2": {
      "Level3": "深层嵌套数据"
    }
  }
}

数组 JSON：
[
  { "Name": "Item1", "Value": 100 },
  { "Name": "Item2" },
  { "Name": "Item3", "Value": 300 }
]

name            email                    城市       公司
----            -----                    ----       ----
Leanne Graham   Sincere@april.biz        Gwenborough Romaguera-Crona
Ervin Howell    Shanna@melissa.tv        Wisokyburgh   Deckow-Crist
```

## 分页请求处理

当 API 返回大量数据时，通常使用分页。以下是一个通用的分页请求函数：

```powershell
function Invoke-RestMethodPaged {
    <#
    .SYNOPSIS
    自动处理分页 API 请求
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [int]$PageSize = 100,
        [int]$MaxPages = 100,
        [hashtable]$Headers,
        [string]$PageParam = 'page',
        [string]$PerPageParam = 'per_page'
    )

    $allResults = [System.Collections.Generic.List[PSObject]]::new()
    $page = 1

    while ($page -le $MaxPages) {
        $separator = if ($Uri -match '\?') { '&' } else { '?' }
        $pageUri = "${Uri}${separator}${PerPageParam}=${PageSize}&${PageParam}=${page}"

        $params = @{
            Uri     = $pageUri
            Method  = 'Get'
        }
        if ($Headers) { $params.Headers = $Headers }

        try {
            $response = Invoke-RestMethod @params
        } catch {
            Write-Warning "第 ${page} 页请求失败：$($_.Exception.Message)"
            break
        }

        if (-not $response -or $response.Count -eq 0) {
            break
        }

        $allResults.AddRange($response)
        Write-Host "已获取第 ${page} 页，累计 $($allResults.Count) 条" -ForegroundColor Cyan

        if ($response.Count -lt $PageSize) {
            break
        }

        $page++
    }

    Write-Host "`n总计获取 $($allResults.Count) 条数据" -ForegroundColor Green
    return $allResults
}

# 示例：获取 GitHub 仓库的所有 Issues
$issues = Invoke-RestMethodPaged `
    -Uri 'https://api.github.com/repos/PowerShell/PowerShell/issues' `
    -Headers @{ Authorization = "Bearer $token" } `
    -PageSize 50

$issues | Select-Object number, title, state,
    @{N='labels'; E={$_.labels.name -join ', '}} |
    Format-Table -AutoSize
```

执行结果示例：

```
已获取第 1 页，累计 50 条
已获取第 2 页，累计 100 条
已获取第 3 页，累计 112 条

总计获取 112 条数据

number title                              state  labels
------ -----                              -----  -------
24501  Fix null coalescing in pipelines   open   Bug, Help Wanted
24498  Add -AsHashtable to ConvertFrom... open   Enhancement
24495  Update ReadMe with new links       closed Documentation
```

## 错误处理与重试

网络请求不可避免会遇到超时、限流等问题。良好的错误处理和重试机制是健壮 API 调用的基础：

```powershell
function Invoke-ApiWithRetry {
    <#
    .SYNOPSIS
    带重试机制的 API 调用
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [ValidateSet('Get','Post','Put','Delete','Patch')]
        [string]$Method = 'Get',

        $Body,
        [hashtable]$Headers,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 2
    )

    $attempt = 0

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            $params = @{
                Uri     = $Uri
                Method  = $Method
            }
            if ($Body) { $params.Body = $Body }
            if ($Headers) { $params.Headers = $Headers }

            $response = Invoke-RestMethod @params -ErrorAction Stop
            return $response

        } catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            if ($statusCode -eq 429) {
                # 限流：使用 Retry-After 头的值
                $retryAfter = $_.Exception.Response.Headers['Retry-After']
                $waitTime = if ($retryAfter) { [int]$retryAfter } else { $RetryDelaySeconds * 2 }
                Write-Warning "API 限流 (429)，等待 ${waitTime} 秒后重试（第 ${attempt} 次）"
                Start-Sleep -Seconds $waitTime
            }
            elseif ($statusCode -ge 500) {
                # 服务器错误：指数退避重试
                $waitTime = $RetryDelaySeconds * [math]::Pow(2, $attempt - 1)
                Write-Warning "服务器错误 ($statusCode)，${waitTime} 秒后重试（第 ${attempt} 次）"
                Start-Sleep -Seconds $waitTime
            }
            elseif ($statusCode -ge 400) {
                # 客户端错误：不重试
                Write-Error "请求失败 ($statusCode)：$($_.Exception.Message)"
                return $null
            }
            else {
                # 其他错误（网络超时等）：重试
                Write-Warning "请求异常：$($_.Exception.Message)（第 ${attempt} 次）"
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }

    Write-Error "已达最大重试次数 ($MaxRetries)，请求失败"
    return $null
}

# 使用带重试的 API 调用
$result = Invoke-ApiWithRetry -Uri 'https://api.github.com/rate_limit' `
    -Headers @{ Authorization = "Bearer $token" } `
    -MaxRetries 3
```

执行结果示例：

```
WARNING: API 限流 (429)，等待 60 秒后重试（第 1 次）
WARNING: 服务器错误 (503)，2 秒后重试（第 2 次）
```

## 注意事项

1. **TLS 版本**：某些 API 要求 TLS 1.2，使用 `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` 强制设置
2. **JSON 序列化深度**：`ConvertTo-Json` 默认深度为 2，嵌套对象会被截断，务必根据实际结构调整 `-Depth` 参数
3. **编码问题**：发送中文内容时，确保 `-ContentType` 包含 `charset=utf-8`，避免乱码
4. **大型响应**：处理大量数据时，考虑使用流式读取或将结果分页处理，避免一次性加载到内存
5. **敏感信息**：不要在脚本中硬编码 API Key 和 Token，使用环境变量或 Azure Key Vault 等安全存储
6. **超时设置**：生产环境建议设置合理的超时 `-TimeoutSec`，避免请求无限等待
