---
layout: post
date: 2025-10-20 08:00:00
updated: 2025-10-20 08:00:00
title: "PowerShell 技能连载 - Pode Web API 开发"
description: PowerTip of the Day - Pode Web API Development in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- pode
- web-api
- rest-api
- http-server
---

_适用于 PowerShell 7.0 及以上版本_

在日常运维和内部工具开发中，我们经常需要一个轻量级的 HTTP 服务来暴露数据或接收指令。传统做法是搭建 IIS、写 C# Web API 项目，但这对于一个简单的查询接口来说未免过于笨重。[Pode](https://github.com/Badgerati/Pode) 是一个纯 PowerShell 实现的跨平台 Web 框架，它内置了路由、中间件、认证、日志等功能，让你用熟悉的 PowerShell 语法就能快速构建 REST API。

Pode 的典型使用场景包括：为运维脚本提供 HTTP 调用入口、搭建内部微服务接口、接收 Webhook 回调、构建简单的管理仪表盘后端等。本文将从零开始，逐步演示如何用 Pode 搭建一个具备完整 CRUD 功能的任务管理 API。

<!-- more -->

## 基础 API 服务搭建

首先安装 Pode 模块并创建一个最基础的服务器，包含健康检查接口和路由组织结构。Pode 使用 `Start-PodeServer` 作为入口，通过 `Add-PodeRoute` 注册路由处理逻辑，整体风格类似于 Express.js 或 Flask。

```powershell
# 安装 Pode 模块
Install-Module -Name Pode -Force -Scope CurrentUser

# 创建基础 API 服务器
Start-PodeServer {
    # 监听本地 8090 端口
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # 全局日志中间件 - 记录每个请求的方法、路径和耗时
    Add-PodeMiddleware -Name 'RequestLogger' -ScriptBlock {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $WebEvent.Data['__stopwatch'] = $sw
        # 继续处理下一个中间件
    }

    Add-PodeMiddleware -Name 'ResponseTimer' -ScriptBlock {
        $sw = $WebEvent.Data['__stopwatch']
        if ($sw) {
            $sw.Stop()
            $elapsed = $sw.ElapsedMilliseconds
            Write-PodeHost "[API] $($WebEvent.Method) $($WebEvent.Path) - ${elapsed}ms"
        }
    }

    # GET /api/health - 健康检查端点
    Add-PodeRoute -Method Get -Path '/api/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            status    = 'healthy'
            timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            version   = '1.0.0'
            machine   = $env:COMPUTERNAME
            pwsh      = $PSVersionTable.PSVersion.ToString()
        }
    }

    # GET /api/info - 服务器信息
    Add-PodeRoute -Method Get -Path '/api/info' -ScriptBlock {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        Write-PodeJsonResponse -Value @{
            computer    = $env:COMPUTERNAME
            os          = if ($os) { $os.Caption } else { 'Unknown' }
            psVersion   = $PSVersionTable.PSVersion.ToString()
            podeVersion = (Get-Module Pode).Version.ToString()
            uptime      = if ($os) {
                [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
            } else { 0 }
        }
    }
}
```

启动服务器后，用浏览器或 `Invoke-RestMethod` 访问即可获取响应。

```text
PS> Invoke-RestMethod http://localhost:8090/api/health

status    : healthy
timestamp : 2025-10-20T08:00:00.123Z
version   : 1.0.0
machine   : WORKSTATION-01
pwsh      : 7.4.6
```

```text
PS> Invoke-RestMethod http://localhost:8090/api/info

computer    : WORKSTATION-01
os          : Microsoft Windows 11 Pro
psVersion   : 7.4.6
podeVersion : 2.12.0
uptime      : 15.3
```

## 内存数据存储与 CRUD 操作

接下来我们实现一个完整的任务管理 API，使用内存哈希表作为数据存储。Pode 支持 `Add-PodeState` 来维护服务端状态，这种状态在服务器运行期间持久存在于内存中。我们将实现标准的 RESTful 风格 CRUD 操作。

