---
layout: post
date: 2026-01-14 08:00:00
updated: 2026-01-14 08:00:00
title: "PowerShell 技能连载 - REST API 开发"
description: "PowerTip of the Day - REST API Development in PowerShell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- rest-api
- web
- http
- microservices
---

_适用于 PowerShell 7.0 及以上版本_

当我们谈论 PowerShell 与 REST API 时，通常是在讨论如何用 `Invoke-RestMethod` 调用外部服务。但 PowerShell 的能力不止于此——借助 .NET 的 `HttpListener` 类或社区开发的 Web 框架，你完全可以用 PowerShell 构建自己的 REST API 服务。

这种能力在内部工具场景中尤为实用。比如 CI/CD 流水线需要一个状态查询端点、监控系统需要一个数据聚合接口、第三方 Webhook 需要一个接收器——这些都不需要引入一整套 ASP.NET 或 Node.js 项目，几十行 PowerShell 脚本就能搞定。本文将从底层到高层，逐步演示三种方案。

<!-- more -->

## 使用 HttpListener 创建基础 REST API

`System.Net.HttpListener` 是 .NET 内置的 HTTP 服务器类，无需安装任何额外模块即可使用。下面这段代码创建了一个支持 GET 和 POST 路由的简易 API，返回 JSON 格式的数据。

```powershell
using namespace System.Net
using namespace System.Text

# 创建 API 数据存储
$script:dataStore = @{
    tasks = [System.Collections.ArrayList]::new()
    1..5 | ForEach-Object {
        @{ id = $_; title = "任务 $_"; status = if ($_ -le 3) { 'done' } else { 'pending' } }
    }
}

# 路由表
$routes = @{
    'GET /api/tasks'    = {
        param($ctx)
        $json = $script:dataStore.tasks | ConvertTo-Json -Depth 3
        Send-JsonResponse $ctx $json 200
    }
    'GET /api/tasks/id' = {
        param($ctx)
        $id = [int]($ctx.Request.Url.Segments | Select-Object -Last 1)
        $task = $script:dataStore.tasks | Where-Object { $_.id -eq $id }
        if ($task) {
            Send-JsonResponse $ctx ($task | ConvertTo-Json) 200
        } else {
            Send-JsonResponse $ctx '{"error":"任务不存在"}' 404
        }
    }
    'POST /api/tasks'   = {
        param($ctx)
        $reader = [StreamReader]::new($ctx.Request.InputStream)
        $body = $reader.ReadToEnd()
        $reader.Close()
        $newTask = $body | ConvertFrom-Json
        $script:dataStore.tasks.Add(@{
            id    = ($script:dataStore.tasks.Count + 1)
            title = $newTask.title
            status = 'pending'
        }) | Out-Null
        Send-JsonResponse $ctx '{"message":"任务已创建"}' 201
    }
}

# 响应辅助函数
function Send-JsonResponse {
    param([HttpListenerContext]$Context, [string]$Body, [int]$StatusCode)
    $buffer = [Encoding]::UTF8.GetBytes($Body)
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = 'application/json; charset=utf-8'
    $Context.Response.ContentLength64 = $buffer.Length
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.Close()
}

# 启动监听器
$listener = [HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Write-Host "API 服务已启动: http://localhost:8080/" -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $method = $ctx.Request.HttpMethod
        $path = $ctx.Request.Url.AbsolutePath.TrimEnd('/')
        Write-Host "  [$method] $path" -ForegroundColor Cyan

        # 路由匹配
        $routeKey = "$method $path"
        $handler = $routes[$routeKey]
        if (-not $handler -and $path -match '/api/tasks/\d+$') {
            $handler = $routes['GET /api/tasks/id']
        }

        if ($handler) {
            & $handler $ctx
        } else {
            Send-JsonResponse $ctx '{"error":"路由不存在"}' 404
        }
    }
} finally {
    $listener.Stop()
    Write-Host "API 服务已停止" -ForegroundColor Yellow
}
```

在另一个终端中测试 API：

```powershell
# 查询所有任务
Invoke-RestMethod http://localhost:8080/api/tasks

# 查询单个任务
Invoke-RestMethod http://localhost:8080/api/tasks/2

# 创建新任务
Invoke-RestMethod http://localhost:8080/api/tasks -Method Post -Body '{"title":"新任务"}' -ContentType 'application/json'
```

执行结果示例：

```
id title  status
-- -----  ------
 1 任务 1 done
 2 任务 2 done
 3 任务 3 done
 4 任务 4 pending
 5 任务 5 pending

id title  status
-- -----  ------
 2 任务 2 done

message
-------
任务已创建
```

## 使用 Pode 框架构建完整 API

