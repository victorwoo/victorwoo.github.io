---
layout: post
date: 2025-01-24 08:00:00
title: "PowerShell 技能连载 - GitOps自动化部署"
description: PowerTip of the Day - GitOps Automation Deployment
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在GitOps实践中，实现配置即代码的自动化部署流程。以下脚本实现Git仓库与Kubernetes集群的自动同步：

```powershell
function Sync-GitOpsDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoUrl,
        
        [ValidateSet('dev','prod')]
        [string]$Environment = 'dev'
    )

    $workdir = Join-Path $env:TEMP "gitops-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # 克隆配置仓库
        git clone $RepoUrl $workdir
        
        # 应用环境配置
        $manifests = Get-ChildItem -Path $workdir/$Environment -Filter *.yaml
        $manifests | ForEach-Object {
            kubectl apply -f $_.FullName
        }
        
        # 生成同步报告
        [PSCustomObject]@{
            Timestamp = Get-Date
            SyncedFiles = $manifests.Count
            Environment = $Environment
            CommitHash = (git -C $workdir rev-parse HEAD)
        }
    }
    catch {
        Write-Error "GitOps同步失败: $_"
    }
    finally {
        Remove-Item $workdir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

实现原理：
1. 临时克隆Git仓库获取最新配置
2. 按环境目录筛选Kubernetes清单文件
3. 使用kubectl批量应用资源配置
4. 生成包含提交哈希的同步报告
5. 自动清理临时工作目录

使用示例：
```powershell
Sync-GitOpsDeployment -RepoUrl 'https://github.com/user/config-repo' -Environment 'prod'
```

最佳实践：
1. 与Webhook集成实现变更触发
2. 添加配置差异比对功能
3. 实现同步历史版本追溯
4. 集成通知机制报告异常

注意事项：
• 需要配置git和kubectl命令行工具
• 生产环境建议使用SSH密钥认证
• 重要变更应通过PR流程审核