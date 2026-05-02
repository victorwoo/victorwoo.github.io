---
layout: post
date: 2025-05-20 08:00:00
updated: 2025-05-20 08:00:00
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
- container
- devops
---

_适用于 PowerShell 7.0 及以上版本_

容器化已成为现代应用部署的标准方式。Docker Desktop 在 Windows 上的普及，使得运维人员需要将 Docker 管理纳入日常自动化工作流。虽然 Docker CLI 本身足够强大，但通过 PowerShell 的管道、对象处理和脚本能力，可以构建更灵活的容器管理方案——从批量操作到日志聚合，从健康检查到自动扩缩容。

本文将讲解如何用 PowerShell 高效管理 Docker 容器、镜像、网络和数据卷。

## Docker 状态查询

通过 PowerShell 包装 Docker CLI 命令，可以获得更好的输出格式和过滤能力：

```powershell
# 检查 Docker 是否可用
docker version --format '{{.Server.Version}}'

# 查看运行中的容器（格式化为 PowerShell 对象）
docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' |
    ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            ID     = $parts[0]
            Name   = $parts[1]
            Image  = $parts[2]
            Status = $parts[3]
            Ports  = $parts[4]
        }
    } | Format-Table -AutoSize

# 查看资源使用情况
docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}' |
    ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            Container = $parts[0]
            CPU       = $parts[1]
            Memory    = $parts[2]
            NetworkIO = $parts[3]
        }
    } | Sort-Object { [double]($_.CPU -replace '%','') } -Descending |
    Format-Table -AutoSize

# 查看所有镜像
docker images --format '{{.Repository}}|{{.Tag}}|{{.Size}}|{{.CreatedSince}}' |
    ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            Repository = $parts[0]
            Tag        = $parts[1]
            Size       = $parts[2]
            Created    = $parts[3]
        }
    } | Format-Table -AutoSize
```

执行结果示例：

```
24.0.7

ID      Name       Image          Status          Ports
--      ----       -----          ------          -----
a1b2c3d web-app    nginx:latest   Up 2 hours      0.0.0.0:80->80/tcp
d4e5f6g api        myapi:v2       Up 5 hours      0.0.0.0:8080->8080/tcp
h7i8j9k redis      redis:7        Up 2 days       6379/tcp

Container CPU       Memory    NetworkIO
--------- ---       ------    ---------
api       12.45%    256MiB    1.2kB / 3.4kB
web-app   0.15%     32MiB     5.6kB / 12.3kB
redis     0.08%     48MiB     0.5kB / 0.2kB

Repository   Tag     Size    Created
----------   ---     ----    -------
nginx        latest  187MB   2 weeks ago
redis        7       138MB   3 weeks ago
myapi        v2      456MB   1 day ago
```

## 批量容器管理

在微服务架构中，经常需要对一组容器执行批量操作：

```powershell
function Get-DockerContainerSet {
    <#
    .SYNOPSIS
    获取容器集合，支持过滤
    #>
    param(
        [string]$NameFilter,
        [string]$LabelFilter,
        [ValidateSet('running','stopped','all')]
        [string]$State = 'running'
    )

    $args = @('ps', '--format', '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Labels}}')
    if ($State -eq 'all') { $args += '-a' }
    if ($State -eq 'stopped') { $args += '--filter', 'status=exited' }
    if ($LabelFilter) { $args += '--filter', "label=$LabelFilter" }

    $containers = & docker $args 2>$null |
        ForEach-Object {
            $parts = $_ -split '\|'
            [PSCustomObject]@{
                ID     = $parts[0]
                Name   = $parts[1]
                Image  = $parts[2]
                Status = $parts[3]
                Labels = $parts[4]
            }
        }

    if ($NameFilter) {
        $containers = $containers | Where-Object { $_.Name -match $NameFilter }
    }

    return $containers
}

# 批量重启特定项目容器
$webContainers = Get-DockerContainerSet -NameFilter 'web' -State 'running'
foreach ($c in $webContainers) {
    Write-Host "重启：$($c.Name)" -ForegroundColor Cyan
    docker restart $c.ID
}

# 清理所有已停止的容器
$stopped = Get-DockerContainerSet -State 'stopped'
if ($stopped) {
    Write-Host "发现 $($stopped.Count) 个已停止的容器" -ForegroundColor Yellow
    $stopped | ForEach-Object { docker rm $_.ID }
    Write-Host "已清理" -ForegroundColor Green
}

# 按标签过滤（如按项目标签）
$projectContainers = Get-DockerContainerSet -LabelFilter 'com.docker.compose.project=myapp'
$projectContainers | Format-Table -AutoSize
```

