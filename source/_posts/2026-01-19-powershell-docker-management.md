---
layout: post
date: 2026-01-19 08:00:00
updated: 2026-01-19 08:00:00
title: "PowerShell 技能连载 - Docker 容器管理"
description: PowerTip of the Day - Docker Container Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- docker
- containers
- devops
- automation
---

_适用于 PowerShell 7.0 及以上版本_

容器化已成为现代应用部署的主流方式。无论是微服务架构、CI/CD 流水线还是本地开发环境，Docker 都扮演着核心角色。在 Windows 和跨平台场景中，PowerShell 凭借强大的对象管道和丰富的模块生态，能够将 Docker 操作无缝融入自动化运维流程。

传统的容器管理往往依赖手动执行 `docker` 命令，效率低下且容易出错。而通过 PowerShell 脚本化封装，我们可以实现镜像构建的标准化、容器编排的可重复部署、以及资源清理的定时任务调度。本文将从基础操作、Docker Compose 编排和运维工具集三个维度，展示如何用 PowerShell 打造完整的容器管理方案。

掌握这些技巧后，你可以将日常的容器运维工作转化为可版本控制、可审计的自动化脚本，真正实现"基础设施即代码"的容器管理理念。

## 容器基础操作

在日常开发中，我们频繁地进行镜像拉取、容器启停和日志查看等操作。下面的脚本将这些常见操作封装为一组可复用的函数，并支持管道操作和结构化输出。

```powershell
function Get-DockerImageList {
    [CmdletBinding()]
    param(
        [string]$Filter,
        [switch]$DanglingOnly
    )

    $args = @('image', 'ls', '--format', '{{.Repository}}:{{.Tag}}|{{.ID}}|{{.Size}}|{{.CreatedSince}}')
    if ($DanglingOnly) {
        $args += @('--filter', 'dangling=true')
    }

    $result = docker $args 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "无法获取镜像列表: $result"
        return
    }

    $images = $result | ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            Repository = $parts[0]
            ImageId    = $parts[1]
            Size       = $parts[2]
            Created    = $parts[3]
        }
    }

    if ($Filter) {
        $images = $images | Where-Object { $_.Repository -like "*$Filter*" }
    }

    $images
}

function Start-DockerApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Image,

        [string]$Name = "app-$(Get-Random -Maximum 9999)",
        [int]$Port = 8080,
        [string]$Volume,
        [hashtable]$EnvVars,
        [string]$Network = 'bridge'
    )

    $dockerArgs = @('run', '-d', '--name', $Name, '--restart', 'unless-stopped')

    # 端口映射
    $dockerArgs += @('-p', "${Port}:${Port}")

    # 挂载卷
    if ($Volume) {
        if (-not (Test-Path $Volume)) {
            New-Item -ItemType Directory -Path $Volume -Force | Out-Null
            Write-Host "已创建挂载目录: $Volume" -ForegroundColor Yellow
        }
        $dockerArgs += @('-v', "${Volume}:/app/data")
    }

    # 环境变量
    if ($EnvVars) {
        foreach ($key in $EnvVars.Keys) {
            $dockerArgs += @('-e', "${key}=$($EnvVars[$key])")
        }
    }

    # 网络
    $dockerArgs += @('--network', $Network)
    $dockerArgs += $Image

    Write-Host "正在启动容器 [$Name]..." -ForegroundColor Cyan
    $containerId = docker $dockerArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "容器已启动: $containerId" -ForegroundColor Green
        return $containerId
    } else {
        Write-Error "启动失败: $containerId"
    }
}

function Get-DockerContainerLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [int]$Tail = 50,
        [switch]$Follow,
        [datetime]$Since
    )

    $args = @('logs')
    if ($Tail -gt 0) { $args += @('--tail', $Tail) }
    if ($Follow) { $args += '--follow' }
    if ($Since) { $args += @('--since', $Since.ToString('yyyy-MM-ddTHH:mm:ss')) }
    $args += $Name

    docker $args 2>&1
}
```

上面的代码定义了三个核心函数：`Get-DockerImageList` 以结构化对象形式输出镜像信息，支持按名称过滤和仅显示悬空镜像；`Start-DockerApp` 封装了容器启动流程，自动处理端口映射、卷挂载、环境变量注入等常见配置；`Get-DockerContainerLog` 提供灵活的日志查看方式，支持尾部行数、实时跟踪和时间过滤。

执行结果示例：

