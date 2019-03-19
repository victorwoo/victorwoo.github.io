---
layout: post
date: 2017-10-24 00:00:00
title: "PowerShell 技能连载 - 创建 MD5 文件哈希"
description: PowerTip of the Day - Creating MD5 File Hashes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
MD5 文件哈希可以唯一确定文件内容，并且可以用来检测文件内容是否唯一。在 PowerShell 5 中，有一个新的 cmdlet 可以创建文件哈希。以下代码将在您的用户配置文件中查找所有 PowerShell 脚本，并且为每个文件生成 MD5 哈希：

```powershell
Get-ChildItem -Path $home -Filter *.ps1 -Recurse |
    Get-FileHash -Algorithm MD5 |
    Select-Object -ExpandProperty Hash
```

一个更好的方法是将哈希值关联到原始路径上：

```powershell
Get-ChildItem -Path $home -Filter *.ps1 -Recurse |
    ForEach-Object {
    [PSCustomObject]@{
        Hash = ($_ | Get-FileHash -Algorithm MD5).Hash
        Path = $_.FullName
    }
    }
```

输出结果类似如下：

```
Hash                             Path
----                             ----
2AE5CA30DCF6550903B994E61A714AC0 C:\Users\tobwe\.nuget\packages\Costura.Fody...
46CB505EECEC72AA8D9104A6263D2A76 C:\Users\tobwe\.nuget\packages\Costura.Fody...
2AE5CA30DCF6550903B994E61A714AC0 C:\Users\tobwe\.nuget\packages\Costura.Fody...
46CB505EECEC72AA8D9104A6263D2A76 C:\Users\tobwe\.nuget\packages\Costura.Fody...
930621EE040F82392017D240CAE13A97 C:\Users\tobwe\.nuget\packages\Fody\2.1.2\T...
39466FE42CE01CC7786D8B446C4C11C2 C:\Users\tobwe\.nuget\packages\MahApps.Metr...
2FF7910807634C984FC704E52ABCDD36 C:\Users\tobwe\.nuget\packages\microsoft.co...
C7E3AAD4816FD98443A7F1C94155954D C:\Users\tobwe\.nuget\packages\microsoft.co...
...
```

<!--本文国际来源：[Creating MD5 File Hashes](http://community.idera.com/powershell/powertips/b/tips/posts/creating-md5-file-hashes)-->
