---
layout: post
date: 2023-04-19 00:00:32
title: "PowerShell 技能连载 - PowerShell 废弃功能（第 2 部分：Exchange Online 中的远程 PowerShell (RPS)）"
description: 'PowerTip of the Day - PowerShell Deprecations (Part 2: Remote PowerShell (RPS) in Exchange Online)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Exchange Online 中的 PowerShell cmdlet 使用“远程 PowerShell”作为远程技术，这是一种在今天世界中存在安全风险的传统技术。这就是为什么 Exchange 团队最初考虑在2023年6月停用 Remote PowerShell。

由于相当多的用户似乎无法切换到新的、更安全的基于 REST 的 v3 PowerShell 模块来管理 Exchange，团队决定添加一种方法让客户重新启用 Remote PowerShell 以延长宽限期（至少适用于 Microsoft 云租户）。

简而言之：如果您仍在使用 Exchange Online 中的 Remote PowerShell，则需要开始计划过渡到基于 REST 的 v3 PowerShell 模块。

<!--本文国际来源：[PowerShell Deprecations (Part 2: Remote PowerShell (RPS) in Exchange Online)](https://blog.idera.com/database-tools/powershell/powertips/powershell-deprecations-part-2-remote-powershell-rps-in-exchange-online/)-->

