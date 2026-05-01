---
layout: post
date: 2026-04-23 08:00:00
title: "PowerShell 技能连载 - Kubernetes Helm 包管理"
description: PowerTip of the Day - Kubernetes Helm Package Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- kubernetes
- helm
- devops
- package-management
---

_适用于 PowerShell 7.0 及以上版本，需要 kubectl 和 helm CLI_

## 背景

Helm 是 Kubernetes 生态中最主流的包管理工具，被誉为 "Kubernetes 的 apt/yum"。它通过 Chart 模板将复杂的应用部署抽象为一组可版本化、可复用的配置文件，极大降低了 Kubernetes 应用的分发和运维门槛。在实际的 DevOps 工作流中，团队往往需要同时管理数十个 Chart 仓库、多套环境配置以及频繁的版本升级与回滚。

PowerShell 凭借强大的对象管道和丰富的字符串处理能力，非常适合用来编排 Helm 工作流。相比 Bash 脚本，PowerShell 能够将 `helm` 和 `kubectl` 的输出直接转化为结构化对象，便于筛选、比较和批量操作。本文将围绕 Chart 仓库管理、Values 文件动态生成和批量部署回滚三个场景，展示如何用 PowerShell 打造高效的 Helm 自动化工具链。

## Chart 仓库与版本管理

在生产环境中，团队通常会订阅多个 Helm 仓库（如 Bitnami、官方稳定仓库、企业私有仓库等），并且需要追踪 Chart 版本的变化。下面的脚本展示了如何用 PowerShell 统一管理仓库、搜索 Chart 并对比版本差异：

```powershell
# 定义仓库列表
$repos = @(
    @{ Name = 'bitnami'; Url = 'https://charts.bitnami.com/bitnami' }
    @{ Name = 'ingress-nginx'; Url = 'https://kubernetes.github.io/ingress-nginx' }
    @{ Name = 'jetstack'; Url = 'https://charts.jetstack.io' }
)

# 批量添加并更新仓库
foreach ($repo in $repos) {
    helm repo add $repo.Name $repo.Url 2>$null
    Write-Host "已添加仓库: $($repo.Name)" -ForegroundColor Green
}

helm repo update

# 搜索指定关键词的 Chart，并按版本排序
$searchKeyword = 'nginx'
$charts = helm search repo $searchKeyword --output json |
    ConvertFrom-Json

$charts |
    Select-Object name, @{N='version';E={ $_.chart_version }}, app_version, description |
    Sort-Object name |
    Format-Table -AutoSize

# 对比已安装版本与仓库最新版本
$releases = helm list --all-namespaces --output json | ConvertFrom-Json

foreach ($rel in $releases) {
    $chartName = $rel.chart -replace '-\d+.*$', ''
    $installed = $rel.chart_version
    $latest = (helm search repo $chartName --output json |
        ConvertFrom-Json |
        Select-Object -First 1).chart_version

    $status = if ($installed -eq $latest) { '已是最新' } else { "可升级: $installed -> $latest" }
    Write-Host ("[{0}] {1} ({2}): {3}" -f $rel.namespace, $rel.name, $chartName, $status)
}

# 更新 Chart 依赖（针对本地 Chart）
$localChartPath = './charts/my-application'
if (Test-Path "$localChartPath/Chart.yaml") {
    helm dependency update $localChartPath
    Write-Host "依赖已更新: $localChartPath" -ForegroundColor Cyan
}
```

执行结果示例：

```text
已添加仓库: bitnami
已添加仓库: ingress-nginx
已添加仓库: jetstack
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "jetstack" chart repository
Update Complete.

name                          version   app_version  description
----                          -------   -----------  -----------
bitnami/nginx                 18.2.5    1.25.4       NGINX Open Source...
ingress-nginx/ingress-nginx   4.11.3    1.11.3       Ingress controller...

[default] api-gateway (api-gateway): 可升级: 1.2.0 -> 1.3.1
[production] cert-manager (cert-manager): 已是最新
[staging] my-app (my-app): 可升级: 2.0.1 -> 2.1.0
依赖已更新: ./charts/my-application
```

## Values 文件动态生成

Helm 的灵活性很大程度上来自 `values.yaml` 文件。在多环境（开发、预发布、生产）部署中，为每个环境维护独立的 Values 文件既繁琐又容易出错。PowerShell 可以基于模板和数据表动态生成 Values 文件，还能安全地处理密码等敏感值：

