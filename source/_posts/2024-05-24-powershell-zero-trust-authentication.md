---
layout: post
date: 2024-05-24 08:00:00
title: "PowerShell 技能连载 - 零信任身份验证与访问控制"
description: PowerTip of the Day - PowerShell Zero Trust Authentication and Access Control
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在现代零信任安全架构中，身份验证和访问控制是核心组件。本文将介绍如何使用 PowerShell 实现零信任身份验证和访问控制的关键功能。

## 实现多因素认证集成

首先，让我们创建一个用于管理多因素认证的函数：

```powershell
function Set-MultiFactorAuthentication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('AuthenticatorApp', 'SMS', 'PhoneCall', 'Email')]
        [string]$MfaMethod,
        
        [Parameter()]
        [string]$PhoneNumber,
        
        [Parameter()]
        [string]$EmailAddress,
        
        [Parameter()]
        [switch]$EnforceMfa,
        
        [Parameter()]
        [switch]$RequireTrustedDevice,
        
        [Parameter()]
        [int]$TrustedDeviceValidityDays = 30
    )
    
    try {
        $mfaConfig = [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            MfaMethod = $MfaMethod
            PhoneNumber = $PhoneNumber
            EmailAddress = $EmailAddress
            EnforceMfa = $EnforceMfa
            RequireTrustedDevice = $RequireTrustedDevice
            TrustedDeviceValidityDays = $TrustedDeviceValidityDays
            LastUpdated = Get-Date
            UpdatedBy = $env:USERNAME
        }
        
        # 验证用户身份
        $user = Get-ADUser -Identity $UserPrincipalName -Properties Enabled, PasswordExpired, PasswordLastSet
        
        if (-not $user) {
            throw "未找到用户：$UserPrincipalName"
        }
        
        # 根据MFA方法设置相应的验证方式
        switch ($MfaMethod) {
            'AuthenticatorApp' {
                # 生成TOTP密钥
                $totpKey = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
                $keyBytes = New-Object byte[] 20
                $totpKey.GetBytes($keyBytes)
                $mfaConfig.TotpKey = [Convert]::ToBase64String($keyBytes)
                
                # 生成QR码数据
                $qrData = "otpauth://totp/$($user.SamAccountName)?secret=$($mfaConfig.TotpKey)&issuer=YourCompany"
                $mfaConfig.QrCodeData = $qrData
            }
            
            'SMS' {
                if (-not $PhoneNumber) {
                    throw "SMS验证需要提供电话号码"
                }
                
                # 验证电话号码格式
                if (-not ($PhoneNumber -match '^\+?[1-9]\d{1,14}$')) {
                    throw "无效的电话号码格式"
                }
                
                $mfaConfig.PhoneNumber = $PhoneNumber
            }
            
            'PhoneCall' {
                if (-not $PhoneNumber) {
                    throw "电话验证需要提供电话号码"
                }
                
                # 验证电话号码格式
                if (-not ($PhoneNumber -match '^\+?[1-9]\d{1,14}$')) {
                    throw "无效的电话号码格式"
                }
                
                $mfaConfig.PhoneNumber = $PhoneNumber
            }
            
            'Email' {
                if (-not $EmailAddress) {
                    throw "邮件验证需要提供电子邮件地址"
                }
                
                # 验证电子邮件格式
                if (-not ($EmailAddress -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')) {
                    throw "无效的电子邮件格式"
                }
                
                $mfaConfig.EmailAddress = $EmailAddress
            }
        }
        
        # 设置MFA状态
        if ($EnforceMfa) {
            # 这里应该连接到身份提供程序（如Azure AD）设置MFA
            Write-Host "正在为用户 $UserPrincipalName 启用强制MFA..."
        }
        
        # 设置可信设备要求
        if ($RequireTrustedDevice) {
            # 这里应该设置设备信任策略
            Write-Host "正在设置可信设备要求，有效期 $TrustedDeviceValidityDays 天..."
        }
        
        # 记录配置更改
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = "MFA配置更新"
            User = $UserPrincipalName
            Changes = $mfaConfig
            PerformedBy = $env:USERNAME
        }
        
        # 这里应该将日志写入安全日志系统
        Write-Host "MFA配置已更新：$($logEntry | ConvertTo-Json)"
        
        return $mfaConfig
    }
    catch {
        Write-Error "设置MFA时出错：$_"
        return $null
    }
}
```

## 实现基于风险的访问控制

接下来，创建一个用于评估访问风险并实施相应控制的函数：