```
PS> Get-DockerImageList -Filter 'nginx'

Repository       ImageId      Size    Created
----------       -------      ----    -------
nginx:latest      a8758716bb   187MB   3 days ago
nginx:alpine      c31a4dc1b5   42MB    2 weeks ago

PS> Start-DockerApp -Image 'nginx:alpine' -Name 'web-test' -Port 8080 -Volume 'C:\data\web' -EnvVars @{ 'NGINX_HOST' = 'localhost' }

正在启动容器 [web-test]...
已创建挂载目录: C:\data\web
容器已启动: d4f5a2c8e1b3...

PS> Get-DockerContainerLog -Name 'web-test' -Tail 10

2026/01/19 08:15:32 [notice] 1#1: start worker process 32
2026/01/19 08:15:32 [notice] 1#1: start worker process 33
192.168.1.100 - - [19/Jan/2026:08:16:01 +0000] "GET / HTTP/1.1" 200 615
```

## Docker Compose 编排与 PowerShell 自动化

在多服务场景下，Docker Compose 是首选的编排工具。我们可以用 PowerShell 动态生成 Compose 文件、管理服务生命周期，并将环境配置与部署流程解耦，实现可重复的一键部署。

```powershell
function New-DockerComposeConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,

        [string]$OutputPath = '.',
        [string]$AppImage = 'myapp:latest',
        [string]$DbImage = 'postgres:16-alpine',
        [string]$RedisImage = 'redis:7-alpine',
        [int]$AppPort = 3000
    )

    $compose = @{
        services = @{
            app = @{
                image       = $AppImage
                ports       = @("${AppPort}:3000")
                environment = @{
                    NODE_ENV      = 'production'
                    DATABASE_URL  = "postgresql://appuser:secret@db:5432/${ProjectName}"
                    REDIS_URL     = 'redis://redis:6379'
                }
                depends_on  = @(
                    @{ service = 'db'; condition = 'service_healthy' }
                    @{ service = 'redis'; condition = 'service_started' }
                )
                restart     = 'unless-stopped'
                deploy = @{
                    resources = @{
                        limits = @{
                            memory = '512M'
                            cpus   = '1.0'
                        }
                    }
                }
            }
            db = @{
                image   = $DbImage
                volumes = @("${ProjectName}-db-data:/var/lib/postgresql/data")
                environment = @{
                    POSTGRES_DB       = $ProjectName
                    POSTGRES_USER     = 'appuser'
                    POSTGRES_PASSWORD = 'secret'
                }
                healthcheck = @{
                    test     = @('CMD-SHELL', 'pg_isready -U appuser -d ' + $ProjectName)
                    interval = '10s'
                    timeout  = '5s'
                    retries  = 5
                }
                restart  = 'unless-stopped'
            }
            redis = @{
                image   = $RedisImage
                volumes = @("${ProjectName}-redis-data:/data")
                command = 'redis-server --appendonly yes --maxmemory 128mb --maxmemory-policy allkeys-lru'
                restart = 'unless-stopped'
            }
        }
        volumes = @{
            "${ProjectName}-db-data"    = @{}
            "${ProjectName}-redis-data" = @{}
        }
    }

    $outputFile = Join-Path $OutputPath "docker-compose-${ProjectName}.yml"
    $compose | ConvertTo-Yaml | Set-Content -Path $outputFile -Encoding UTF8
    Write-Host "已生成 Compose 文件: $outputFile" -ForegroundColor Green

    return $outputFile
}

function Invoke-DockerCompose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComposeFile,

        [ValidateSet('Up', 'Down', 'Restart', 'Pull', 'Ps')]
        [string]$Action = 'Up',

        [switch]$Build,
        [switch]$Detach
    )

    $baseArgs = @('-f', $ComposeFile)

    switch ($Action) {
        'Up' {
            $args = $baseArgs + @('up')
            if ($Detach) { $args += '-d' }
            if ($Build) { $args += '--build' }
            Write-Host "正在启动服务..." -ForegroundColor Cyan
        }
        'Down' {
            $args = $baseArgs + @('down', '--volumes', '--remove-orphans')
            Write-Host "正在停止并清理服务..." -ForegroundColor Yellow
        }
        'Restart' {
            $args = $baseArgs + @('restart')
            Write-Host "正在重启服务..." -ForegroundColor Cyan
        }
        'Pull' {
            $args = $baseArgs + @('pull')
            Write-Host "正在拉取最新镜像..." -ForegroundColor Cyan
        }
        'Ps' {
            $args = $baseArgs + @('ps', '--format', 'table {{.Name}}\t{{.Status}}\t{{.Ports}}')
        }
    }

    docker $args 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compose 操作 [$Action] 执行失败"
    }
}
```

这段代码的核心思路是将 Compose 配置参数化。`New-DockerComposeConfig` 根据项目名称和镜像版本动态生成 YAML 文件，包含健康检查、资源限制和持久化卷定义。`Invoke-DockerCompose` 对 `docker compose` 子命令做了一层 PowerShell 封装，支持启动、停止、重启、拉取镜像和查看状态等操作，每个动作都有清晰的状态提示。

执行结果示例：

