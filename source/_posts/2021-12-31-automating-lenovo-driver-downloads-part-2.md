---
layout: post
date: 2021-12-31 00:00:00
title: "PowerShell 技能连载 -  自动化下载联想驱动程序（第 2 部分）"
description: PowerTip of the Day - Automating Lenovo Driver Downloads (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的示例中，我们说明了如何从 Web 抓取联想驱动程序信息。在此示例中，返回的一些信息是原始数字信息：例如，表示 "3" 表示需要重启。

在这个技能中，我们想展示如何幻数 (cryptic numeric values) 转换为友好的文本。首先，让我们来看看改进的 Lenovo 函数：

```powershell
function Get-LenovoDriver
{
     param
     (
          $Model = '20JN',

          $Os = 'Win7',

          $Category = '*'
     )


     $restartText = @{
          '0' = "No restart"
          '1' = "Forced restart"
          '3' = "Restart required"
          '4' = "Shutdown after install"
     }

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
               $readme = [System.IO.Path]::ChangeExtension($filename, 'txt')
               $readme = $info.Package.Files.Readme.file.Name

               [PSCustomObject]@{
                    Category = $name
                    Command = $info.package.ExtractCommand
                    Space = $info.package.DiskspaceNeeded
                    SpaceMB = [Math]::Round( ($info.package.DiskspaceNeeded / 1MB), 1)
                    Reboot = $info.package.Reboot.type
                    RebootFriendly = $restartText[$info.package.Reboot.type]
                    Version = $info.package.version
                    Download = "https://download.lenovo.com/pccbbs/mobiles/$filename"
                    ReadMe = "https://download.lenovo.com/pccbbs/mobiles/$readme"
                    Datum = Get-Date
               }
          }
}
```

您现在可以通过以下方式获取有关任何 Lenovo 机器的任何驱动程序更新的信息：

```powershell
PS C:\> Get-LenovoDriver -Model 20JN -Os Win10 | Out-GridView -PassThru


Category       : Camera and Card Reader
Command        : n1qib04w.exe /VERYSILENT /DIR=%PACKAGEPATH% /EXTRACT="YES"
Space          : 6442356
SpaceMB        : 6,1
Reboot         : 1
RebootFriendly : Forced restart
Version        : 3760
Download       : https://download.lenovo.com/pccbbs/mobiles/n1qib04w.exe
ReadMe         : https://download.lenovo.com/pccbbs/mobiles/n1qib04w.txt
Datum          : 09.12.2021 13:21:21
```

属性 "`Reboot`" 显示原始的幻数。 新属性 "`“RebootFriendly”`" 则用友好的文本表示，在这个例子中是 "Forced restart"。

让我们解读一下源代码来了解转换的过程。

对于任何转换过程，您需要准备一个哈希表，该表将幻数映射到友好的文本：

```powershell
$restartText = @{
          '0' = "No restart"
          '1' = "Forced restart"
          '3' = "Restart required"
          '4' = "Shutdown after install"
     }
```

接下来，将数值转换为文本，与查找哈希表值一样简单：

```powershell
...
Reboot = $info.package.Reboot.type
RebootFriendly = $restartText[$info.package.Reboot.type]
...
```

<!--本文国际来源：[Automating Lenovo Driver Downloads (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/automating-lenovo-driver-downloads-part-2)-->