执行结果示例：

```
重启：web-frontend
重启：web-api
web-frontend
web-api

发现 3 个已停止的容器
已清理

ID      Name       Image       Status         Labels
--      ----       -----       ------         -----
a1b2c3d myapp-web  nginx       Up 2 hours     com.docker.compose.project=myapp
d4e5f6g myapp-api  myapi:v2    Up 5 hours     com.docker.compose.project=myapp
```

## 容器日志聚合

管理多个容器时，聚合日志是常见的运维需求：

```powershell
function Get-DockerLogsAggregated {
    <#
    .SYNOPSIS
    聚合多个容器的日志
    #>
    param(
        [string[]]$ContainerNames,
        [int]$Tail = 100,
        [datetime]$Since
    )

    $allLogs = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($name in $ContainerNames) {
        $args = @('logs', '--tail', $Tail, '--timestamps')
        if ($Since) {
            $args += @('--since', $Since.ToString('yyyy-MM-ddTHH:mm:ss'))
        }
        $args += $name

        $logs = & docker @args 2>&1 |
            ForEach-Object {
                if ($_ -match '^(\d{4}-\d{2}-\d{2}T[\d:.]+)\s+(.+)$') {
                    [PSCustomObject]@{
                        Timestamp  = $Matches[1]
                        Container  = $name
                        Message    = $Matches[2].Trim()
                        Level      = if ($Matches[2] -match 'ERROR|FATAL|CRITICAL') { 'Error' }
                                     elseif ($Matches[2] -match 'WARN') { 'Warning' }
                                     else { 'Info' }
                    }
                }
            }

        $allLogs.AddRange($logs)
    }

    $allLogs | Sort-Object Timestamp | Format-Table -AutoSize
}

# 聚合 Web 应用相关容器的日志
Get-DockerLogsAggregated -ContainerNames @('web-app', 'api', 'redis') -Tail 50 |
    Where-Object Level -ne 'Info' |
    Format-Table -AutoSize

# 搜索特定错误
$allLogs = Get-DockerLogsAggregated -ContainerNames @('web-app', 'api') -Since (Get-Date).AddHours(-1)
$allLogs | Where-Object { $_.Message -match 'timeout|connection refused|OOM' }
```

执行结果示例：

```
Timestamp            Container Message                           Level
---------            --------- -------                           -----
2025-05-20T08:15:32Z api       ERROR: Database connection timeout Error
2025-05-20T08:15:35Z api       WARN: Retrying connection...      Warning
2025-05-20T08:20:18Z web-app   ERROR: Upstream timeout (504)     Error

Timestamp            Container Message
---------            --------- -------
2025-05-20T08:15:32Z api       ERROR: Database connection timeout
2025-05-20T08:20:18Z web-app   ERROR: Upstream timeout (504)
```

## 容器健康检查

编写健康检查脚本，监控容器运行状态并在异常时告警：

```powershell
function Test-DockerHealth {
    <#
    .SYNOPSIS
    检查所有容器的健康状态
    #>
    param(
        [string]$WebhookUrl
    )

    $containers = & docker ps -a --format '{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}' |
        ForEach-Object {
            $parts = $_ -split '\|'
            [PSCustomObject]@{
                ID     = $parts[0]
                Name   = $parts[1]
                Status = $parts[2]
                Image  = $parts[3]
            }
        }

    $unhealthy = @()
    $healthy   = @()

    foreach ($c in $containers) {
        $inspect = docker inspect $c.ID --format '{{.State.Status}}|{{.State.Health.Status}}' 2>$null
        if ($inspect) {
            $stateParts = $inspect -split '\|'
            $c | Add-Member -NotePropertyName 'State' -NotePropertyValue $stateParts[0] -Force
            $c | Add-Member -NotePropertyName 'Health' -NotePropertyValue $stateParts[1] -Force
        }

        if ($c.State -ne 'running' -or $c.Health -eq 'unhealthy') {
            $unhealthy += $c
        } else {
            $healthy += $c
        }
    }

    Write-Host "========== Docker 健康报告 ==========" -ForegroundColor Cyan
    Write-Host "健康：$($healthy.Count) | 异常：$($unhealthy.Count)" -ForegroundColor $(if ($unhealthy.Count -gt 0) { 'Red' } else { 'Green' })

    if ($unhealthy) {
        Write-Host "`n异常容器：" -ForegroundColor Red
        $unhealthy | Format-Table Name, State, Health, Image -AutoSize

        # 发送告警
        if ($WebhookUrl) {
            $body = @{
                text = "Docker 告警：$($unhealthy.Count) 个容器异常`n" + `
                       ($unhealthy | ForEach-Object { "- $($_.Name): $($_.State)/$($_.Health)" }) -join "`n"
            } | ConvertTo-Json

            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
        }
    }

    return @{
        Healthy   = $healthy
        Unhealthy = $unhealthy
    }
}

