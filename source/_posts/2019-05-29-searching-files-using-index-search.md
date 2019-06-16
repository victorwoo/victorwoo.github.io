---
layout: post
date: 2019-05-29 00:00:00
title: "PowerShell 技能连载 - 通过 Index Search 搜索文件"
description: PowerTip of the Day - Searching Files Using Index Search
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 索引服务能够对您的用户数据文件进行索引，并且在文件资源管理器中快速搜索。以下是一个基于内容返回文件的函数：

```powershell
function Search-FileContent ([String][Parameter(Mandatory)]$FilterText, $Path = $home )
{
    $objConnection = New-Object -COM ADODB.Connection
    $objRecordset  = New-Object -COM ADODB.Recordset

    $objConnection.Open("Provider=Search.CollatorDSO;Extended properties='Application=Windows';")

    $objRecordset.Open("SELECT System.ItemPathDisplay FROM SYSTEMINDEX WHERE Contains('""$FilterText""') AND SCOPE='$Path'", $objConnection)
    While (!$objRecordset.EOF )
    {
        $objRecordset.Fields.Item("System.ItemPathDisplay").Value
        $null = $objRecordset.MoveNext()
    }
}
```

要使用它，请指定一个关键字。以下代码返回所有包含该关键字的文件：

```powershell
PS> Search-FileContent -FilterText testcase -Path C:\Users\tobwe\Documents\
C:\Users\tobwe\Documents\Development\experiment1.zip
```

如你快速发现的，Index Search 并不会返回 PowerShell 脚本（*.ps1 文件）。缺省情况下，PowerShell 脚本并没有被索引。如果您希望通过内容搜索到这些文件，请到 Index Service 设置并且包含 PowerShell 脚本。点击这里了解更多：[https://devblogs.microsoft.com/scripting/use-windows-search-to-find-your-powershell-scripts/](https://devblogs.microsoft.com/scripting/use-windows-search-to-find-your-powershell-scripts/)

<!--本文国际来源：[Searching Files Using Index Search](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/searching-files-using-index-search)-->

