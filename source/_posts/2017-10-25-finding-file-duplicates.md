---
layout: post
date: 2017-10-25 00:00:00
title: "PowerShell 技能连载 - 查找重复的文件"
description: PowerTip of the Day - Finding File Duplicates
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
在前一个技能中我们介绍了如何用 `Get-FileHash` cmdlet（PowerShell 5 新增的功能）来生成脚本文件的 MD5 哈希。

哈希可以用来查找重复的文件。大体上，哈希表可以用来检查一个文件哈希是否已经发现过。以下代码检查您的用户配置文件中的所有脚本并且报告重复的文件：

```powershell
$dict = @{}

Get-ChildItem -Path $home -Filter *.ps1 -Recurse |
    ForEach-Object {
        $hash = ($_ | Get-FileHash -Algorithm MD5).Hash
        if ($dict.ContainsKey($hash))
        {
            [PSCustomObject]@{
                Original = $dict[$hash]
                Duplicate = $_.FullName
                }
        }
        else
        {
            $dict[$hash]=$_.FullName
        }
    } |
    Out-GridView
```

<!--more-->
本文国际来源：[Finding File Duplicates](http://community.idera.com/powershell/powertips/b/tips/posts/finding-file-duplicates)