```powershell
# 定义环境配置矩阵
$environments = @{
    dev = @{
        replicas    = 1
        imageTag    = 'latest'
        resources   = @{ cpuRequest = '100m'; memRequest = '128Mi' }
        ingress     = @{ enabled = $false }
    }
    staging = @{
        replicas    = 2
        imageTag    = 'v2.1.0-rc.1'
        resources   = @{ cpuRequest = '250m'; memRequest = '256Mi' }
        ingress     = @{ enabled = $true; host = 'staging.example.com' }
    }
    production = @{
        replicas    = 3
        imageTag    = 'v2.0.1'
        resources   = @{ cpuRequest = '500m'; memRequest = '512Mi' }
        ingress     = @{ enabled = $true; host = 'app.example.com'; tls = $true }
    }
}

# 为每个环境生成 values 文件
foreach ($envName in $environments.Keys) {
    $env = $environments[$envName]
    $values = [ordered]@{
        replicaCount = $env.replicas
        image        = [ordered]@{
            repository = 'registry.example.com/my-app'
            tag        = $env.imageTag
            pullPolicy = if ($env.imageTag -eq 'latest') { 'Always' } else { 'IfNotPresent' }
        }
        resources    = [ordered]@{
            requests = [ordered]@{
                cpu    = $env.resources.cpuRequest
                memory = $env.resources.memRequest
            }
        }
        ingress      = $env.ingress
    }

    $outputPath = "values-$envName.yaml"

    # 使用 ConvertTo-Yaml（或手动构建 YAML 字符串）
    # 这里用 helm 的 --set 语法验证生成结果
    $jsonContent = $values | ConvertTo-Json -Depth 10

    # 将 JSON 转为 YAML（利用 yq 或简单字符串替换）
    $jsonContent | python3 -c "import sys,yaml,json; yaml.dump(json.load(sys.stdin),open('$outputPath','w'),default_flow_style=False)"

    Write-Host "已生成: $outputPath" -ForegroundColor Green
}

# 敏感值处理：从外部密钥管理器获取
function Get-SecretForHelm {
    param([string]$SecretName)

    # 从环境变量或 Azure Key Vault / HashiCorp Vault 获取
    $value = [System.Environment]::GetEnvironmentVariable("HELM_SECRET_$SecretName")
    if (-not $value) {
        # 尝试从 kubectl secret 获取
        $value = kubectl get secret app-secrets -o jsonpath="{.data.$SecretName}" |
            base64 -d 2>$null
    }
    return $value
}

# 合并基础 values 与环境覆盖
function Merge-HelmValues {
    param($BasePath, $OverridePath, $OutputPath)

    # 使用 yq 合并 YAML 文件
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' `
        $BasePath $OverridePath -o yaml > $OutputPath

    Write-Host "合并完成: $OutputPath" -ForegroundColor Cyan
}

# 生成包含敏感值的最终 values
$dbPassword = Get-SecretForHelm -SecretName 'DB_PASSWORD'
if ($dbPassword) {
    $secretValues = "database:`n  password: $dbPassword"
    $secretValues | Out-File -FilePath 'values-secrets.yaml' -Encoding utf8
    Merge-HelmValues -BasePath 'values-production.yaml' `
        -OverridePath 'values-secrets.yaml' `
        -OutputPath 'values-production-final.yaml'
}
```

执行结果示例：

```text
已生成: values-dev.yaml
已生成: values-staging.yaml
已生成: values-production.yaml
合并完成: values-production-final.yaml

# 生成的 values-dev.yaml 内容摘要：
replicaCount: 1
image:
  repository: registry.example.com/my-app
  tag: latest
  pullPolicy: Always
resources:
  requests:
    cpu: 100m
    memory: 128Mi
ingress:
  enabled: false
```

## 批量部署与回滚

在微服务架构下，一次发布可能涉及多个 Helm Release。手动逐个执行 `helm upgrade` 既耗时又容易遗漏。下面的脚本实现了多命名空间批量部署、发布状态追踪以及一键回滚功能：

```powershell
# 定义部署清单
$deployments = @(
    @{
        Name        = 'api-gateway'
        Namespace   = 'production'
        Chart       = 'bitnami/nginx'
        ValuesFile  = 'values-production.yaml'
        Wait        = $true
    }
    @{
        Name        = 'auth-service'
        Namespace   = 'production'
        Chart       = './charts/auth-service'
        ValuesFile  = 'values-auth-production.yaml'
        Wait        = $true
    }
    @{
        Name        = 'frontend'
        Namespace   = 'production'
        Chart       = './charts/frontend'
        ValuesFile  = 'values-frontend-production.yaml'
        Wait        = $false
    }
)

# 确保 namespace 存在
$namespaces = $deployments | Select-Object -ExpandProperty Namespace -Unique
foreach ($ns in $namespaces) {
    $exists = kubectl get namespace $ns --ignore-not-found 2>$null
    if (-not $exists) {
        kubectl create namespace $ns
        Write-Host "已创建命名空间: $ns" -ForegroundColor Yellow
    }
}

# 批量部署并记录结果
$results = [System.Collections.Generic.List[PSObject]]::new()