```powershell
function Test-AccessRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter()]
        [string]$IPAddress,
        
        [Parameter()]
        [string]$Location,
        
        [Parameter()]
        [string]$DeviceId,
        
        [Parameter()]
        [hashtable]$AdditionalContext
    )
    
    try {
        $riskAssessment = [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            ResourceId = $ResourceId
            Timestamp = Get-Date
            RiskScore = 0
            RiskLevel = "Unknown"
            RiskFactors = @()
            RecommendedActions = @()
            AccessDecision = "Pending"
        }
        
        # 评估用户风险
        $userRisk = 0
        $userRiskFactors = @()
        
        # 检查用户登录历史
        $loginHistory = Get-ADUser -Identity $UserPrincipalName -Properties LastLogonDate, PasswordLastSet, Enabled |
            Select-Object LastLogonDate, PasswordLastSet, Enabled
        
        if (-not $loginHistory.Enabled) {
            $userRisk += 50
            $userRiskFactors += "用户账户已禁用"
        }
        
        if ($loginHistory.PasswordLastSet -lt (Get-Date).AddDays(-90)) {
            $userRisk += 20
            $userRiskFactors += "密码已过期"
        }
        
        if ($loginHistory.LastLogonDate -lt (Get-Date).AddDays(-30)) {
            $userRisk += 15
            $userRiskFactors += "长期未登录"
        }
        
        # 评估设备风险
        $deviceRisk = 0
        $deviceRiskFactors = @()
        
        if ($DeviceId) {
            $deviceHealth = Test-DeviceHealth -ComputerName $DeviceId -IncludeFirewall -IncludeAntivirus -IncludeUpdates
            
            if (-not $deviceHealth.ComplianceStatus) {
                $deviceRisk += 40
                $deviceRiskFactors += "设备不符合安全要求"
            }
            
            if ($deviceHealth.HealthScore -lt 70) {
                $deviceRisk += 30
                $deviceRiskFactors += "设备健康状态不佳"
            }
        }
        
        # 评估位置风险
        $locationRisk = 0
        $locationRiskFactors = @()
        
        if ($Location) {
            # 检查是否在可信位置
            $trustedLocations = @("Office", "Home", "VPN")
            if ($Location -notin $trustedLocations) {
                $locationRisk += 30
                $locationRiskFactors += "访问来自非可信位置"
            }
        }
        
        if ($IPAddress) {
            # 检查IP地址信誉
            $ipRisk = Test-IPReputation -IPAddress $IPAddress
            if ($ipRisk.RiskLevel -eq "High") {
                $locationRisk += 40
                $locationRiskFactors += "IP地址信誉不佳"
            }
        }
        
        # 计算总体风险分数
        $totalRisk = $userRisk + $deviceRisk + $locationRisk
        $riskAssessment.RiskScore = $totalRisk
        
        # 确定风险等级
        $riskAssessment.RiskLevel = switch ($totalRisk) {
            { $_ -ge 100 } { "Critical" }
            { $_ -ge 75 } { "High" }
            { $_ -ge 50 } { "Medium" }
            { $_ -ge 25 } { "Low" }
            default { "Minimal" }
        }
        
        # 收集所有风险因素
        $riskAssessment.RiskFactors = @(
            $userRiskFactors
            $deviceRiskFactors
            $locationRiskFactors
        ) | Where-Object { $_ }
        
        # 根据风险等级确定访问决策
        $riskAssessment.AccessDecision = switch ($riskAssessment.RiskLevel) {
            "Critical" {
                $riskAssessment.RecommendedActions += "阻止访问"
                $riskAssessment.RecommendedActions += "通知安全团队"
                "Deny"
            }
            "High" {
                $riskAssessment.RecommendedActions += "要求额外的身份验证"
                $riskAssessment.RecommendedActions += "限制访问范围"
                "Restricted"
            }
            "Medium" {
                $riskAssessment.RecommendedActions += "要求MFA验证"
                $riskAssessment.RecommendedActions += "记录详细访问日志"
                "Conditional"
            }
            "Low" {
                $riskAssessment.RecommendedActions += "正常访问"
                "Allow"
            }
            default {
                $riskAssessment.RecommendedActions += "需要人工审核"
                "Review"
            }
        }
        
        # 记录风险评估结果
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = "访问风险评估"
            User = $UserPrincipalName
            Resource = $ResourceId
            RiskAssessment = $riskAssessment
            Context = @{
                IPAddress = $IPAddress
                Location = $Location
                DeviceId = $DeviceId
                AdditionalContext = $AdditionalContext
            }
        }
        
        # 这里应该将日志写入安全日志系统
        Write-Host "风险评估完成：$($logEntry | ConvertTo-Json)"
        
        return $riskAssessment
    }
    catch {
        Write-Error "评估访问风险时出错：$_"
        return $null
    }
}
```

## 实现动态权限管理

最后，创建一个用于管理动态权限的函数：