```powershell
Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # 初始化内存数据存储
    Set-PodeState -Name 'Tasks' -Value @(
        @{
            Id          = 1
            Title       = '部署生产环境补丁'
            Description = '安装 2025 年 10 月安全更新'
            Priority    = 'High'
            Status      = 'Pending'
            CreatedAt   = '2025-10-18T09:00:00'
        }
        @{
            Id          = 2
            Title       = '备份数据库'
            Description = '执行每周全量备份'
            Priority    = 'Medium'
            Status      = 'Completed'
            CreatedAt   = '2025-10-17T14:30:00'
        }
    )

    # 设置下一个可用 ID
    Set-PodeState -Name 'NextTaskId' -Value 3

    # GET /api/tasks - 获取所有任务，支持筛选和分页
    Add-PodeRoute -Method Get -Path '/api/tasks' -ScriptBlock {
        $tasks = Get-PodeState -Name 'Tasks'
        $status = $WebEvent.Query['status']
        $priority = $WebEvent.Query['priority']
        $limit = if ($WebEvent.Query['limit']) { [int]$WebEvent.Query['limit'] } else { 50 }

        # 按条件筛选
        $filtered = $tasks
        if ($status) {
            $filtered = $filtered | Where-Object { $_.Status -eq $status }
        }
        if ($priority) {
            $filtered = $filtered | Where-Object { $_.Priority -eq $priority }
        }

        # 限制返回数量
        $result = $filtered | Select-Object -First $limit

        Write-PodeJsonResponse -Value @{
            total = $filtered.Count
            count = $result.Count
            limit = $limit
            data  = @($result)
        }
    }

    # GET /api/tasks/:id - 获取单个任务
    Add-PodeRoute -Method Get -Path '/api/tasks/:id' -ScriptBlock {
        $taskId = [int]$WebEvent.Parameters['id']
        $tasks = Get-PodeState -Name 'Tasks'
        $task = $tasks | Where-Object { $_.Id -eq $taskId } | Select-Object -First 1

        if ($task) {
            Write-PodeJsonResponse -Value $task
        } else {
            Set-PodeResponseStatus -Code 404
            Write-PodeJsonResponse -Value @{
                error = "Task with Id=$taskId not found"
            }
        }
    }

    # POST /api/tasks - 创建新任务
    Add-PodeRoute -Method Post -Path '/api/tasks' -ScriptBlock {
        $body = $WebEvent.Data
        $nextId = Get-PodeState -Name 'NextTaskId'
        $tasks = Get-PodeState -Name 'Tasks'

        $newTask = @{
            Id          = $nextId
            Title       = $body.Title
            Description = if ($body.Description) { $body.Description } else { '' }
            Priority    = if ($body.Priority) { $body.Priority } else { 'Medium' }
            Status      = 'Pending'
            CreatedAt   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        }

        # 添加到列表并更新状态
        $tasks = @($tasks) + $newTask
        Set-PodeState -Name 'Tasks' -Value $tasks
        Set-PodeState -Name 'NextTaskId' -Value ($nextId + 1)

        Set-PodeResponseStatus -Code 201
        Write-PodeJsonResponse -Value $newTask
    }

    # PUT /api/tasks/:id - 更新任务
    Add-PodeRoute -Method Put -Path '/api/tasks/:id' -ScriptBlock {
        $taskId = [int]$WebEvent.Parameters['id']
        $body = $WebEvent.Data
        $tasks = Get-PodeState -Name 'Tasks'
        $found = $false

        $updatedTasks = foreach ($t in $tasks) {
            if ($t.Id -eq $taskId) {
                $found = $true
                @{
                    Id          = $t.Id
                    Title       = if ($body.Title) { $body.Title } else { $t.Title }
                    Description = if ($body.Description) { $body.Description } else { $t.Description }
                    Priority    = if ($body.Priority) { $body.Priority } else { $t.Priority }
                    Status      = if ($body.Status) { $body.Status } else { $t.Status }
                    CreatedAt   = $t.CreatedAt
                    UpdatedAt   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                }
            } else {
                $t
            }
        }

        if ($found) {
            Set-PodeState -Name 'Tasks' -Value @($updatedTasks)
            $updated = $updatedTasks | Where-Object { $_.Id -eq $taskId } | Select-Object -First 1
            Write-PodeJsonResponse -Value $updated
        } else {
            Set-PodeResponseStatus -Code 404
            Write-PodeJsonResponse -Value @{
                error = "Task with Id=$taskId not found"
            }
        }
    }

    # DELETE /api/tasks/:id - 删除任务
    Add-PodeRoute -Method Delete -Path '/api/tasks/:id' -ScriptBlock {
        $taskId = [int]$WebEvent.Parameters['id']
        $tasks = Get-PodeState -Name 'Tasks'
        $original = $tasks

        $remaining = @($tasks | Where-Object { $_.Id -ne $taskId })

        if ($remaining.Count -lt $original.Count) {
            Set-PodeState -Name 'Tasks' -Value $remaining
            Write-PodeJsonResponse -Value @{
                message = "Task $taskId deleted"
                remaining = $remaining.Count
            }
        } else {
            Set-PodeResponseStatus -Code 404
            Write-PodeJsonResponse -Value @{
                error = "Task with Id=$taskId not found"
            }
        }
    }
}
```

