---
layout: post
date: 2015-03-11 11:00:00
title: "PowerShell 技能连载 - 禁止确认信息"
description: PowerTip of the Day - Suppress Confirmation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

某些 cmdlet（例如 `Remove-ADGroupMember`）会自动提示确认信息。这在无人值守的脚本中会有问题。

要禁用这些不需要的确认对话框，请显式将 `-Confirm` 开关参数设置为 `false`：

    Remove-ADGroupMember -Identity 'Domain Admins' -Members user12 -Confirm:$false

或者，您可以修改安全级别。PowerShell 将会自动读取该设置。这行代码将所有 cmdlet 的自动确认关闭：

    $ConfirmPreference = 'None'

请注意两个技能都只对缺省的确认对话框有效。如果一个 cmdlet 以 PowerShell 确认框架之外的方式提示确认，您需要参阅 cmdlet 的文档来查找如何禁止它的方法。

<!--本文国际来源：[Suppress Confirmation](http://community.idera.com/powershell/powertips/b/tips/posts/suppress-confirmation)-->
