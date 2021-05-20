---
layout: post
date: 2021-04-19 00:00:00
title: "PowerShell 技能连载 - 使用 NTFS 流（第 5 部分）"
description: PowerTip of the Day - Working with NTFS Streams (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能中，我们研究了 NTFS 流，并发现 Windows 如何使用“区域信息”流标记下载的文件。您还学习了使用 `Unblock-File` 从文件中删除此限制。

在最后一部分中，我们做了相反的事情，查找从不受信任的来源下载的文件。例如，此行列出了所有附加了 `Zone.Identifier` 流的文件：

```powershell
$path = "$env:userprofile\Downloads"

Get-ChildItem -Path $Path -file |
  Where-Object { @(Get-Item -Path $_.FullName -Stream *).Stream -contains 'Zone.Identifier' }
```

所有这些文件都来自 Windows 认为不一定可信的来源。

要了解更多信息，您必须阅读附件中的信息流。这段代码揭示了“下载”文件夹中所有“区域信息”流的全部内容：

```powershell
$path = "$env:userprofile\Downloads"

Get-ChildItem -Path $Path -file |
  Where-Object { @(Get-Item -Path $_.FullName -Stream *).Stream -contains 'Zone.Identifier' } |
  ForEach-Object {
    Get-Content -Path $_.FullName -Stream Zone.Identifier
  }
```

显然，该信息包含有关引用和来源的信息，因此您可以还原此信息并找出在“下载”文件夹中找到的所有内容的来源：

```powershell
$path = "$env:userprofile\Downloads"

Get-ChildItem -Path $Path -file |
  Where-Object { @(Get-Item -Path $_.FullName -Stream *).Stream -contains 'Zone.Identifier' } |
  ForEach-Object {
    $info = Get-Content -Path $_.FullName -Stream Zone.Identifier
    [PSCustomObject]@{
        Name = $_.Name
        Referrer = @(($info -like 'ReferrerUrl=*').Split('='))[-1]
        HostUrl = @(($info -like 'HostUrl=*').Split('='))[-1]
        Path = $_.FullName
    }
  } |
  Out-GridView
```

这使您可以很好地了解下载的原始来源。

<!--本文国际来源：[Working with NTFS Streams (Part 5)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-ntfs-streams-part-5)-->