以下是调用这些 API 的示例。先创建一条新任务，再查询所有任务列表。

```text
PS> $body = @{ Title = '检查 SSL 证书过期'; Priority = 'High' } | ConvertTo-Json
PS> Invoke-RestMethod -Method Post -Uri http://localhost:8090/api/tasks -Body $body -ContentType 'application/json'

Id          : 3
Title       : 检查 SSL 证书过期
Description :
Priority    : High
Status      : Pending
CreatedAt   : 2025-10-20T08:15:00
```

```text
PS> Invoke-RestMethod http://localhost:8090/api/tasks?status=Pending

total : 2
count : 2
limit : 50
data  : {@{Id=1; Title=部署生产环境补丁; ...}, @{Id=3; Title=检查 SSL 证书过期; ...}}
```

## JWT 认证与请求验证

在生产环境中，API 需要认证机制来保护敏感操作。Pode 内置了对 JWT (JSON Web Token) 认证的支持，只需要几行配置就能为路由添加安全防护。同时我们还可以利用中间件实现请求体验证，确保提交的数据格式正确。

```powershell
Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # 配置 JWT 认证 - 使用自定义密钥签名
    New-PodeAuthScheme -ApiKey -Location Header -Name 'Authorization' |
        Add-PodeAuth -Name 'JwtAuth' -Sessionless -ScriptBlock {
            param($token)

            # 移除 "Bearer " 前缀
            if ($token.StartsWith('Bearer ')) {
                $token = $token.Substring(7)
            }

            try {
                # 验证 JWT（此处用对称密钥示例，生产环境应使用证书）
                $parts = $token.Split('.')
                if ($parts.Count -ne 3) {
                    return @{ Message = 'Invalid token format' }
                }

                # 解码 Payload（Base64Url）
                $payloadBytes = [System.Convert]::FromBase64String(
                    $parts[1].Replace('-', '+').Replace('_', '/')
                )
                $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
                $payload = $payloadJson | ConvertFrom-Json

                # 检查过期时间
                if ($payload.exp -and $payload.exp -lt [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) {
                    return @{ Message = 'Token expired' }
                }

                # 认证成功，返回用户信息
                return @{
                    User = @{
                        Name  = $payload.sub
                        Role  = $payload.role
                        Issue = $payload.iss
                    }
                }
            } catch {
                return @{ Message = "Token validation failed: $_" }
            }
        }

    # POST /api/auth/login - 登录获取 Token
    Add-PodeRoute -Method Post -Path '/api/auth/login' -ScriptBlock {
        $body = $WebEvent.Data
        $username = $body.Username
        $password = $body.Password

        # 简化示例 - 生产环境应查询数据库验证
        $validUsers = @{
            'admin'  = @{ Password = 'P@ssw0rd'; Role = 'Admin' }
            'reader' = @{ Password = 'Read0nly'; Role = 'Reader' }
        }

        if (-not $validUsers.ContainsKey($username)) {
            Set-PodeResponseStatus -Code 401
            Write-PodeJsonResponse -Value @{ error = 'Unknown user' }
            return
        }

        if ($validUsers[$username].Password -ne $password) {
            Set-PodeResponseStatus -Code 401
            Write-PodeJsonResponse -Value @{ error = 'Invalid password' }
            return
        }

        # 构建 JWT Payload
        $header = @{ alg = 'HS256'; typ = 'JWT' } | ConvertTo-Json -Compress
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $payload = @{
            sub = $username
            role = $validUsers[$username].Role
            iss = 'pode-api-server'
            iat = $now
            exp = $now + 3600
        } | ConvertTo-Json -Compress

        # Base64Url 编码
        $headerB64 = [System.Convert]::ToBase64String(
            [System.Text.Encoding]::UTF8.GetBytes($header)
        ).TrimEnd('=').Replace('+', '-').Replace('/', '_')

        $payloadB64 = [System.Convert]::ToBase64String(
            [System.Text.Encoding]::UTF8.GetBytes($payload)
        ).TrimEnd('=').Replace('+', '-').Replace('/', '_')

        # 生成签名（简化示例 - 生产环境应使用 HMAC-SHA256）
        $secret = 'my-secret-key-2025'
        $signInput = "$headerB64.$payloadB64"
        $hmac = [System.Security.Cryptography.HMACSHA256]::new(
            [System.Text.Encoding]::UTF8.GetBytes($secret)
        )
        $signatureBytes = $hmac.ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($signInput)
        )
        $signatureB64 = [System.Convert]::ToBase64String($signatureBytes).
            TrimEnd('=').Replace('+', '-').Replace('/', '_')

        $jwt = "$headerB64.$payloadB64.$signatureB64"

        Write-PodeJsonResponse -Value @{
            token     = $jwt
            tokenType = 'Bearer'
            expiresIn = 3600
            role      = $validUsers[$username].Role
        }
    }

    # 请求体验证中间件
    Add-PodeMiddleware -Name 'TaskValidation' -Route '/api/tasks' -ScriptBlock {
        if ($WebEvent.Method -in @('Post', 'Put')) {
            $body = $WebEvent.Data
            $errors = @()

            if (-not $body.Title -or $body.Title.Trim().Length -eq 0) {
                $errors += 'Title is required'
            }
            if ($body.Title -and $body.Title.Length -gt 200) {
                $errors += 'Title must not exceed 200 characters'
            }
            if ($body.Priority -and $body.Priority -notin @('Low', 'Medium', 'High', 'Critical')) {
                $errors += "Priority must be one of: Low, Medium, High, Critical"
            }
            if ($body.Status -and $body.Status -notin @('Pending', 'InProgress', 'Completed', 'Cancelled')) {
                $errors += "Status must be one of: Pending, InProgress, Completed, Cancelled"
            }

            if ($errors.Count -gt 0) {
                Set-PodeResponseStatus -Code 400
                Write-PodeJsonResponse -Value @{
                    error  = 'Validation failed'
                    detail = $errors
                }
                # 阻止请求继续传递到路由处理
                return $false
            }
        }
    }

    # 需要认证的受保护路由 - GET /api/tasks
    Add-PodeRoute -Method Get -Path '/api/tasks' -Authentication 'JwtAuth' -ScriptBlock {
        $tasks = Get-PodeState -Name 'Tasks'
        Write-PodeJsonResponse -Value @{
            user  = $WebEvent.Auth.User.Name
            count = $tasks.Count
            data  = @($tasks)
        }
    }
}
```

