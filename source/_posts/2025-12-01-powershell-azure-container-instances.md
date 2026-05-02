---
layout: post
date: 2025-12-01 08:00:00
updated: 2025-12-01 08:00:00
title: "PowerShell 技能连载 - Azure 容器实例管理"
description: PowerTip of the Day - Azure Container Instances Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- containers
- aci
- cloud
---

_适用于 PowerShell 7.0 及以上版本_

Azure Container Instances（ACI）是 Azure 提供的无服务器容器运行服务，无需预配虚拟机或配置 Kubernetes 集群，就能在云端快速启动容器。对于运维人员来说，这意味着可以用最低的基础设施开销来运行批处理任务、CI/CD 作业或临时服务。

在日常运维场景中，我们经常需要快速部署一个容器来验证功能、处理数据或提供临时 API。传统方式需要登录 Azure 门户、手动点击多项配置，效率低下且容易出错。通过 PowerShell 的 `Az` 模块，可以将这些操作全部自动化，从创建资源组到部署容器、再到监控和清理，一条流水线搞定。

本文将介绍如何使用 PowerShell 完成 ACI 的基础操作、安全部署和监控清理，帮助你建立一套可复用的容器管理自动化方案。

## ACI 基础操作：创建资源组与容器组

第一步是准备 Azure 环境并创建容器实例。以下脚本演示了登录 Azure、创建资源组、部署容器组并查询运行状态的完整流程。

```powershell
# 登录 Azure 账户
Connect-AzAccount

# 定义变量
$ResourceGroupName = 'aci-demo-rg'
$Location = 'eastus'
$ContainerGroupName = 'demo-container-group'
$Image = 'mcr.microsoft.com/aci/helloworld'

# 创建资源组
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
Write-Host "资源组 '$($rg.ResourceGroupName)' 创建完成，位置：$($rg.Location)"

# 创建容器组
$containerGroup = New-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName `
    -Image $Image `
    -OsType 'Linux' `
    -Cpu 1 `
    -MemoryInGB 1 `
    -Port 80 `
    -IpAddressType 'Public'

Write-Host "容器组 '$ContainerGroupName' 已创建"

# 查询容器组状态
$status = Get-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName

Write-Host "容器状态：$($status.ProvisioningState)"
Write-Host "公共 IP：$($status.IpAddress)"
Write-Host "FQDN：$($status.Fqdn)"
```

执行后，你将看到类似如下的输出：

```
资源组 'aci-demo-rg' 创建完成，位置：eastus
容器组 'demo-container-group' 已创建
容器状态：Succeeded
公共 IP：20.51.100.42
FQDN：demo-container-group.eastus.azurecontainer.io
```

创建成功后，可以通过返回的公共 IP 或 FQDN 直接访问容器内运行的服务。`Get-AzContainerGroup` 命令可以随时查询容器的最新状态，方便集成到监控脚本中。

## 容器部署：环境变量与密钥管理

实际生产中，容器通常需要配置环境变量和敏感信息。ACI 支持通过安全挂载 Azure Key Vault 中的密钥，避免在代码或命令行中暴露凭据。

```powershell
# 定义安全引用变量
$ResourceGroupName = 'aci-demo-rg'
$ContainerGroupName = 'secure-app-group'

# 创建 Key Vault（如果不存在）
$VaultName = 'aci-demo-kv'
$kv = Get-AzKeyVault -VaultName $VaultName -ErrorAction SilentlyContinue
if (-not $kv) {
    $kv = New-AzKeyVault `
        -VaultName $VaultName `
        -ResourceGroupName $ResourceGroupName `
        -Location 'eastus'
    Write-Host "Key Vault '$VaultName' 已创建"
}

# 向 Key Vault 添加数据库连接字符串
$secretValue = ConvertTo-SecureString `
    -String 'Server=db.example.com;Database=appdb;User=appuser;Pwd=Str0ngP@ss!' `
    -AsPlainText -Force

Set-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name 'DatabaseConnectionString' `
    -SecretValue $secretValue

Write-Host "密钥已写入 Key Vault"

# 使用环境变量部署容器
$envVars = @(
    @{ Name = 'APP_ENV'; Value = 'production' }
    @{ Name = 'LOG_LEVEL'; Value = 'info' }
    @{ Name = 'WORKERS'; Value = '4' }
)

$containerGroup = New-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName `
    -Image 'nginx:latest' `
    -OsType 'Linux' `
    -Cpu 1 `
    -MemoryInGB 1.5 `
    -Port 80 `
    -IpAddressType 'Public' `
    -EnvironmentVariable $envVars

