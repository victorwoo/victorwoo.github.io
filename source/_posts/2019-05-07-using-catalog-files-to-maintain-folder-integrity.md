---
layout: post
date: 2019-05-07 00:00:00
title: "PowerShell 技能连载 - 使用目录文件来维护文件夹完整性"
description: PowerTip of the Day - Using Catalog Files to Maintain Folder Integrity
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望确保一个文件夹的内容保持不变，那么可以使用目录文件。目录文件可以列出所有文件夹内容并为文件夹中的每个文件创建哈希。以下是一个例子：

```powershell
# path to folder to create a catalog file for
# (make sure it exists and isn't too large)
$path = "$Home\Desktop"
# path to catalog file to be created
$catPath = "$env:temp\myDesktop.cat"
# create catalog
New-FileCatalog -Path $path -CatalogVersion 2.0 -CatalogFilePath $catPath
```

根据文件夹的大小，可能需要一些时间来创建目录文件。您无法创建被锁定和在使用中的文件的目录。生成的目录文件是一个二进制文件并且包含目录中所有文件的哈希。

要检查文件夹是否未被该国，您可以使用 `Test-FileCatalog` 命令：

```powershell
PS> Test-FileCatalog -Detailed -Path $path -CatalogFilePath $catPath


Status        : Valid
HashAlgorithm : SHA256
CatalogItems  : {...}
PathItems     : {...}
Signature     : System.Management.Automation.Signature
```

如果文件夹内容和目录相匹配，那么结果状态为 "Valid"。否则，`CatalogItems` 属性将包含一个文件夹中所有内容的详细列表，以及它们是否变更过的标志。

<!--本文国际来源：[Using Catalog Files to Maintain Folder Integrity](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-catalog-files-to-maintain-folder-integrity)-->

