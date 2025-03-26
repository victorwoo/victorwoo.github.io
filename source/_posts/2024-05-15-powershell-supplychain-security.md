---
layout: post
date: 2024-05-15 08:00:00
title: "PowerShell 技能连载 - 软件供应链安全自动化审计"
description: "实现第三方组件签名验证与依赖包漏洞扫描"
categories:
- powershell
- security
- devops
tags:
- supplychain
- vulnerability
- compliance
---

```powershell
function Invoke-SupplyChainScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScanPath,
        
        [ValidateSet('Critical','High','Medium','Low')]
        [string]$SeverityLevel = 'Critical'
    )

    $report = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ScannedComponents = @()
        SecurityFindings = @()
    }

    # 组件哈希校验与签名验证
    Get-ChildItem $ScanPath -Recurse -Include *.dll,*.exe,*.psm1 | ForEach-Object {
        $fileHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $signature = Get-AuthenticodeSignature $_.FullName
        
        $component = [PSCustomObject]@{
            FileName = $_.Name
            FilePath = $_.FullName
            SHA256 = $fileHash
            IsSigned = $signature.Status -eq 'Valid'
            Publisher = $signature.SignerCertificate.Subject
        }
        $report.ScannedComponents += $component

        if (-not $component.IsSigned) {
            $report.SecurityFindings += [PSCustomObject]@{
                Severity = 'High'
                Description = "未签名的组件: $($_.Name)"
                Recommendation = "要求供应商提供数字签名版本或验证组件来源"
            }
        }
    }

    # 依赖包漏洞扫描
    $nugetPackages = Get-ChildItem $ScanPath -Recurse -Include packages.config
    $nugetPackages | ForEach-Object {
        [xml]$config = Get-Content $_.FullName
        $config.packages.package | ForEach-Object {
            $cveData = Invoke-RestMethod "https://api.cvecheck.org/v1/search?id=$($_.id)"
            if ($cveData.vulnerabilities | Where-Object { $_.severity -ge $SeverityLevel }) {
                $report.SecurityFindings += [PSCustomObject]@{
                    Severity = $SeverityLevel
                    Description = "存在漏洞的依赖包: $($_.id) v$($_.version)"
                    Recommendation = "升级到最新安全版本 $($cveData.latestVersion)"
                }
            }
        }
    }

    $report | Export-Csv -Path "$ScanPath\SupplyChainReport_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
    return $report
}
```

**核心功能**：
1. 软件组件哈希指纹校验
2. 数字签名自动验证
3. NuGet依赖包漏洞扫描
4. CVE数据库集成查询

**典型应用场景**：
- 开发环境第三方组件安全检查
- CI/CD流水线安全卡点
- 供应商交付物合规验证
- 企业软件资产安全基线报告