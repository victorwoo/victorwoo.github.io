---
layout: post
date: 2024-06-13 08:00:00
title: "PowerShell 技能连载 - Microsoft Graph API 集成自动化"
description: "实现Office 365用户与团队资源全生命周期管理"
categories:
- powershell
- office365
tags:
- microsoft-graph
- automation
- azure-ad
---

```powershell
function Manage-Office365Resources {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('User','Team')]
        [string]$ResourceType,
        
        [string]$DisplayName
    )

    $managementReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Operations = @()
        SuccessRate = 0
        LicenseDetails = @{}
    }

    try {
        # 获取Graph API访问令牌
        $token = Get-MsalToken -ClientId $env:AZURE_CLIENT_ID -TenantId $env:AZURE_TENANT_ID

        # 资源操作逻辑
        switch ($ResourceType) {
            'User' {
                $userParams = @{
                    Method = 'POST'
                    Uri = "https://graph.microsoft.com/v1.0/users"
                    Headers = @{ Authorization = "Bearer $($token.AccessToken)" }
                    Body = @{
                        accountEnabled = $true
                        displayName = $DisplayName
                        mailNickname = $DisplayName.Replace(' ','').ToLower()
                        userPrincipalName = "$($DisplayName.Replace(' ',''))@$env:AZURE_DOMAIN"
                        passwordProfile = @{
                            forceChangePasswordNextSignIn = $true
                            password = [System.Convert]::ToBase64String((1..12 | ForEach-Object { [char](Get-Random -Minimum 33 -Maximum 126) }))
                        }
                    } | ConvertTo-Json
                }
                $response = Invoke-RestMethod @userParams
                $managementReport.Operations += [PSCustomObject]@{
                    Type = 'UserCreated'
                    ID = $response.id
                }
            }
            
            'Team' {
                $teamParams = @{
                    Method = 'POST'
                    Uri = "https://graph.microsoft.com/v1.0/teams"
                    Headers = @{ Authorization = "Bearer $($token.AccessToken)" }
                    Body = @{
                        "template@odata.bind" = "https://graph.microsoft.com/v1.0/teamsTemplates('standard')"
                        displayName = $DisplayName
                        description = "Automatically created team"
                    } | ConvertTo-Json
                }
                $response = Invoke-RestMethod @teamParams
                $managementReport.Operations += [PSCustomObject]@{
                    Type = 'TeamProvisioned'
                    ID = $response.id
                }
            }
        }

        # 获取许可证信息
        $licenseData = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/subscribedSkus" \
            -Headers @{ Authorization = "Bearer $($token.AccessToken)" }
        $managementReport.LicenseDetails = $licenseData.value | 
            Group-Object skuPartNumber -AsHashTable |
            ForEach-Object { @{$_.Key = $_.Value.consumedUnits} }

        # 计算成功率
        $managementReport.SuccessRate = ($managementReport.Operations.Count / 1) * 100
    }
    catch {
        Write-Error "资源管理失败: $_"
    }

    # 生成管理报告
    $managementReport | Export-Clixml -Path "$env:TEMP/GraphReport_$(Get-Date -Format yyyyMMdd).xml"
    return $managementReport
}
```

**核心功能**：
1. Azure AD用户自动化创建
2. Microsoft Teams团队自动部署
3. 许可证使用情况监控
4. XML格式管理报告

**应用场景**：
- 企业用户生命周期管理
- 团队协作环境快速部署
- 许可证使用效率分析
- 合规审计数据准备