下面演示完整的认证流程：先登录获取 Token，再用 Token 访问受保护的 API。

```text
PS> $cred = @{ Username = 'admin'; Password = 'P@ssw0rd' } | ConvertTo-Json
PS> $resp = Invoke-RestMethod -Method Post -Uri http://localhost:8090/api/auth/login -Body $cred -ContentType 'application/json'

token     : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIi...
tokenType : Bearer
expiresIn : 3600
role      : Admin

PS> $headers = @{ Authorization = "Bearer $($resp.token)" }
PS> Invoke-RestMethod -Uri http://localhost:8090/api/tasks -Headers $headers

user  : admin
count : 3
data  : {@{Id=1; Title=部署生产环境补丁; ...}, ...}
```

```text
PS> # 不带 Token 访问受保护路由会被拒绝
PS> Invoke-RestMethod http://localhost:8090/api/tasks
Invoke-RestMethod: 401 Unauthorized
```

```text
PS> # 提交无效数据会触发验证中间件
PS> $bad = @{ Title = ''; Priority = 'Invalid' } | ConvertTo-Json
PS> Invoke-RestMethod -Method Post -Uri http://localhost:8090/api/tasks -Body $bad -ContentType 'application/json'
Invoke-RestMethod: 400 Bad Request
```

## 注意事项

1. **生产环境应使用 HTTPS**：Pode 支持通过 `Add-PodeEndpoint -Protocol Https -Certificate` 配置 SSL/TLS 证书。在公网部署时务必启用 HTTPS，避免认证凭据和 API 数据以明文传输。

2. **状态存储不跨重启**：`Set-PodeState` 维护的数据存储在内存中，服务器重启后数据丢失。如需持久化，应结合文件、SQLite 或外部数据库。Pode 社区有 `Pode.Web` 和各种数据库连接器可以配合使用。

3. **并发与线程模型**：Pode 默认使用多线程处理请求（通过 runspace pool），但 `Get-PodeState` / `Set-PodeState` 对共享状态的访问已内置线程安全机制。如果直接操作全局变量或文件，需要自行处理并发问题。

4. **JWT 示例仅为演示**：本文中的 JWT 实现是简化版本，仅用于说明 Pode 认证流程的工作原理。在实际项目中，应使用成熟的 JWT 库（如 `System.IdentityModel.Tokens.Jwt`）来生成和验证令牌，并妥善保管签名密钥。

5. **错误处理应覆盖全面**：API 中每个可能失败的操作都应有 `try/catch` 保护，避免未处理异常导致整个请求线程崩溃。建议在全局中间件中统一捕获异常并返回标准化的错误响应格式。

6. **跨平台运行**：Pode 完全基于 PowerShell 编写，在 Windows、Linux 和 macOS 上均可运行。使用 `dotnet` 命令或 Docker 容器即可将 Pode API 部署到 Linux 服务器，适合构建轻量级的跨平台运维微服务。
