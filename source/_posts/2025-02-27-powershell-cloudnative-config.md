---
layout: post
date: 2025-02-27 08:00:00
title: "PowerShell 技能连载 - 云原生配置管理"
description: PowerTip of the Day - Cloud-Native Configuration Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在云原生环境中，自动化资源配置管理至关重要。以下脚本实现Kubernetes部署模板生成与应用：

```powershell
function New-K8sDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppName,
        
        [ValidateRange(1,10)]
        [int]$Replicas = 3,
        
        [ValidateSet('development','production')]
        [string]$Environment = 'production'
    )

    $yaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $AppName-$Environment
spec:
  replicas: $Replicas
  selector:
    matchLabels:
      app: $AppName
  template:
    metadata:
      labels:
        app: $AppName
        env: $Environment
    spec:
      containers:
      - name: $AppName
        image: registry/vichamp/$AppName:latest
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
"@

    try {
        $tempFile = New-TemporaryFile
        $yaml | Out-File $tempFile.FullName
        
        kubectl apply -f $tempFile.FullName
        
        [PSCustomObject]@{
            AppName = $AppName
            Environment = $Environment
            Manifest = $yaml
            Status = 'Applied'
        }
    }
    catch {
        Write-Error "Kubernetes部署失败: $_"
    }
    finally {
        Remove-Item $tempFile.FullName -ErrorAction SilentlyContinue
    }
}
```

实现原理：
1. 使用here-string动态生成标准YAML部署模板
2. 通过环境参数控制副本数量和部署环境
3. 自动创建临时文件执行kubectl apply命令
4. 返回包含应用状态的定制对象
5. 完善的错误处理与临时文件清理机制

使用示例：
```powershell
New-K8sDeployment -AppName 'order-service' -Environment 'production' -Replicas 5
```

最佳实践：
1. 与CI/CD流水线集成实现自动部署
2. 添加资源请求/限制验证逻辑
3. 实现部署历史版本回滚功能
4. 集成Prometheus监控指标

注意事项：
• 需要配置kubectl访问权限
• 建议添加YAML语法验证
• 生产环境需设置严格的资源限制