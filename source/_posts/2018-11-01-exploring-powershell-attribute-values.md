---
layout: post
date: 2018-11-01 00:00:00
title: "PowerShell 技能连载 - 探索 PowerShell 属性值"
description: PowerTip of the Day - Exploring PowerShell Attribute Values
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
您也许知道，您可以对变量和参数添加属性来更有针对性地定义它们。例如，以下代码定义了一个包含只允许三个字符串之一的必选参数的函数：

```powershell
function Test-Attribute
{
    [CmdletBinding()]
    param
    (
        [string]
        [Parameter(Mandatory)]
        [ValidateSet("A","B","C")]
        $Choice
    )

    "Choice: $Choice"
}
```

如果您想知道这些属性有哪些选择，以下是实现方法。您所需要了解的是代表属性的真实名称。PowerShell 自身的属性都位于 `System.Management.Automation` 命名空间。以下是两个最常用的：

```poweshell
[Parameter()] = [System.Management.Automation.ParameterAttribute]
[CmdletBinding()] = [System.Management.Automation.CmdletBindingAttribute]
```

要查看某个指定属性的合法数值，只需要实例化一个制定类型的对象，并查看它的属性：

```powershell
[System.Management.Automation.ParameterAttribute]::new() |
    Get-Member -MemberType *Property |
    Select-Object -ExpandProperty Name
```

这将返回一个包含所有 `[Parameter()]` 属性所有合法属性值的列表：

    DontShow
    HelpMessage
    HelpMessageBaseName
    HelpMessageResourceId
    Mandatory
    ParameterSetName
    Position
    TypeId
    ValueFromPipeline
    ValueFromPipelineByPropertyName
    ValueFromRemainingArguments

当您向每个值添加期望的数据类型时，该列表就更有用了：

```powershell
[System.Management.Automation.ParameterAttribute]::new() |
    Get-Member -MemberType *Property |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Type = ($_.Definition -split ' ')[0]
        }
    }
```

现在它看起来类似这样：

```powershell
Name                            Type
----                            ----
DontShow                        bool
HelpMessage                     string
HelpMessageBaseName             string
HelpMessageResourceId           string
Mandatory                       bool
ParameterSetName                string
Position                        int
TypeId                          System.Object
ValueFromPipeline               bool
ValueFromPipelineByPropertyName bool
ValueFromRemainingArguments     bool
```

例如这是 `[CmdletBinding()]` 的列表：

```powershell
[System.Management.Automation.CmdletBindingAttribute]::new() |
    Get-Member -MemberType *Property |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Type = ($_.Definition -split ' ')[0]
        }
    }



Name                    Type
----                    ----
ConfirmImpact           System.Management.Automation.ConfirmImpact
DefaultParameterSetName string
HelpUri                 string
PositionalBinding       bool
RemotingCapability      System.Management.Automation.RemotingCapability
SupportsPaging          bool
SupportsShouldProcess   bool
SupportsTransactions    bool
TypeId                  System.Object
```

<!--more-->
本文国际来源：[Exploring PowerShell Attribute Values](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-powershell-attribute-values)