Write-Host "容器 '$ContainerGroupName' 已部署，含环境变量配置"
```

执行结果示例：

```
Key Vault 'aci-demo-kv' 已创建
密钥已写入 Key Vault
容器 'secure-app-group' 已部署，含环境变量配置
```

通过 Key Vault 管理敏感信息是 Azure 的最佳实践。环境变量适合传入非敏感的配置项（如运行模式、日志级别），而数据库密码、API 密钥等则应存储在 Key Vault 中，通过托管标识或安全引用注入容器，确保凭据不会出现在脚本或日志中。

## 容器监控、日志收集与自动清理

容器的生命周期管理同样重要。以下脚本演示了如何获取容器日志、检查资源使用情况，以及在任务完成后自动清理资源。

```powershell
# 监控和清理变量
$ResourceGroupName = 'aci-demo-rg'
$ContainerGroupName = 'demo-container-group'

# 获取容器日志（最近 50 行）
$logs = Get-AzContainerInstanceLog `
    -ResourceGroupName $ResourceGroupName `
    -ContainerGroupName $ContainerGroupName `
    -ContainerName $ContainerGroupName `
    -Tail 50

Write-Host "=== 容器日志（最近 50 行）==="
Write-Host $logs

# 列出资源组中所有容器组的状态
$allContainers = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName

foreach ($cg in $allContainers) {
    $startTime = $cg.Containers[0].InstanceView.CurrentState.StartTime
    Write-Host ("容器组：{0,-30} 状态：{1,-12} IP：{2}" -f `
        $cg.Name, `
        $cg.ProvisioningState, `
        $cg.IpAddress)
}

# 自动清理：删除运行超过 24 小时的容器组
$cutoff = (Get-Date).AddHours(-24)

foreach ($cg in $allContainers) {
    $startTime = $cg.Containers[0].InstanceView.CurrentState.StartTime
    if ($startTime -and $startTime -lt $cutoff) {
        Write-Host "清理过期容器组：$($cg.Name)（启动于 $startTime）"
        Remove-AzContainerGroup `
            -ResourceGroupName $ResourceGroupName `
            -Name $cg.Name `
            -Confirm:$false
    }
}

Write-Host "`n清理完成。剩余容器组："
$remaining = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName
$remaining | ForEach-Object { Write-Host "  - $($_.Name)" }
```

执行结果示例：

```
=== 容器日志（最近 50 行）===
Starting web server on port 80...
Serving content from /usr/local/apache2/htdocs/
GET / 200 15ms
GET /favicon.ico 404 2ms

容器组：demo-container-group              状态：Succeeded   IP：20.51.100.42
容器组：secure-app-group                  状态：Succeeded   IP：20.51.100.88
清理过期容器组：demo-container-group（启动于 2025-11-30 06:30:00）

清理完成。剩余容器组：
  - secure-app-group
```

自动清理机制可以有效控制成本。ACI 按容器运行时间计费，如果不及时清理临时容器，费用会持续累积。建议将清理脚本配置为定时任务（如 Azure Automation Runbook），每天自动扫描并回收超期的容器实例。

## 注意事项

1. **权限要求**：执行 ACI 操作需要 Azure 订阅的 `Contributor` 角色权限，建议创建专用服务主体（Service Principal）并授予最小权限，避免在日常脚本中使用管理员账户。

2. **区域可用性**：ACI 支持的 Azure 区域和 SKU 类型有限，部署前请确认目标区域是否支持你需要的特性（如 GPU 容器、虚拟网络集成等）。

3. **资源配额限制**：每个订阅对 ACI 有默认配额限制（如 CPU 核心数、容器组数量），大规模部署前可通过 `Get-AzVMUsage` 检查当前使用量，必要时提交配额提升申请。

4. **密钥轮换**：Key Vault 中的密钥应建立定期轮换机制，可结合 Azure Key Vault 的自动轮换策略，避免长期使用同一套凭据。

5. **日志持久化**：ACI 容器重启后本地日志会丢失，生产环境应将日志输出到 Azure Log Analytics 或外部存储，通过容器环境变量配置日志转发地址。

6. **成本控制**：ACI 按秒计费，适合短期任务和突发负载。如果容器需要长期运行（超过 1 周），建议迁移到 Azure Kubernetes Service（AKS），综合成本更低。
