---
layout: post
date: 2014-12-31 12:00:00
title: "PowerShell 技能连载 - 改变 GPO 描述/备注"
description: PowerTip of the Day - Changing GPO Description/Comment
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_需要 GroupPolicy 模块_

当您创建了一个新的组策略，您可以设置一个备注（或描述）。然而，没有一种明显的办法来修改这个备注值。

以下这段代码用于获取一个组策略，然后读取并/或修改它的描述。请确保您将“PolicyName”的名称修改为在您环境中实际存在的一个组策略名：

    Import-Module -Name GroupPolicy
    $policy = Get-Gpo -Name 'PolicyName'
    $policy.Description
    $policy.Description = 'New Description'

请注意只有当您重新打开了组策略客户端工具时，修改的内容才会反映到 UI 中。还请注意您需要 `GroupPolicy` PowerShell 模块。它随 Microsoft 的 RSAT 工具免费发布。在客户端，`GroupPolicy` 模块需要在控制面板/程序中启用才可以使用。

<!--本文国际来源：[Changing GPO Description/Comment](http://community.idera.com/powershell/powertips/b/tips/posts/changing-gpo-description-comment)-->
