---
layout: post
date: 2018-11-26 00:00:00
title: "PowerShell 技能连载 - 使用目录文件"
description: PowerTip of the Day - Using Catalog Files
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
目录文件支持 (.cat) 是 PowerShell 5.1 新引入的特性。目录文件基本上是包含哈希值的文件列表。您可以用它们来确保一个指定的文件结构没有改变。

以下是一个简单的示例。它输入一个文件夹（请确保文件夹存在，否则将它重命名）并对整个文件夹的内容创建一个目录文件。请注意这将对文件夹中的每个文件创建一个哈希值，所以请留意文件夹的体积不要太大：

```powershell
$path = c:\folderToCheck"
$catPath = "$home\Desktop\summary.cat"
New-FileCatalog -Path $path -CatalogVersion 2.0 -CatalogFilePath $catPath
```

`New-FileCatalog` 将在桌面上创建一个 summary.cat 文件。这个文件可以用于测试文件夹结构并确保文件没有改变过：

```powershell
Test-FileCatalog -Detailed -Path $path -CatalogFilePath $catPath
```

结果看起来类似这样：

    Status        : Valid
    HashAlgorithm : SHA1
    CatalogItems  : {[remoting systeminventar.ps1, 
                    F43C8D6F9CB93FB9AA5DBA6733D9996645832256], [klonen und 
                    prozessprio.ps1, F3DE20424CD90CDB5B85933B777A2F9A3F3D3187], 
                    [scriptblock rueckgabewerte.ps1, 
                    EB239D7906EF42E2639CACBE68C6FDD8F4AD899F], [Untitled4.ps1, 
                    E5E4DC20934287ED869230706A1DEEDEB550B8DE]...}
    PathItems     : {[beispielsyntax.ps1, 
                    5183C82B7F0F3D0623242DD5F97A658724BE3B81], [closure.ps1, 
                    D2A036B068548B3E773E3BEBCF40997231576ED1], [debug1.ps1, 
                    3547D2659792A9ABA9E6E12F287D7A8116540FCF], [debug2.ps1, 
                    76C63FA578C09F30DF2BE055C37C039AFB1EFEDE]...}
    Signature     : System.Management.Automation.Signature 

请注意 `New-FileCatalog` 当前并不支持路径中的特殊字符，例如德语的 "Umlaute"。

<!--more-->
本文国际来源：[Using Catalog Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-catalog-files)
