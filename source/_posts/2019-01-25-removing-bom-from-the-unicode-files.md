---
layout: post
date: 2019-01-25 00:00:00
title: "PowerShell 技能连载 - 从 Unicode 文件中移除 BOM"
description: PowerTip of the Day - Removing BOM from the Unicode Files
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
BOM（字节顺序标记）是在某些 Unicode 编码的文本文件特有的字节顺序。如果您收到一个包含了 BOM 的文件，而要处理它的其它系统并不支持 BOM，那么以下是如何用 PowerShell 移除这类文件中的 BOM 的方法：

```powershell
function Remove-BomFromFile ($OldPath, $NewPath)
{
  $Content = Get-Content $OldPath -Raw
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  [IO.File]::WriteAllLines($NewPath, $Content, $Utf8NoBomEncoding)
}
```

现在要获取一个文件的 BOM 并将它转为一个无 BOM 的文件就很方便了：

```powershell
$Path = "$env:temp\export.csv"
$NewPath = "$env:temp\export_new.csv"
Remove-BomFromFile -OldPath $Path -NewPath $NewPath 
```

<!--more-->
本文国际来源：[Removing BOM from the Unicode Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/removing-bom-from-the-unicode-files)