Test-DockerHealth -WebhookUrl 'https://hooks.slack.com/services/xxx'
```

执行结果示例：

```
========== Docker 健康报告 ==========
健康：5 | 异常：2

异常容器：
Name     State    Health     Image
----     -----    ------     -----
db-main  running  unhealthy  postgres:16
worker   exited   unhealthy  myapp-worker:v3
```

## 镜像清理与维护

Docker 镜像会占用大量磁盘空间，定期清理是必要的维护操作：

```powershell
function Optimize-DockerImages {
    <#
    .SYNOPSIS
    清理无用的 Docker 镜像
    #>
    param(
        [int]$KeepLastVersions = 3
    )

    # 显示当前磁盘占用
    $diskUsage = docker system df --format '{{.Type}}|{{.Size}}|{{.Reclaimable}}' |
        ForEach-Object {
            $parts = $_ -split '\|'
            [PSCustomObject]@{
                Type        = $parts[0]
                Size        = $parts[1]
                Reclaimable = $parts[2]
            }
        }
    $diskUsage | Format-Table -AutoSize

    # 清理悬空镜像（没有标签的）
    Write-Host "`n清理悬空镜像..." -ForegroundColor Yellow
    docker image prune -f

    # 按仓库名分组，保留最近的 N 个版本
    $images = & docker images --format '{{.Repository}}|{{.Tag}}|{{.ID}}|{{.CreatedSince}}' |
        ForEach-Object {
            $parts = $_ -split '\|'
            [PSCustomObject]@{
                Repository = $parts[0]
                Tag        = $parts[1]
                ID         = $parts[2]
                Created    = $parts[3]
            }
        }

    $groups = $images | Where-Object { $_.Tag -ne '<none>' } | Group-Object Repository

    foreach ($group in $groups) {
        if ($group.Count -gt $KeepLastVersions) {
            $toRemove = $group.Group |
                Sort-Object Created |
                Select-Object -SkipLast $KeepLastVersions

            foreach ($img in $toRemove) {
                Write-Host "  移除旧镜像：$($img.Repository):$($img.Tag)" -ForegroundColor DarkGray
                docker rmi $img.ID 2>$null | Out-Null
            }
        }
    }

    # 最终清理
    docker system prune -f 2>$null | Out-Null
    Write-Host "`n清理完成" -ForegroundColor Green

    # 显示清理后的空间
    docker system df
}

Optimize-DockerImages -KeepLastVersions 3
```

执行结果示例：

```
TYPE      SIZE      RECLAIMABLE
Images    12.45GB   4.23GB (34%)
Containers 0B       0B
Local Volumes 1.2GB  456MB (38%)

清理悬空镜像...
  移除旧镜像：myapp:v1
  移除旧镜像：myapp:v1.5
  移除旧镜像：nginx:1.24

清理完成
TYPE            TOTAL   ACTIVE  SIZE      RECLAIMABLE
Images          8       5       8.22GB    1.2GB (15%)
Containers      5       5       0B        0B
Local Volumes   3       3       1.2GB     0B
```

## 注意事项

1. **Docker Desktop 依赖**：Windows 上 Docker Desktop 需要 WSL2 或 Hyper-V，确保系统支持
2. **管道编码**：Docker CLI 输出可能包含 ANSI 转义码，使用 `--no-trunc` 和 `--format` 模板获取干净输出
3. **并发操作**：大量容器操作时避免逐个串行执行，考虑并行处理（使用 `Start-Job` 或 Runspace）
4. **日志量控制**：生产容器日志量可能非常大，使用 `-Tail` 和 `-Since` 参数限制查询范围
5. **镜像安全**：定期扫描镜像漏洞，使用 `docker scout` 或 Trivy 等工具
6. **资源限制**：运行容器时始终设置 `-m`（内存限制）和 `--cpus`（CPU 限制），防止容器耗尽宿主机资源