```
PS> New-DockerComposeConfig -ProjectName 'myblog' -AppImage 'myblog:v2.1' -AppPort 8080

已生成 Compose 文件: .\docker-compose-myblog.yml

PS> Invoke-DockerCompose -ComposeFile '.\docker-compose-myblog.yml' -Action Up -Detach -Build

正在启动服务...
[+] Building 15.2s
 => [app internal] load build definition from Dockerfile
 => [app] => exporting to image
[+] Running 4/4
 ✔ Network myblog_default    Created
 ✔ Container myblog-redis-1  Started
 ✔ Container myblog-db-1     Healthy
 ✔ Container myblog-app-1    Started

PS> Invoke-DockerCompose -ComposeFile '.\docker-compose-myblog.yml' -Action Ps

NAME               STATUS              PORTS
myblog-app-1       Up 2 minutes        0.0.0.0:8080->3000/tcp
myblog-db-1        Up 2 minutes (healthy) 5432/tcp
myblog-redis-1     Up 2 minutes        6379/tcp
```

## 容器运维工具集

随着容器数量增长，定期清理无用资源、监控容器健康状态和检查镜像安全变得至关重要。下面的工具集提供了批量清理、资源监控和安全扫描的自动化能力。

```powershell
function Remove-DockerOrphanResources {
    [CmdletBinding()]
    param(
        [switch]$IncludeVolumes,
        [switch]$DryRun
    )

    $report = [System.Text.StringBuilder]::new()
    [void]$report.AppendLine("=== Docker 资源清理报告 ===")
    [void]$report.AppendLine("执行时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n")

    # 清理已停止的容器
    $stopped = docker ps -aq --filter 'status=exited' 2>$null
    if ($stopped) {
        $count = ($stopped | Measure-Object).Count
        [void]$report.AppendLine("[容器] 发现 $count 个已停止的容器")
        if (-not $DryRun) {
            docker rm $stopped 2>$null | Out-Null
            [void]$report.AppendLine("  -> 已清理")
        }
    }

    # 清理悬空镜像
    $dangling = docker images -q --filter 'dangling=true' 2>$null
    if ($dangling) {
        $count = ($dangling | Measure-Object).Count
        [void]$report.AppendLine("[镜像] 发现 $count 个悬空镜像")
        if (-not $DryRun) {
            docker rmi $dangling 2>$null | Out-Null
            [void]$report.AppendLine("  -> 已清理")
        }
    }

    # 清理未使用的网络
    $networks = docker network ls --filter 'type=custom' -q 2>$null
    if ($networks) {
        $count = ($networks | Measure-Object).Count
        [void]$report.AppendLine("[网络] 发现 $count 个自定义网络")
        if (-not $DryRun) {
            docker network prune -f 2>$null | Out-Null
            [void]$report.AppendLine("  -> 已清理")
        }
    }

    # 清理未使用的卷
    if ($IncludeVolumes) {
        $volumes = docker volume ls -q --filter 'dangling=true' 2>$null
        if ($volumes) {
            $count = ($volumes | Measure-Object).Count
            [void]$report.AppendLine("[卷] 发现 $count 个悬空卷")
            if (-not $DryRun) {
                docker volume prune -f 2>$null | Out-Null
                [void]$report.AppendLine("  -> 已清理")
            }
        }
    }

    # 回收磁盘空间
    if (-not $DryRun) {
        [void]$report.AppendLine("`n正在回收磁盘空间...")
        $reclaim = docker system df --format '{{.Reclaimable}}' 2>$null
        docker system prune -f 2>$null | Out-Null
        [void]$report.AppendLine("可回收空间: $($reclaim -join ', ')")
    } else {
        [void]$report.AppendLine("`n[模拟模式] 未执行实际清理操作")
    }

    $report.ToString()
}

function Get-DockerResourceMonitor {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 5,
        [int]$Count = 12
    )

    for ($i = 0; $i -lt $Count; $i++) {
        $timestamp = Get-Date -Format 'HH:mm:ss'

        $stats = docker stats --no-stream --format `
            '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.PIDs}}' 2>$null

        if ($i -eq 0) {
            Write-Host ("{0,-8} {1,-20} {2,-10} {3,-15} {4,-8} {5,-20} {6,-6}" -f `
                '时间', '容器', 'CPU', '内存使用', '内存%', '网络IO', 'PID') `
                -ForegroundColor Cyan
            Write-Host ('-' * 90)
        }

        $stats | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Count -eq 6) {
                Write-Host ("{0,-8} {1,-20} {2,-10} {3,-15} {4,-8} {5,-20} {6,-6}" -f `
                    $timestamp, $parts[0], $parts[1], $parts[2], $parts[3], $parts[4], $parts[5])
            }
        }

        if ($i -lt $Count - 1) {
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}

