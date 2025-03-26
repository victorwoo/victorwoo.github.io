---
layout: post
date: 2024-04-25 08:00:00
title: "PowerShell 技能连载 - 容器安全扫描"
description: PowerTip of the Day - Container Security Scanning
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在容器化环境中，安全扫描是确保部署安全的关键步骤。以下脚本实现Docker镜像漏洞扫描：

```powershell
function Invoke-ContainerScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImageName,
        
        [ValidateSet('Low','Medium','High','Critical')]
        [string]$SeverityLevel = 'High'
    )

    $report = [PSCustomObject]@{
        Vulnerabilities = @()
        TotalCount = 0
        RiskRating = 'Unknown'
    }

    try {
        # 执行安全扫描
        $result = docker scan $ImageName --severity $SeverityLevel --format json | ConvertFrom-Json
        
        # 解析扫描结果
        $report.Vulnerabilities = $result.vulnerabilities | Select-Object @{
            Name = 'CVEID'; Expression = {$_.vulnerabilityID}
        }, @{
            Name = 'Severity'; Expression = {$_.severity}
        }, @{
            Name = 'Component'; Expression = {$_.pkgName}
        }
        
        $report.TotalCount = $result.vulnerabilities.Count
        
        # 计算风险评级
        $report.RiskRating = switch ($result.vulnerabilities.Count) {
            {$_ -gt 20} {'Critical'}
            {$_ -gt 10} {'High'}
            {$_ -gt 5} {'Medium'}
            default {'Low'}
        }
    }
    catch {
        Write-Error "扫描失败: $_"
    }

    return $report
}
```

实现原理：
1. 集成Docker Scan命令实现镜像安全扫描
2. 通过JSON格式输出解析漏洞数据
3. 根据漏洞数量和严重级别计算风险评级
4. 支持按严重级别过滤扫描结果

使用示例：
```powershell
Invoke-ContainerScan -ImageName 'nginx:latest' -SeverityLevel 'Critical'
```

最佳实践：
1. 集成到CI/CD流水线实现自动阻断
2. 定期更新漏洞数据库
3. 与镜像仓库集成实现预检扫描
4. 生成HTML格式的详细报告

注意事项：
• 需要安装Docker Desktop 4.8+版本
• 扫描可能消耗较多系统资源
• 建议配置扫描超时机制