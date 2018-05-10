---
layout: post
date: 2018-05-02 00:00:00
title: "PowerShell 技能连载 - 列出属性和值（第 3 部分）"
description: PowerTip of the Day - Listing Properties with Values (Part 3)
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
当您希望检查单个对象和它的属性时，将对象用管道输出到 `Out-GridView` 指令不是太方便：网格视图窗口显示一个（非常长的）单行属性。试试这行代码，自己体验一下：

```powershell
PS> Get-Process -Id $pid | Select-Object -Property * | Out-GridView
```

我们之前用过以下函数来对所有没有值的属性排序。但是这个函数还能做更多的事。他支持 `-AsHashtable` 参数，能将一个对象转换为哈希表，可以有效地帮助您显示单个对象的详细内容：

```powershell
# Only list output fields with content

function Remove-EmptyProperty  {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
            $InputObject,

            [Switch]
            $AsHashTable
    )


    begin
    {
        $props = @()

    }

    process {
        if ($props.COunt -eq 0)
        {
            $props = $InputObject |
            Get-Member -MemberType *Property |
            Select-Object -ExpandProperty Name |
            Sort-Object
        }

        $notEmpty = $props | Where-Object {
            !($InputObject.$_ -eq $null -or
                $InputObject.$_ -eq '' -or
                $InputObject.$_.Count -eq 0) |
            Sort-Object

        }

        if ($AsHashTable)
        {
            $notEmpty |
            ForEach-Object {
                $h = [Ordered]@{}} {
                    $h.$_ = $InputObject.$_
                    } {
                    $h
                    }
        }
        else
        {
            $InputObject |
            Select-Object -Property $notEmpty
        }
    }
}
```

当指定了 `-AsHashtable` 以后，`Out-GridView` 纵向显示对象内容，而不是水平显示。而且由于它叶移除了所有空白属性并按字母顺序对属性排序，它变得更容易查看和检视对象：

```powershell
PS> Get-Process -Id $pid | Select-Object -Property * | Remove-EmptyProperty -AsHashTable | Out-GridView
```

例如把它用在 AD 用户对象上：

```powershell
PS> Get-ADUser $env:username -Properties * | Remove-EmptyProperty -AsHashTable | Out-GridView
```

<!--more-->
本文国际来源：[Listing Properties with Values (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/listing-properties-with-values-part-3)
