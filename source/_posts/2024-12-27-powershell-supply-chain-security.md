---
layout: post
date: 2024-12-27 08:00:00
title: "PowerShell 技能连载 - 供应链安全漏洞扫描"
description: PowerTip of the Day - Supply Chain Security Scanning with Trivy
categories:
- powershell
- security
tags:
- powershell
- devsecops
- supply-chain
---

```powershell
function Invoke-SupplyChainScan {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImageName,
        [string]$OutputFormat = 'table',
        [string]$SeverityLevel = 'HIGH,CRITICAL'
    )

    # 安装Trivy漏洞扫描器
    if (-not (Get-Command trivy -ErrorAction SilentlyContinue)) {
        winget install aquasecurity.trivy
    }

    try {
        # 执行容器镜像扫描
        $result = trivy image --format $OutputFormat --severity $SeverityLevel $ImageName
        
        # 生成HTML报告
        $htmlReport = "$env:TEMP\scan_report_$(Get-Date -Format yyyyMMddHHmmss).html"
        trivy image --format template --template "@contrib/html.tpl" -o $htmlReport $ImageName
        
        [PSCustomObject]@{
            ScanTarget = $ImageName
            VulnerabilitiesFound = $result.Count
            CriticalCount = ($result | Where-Object { $_ -match 'CRITICAL' }).Count
            HighCount = ($result | Where-Object { $_ -match 'HIGH' }).Count
            HTMLReportPath = $htmlReport
        }
    }
    catch {
        Write-Error "漏洞扫描失败：$_"
    }
}
```

核心功能：
1. 集成Trivy进行容器镜像漏洞扫描
2. 支持多种输出格式(table/json/html)
3. 自动生成带严重等级分类的报告
4. 包含依赖组件版本检查

应用场景：
- CI/CD流水线安全门禁
- 第三方组件入仓检查
- 生产环境镜像定期审计