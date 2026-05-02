---
layout: post
date: 2025-04-01 08:00:00
updated: 2025-04-01 08:00:00
title: "PowerShell 技能连载 - Docker 容器管理"
description: PowerTip of the Day - Managing Docker Containers with PowerShell
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

_适用于 Docker 20.10+ 及 PowerShell 7.0+_

容器化部署已经从尝鲜走向了主流。无论是微服务架构还是 CI/CD 流水线，Docker 几乎无处不在。然而，日常运维中频繁手动输入 `docker run`、`docker logs` 等命令不仅效率低下，而且容易出错。PowerShell 凭借其强大的对象管道和函数封装能力，非常适合用来编排 Docker 操作——把重复性工作交给脚本，让运维人员专注于真正重要的事情。

本文将从环境检查、容器生命周期管理、批量巡检、镜像清理、日志收集五个方面，逐步展示如何用 PowerShell 高效管理 Docker 容器，最后给出一个完整的 Nginx 部署实战示例。

<!-- more -->

## 检查 Docker 环境

动手管理容器之前，首先要确认 Docker 引擎是否正常运行、磁盘空间是否充足、当前有多少容器在跑。下面的函数一次性完成这三项检查，并将结果以表格形式输出。

```powershell
function Test-DockerEnvironment {
    $result = @()

    # 检查 Docker 引擎版本
    try {
        $version = docker version --format "{{.Server.Version}}" 2>$null
        $result += [PSCustomObject]@{
            Check  = "Docker 引擎"
            Status = if ($version) { "运行中 v$version" } else { "未运行" }
        }
    } catch {
        $result += [PSCustomObject]@{ Check = "Docker 引擎"; Status = "未安装" }
    }

    # 查看磁盘占用
    $diskUsage = docker system df --format "{{.Type}}: {{.Size}}" 2>$null
    $result += [PSCustomObject]@{ Check = "磁盘占用"; Status = ($diskUsage -join "; ") }

    # 统计运行中容器数量
    $running = docker ps -q 2>$null
    $result += [PSCustomObject]@{ Check = "运行中容器"; Status = "$(@($running).Count) 个" }

    return $result | Format-Table -AutoSize
}
```

调用该函数后，输出结果一目了然：

```text
Check        Status
-----        ------
Docker 引擎  运行中 v24.0.7
磁盘占用     Images: 1.2GB; Containers: 340MB; Local Volumes: 0B
运行中容器   3 个
```

如果引擎状态显示"未运行"或"未安装"，需要先排查 Docker 服务再继续。

## 容器生命周期管理

日常操作中，创建容器往往是最频繁的动作。直接拼接 `docker run` 命令不仅参数冗长，还容易遗漏端口或环境变量。我们将它封装为 PowerShell 函数，通过命名参数来调用。

```powershell
function New-DockerAppContainer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Image,
        [hashtable]$PortMappings,
        [hashtable]$EnvVars,
        [string[]]$Volumes,
        [string]$Network = "bridge",
        [string]$RestartPolicy = "unless-stopped"
    )

    $args = @("run", "-d", "--name", $Name, "--restart", $RestartPolicy)

    # 逐项添加端口映射
    foreach ($port in $PortMappings.GetEnumerator()) {
        $args += @("-p", "$($port.Key):$($port.Value)")
    }
    # 逐项添加环境变量
    foreach ($env in $EnvVars.GetEnumerator()) {
        $args += @("-e", "$($env.Key)=$($env.Value)")
    }
    # 逐项添加数据卷挂载
    foreach ($vol in $Volumes) {
        $args += @("-v", $vol)
    }

    $args += @("--network", $Network, $Image)

    $containerId = & docker $args 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "容器 $Name 已启动: $containerId" -ForegroundColor Green
        return $containerId.Substring(0, 12)
    } else {
        Write-Host "启动失败: $containerId" -ForegroundColor Red
    }
}
```

使用这个函数创建一个 Nginx 容器，将宿主机 8080 端口映射到容器 80 端口，并挂载自定义网页目录：

```powershell
New-DockerAppContainer -Name "my-nginx" `
    -Image "nginx:latest" `
    -PortMappings @{ 8080 = 80 } `
    -EnvVars @{ NGINX_HOST = "example.com" } `
    -Volumes @("/data/nginx/html:/usr/share/nginx/html")
```

