---
layout: post
date: 2018-01-02 00:00:00
title: "PowerShell 技能连载 - 按数据类型绑定参数"
description: PowerTip of the Day - Binding Parameters by Data Type
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
PowerShell 可以根据数据类型匹配自动地绑定参数。以下是一个体现该特性的示例

```powershell
function Test-Binding
{
    [CmdletBinding(DefaultParameterSetName='Date')]
    param
    (
        [Parameter(ParameterSetName='Integer', Position=0, Mandatory=$true)]
        [int]
        $Id,

        [Parameter(ParameterSetName='String', Position=0, Mandatory=$true)]
        [string]
        $Name,

        [Parameter(ParameterSetName='Date', Position=0, Mandatory=$true)]
        [datetime]
        $Date
    )

    $chosenParameterSet = $PSCmdlet.ParameterSetName
    Switch ($chosenParameterSet)
    {
        'Integer' { 'User has chosen Integer' }
        'String'  { 'User has chosen String' }
        'Date'    { 'User has chosen Date' }
    }

    [PSCustomObject]@{
        Integer = $Id
        String = $Name
        Date = $Date
    }
}
```

现在用户可以测试 `Test-Binding` 并且提交参数：

```powershell
PS C:\> Test-Binding "Hello"
User has chosen String

Integer String Date
------- ------ ----
        0 Hello



PS C:\> Test-Binding 12
User has chosen Integer

Integer String Date
------- ------ ----
        12



PS C:\> Test-Binding (Get-Date)
User has chosen Date

Integer String Date
------- ------ ----
        0        11/21/2017 11:44:33 AM
```

<!--more-->
本文国际来源：[Binding Parameters by Data Type](http://community.idera.com/powershell/powertips/b/tips/posts/binding-parameters-by-data-type)
