---
layout: post
date: 2018-01-03 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 函数中支持风险缓解"
description: PowerTip of the Day - Supporting Risk Mitigation in PowerShell Functions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
当一个 PowerShell 函数进行一个可能有风险的系统变更时，推荐使用 `-WhatIf` 和 `-Configm` 风险缓解参数。以下是基本的需求：

```powershell
function Test-WhatIf
{
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low',HelpUri='http://www.myhelp.com')]
    param()



    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,"Say 'Hello'"))
    {
        "I am executing..."
    }
    else
    {
        "I am simulating..."
    }

}
```

当运行这个函数时，PowerShell 会遵从 `-WhatIf` 和 `-Confirm` 参数设置：

```powershell
PS C:\> Test-WhatIf -WhatIf
What if: Performing the operation "Say 'Hello'" on target "PC10".
I am simulating...

PS C:\> Test-WhatIf
I am executing...

PS C:\>
```

这个函数还定义了一个 `ConfirmImpact` 属性，它的值可以是 `Low`、`Medium` 或 `High`，表示这个函数的操作引起的改变有多严重。

当 `ConfirmImpact` 的值大于或等于 `$ConfirmPreference` 变量中定义的值时，PowerShell 自动向用户显示一个确认信息：

```powershell
PS C:\> $ConfirmPreference = "Low"

PS C:\> Test-WhatIf
I am executing...


Confirmation
Do you really want to perform this action?
...
I am simulating...
```

<!--more-->
本文国际来源：[Supporting Risk Mitigation in PowerShell Functions](http://community.idera.com/powershell/powertips/b/tips/posts/supporting-risk-mitigation-in-powershell-functions)