`HttpListener` 虽然灵活，但需要手动处理路由、中间件等逻辑。[Pode](https://github.com/Badgerati/Pode) 是一个专为 PowerShell 设计的跨平台 Web 框架，提供了路由、中间件、认证、静态文件、日志等开箱即用的功能。

```powershell
# 安装 Pode 模块（首次使用）
Install-Module Pode -Force -Scope CurrentUser

# 创建 api-server.ps1
Start-PodeServer {
    # 监听端口
    Add-PodeEndpoint -Address localhost -Port 3000 -Protocol Http

    # 配置日志
    New-PodeLoggingMethod -File -Name 'api-errors' | Enable-PodeErrorLogging
    New-PodeLoggingMethod -File -Name 'api-requests' | New-PodeRequestLogging

    # JWT 认证中间件
    New-PodeAuthScheme -Bearer | Add-PodeAuth -Name 'jwt-auth' -Sessionless {
        param($token)
        try {
            $payload = $token | Invoke-RestMethod -Uri 'https://your-idp/.well-known/jwks.json'
            # 简化演示：直接验证 token 非空
            if ([string]::IsNullOrEmpty($token)) {
                return @{ Message = 'Token 无效' }
            }
            return @{ User = @{ Name = 'api-user'; Role = 'admin' } }
        } catch {
            return @{ Message = "认证失败: $_" }
        }
    }

    # 全局中间件：请求计时
    Add-PodeMiddleware -Name 'timer' -ScriptBlock {
        $WebEvent.Metadata['StartTime'] = [datetime]::UtcNow
    }

    # 全局中间件：CORS 支持
    Add-PodeMiddleware -Name 'cors' -ScriptBlock {
        $WebEvent.Response.Headers.Add('Access-Control-Allow-Origin', '*')
        $WebEvent.Response.Headers.Add('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE')
        if ($WebEvent.Method -eq 'OPTIONS') {
            Set-PodeResponseStatus -Code 204
        }
    }

    # 健康检查端点（无需认证）
    Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            status   = 'healthy'
            uptime   = (Get-Date) - $PodeContext.Server.StartTime
            version  = '1.0.0'
            hostname = $env:COMPUTERNAME
        }
    }

    # GET /api/items - 获取列表
    Add-PodeRoute -Method Get -Path '/api/items' -Authentication 'jwt-auth' -ScriptBlock {
        $page = [int]($WebEvent.Query['page'] ?? '1')
        $size = [int]($WebEvent.Query['size'] ?? '20')
        Write-PodeJsonResponse -Value @{
            data     = @(
                @{ id = 1; name = '项目 A'; status = 'active' }
                @{ id = 2; name = '项目 B'; status = 'archived' }
                @{ id = 3; name = '项目 C'; status = 'active' }
            )
            page    = $page
            size    = $size
            total   = 3
        }
    }

    # POST /api/items - 创建项目
    Add-PodeRoute -Method Post -Path '/api/items' -Authentication 'jwt-auth' -ScriptBlock {
        $body = $WebEvent.Data
        if (-not $body.name) {
            Set-PodeResponseStatus -Code 400
            Write-PodeJsonResponse -Value @{ error = 'name 字段必填' }
            return
        }
        Write-PodeJsonResponse -Value @{
            id      = Get-Random -Maximum 1000
            name    = $body.name
            status  = 'created'
            message = '项目创建成功'
        } -StatusCode 201
    }

    # 静态文件托管
    Add-PodeStaticRoute -Path '/docs' -Source './public'

    Write-Host "Pode API 服务运行在 http://localhost:3000" -ForegroundColor Green
}
```

启动服务后测试各端点：

```powershell
# 健康检查
Invoke-RestMethod http://localhost:3000/health | Format-List

# 获取项目列表（带认证头）
$headers = @{ Authorization = 'Bearer your-jwt-token-here' }
Invoke-RestMethod http://localhost:3000/api/items -Headers $headers

# 分页查询
Invoke-RestMethod 'http://localhost:3000/api/items?page=1&size=10' -Headers $headers

# 创建新项目
$body = @{ name = '项目 D' } | ConvertTo-Json
Invoke-RestMethod http://localhost:3000/api/items -Method Post -Headers $headers -Body $body -ContentType 'application/json'
```

执行结果示例：

```
status  : healthy
uptime  : 00:15:32.0180000
version : 1.0.0
hostname: SERVER01

data    : {@{id=1; name=项目 A; status=active}, @{id=2; name=项目 B;
          status=archived}, @{id=3; name=项目 C; status=active}}
page    : 1
size    : 20
total   : 3

id      : 847
name    : 项目 D
status  : created
message : 项目创建成功
```

## API 部署与运维

将 API 从开发脚本变成生产服务，需要考虑日志记录、健康检查、自动重启等运维需求。以下脚本展示了如何将 Pode API 注册为 Windows 服务，并添加运维监控端点。

```powershell
# 将 API 注册为 Windows 服务
function Register-ApiService {
    param(
        [string]$Name = 'PowershellApi',
        [string]$ScriptPath = 'C:\api\server.ps1'
    )

    # 使用 NSSM（Non-Sucking Service Manager）注册服务
    $nssmPath = 'C:\tools\nssm.exe'
    if (-not (Test-Path $nssmPath)) {
        Write-Warning '请先安装 NSSM: choco install nssm'
        return
    }

    # 注册服务
    & $nssmPath install $Name pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    & $nssmPath set $Name DisplayName "PowerShell REST API Service"
    & $nssmPath set $Name Description "内部工具 REST API 服务"
    & $nssmPath set $Name Start SERVICE_AUTO_START
    & $nssmPath set $Name AppDirectory (Split-Path $ScriptPath)
    & $nssmPath set $Name AppStdout (Join-Path (Split-Path $ScriptPath) 'stdout.log')
    & $nssmPath set $Name AppStderr (Join-Path (Split-Path $ScriptPath) 'stderr.log')
    & $nssmPath set $Name AppRotateFiles 1
    & $nssmPath set $Name AppRotateBytes 10485760

    Write-Host "服务 [$Name] 已注册，使用以下命令管理：" -ForegroundColor Green
    Write-Host "  启动: nssm start $Name"
    Write-Host "  停止: nssm stop $Name"
    Write-Host "  状态: nssm status $Name"
    Write-Host "  删除: nssm remove $Name confirm"
}

# 运维监控脚本：定时检查 API 可用性
function Test-ApiHealth {
    param(
        [string]$BaseUrl = 'http://localhost:3000',
        [int]$IntervalSeconds = 30
    )

    $logFile = "C:\api\health-$(Get-Date -Format 'yyyyMMdd').log"

    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-RestMethod "$BaseUrl/health" -TimeoutSec 5
            $sw.Stop()
            $latency = $sw.ElapsedMilliseconds

            $logEntry = "[$timestamp] OK | latency: ${latency}ms | uptime: $($response.uptime)"
            Write-Host $logEntry -ForegroundColor Green
            Add-Content -Path $logFile -Value $logEntry

        } catch {
            $logEntry = "[$timestamp] FAIL | error: $($_.Exception.Message)"
            Write-Host $logEntry -ForegroundColor Red
            Add-Content -Path $logFile -Value $logEntry

            # 可选：自动重启服务
            # Restart-Service -Name 'PowershellApi' -Force
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}

# 一键部署函数
function Deploy-ApiService {
    param([string]$ApiDir = 'C:\api')

    # 创建目录
    $dirs = @($ApiDir, "$ApiDir\logs", "$ApiDir\public")
    $dirs | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }

    # 部署最新代码
    Copy-Item '.\api-server.ps1' "$ApiDir\server.ps1" -Force
    Copy-Item '.\public\*' "$ApiDir\public\" -Recurse -Force

    # 注册并启动服务
    Register-ApiService -ScriptPath "$ApiDir\server.ps1"

    Write-Host "部署完成！API 地址: http://localhost:3000" -ForegroundColor Green
    Write-Host "健康检查: http://localhost:3000/health" -ForegroundColor Cyan
    Write-Host "API 文档: http://localhost:3000/docs" -ForegroundColor Cyan
}
```

执行结果示例：

```
服务 [PowershellApi] 已注册，使用以下命令管理：
  启动: nssm start PowershellApi
  停止: nssm stop PowershellApi
  状态: nssm status PowershellApi
  删除: nssm remove PowershellApi confirm

[2026-01-14 10:00:00] OK | latency: 12ms | uptime: 00:45:12.0000000
[2026-01-14 10:00:30] OK | latency: 8ms  | uptime: 00:45:42.0000000
[2026-01-14 10:01:00] OK | latency: 15ms | uptime: 00:46:12.0000000
[2026-01-14 10:01:30] FAIL | error: Unable to connect to the remote server
[2026-01-14 10:02:00] OK | latency: 10ms | uptime: 00:00:30.0000000

部署完成！API 地址: http://localhost:3000
健康检查: http://localhost:3000/health
API 文档: http://localhost:3000/docs
```

## 注意事项

1. **HttpListener 权限**：在 Windows 上监听非 localhost 地址时，需要以管理员身份运行 `netsh http add urlacl url=http://+:8080/ user=Everyone` 来预留 URL 命名空间，否则会抛出"拒绝访问"异常。

2. **并发处理**：`HttpListener` 的 `GetContext()` 是同步阻塞调用，只能一次处理一个请求。生产环境应使用 `BeginGetContext` / `EndGetContext` 异步模式，或者直接采用 Pode 框架——它内部已处理好并发问题。

3. **HTTPS 支持**：生产环境务必启用 TLS。Pode 支持 `Add-PodeEndpoint -ProtocolHttps -Certificate` 参数直接绑定证书；`HttpListener` 则需要通过 `netsh` 绑定 SSL 证书到端口。

4. **内存泄漏防范**：长时间运行的 API 服务需要注意 `IDisposable` 对象（如 `HttpListener`、`StreamReader`）的释放。使用 `try/finally` 确保资源被正确清理，或使用 `using` 语句（PowerShell 7.0+ 支持）。

5. **错误处理与日志**：永远不要让未捕获的异常终止整个服务进程。在路由处理器中使用 `try/catch`，并将错误写入结构化日志文件，方便后续通过 ELK 或 Splunk 等工具分析。

6. **跨平台部署**：如果需要在 Linux 上运行，`HttpListener` 方案可以工作（依赖 .NET 的 Unix Socket 实现），但更推荐使用 Pode——它原生支持 Linux，可以搭配 systemd 或 Docker 容器化部署，实现与 Windows 服务对等的运维体验。