```powershell
function Set-DynamicPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Read', 'Write', 'Execute', 'Full')]
        [string]$PermissionLevel,
        
        [Parameter()]
        [int]$DurationMinutes = 60,
        
        [Parameter()]
        [hashtable]$ContextualAttributes,
        
        [Parameter()]
        [switch]$RequireApproval,
        
        [Parameter()]
        [string]$ApproverEmail
    )
    
    try {
        $permissionRequest = [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            ResourceId = $ResourceId
            PermissionLevel = $PermissionLevel
            RequestTime = Get-Date
            ExpirationTime = (Get-Date).AddMinutes($DurationMinutes)
            ContextualAttributes = $ContextualAttributes
            RequireApproval = $RequireApproval
            ApproverEmail = $ApproverEmail
            Status = "Pending"
            ApprovalStatus = if ($RequireApproval) { "Pending" } else { "NotRequired" }
            GrantedBy = $null
            GrantedAt = $null
        }
        
        # 验证用户身份
        $user = Get-ADUser -Identity $UserPrincipalName -Properties Enabled, PasswordExpired
        
        if (-not $user) {
            throw "未找到用户：$UserPrincipalName"
        }
        
        if (-not $user.Enabled) {
            throw "用户账户已禁用"
        }
        
        # 评估访问风险
        $riskAssessment = Test-AccessRisk -UserPrincipalName $UserPrincipalName -ResourceId $ResourceId
        
        if ($riskAssessment.RiskLevel -eq "Critical") {
            $permissionRequest.Status = "Denied"
            $permissionRequest.Reason = "风险评估显示严重风险"
            return $permissionRequest
        }
        
        # 如果需要审批
        if ($RequireApproval) {
            # 发送审批请求
            $approvalRequest = [PSCustomObject]@{
                RequestId = [System.Guid]::NewGuid().ToString()
                UserPrincipalName = $UserPrincipalName
                ResourceId = $ResourceId
                PermissionLevel = $PermissionLevel
                DurationMinutes = $DurationMinutes
                ContextualAttributes = $ContextualAttributes
                ApproverEmail = $ApproverEmail
                RequestTime = Get-Date
            }
            
            # 这里应该发送审批请求邮件
            Write-Host "已发送审批请求：$($approvalRequest | ConvertTo-Json)"
            
            return $permissionRequest
        }
        
        # 根据风险等级调整权限
        switch ($riskAssessment.RiskLevel) {
            "High" {
                # 高风险用户获得受限权限
                $permissionRequest.PermissionLevel = "Read"
                $permissionRequest.DurationMinutes = [Math]::Min($DurationMinutes, 30)
            }
            "Medium" {
                # 中风险用户获得标准权限
                $permissionRequest.DurationMinutes = [Math]::Min($DurationMinutes, 120)
            }
            "Low" {
                # 低风险用户获得完整权限
                # 保持原始权限设置
            }
        }
        
        # 授予权限
        $permissionRequest.Status = "Granted"
        $permissionRequest.GrantedBy = $env:USERNAME
        $permissionRequest.GrantedAt = Get-Date
        
        # 记录权限授予
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = "动态权限授予"
            User = $UserPrincipalName
            Resource = $ResourceId
            PermissionRequest = $permissionRequest
            RiskAssessment = $riskAssessment
        }
        
        # 这里应该将日志写入安全日志系统
        Write-Host "权限已授予：$($logEntry | ConvertTo-Json)"
        
        return $permissionRequest
    }
    catch {
        Write-Error "设置动态权限时出错：$_"
        return $null
    }
}
```

## 使用示例

以下是如何使用这些函数来实施零信任身份验证和访问控制的示例：

```powershell
# 为用户配置MFA
$mfaConfig = Set-MultiFactorAuthentication -UserPrincipalName "user@example.com" `
    -MfaMethod "AuthenticatorApp" `
    -EnforceMfa `
    -RequireTrustedDevice `
    -TrustedDeviceValidityDays 30

# 评估访问风险
$riskAssessment = Test-AccessRisk -UserPrincipalName "user@example.com" `
    -ResourceId "resource123" `
    -IPAddress "192.168.1.100" `
    -Location "Office" `
    -DeviceId "DESKTOP-ABC123" `
    -AdditionalContext @{
        "Application" = "SensitiveApp"
        "TimeOfDay" = "BusinessHours"
    }

# 设置动态权限
$permissions = Set-DynamicPermissions -UserPrincipalName "user@example.com" `
    -ResourceId "resource123" `
    -PermissionLevel "Read" `
    -DurationMinutes 120 `
    -ContextualAttributes @{
        "Project" = "ProjectA"
        "Role" = "Developer"
    } `
    -RequireApproval `
    -ApproverEmail "manager@example.com"
```

## 最佳实践

1. 始终实施最小权限原则，只授予必要的访问权限
2. 定期审查和更新访问权限
3. 实施持续的风险评估和监控
4. 记录所有访问决策和权限变更
5. 建立清晰的审批流程和升级机制
6. 定期进行安全审计和合规性检查
7. 实施自动化的工作流程以减少人为错误
8. 确保所有安全事件都有适当的响应机制 