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
---
大多数 PowerShell 函数使用静态参数。它们是定义在 `param()` 代码块中的，并且始终存在。一个不太为人所知的情况是您也可以快速地编程添加动态参数。动态参数的最大优势是您可以完全控制它们什么时候可以出现，以及它们可以接受什么类型的数值。它的缺点是需要使用大量底层的代码来“编程”参数属性。

以下是一个示例函数。它只有一个名为 "`Company`" 的静态参数。仅当您选择了一个公司，该函数才会添加一个名为 "`Department`" 的新的动态参数。新的动态参数 `-Department` 根据选择的公司暴露出一个可用值的列表。实质上，根据选择的公司，`-Department` 参数被关联到一个独立的 `ValidateSet` 属性：

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

请注意！当您在选择的编辑器中键入 `Test-Department`，初始情况下只有一个参数：`Tbc-Company`。当您选择了四个可用得公司之一，第二个参数 `-Department` 将变得可用，并且显示当前选中的公司可用的部门。

<!--本文国际来源：[Using Dynamic Parameters](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-dynamic-parameters)-->
