---
layout: post
date: 2018-10-31 00:00:00
title: "PowerShell 技能连载 - 使用动态参数"
description: PowerTip of the Day - Using Dynamic Parameters
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
大多数 PowerShell 函数使用静态参数。它们在 `param()` 中定义，而且总是存在。一个很少人知道的事实是您也可以快速地添加动态参数。动态参数的最大好处是您完全不需要事先知道它们什么时候出现，以及它接受什么数据类型。缺点是您需要用一大堆底层代码来“编写”参数属性的代码。

以下是一个示例函数。它只有一个名为 "`Company`" 的静态变量。仅当您传入公司参数的时候该函数才会增加一个名为 "`Department`" 的动态参数。根据选择的公司，新的动态参数 `-Department` 将暴露一个合法值的列表。实质上，根据选择的公司，`-Department` 参数被赋予一个独立的 `ValidateSet` 属性：

```powershell
function Test-Department
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Microsoft','Amazon','Google','Facebook')]
        $Company
    )

    dynamicparam
    {
        # this hash table defines the departments available in each company
        $data = @{
            Microsoft = 'CEO', 'Marketing', 'Delivery'
            Google = 'Marketing', 'Delivery'
            Amazon = 'CEO', 'IT', 'Carpool'
            Facebook = 'CEO', 'Facility', 'Carpool'
        }

        # check to see whether the user already chose a company
        if ($Company)
        {
            # yes, so create a new dynamic parameter
            $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]

            # define the parameter attribute
            $attribute = New-Object System.Management.Automation.ParameterAttribute
            $attribute.Mandatory = $false
            $attributeCollection.Add($attribute)

            # create the appropriate ValidateSet attribute, listing the legal values for
            # this dynamic parameter
            $attribute = New-Object System.Management.Automation.ValidateSetAttribute($data.$Company)
            $attributeCollection.Add($attribute)

            # compose the dynamic -Department parameter
            $Name = 'Department'
            $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($Name,
            [string], $attributeCollection)
            $paramDictionary.Add($Name, $dynParam)

            # return the collection of dynamic parameters
            $paramDictionary
        }
    }

    end
    {
        # take the dynamic parameters from $PSBoundParameters
        $Department = $PSBoundParameters.Department

        "Chosen department for $Company : $Department"
    }
}
```

请注意！当您在选用的编辑器中输入 `Test-Department`，起初只有一个参数：`-Company`。一旦您选择四个可用的公司之一，第二个参数 `-Department` 就可以使用并且显示选中公司中可用的部门。

<!--more-->
本文国际来源：[Using Dynamic Parameters](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-dynamic-parameters)
