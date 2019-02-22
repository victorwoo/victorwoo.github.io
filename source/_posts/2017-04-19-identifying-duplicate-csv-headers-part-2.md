---
layout: post
date: 2017-04-19 00:00:00
title: "PowerShell 技能连载 - 确认重复的 CSV 表头（第二部分）"
description: PowerTip of the Day - Identifying Duplicate CSV Headers (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个 CSV 文件包含重复的表头时，它无法被导入。在前一个技能中我们掩饰了如何检测一个 CSV 文件中重复的表头。以下是一个自动更正重复项的实践。

第一步，您需要一个包含重复表头的 CSV 文件。例如在德文系统中，您可以这样创建一个文件：

```powershell
PS C:\> driverquery /V /FO CSV | Set-Content -Path $env:temp\test.csv -Encoding UTF8
```

快速打开该文件并检查它是否确实包含重复项。

```powershell
PS C:\> notepad $env:temp\test.csv
```

如果没有重复项，请将某些表头重命名以制造一些重复项，并保存文件。

您现在可以用 `Import-Csv` 导入 CSV 文件了：

```powershell
PS C:\>  Import-Csv -Path $env:temp\test.csv -Delimiter ','
Import-Csv : Element  "Status" is present already.
In Zeile:1 Zeichen:1
+ Import-Csv -Path $env:temp\test.csv  -Delimiter ','
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    +  CategoryInfo          : NotSpecified: (:)  [Import-Csv], ExtendedTypeSystemException
    +  FullyQualifiedErrorId :  AlreadyPresentPSMemberInfoInternalCollectionAdd,Microsoft.PowerShell.Commands.ImportCsvCommand
```

这是一个新的名为 `Import-CsvWithoutDuplicate` 的函数，可以自动处理重复的项：

```powershell
function Import-CsvWithDuplicate($Path, $Delimiter=',', $Encoding='UTF8')
{
    # get the header line and all header items
    $headerLine = Get-Content $Path | Select-Object -First 1
    $headers = $headerLine.Split($Delimiter)

    # check for duplicate header names, and if found, add an incremented
    # number to it
    $dupDict = @{}
    $newHeaders = @(foreach($header in $headers)
    {
        $incrementor = 1
        $header = $header.Trim('"')
        $newheader = $header

        # increment numbers until the new name is unique
        while ($dupDict.ContainsKey($newheader) -eq $true)
        {
            $newheader = "$header$incrementor"
            $incrementor++
        }

        $dupDict.Add($newheader, $header)

        # return the new header, producing a string array
        $newheader
    })

    # read the CSV without its own headers..
    Get-Content -Path $Path -Encoding $Encoding |
        Select-Object -Skip 1 |
        # ..and replace headers with newly created list
        ConvertFrom-CSV -Delimiter $Delimiter -Header $newHeaders
}
```

通过它，您可以安全地导入 CSV 文件，不会遇到重复的表头：

```powershell
PS C:\> Import-CsvWithDuplicate -Path $env:temp\test.csv -Delimiter ','


Modulname                  : 1394ohci
Anzeigename                : OHCI-konformer 1394-Hostcontroller
Beschreibung               : OHCI-konformer 1394-Hostcontroller
Treibertyp                 : Kernel
Startmodus                 : Manual
Status                     : Stopped
Status1                    : OK
Beenden annehmen           : FALSE
Anhalten annehmen          : FALSE
Ausgelagerter Pool (Bytes) : 4.096
Code(Bytes)                : 204.800
BSS(Bytes)                 : 0
Linkdatum                  : 16.07.2016 04:21:36
Pfad                       : C:\WINDOWS\system32\drivers\1394ohci.sys
Init(Bytes)                : 4.096

Modulname                  : 3ware
Anzeigename                : 3ware
Beschreibung               : 3ware
Treibertyp                 : Kernel
Startmodus                 : Manual
Status                     : Stopped
Status1                    : OK
Beenden annehmen           : FALSE
Anhalten annehmen          : FALSE
Ausgelagerter Pool (Bytes) : 0
(...)
```

如您所见，这个函数自动将第二个 "Status" 实例重命名为 "Status1"。

<!--本文国际来源：[Identifying Duplicate CSV Headers (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-duplicate-csv-headers-part-2)-->
