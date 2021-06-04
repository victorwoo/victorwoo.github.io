---
layout: post
date: 2021-05-21 00:00:00
title: "PowerShell 技能连载 - 修复 CSV 导出（第 1 部分）"
description: PowerTip of the Day - Repairing CSV Exports (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您将数据转换为 CSV 时，您可能会遇到一个很烦恼的情况：某些属性不是显示原始数据。下面是一个例子：

```powershell
PS> Get-Service | Select-Object -Property Name, DependentServices, RequiredServices | ConvertTo-Csv

#TYPE Selected.System.ServiceProcess.ServiceController
"Name","DependentServices","RequiredServices"
"AarSvc_e1277","System.ServiceProcess.ServiceController[]","System.ServiceProcess.ServiceController[]"
"AdobeARMservice","System.ServiceProcess.ServiceController[]","System.ServiceProcess.ServiceController[]"
```

如您所见，`DependentServices` 和 `RequiredServices` 属性和所有服务显示的内容是一样的。

当属性包含数组时会发生这种情况。扁平化二维导出格式（例如 CSV）无法显示数组，因此将显示数组数据类型。这对用户来说当然根本没有帮助。

在我们解决它之前先总结一下：您在这里看到的是许多场景中的严重问题。它不仅影响CSV导出，还影响导出为 Excel 或其他二维表格格式。

要解决这个问题，您必须将所有数组转换为字符串。您可以手动或自动执行此操作。在这个技能中，我们首先展示手动方法来关注效果。在未来的技能中，我们会自动执行相同的操作。

这是从上方正确导出所选数据的手动方法：

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

数据现在显示所有数组内容，因为 `ForEach-Object` 循环已使用 `-join` 运算符将数组内容转换为逗号分隔的字符串。

    "Name","DependentServices","RequiredServices"
    "AppIDSvc","applockerfltr","RpcSs,CryptSvc,AppID"
    "Appinfo","","RpcSs,ProfSvc"
    "AppVClient","","AppvVfs,RpcSS,AppvStrm,netprofm"
    "AppXSvc","","rpcss,staterepository"
    "AssignedAccessManagerSvc","",""
    ...

只要您通过 `Select-Object` 操作原始数据，就可以进行这种“调整”：`Select-Object` 始终复制（克隆）信息，因此一旦 `Select-Object` 处理了数据，您就拥有这些对象并可以以任何方式更改其属性。

<!--本文国际来源：[Repairing CSV Exports (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-csv-exports-part-1)-->

