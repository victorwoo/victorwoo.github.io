---
layout: post
date: 2021-04-15 00:00:00
title: "PowerShell 技能连载 - 使用 NTFS 流（第 4 部分）"
description: PowerTip of the Day - Working with NTFS Streams (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每当您从 Internet（或其他不受信任的来源）下载文件并将其存储在 NTFS 驱动器上时，Windows 就会使用区域标识符对这些文件进行静默标记。例如，这就是为什么 PowerShell 拒绝执行从域外部下载的脚本的原因。

您实际上可以查看区域标识符。只要确保您从 Internet 下载文件并将其存储在 NTFS 驱动器上即可。接下来，使用此行查看区域标识符：

```powershell
Get-Content -Path C:\users\tobia\Downloads\Flyer2021.rar -Stream Zone.Identifier
```

如果存在该流，则您会看到类似以下信息：

    [ZoneTransfer]
    ZoneId=3
    ReferrerUrl=https://shop.laserkino.de/
    HostUrl=https://www.somecompany/Flyer2021.rar

它暴露了文件的来源以及从中检索文件的远程区域的类型。如果没有附加到文件的区域信息，则上述命令将引发异常。

若要从文件中删除区域信息（并删除所有限制），请使用 `Unblock-File` cmdlet。例如，要取消阻止“下载”文件夹中的所有文件，请尝试以下操作：

```powershell
Get-ChildItem -Path C:\users\tobia\Downloads\ -File | Unblock-File -WhatIf
```

删除 `-WhatIf` 参数以实际删除该保护流。

<!--本文国际来源：[Working with NTFS Streams (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-ntfs-streams-part-4)-->

