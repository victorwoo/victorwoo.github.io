---
layout: post
date: 2024-09-23 08:00:00
title: "PowerShell JEA安全架构解析"
description: "实现最小权限管理与会话沙箱控制"
categories:
- powershell
- security
tags:
- jea
- role-capability
---

## JEA端点配置
```powershell
# 创建会话配置文件
$sessionParams = @{
    Path = '.JEAConfig.pssc'
    SessionType = 'RestrictedRemoteServer'
    RunAsVirtualAccount = $true
    RoleDefinitions = @{ 'CONTOSO\SQLUsers' = @{ RoleCapabilities = 'SqlReadOnly' } }
}
New-PSSessionConfigurationFile @sessionParams
```

## 角色能力定义
```powershell
# 创建角色能力文件
$roleCapability = @{
    Path = 'Roles\SqlReadOnly.psrc'
    VisibleCmdlets = 'Get-Sql*'
    VisibleFunctions = 'ConvertTo-Query'
    VisibleProviders = 'FileSystem'
    ScriptsToProcess = 'Initialize-SqlEnv.ps1'
}
New-PSRoleCapabilityFile @roleCapability
```

## 会话沙箱验证
```powershell
# 连接JEA端点并验证权限
$session = New-PSSession -ConfigurationName JEAConfig
Invoke-Command -Session $session {
    Get-Command -Name *  # 仅显示白名单命令
    Get-ChildItem C:\   # 触发权限拒绝
}
```

## 典型应用场景
1. 数据库只读访问控制
2. 第三方供应商操作审计
3. 生产环境故障诊断隔离
4. 跨域资源受限访问

## 安全加固要点
- 虚拟账户生命周期控制
- 转录日志完整性校验
- 模块白名单签名验证
- 会话超时熔断机制