function Test-DockerImageSecurity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Image,

        [string]$Severity = 'HIGH,CRITICAL',
        [switch]$SkipDbUpdate
    )

    Write-Host "正在扫描镜像: $Image" -ForegroundColor Cyan
    Write-Host "严重级别过滤: $Severity`n"

    # 检查 trivy 是否安装
    $trivy = Get-Command trivy -ErrorAction SilentlyContinue
    if (-not $trivy) {
        Write-Warning "未找到 trivy 扫描器，使用 docker scout 替代"
        $scanResult = docker scout cves $Image 2>&1
    } else {
        $trivyArgs = @('image', '--severity', $Severity, '--format', 'table', $Image)
        if ($SkipDbUpdate) { $trivyArgs += '--skip-db-update' }
        $scanResult = trivy $trivyArgs 2>&1
    }

    $scanResult | ForEach-Object { Write-Host $_ }

    # 提取漏洞摘要
    $criticalCount = ($scanResult | Select-String -Pattern 'CRITICAL' -SimpleMatch).Count
    $highCount = ($scanResult | Select-String -Pattern 'HIGH' -SimpleMatch).Count

    [PSCustomObject]@{
        Image     = $Image
        Critical  = $criticalCount
        High      = $highCount
        ScanTime  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Status    = if ($criticalCount -gt 0) { 'NEEDS ATTENTION' } else { 'ACCEPTABLE' }
    }
}
```

这套工具集包含三个核心功能：`Remove-DockerOrphanResources` 生成详细的清理报告，支持 DryRun 模式预览将要删除的资源，避免误删；`Get-DockerResourceMonitor` 以固定间隔采集所有运行中容器的 CPU、内存和网络指标，适合排查性能瓶颈；`Test-DockerImageSecurity` 调用 Trivy 或 Docker Scout 对镜像进行漏洞扫描，按严重级别过滤结果。

执行结果示例：

```
PS> Remove-DockerOrphanResources -DryRun

=== Docker 资源清理报告 ===
执行时间: 2026-01-19 08:30:00

[容器] 发现 3 个已停止的容器
[镜像] 发现 5 个悬空镜像
[网络] 发现 2 个自定义网络

[模拟模式] 未执行实际清理操作

PS> Get-DockerResourceMonitor -Count 3

时间     容器                 CPU        内存使用         内存%     网络IO               PID
------------------------------------------------------------------------------------------
08:30:05 myblog-app-1         2.35%      128MiB/512MiB   25.00%   1.2kB/856B           18
08:30:05 myblog-db-1          0.82%      89MiB/256MiB    34.77%   456B/312B            12
08:30:05 myblog-redis-1       0.15%      12MiB/128MiB    9.38%    234B/156B            6
08:30:10 myblog-app-1         3.12%      132MiB/512MiB   25.78%   2.1kB/1.1kB          18
08:30:10 myblog-db-1          1.05%      91MiB/256MiB    35.55%   512B/378B            12
08:30:10 myblog-redis-1       0.18%      12MiB/128MiB    9.38%    256B/178B            6

PS> Test-DockerImageSecurity -Image 'myblog:v2.1' -Severity 'HIGH,CRITICAL'

正在扫描镜像: myblog:v2.1
严重级别过滤: HIGH,CRITICAL

Total: 3 (HIGH: 2, CRITICAL: 1)

Image     Critical High ScanTime           Status
-----     -------- ---- --------           ------
myblog:v2.1        1    2 2026-01-19 08:35:12 NEEDS ATTENTION
```

## 注意事项

1. **Docker 服务依赖**：运行脚本前确保 Docker Desktop 或 Docker Engine 已启动并正常运行，可通过 `docker info` 命令快速验证，脚本中建议加入服务状态检查逻辑。

2. **ConvertTo-Yaml 模块**：`New-DockerComposeConfig` 函数依赖 `powershell-yaml` 模块来序列化 YAML，使用前需执行 `Install-Module -Name powershell-yaml -Scope CurrentUser` 安装。

3. **权限与安全**：容器操作通常需要管理员或 docker 用户组权限，在 CI/CD 环境中注意凭据管理，避免在 Compose 文件中硬编码数据库密码，应使用 Docker Secrets 或环境变量文件。

4. **资源清理的破坏性**：`Remove-DockerOrphanResources` 的 `-IncludeVolumes` 参数会删除未挂载的卷数据，生产环境中务必先使用 `-DryRun` 预览，确认无误后再执行实际清理。

5. **监控性能开销**：`Get-DockerResourceMonitor` 通过 `docker stats` 采集指标会引入轻微的 CPU 开销，在容器数量超过 50 个时建议降低采集频率或仅监控关键服务。

6. **镜像扫描工具**：`Test-DockerImageSecurity` 优先使用 Trivy（开源免费），备选 Docker Scout（需 Docker Desktop 许可）。对于企业级场景，可集成 Aqua、Snyk 等商业扫描平台获取更全面的漏洞情报。