执行结果如下，返回截断后的容器 ID 表示创建成功：

```text
容器 my-nginx 已启动: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8g9h0
a1b2c3d4e5f6
```

容器创建之后，停止、重启、移除等操作也很常用：

```powershell
# 停止容器
docker stop my-nginx

# 重新启动已停止的容器
docker start my-nginx

# 移除容器（需先停止）
docker rm my-nginx
```

每个命令都会返回容器名称或 ID，确认操作已生效。

## 批量容器巡检

当服务器上同时运行着多个容器时，逐个执行 `docker stats` 查看资源占用效率很低。下面的函数能一次性生成所有容器的 CPU、内存使用报告：

```powershell
function Get-DockerContainerReport {
    param([switch]$All)  # 加 -All 参数可包含已停止的容器

    $format = "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}"
    $filter = if ($All) { "docker ps -a" } else { "docker ps" }
    $containers = Invoke-Expression "$filter --format '$format'" 2>$null

    $report = foreach ($line in $containers) {
        $parts = $line -split '\|'
        $id = $parts[0].Substring(0, [Math]::Min(12, $parts[0].Length))

        # 获取该容器的实时资源占用（不使用流式输出）
        $stats = docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" $id 2>$null
        $statParts = if ($stats) { $stats -split '\|' } else { @("N/A", "N/A") }

        [PSCustomObject]@{
            Container = $parts[1]
            Image     = $parts[2]
            Status    = $parts[3]
            CPU       = $statParts[0]
            Memory    = $statParts[1]
            Ports     = $parts[4]
        }
    }
    return $report | Format-Table -AutoSize
}
```

执行后可以得到一张汇总表格，快速定位资源异常的容器：

```text
Container Image         Status      CPU    Memory          Ports
--------- -----         ------      ---    ------          -----
my-nginx  nginx:latest  Up 2 hours  0.01%  4.2MiB / 16GiB  0.0.0.0:8080->80/tcp
my-redis  redis:7       Up 5 hours  0.12%  8.5MiB / 16GiB  6379/tcp
my-api    myapp:v2      Up 1 hour   2.35%  128MiB / 16GiB  0.0.0.0:3000->3000/tcp
```

如果发现某个容器 CPU 或内存占用异常偏高，可以立即用日志函数排查原因。

## 镜像清理

反复构建镜像会产生大量无标签的悬空镜像（dangling images），它们不参与任何容器的运行，却持续占用磁盘空间。定期清理是保持环境整洁的好习惯。

```powershell
function Remove-DockerDanglingImages {
    # 查找所有悬空镜像
    $dangling = docker images -f "dangling=true" -q 2>$null

    if ($dangling) {
        # 计算悬空镜像总大小
        $size = docker images -f "dangling=true" --format "{{.Size}}" 2>$null
        $totalMB = ($size | ForEach-Object {
            if ($_ -match '(\d+\.?\d*)\s*(GB|MB)') {
                if ($Matches[2] -eq "GB") { [double]$Matches[1] * 1024 }
                else { [double]$Matches[1] }
            }
        } | Measure-Object -Sum).Sum

        Write-Host "发现 $($dangling.Count) 个悬空镜像，约 $([math]::Round($totalMB, 0)) MB" -ForegroundColor Yellow
        $confirm = Read-Host "是否清理? (y/n)"

        if ($confirm -eq "y") {
            docker image prune -f 2>$null
            Write-Host "清理完成" -ForegroundColor Green
        }
    } else {
        Write-Host "没有悬空镜像，磁盘很干净" -ForegroundColor Green
    }
}
```

执行效果如下，可以看到释放了多少空间：

```text
发现 7 个悬空镜像，约 1420 MB
是否清理? (y/n): y
Deleted Images:
untagged: <none>@<none>
deleted: sha256:abc123...
Total reclaimed space: 1.38GB
清理完成
```

建议将这个函数加入定期维护脚本，避免磁盘被无用镜像占满。

## 容器日志收集

排查容器故障时，日志是最关键的信息来源。`docker logs` 命令功能丰富但参数不好记，我们用 PowerShell 函数封装常用选项：按条数截取、按时间过滤、导出到文件。