foreach ($dep in $deployments) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "`n部署: $($dep.Name) -> $($dep.Namespace)" -ForegroundColor Cyan

    $waitFlag = if ($dep.Wait) { '--wait' } else { '' }
    $command = "helm upgrade --install $($dep.Name) $($dep.Chart) " +
        "--namespace $($dep.Namespace) " +
        "-f $($dep.ValuesFile) $waitFlag --timeout 5m"

    $output = Invoke-Expression $command 2>&1
    $stopwatch.Stop()

    $success = $LASTEXITCODE -eq 0
    $results.Add([PSCustomObject]@{
        Name       = $dep.Name
        Namespace  = $dep.Namespace
        Status     = if ($success) { 'deployed' } else { 'failed' }
        Duration   = '{0:N1}s' -f $stopwatch.Elapsed.TotalSeconds
        Output     = $output | Select-Object -First 3
    })
}

# 输出部署报告
Write-Host "`n===== 部署报告 =====" -ForegroundColor Yellow
$results |
    Select-Object Name, Namespace, Status, Duration |
    Format-Table -AutoSize

# 检查是否有失败的部署
$failed = $results | Where-Object { $_.Status -eq 'failed' }
if ($failed) {
    Write-Host "`n以下部署失败，准备回滚:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $($_.Name) ($($_.Namespace))" }

    # 一键回滚所有失败项
    foreach ($f in $failed) {
        Write-Host "`n回滚: $($f.Name)" -ForegroundColor Red
        helm rollback $f.Name --namespace $f.Namespace
        $rollbackStatus = if ($LASTEXITCODE -eq 0) { '回滚成功' } else { '回滚失败' }
        Write-Host "  $rollbackStatus"
    }
}

# 生成当前所有 Release 状态摘要
$allReleases = helm list --all-namespaces --output json | ConvertFrom-Json
$report = $allReleases |
    Select-Object name, namespace, @{N='chart';E={ $_.chart -replace '-\d+.*$', '' }},
        chart_version, status, updated |
    Sort-Object namespace, name

Write-Host "`n===== 当前 Release 状态 =====" -ForegroundColor Green
$report | Format-Table -AutoSize

# 导出报告为 CSV（可选）
$report | Export-Csv -Path "helm-deploy-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" `
    -NoTypeInformation -Encoding utf8
Write-Host "报告已导出到 CSV 文件" -ForegroundColor Cyan
```

执行结果示例：

```text
已创建命名空间: production

部署: api-gateway -> production
Release "api-gateway" has been upgraded. Happy Helming!
NAME: api-gateway
LAST DEPLOYED: Wed Apr 23 10:30:00 2026

部署: auth-service -> production
Release "auth-service" has been upgraded. Happy Helming!
NAME: auth-service
LAST DEPLOYED: Wed Apr 23 10:30:45 2026

部署: frontend -> production
Release "frontend" has been upgraded. Happy Helming!

===== 部署报告 =====
Name          Namespace   Status    Duration
----          ---------   ------    --------
api-gateway   production  deployed  32.5s
auth-service  production  deployed  41.2s
frontend      production  deployed   3.1s

===== 当前 Release 状态 =====
name           namespace   chart          chart_version status    updated
----           ---------   -----          ------------- ------    -------
api-gateway    production  nginx          18.2.5        deployed  2026-04-23 10:30:00
auth-service   production  auth-service   1.5.0         deployed  2026-04-23 10:30:45
frontend       production  frontend       2.1.0         deployed  2026-04-23 10:31:02
报告已导出到 CSV 文件
```

## 注意事项

- **Helm 版本兼容性**：本文示例基于 Helm 3.x，Helm 2 已停止维护，请确保使用 `helm version` 确认当前版本为 3.0 以上。Helm 3 移除了 Tiller，安全性显著提升。
- **JSON 输出解析**：`helm` 命令支持 `--output json` 参数，配合 `ConvertFrom-Json` 可以将结果转为 PowerShell 对象。但不同 Helm 版本的 JSON 字段名可能略有差异（如 `chart_version` 与 `app_version`），使用前建议先检查输出结构。
- **敏感值管理**：不要将密码、Token 等敏感信息硬编码在 Values 文件或脚本中。应结合 Kubernetes Secret、外部密钥管理器（如 HashiCorp Vault、Azure Key Vault）或 Helm Secrets 插件来管理敏感配置。
- **回滚策略**：`helm rollback` 默认回滚到上一个修订版本。如果需要回滚到更早的版本，先用 `helm history <release>` 查看修订记录，再指定 `helm rollback <release> <revision>` 回滚到目标版本。
- **超时与等待**：生产环境部署建议始终使用 `--wait` 和 `--timeout` 参数，确保 Helm 等待所有 Pod 就绪后才认为部署成功。合理的超时值通常为 5-10 分钟，具体取决于应用的启动时间。
- **并发部署限制**：虽然 PowerShell 支持并发执行（如 `ForEach-Object -Parallel`），但 Helm 对同一 Release 的并发操作并不安全。建议对同一 Release 的操作串行执行，不同 Release 之间可以安全地并发部署。
