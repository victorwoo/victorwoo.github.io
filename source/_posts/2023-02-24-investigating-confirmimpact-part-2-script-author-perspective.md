---
layout: post
date: 2023-02-24 00:00:28
title: "PowerShell 技能连载 - 研究 ConfirmImpact（第 2 部分：脚本作者视角）"
description: 'PowerTip of the Day - Investigating ConfirmImpact (Part 2: Script Author Perspective)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的部分中，已经解释了 PowerShell 将 `$ConfirmPreference` 自动变量作为其风险缓解系统的一部分使用：每当一个 PowerShell 命令自身的 "`ConfirmImpact`" 高于或等于 `$ConfirmPreference` 中的设置时，PowerShell 将显示自动确认对话框。

作为函数或脚本作者，您可以使用属性 `CmdletBinding()` 设置函数或脚本的“影响级别”：

```powershell
function Remove-Something
{
    [CmdletBinding(ConfirmImpact='Medium')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    "You entered $Name"
}
```

示例函数 `Remove-Something` 已将其 `ConfirmImpact` 声明为 "`Medium`"，因此当您运行它时，如果 `$ConfirmPreference` 设置为 "`Medium`" 以上的级别，PowerShell 将触发自动确认。

二进制 cmdlet 也是一样。要找出二进制 cmdlet 的确认影响，您可以使用以下函数：

```powershell
filter Get-ConfirmInfo
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $CommandName
    )

    $CommandInfo = Get-Command -Name $CommandName
    [System.Management.Automation.CommandMetaData]::new($CommandInfo) |
    Select-Object -Property Name, ConfirmImpact, SupportsShouldProcess
}
```

当您提交命令名称时，它将显示命令作者定义的 `ConfirmImpact`，以及命令是否支持模拟开关，例如 `-WhatIf`（在这个情况下，`SupportsShouldProcess` 显示 `$true`）。

```powershell
PS> 'Get-Random', 'Remove-Item', 'Stop-Process' | Get-ConfirmInfo

Name         ConfirmImpact SupportsShouldProcess
----         ------------- ---------------------
Get-Random          Medium                 False
Remove-Item         Medium                  True
Stop-Process        Medium                  True
```

由于 `Get-ConfirmInfo` 支持管道，因此您甚至可以检查您的 PowerShell 命令集并搜索高影响级别的命令：

```powershell
PS> Get-Command -Verb Remove | Get-ConfirmInfo | Where-Object ConfirmImpact -eq High

Name                        ConfirmImpact SupportsShouldProcess
----                        ------------- ---------------------
Remove-CIAccessControlRule           High                  True
Remove-CIVApp                        High                  True
Remove-CIVAppNetwork                 High                  True
Remove-CIVAppTemplate                High                  True
Remove-BCDataCacheExtension          High                  True
Remove-ClusterAffinityRule           High                  True
Remove-ClusterFaultDomain            High                  True
(...)
```
<!--本文国际来源：[Investigating ConfirmImpact (Part 2: Script Author Perspective)](https://blog.idera.com/database-tools/powershell/powertips/investigating-confirmimpact-part-2-script-author-perspective/)-->