```powershell
function Get-DockerContainerLog {
    param(
        [Parameter(Mandatory)][string]$ContainerName,
        [int]$Tail = 100,          # 默认取最近 100 条
        [datetime]$Since,          # 可选：只取此时间之后的日志
        [string]$OutputPath        # 可选：导出到文件路径
    )

    $args = @("logs", "--tail", $Tail)
    if ($Since) {
        $args += @("--since", $Since.ToString("yyyy-MM-ddTHH:mm:ss"))
    }
    $args += $ContainerName

    $logs = & docker $args 2>&1

    if ($OutputPath) {
        $logs | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "日志已保存到: $OutputPath"
    } else {
        return $logs
    }
}
```

查看最近 5 条日志：

```powershell
Get-DockerContainerLog -ContainerName "my-nginx" -Tail 5
```

```text
192.168.1.100 - - [01/Apr/2025:10:23:45 +0000] "GET / HTTP/1.1" 200 612 "-"
"Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
192.168.1.101 - - [01/Apr/2025:10:24:01 +0000] "GET /api/health HTTP/1.1" 200 2 "-"
"curl/7.88.1"
```

如果想一次性导出所有运行中容器的日志用于归档分析，可以使用以下批量导出函数：

```powershell
function Export-AllContainerLogs {
    param([string]$OutputDir = "./container_logs")

    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

    $containers = docker ps --format "{{.Names}}" 2>$null
    foreach ($name in $containers) {
        $logFile = Join-Path $OutputDir "${name}_$(Get-Date -Format 'yyyyMMdd').log"
        Get-DockerContainerLog -ContainerName $name -Tail 1000 -OutputPath $logFile
    }
    Write-Host "所有容器日志已导出到: $OutputDir" -ForegroundColor Green
}
```

```text
日志已保存到: ./container_logs/my-nginx_20250401.log
日志已保存到: ./container_logs/my-redis_20250401.log
日志已保存到: ./container_logs/my-api_20250401.log
所有容器日志已导出到: ./container_logs
```

## 完整实战：部署 Nginx 并验证

最后，我们把前面介绍的功能串联起来，演示一个从环境检查到服务上线的完整流程。

```powershell
# 第一步：确认 Docker 环境
Test-DockerEnvironment
```

```text
Check        Status
-----        ------
Docker 引擎  运行中 v24.0.7
磁盘占用     Images: 320MB; Containers: 0B; Local Volumes: 0B
运行中容器   0 个
```

环境正常，继续创建容器：

```powershell
# 第二步：创建 Nginx 容器
New-DockerAppContainer -Name "my-nginx" `
    -Image "nginx:latest" `
    -PortMappings @{ 8080 = 80 } `
    -EnvVars @{ NGINX_HOST = "localhost" } `
    -Volumes @("/data/nginx/html:/usr/share/nginx/html")
```

```text
容器 my-nginx 已启动: f3a1b2c3d4e5f6a7b8c9d0e1f2a3b4
f3a1b2c3d4e5
```

容器启动后，检查运行状态：

```powershell
# 第三步：查看容器巡检报告
Get-DockerContainerReport
```

```text
Container Image         Status       CPU    Memory          Ports
--------- -----         ------       ---    ------          -----
my-nginx  nginx:latest  Up 30 secs   0.00%  3.8MiB / 16GiB  0.0.0.0:8080->80/tcp
```

访问服务确认是否正常响应：

```powershell
# 第四步：验证服务是否可达
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing |
    Select-Object StatusCode, StatusDescription
```

```text
StatusCode StatusDescription
---------- ------------------
       200 OK
```

收到 200 响应，Nginx 已成功运行。最后查看一下访问日志：

```powershell
# 第五步：查看最新日志
Get-DockerContainerLog -ContainerName "my-nginx" -Tail 3
```

```text
192.168.1.50 - - [01/Apr/2025:08:00:12 +0000] "GET / HTTP/1.1" 200 612 "-"
"Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
```

## 小结

通过 PowerShell 封装 Docker 命令，我们获得了几个关键优势：参数化调用取代了冗长的命令行拼接；对象化输出让结果可以直接参与管道操作；函数封装实现了跨场景复用。日常运维中有几条实践建议：始终使用 `--restart unless-stopped` 保证服务自愈；定期运行镜像清理脚本释放磁盘；将日志导出纳入定时任务，方便事后追溯和审计。
