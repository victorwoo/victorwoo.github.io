---
layout: post
date: 2025-01-10 08:00:00
title: "PowerShell 技能连载 - 容器化脚本自动化管理"
description: "实现Docker镜像构建与部署的全流程自动化"
categories:
- powershell
- devops
tags:
- docker
- container
- automation
---

```powershell
function Invoke-ContainerPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImageName,
        [string]$DockerfilePath = './Dockerfile'
    )

    $report = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        BuildLog = @()
        DeploymentStatus = @()
    }

    # 构建Docker镜像
    $buildOutput = docker build -t $ImageName -f $DockerfilePath . 2>&1
    $report.BuildLog += $buildOutput

    # 推送镜像到仓库
    if ($LASTEXITCODE -eq 0) {
        $pushOutput = docker push $ImageName 2>&1
        $report.BuildLog += $pushOutput
    }

    # 部署到Kubernetes
    if ($LASTEXITCODE -eq 0) {
        $k8sOutput = kubectl apply -f deployment.yaml 2>&1
        $report.DeploymentStatus += [PSCustomObject]@{
            Cluster = (kubectl config current-context)
            Status = if($LASTEXITCODE -eq 0){'Success'}else{'Failed'}
            Output = $k8sOutput
        }
    }

    # 生成HTML报告
    $htmlReport = $report | ConvertTo-Html -Fragment
    $htmlReport | Out-File "$env:TEMP/ContainerReport_$(Get-Date -Format yyyyMMdd).html"
    return $report
}
```

**核心功能**：
1. Docker镜像自动化构建
2. 容器仓库自动推送
3. Kubernetes部署集成
4. HTML运维报告生成

**典型应用场景**：
- 持续集成/持续部署(CI/CD)
- 跨环境容器镜像管理
- 蓝绿部署策略实施
- 容器化应用生命周期管理