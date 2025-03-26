---
layout: post
date: 2024-04-15 00:00:00
title: "PowerShell 技能连载 - 针对Windows服务器的4种强大的PowerShell安全技术"
description: "4 Powerful PowerShell Security Techniques for Windows Servers"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
# 简介

在不断发展的网络安全领域中，加固您的[Windows服务器](https://en.wikipedia.org/wiki/Windows_Server)不仅是最佳实践，而且是必要的。[PowerShell](https://powershellguru.com/powershell-tutorial-for-beginners/)凭借其多功能性和自动化能力，在确保服务器安全的神奇旅程中成为我们可靠的魔杖。让我们讨论一下4种PowerShell安全技术，这将有助于实现我们的目标。

# PowerShell安全性: 使用PowerShell进行审计

## 使用POSH-Sysmon配置Sysmon

**Sysmon: 沉默的哨兵**

由微软开发的Sysmon是一个强大的工具，用于监视系统并添加细粒度事件以便即使在重启后也能被跟踪。

这就像拥有一把神奇的放大镜，可以揭示服务器上隐藏的活动。

**为什么使用POSH-Sysmon?**

POSH-Sysmon是一个简化配置Sysmon 的PowerShell脚本。

它让您可以轻松地使用PowerShell创建和管理 Sysinternals Sysmon v2.0 配置文件。

通过Sysmon，您可以跟踪与进程创建、网络连接、注册表更改等相关的事件。

**示例: 检测凭证提取尝试**

要追踪最关键的事件之一——恶意进程尝试从内存中提取凭据时，

请使用 ProcessAccess 过滤器来检测Local Security Authority Subsystem Service (LSASS) 中此类尝试：

```powershell
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' | Where-Object {$_.EventID -eq 10 -and $_.Message -like '*LSASS*'}
```

# 强化您的电子邮件堡垒：客户端规则转发阻止控制

**为什么这很重要？**

攻击者经常利用Office 365，在Outlook中设置静默规则，将敏感电子邮件转发到他们的账户。

通过启用客户端规则转发阻止控制来加强您的电子邮件安全性。

**PowerShell操作:**

使用PowerShell启用转发阻止：

```powershell
Set-OrganizationConfig -RulesQuota 0
```

# 使用DSC进行PowerShell安全配置

**什么是PowerShell DSC?**

期望状态配置（DSC）就像一种魔法咒语，确保您的服务器保持安全配置。

它允许您定义和强制执行Windows服务器的期望状态。

**示例：根据CIS基准进行安全配置**

使用PowerShell DSC根据CIS Microsoft Windows Server 2019或Azure Secure Center Baseline for Windows Server 2016等基准应用安全配置。

您的DSC代码成为了您的护身符：

```powershell
Configuration SecureServer {
    Import-DscResource -ModuleName SecurityPolicyDsc
    Node 'localhost' {
        SecurityPolicy 'Audit - Audit account logon events' {
            PolicySetting = 'Success,Failure'
        }
        # 更多安全设置在此处...
    }
}
```

# HardeningKitty：Windows配置的猫护卫

**小猫在忙什么？**

HardeningKitty，我们的猫友，会自动检查和评估Windows系统的硬化。

它还会检查像Microsoft Office和Microsoft Edge这样的单个应用程序。

**PowerShell完美性：**

运行HardeningKitty来评估您系统的安全姿态：

```powershell
.\HardeningKitty.ps1 -AuditSystem
```

# 结论

通过使用PowerShell，我们施展了审计、保护和加固我们的Windows服务器。记住，安全是一个持续不断的追求 —— 让你的咒语锋利，让你的PowerShell脚本更加精湛！
