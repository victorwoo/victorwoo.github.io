---
layout: post
date: 2021-12-29 00:00:00
title: "PowerShell 技能连载 - 自动化下载联想驱动程序（第 1 部分）"
description: PowerTip of the Day - Automating Lenovo Driver Downloads (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多硬件供应商提供基于 Web 的自助服务门户。以下是 Lenovo 返回有关驱动程序和其他更新下载的详细信息的示例：

[https://download.lenovo.com/cdrt/tools/drivermatrix/dm.html](https://download.lenovo.com/cdrt/tools/drivermatrix/dm.html)

如果您需要管理成百上千台机器或需要定期查找信息，您当然希望自动化此资源。典型的第一种方法是检查 HTML 源代码并搜索 Web 服务，或者如果一切都失败了，则使用 `Invoke-RestMethod` 和 session cookie 来发送表单数据并模仿用户输入。

这不仅复杂，甚至可能完全失败。例如，Lenovo 网站使用 Javascript 编写 Web 前端，因此 PowerShell 和 `Invoke-RestMethod` 此时起不了作用。您必须使用基于 Selenium 的测试浏览器或其他高级 Web 浏览器自动化。

但是，当您仔细查看 HTML 源代码时，您可能会遇到这样的代码：

```powershell
$.get("../../../catalog/" + x + "_" + document.getElementById("os").value + ".xml", function(data, status)
```

显然，网站上显示的数据来自静态 XML 文件，因此实际上不需要对 Web 界面进行自动化操作。在这种情况下，您只需要知道这些 XML 文件的命名方式。

这是包装这些 XML 文档的 PowerShell 函数。它返回所有型号的 Lenovo 驱动程序信息，并且是完全自动化的：

```powershell
function Get-LenovoDriver
{
     param
     (
          $Model = '20JN',

          $Os = 'Win7',

          $Category = '*'
     )




     $url = "https://download.lenovo.com/catalog/${model}_$os.xml"
     $info = $model, $os
     $url = "https://download.lenovo.com/catalog/{0}_{1}.xml" -f $info

     $xml = Invoke-RestMethod -Uri $url -UseBasicParsing
     $data = [xml]$xml.Substring(3)
     [xml]$data = $xml.Substring(3)



     $data.packages.package |
          Where-Object { $_.Category -like $Category } |
          ForEach-Object {
          $location = $_.location
          $name = $_.category
          $rohdaten = Invoke-RestMethod -Uri $location -UseBasicParsing
          [xml]$info = $rohdaten.Substring(3)
          $filename = $info.Package.Files.Installer.File.Name
          [PSCustomObject]@{
               Category = $name
               Command = $info.package.ExtractCommand
               Space = $info.package.DiskspaceNeeded
               Reboot = $info.package.Reboot.type
               Version = $info.package.version
               Download = "https://download.lenovo.com/pccbbs/mobiles/$filename"
               Datum = Get-Date
          }
     }
}
```

您现在可以直接从 PowerShell 命令行检索信息，而不是手动操作 HTML 页面，例如：

```powershell
PS> Get-LenovoDriver -Model 20JN -Os Win10 | Out-GridView -PassThru


Category : ThinkVantage Technology
Command  : n1msk20w.exe /VERYSILENT /DIR=%PACKAGEPATH% /EXTRACT="YES"
Space    : 33206066
Reboot   : 3
Version  : 1.82.0.20
Download : https://download.lenovo.com/pccbbs/mobiles/n1msk20w.exe
Datum    : 09.12.2021 13:16:00
```

即使您不管理 Lenovo 硬件，您也可以复用此示例中介绍的一些技术。

<!--本文国际来源：[Automating Lenovo Driver Downloads (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/automating-lenovo-driver-downloads-part-1)-->

