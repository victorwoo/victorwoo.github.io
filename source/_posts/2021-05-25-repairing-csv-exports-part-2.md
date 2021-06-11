---
layout: post
date: 2021-05-25 00:00:00
title: "PowerShell 技能连载 - 修复 CSV 导出（第 2 部分）"
description: PowerTip of the Day - Repairing CSV Exports (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们指出了将对象转换为 CSV 时的一个普遍问题：任何包含数组的属性都将显示数组数据类型而不是数组内容。下面是一个例子：

```powershell
PS> Get-Service | Select-Object -Property Name, DependentServices, RequiredServices | ConvertTo-Csv

#TYPE Selected.System.ServiceProcess.ServiceController
"Name","DependentServices","RequiredServices"
"AarSvc_e1277","System.ServiceProcess.ServiceController[]","System.ServiceProcess.ServiceController[]"
"AdobeARMservice","System.ServiceProcess.ServiceController[]","System.ServiceProcess.ServiceController[]"
```

在上一个技能中，我们还展示了该问题的手动解决方案：您总是可以使用 `-join` 运算符手动将任何数组属性的内容转换为字符串：

```powershell
Get-Service |
  Select-Object -Property Name, DependentServices, RequiredServices |

  ForEach-Object {
    $_.DependentServices = $_.DependentServices -join ','
    $_.RequiredServices = $_.RequiredServices -join ','
    return $_
  } |

  ConvertTo-Csv
```

数据现已“修复”，数组属性内容显示正确：

    "Name","DependentServices","RequiredServices"
    "AppIDSvc","applockerfltr","RpcSs,CryptSvc,AppID"
    "Appinfo","","RpcSs,ProfSvc"
    "AppVClient","","AppvVfs,RpcSS,AppvStrm,netprofm"
    "AppXSvc","","rpcss,staterepository"
    "AssignedAccessManagerSvc","",""
    ...

但是，将数组属性转换为扁平字符串可能需要大量手动工作，因此这里有一个名为 `Convert-ArrayPropertyToString` 的新函数，它会自动完成所有转换：

```powershell
function Convert-ArrayPropertyToString
{
  process
  {
    $original = $_
    Foreach ($prop in $_.PSObject.Properties)
    {
      if ($Prop.Value -is [Array] -and $prop.MemberType -ne 'AliasProperty')
      {
        Add-Member -InputObject $original -MemberType NoteProperty -Name $prop.Name -Value ($prop.Value -join ',') -Force
      }
    }
    $original
  }
}
```

要将对象转换为 CSV 而不丢失数组信息，只需将它通过管道传给新函数：

```powershell
PS> Get-Service | Select-Object -Property Name, DependentServices, RequiredServices | Convert-ArrayPropertyToString | ConvertTo-Csv

#TYPE Selected.System.ServiceProcess.ServiceController
"Name","DependentServices","RequiredServices"
"AarSvc_e1277","",""
"AppIDSvc","applockerfltr","RpcSs,CryptSvc,AppID"
"Appinfo","","RpcSs,ProfSvc"
"AppMgmt","",""
"AppReadiness","",""
"AppVClient","","AppvVfs,RpcSS,AppvStrm,netprofm"
```

厉害吧？新函数能为您完成所有工作，它适用于任何对象：

```powershell
PS> [PSCustomObject]@{
  Name = 'Tobias'
  Array = 1,2,3,4
  Date = Get-Date
} | Convert-ArrayPropertyToString

Name   Date                Array
----   ----                -----
Tobias 06.05.2021 11:30:58 1,2,3,4
```

`Convert-ArrayPropertyToString` 使用在任何 PowerShell 对象都包含的 `PSObject` 隐藏属性来获取属性名称。接下来，它检查数组内容的所有属性。如果找到，它会自动将数组转换为逗号分隔的字符串。

为了能够使用新的扁平字符串内容覆盖现有属性——即使属性被写保护——它使用 `Add-Member` 并使用 `-Force` 隐藏属性。新的扁平字符串内容并没有真正覆盖属性。相反，它们被添加并优先使用。实际上，任何对象——即使其属性被写保护——都可以调整。

现在，每当您需要创建 Excel 报告或将数据导出到 CSV 时，您都可以轻松保留数组内容。

<!--本文国际来源：[Repairing CSV Exports (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-csv-exports-part-2)-->

