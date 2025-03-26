---
layout: post
date: 2025-03-14 08:00:00
title: "PowerShell REST API高级集成技术"
description: "掌握OAuth认证与分页数据处理实战"
categories:
- powershell
- web-services
tags:
- rest-api
- oauth2
---

## OAuth2认证流程
```powershell
$tokenParams = @{
    Uri = 'https://login.microsoftonline.com/tenant/oauth2/v2.0/token'
    Method = 'POST'
    Body = @{
        client_id = $clientId
        scope = 'https://graph.microsoft.com/.default'
        client_secret = $secret
        grant_type = 'client_credentials'
    }
}

$token = Invoke-RestMethod @tokenParams
$headers = @{Authorization = "Bearer $($token.access_token)"}
```

## 分页数据获取
```powershell
$result = while ($true) {
    $response = Invoke-RestMethod -Uri $url -Headers $headers
    $response.value
    if (-not $response.'@odata.nextLink') { break }
    $url = $response.'@odata.nextLink'
}
```

## 错误重试机制
```powershell
function Invoke-RetryRequest {
    param(
        [scriptblock]$Action,
        [int]$MaxRetries = 3
    )
    
    $attempt = 0
    do {
        try {
            return & $Action
        }
        catch {
            $attempt++
            if ($attempt -ge $MaxRetries) { throw }
            Start-Sleep -Seconds (2 * $attempt)
        }
    } while ($true)
}
```

## 最佳实践
1. 令牌缓存与自动刷新
2. 请求速率限制处理
3. 异步批量数据处理
4. 响应数据验证机制

## 安全规范
- 敏感信息加密存储
- 使用HTTPS严格模式
- 限制API权限范围
- 定期轮换访问凭证