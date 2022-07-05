---
layout: post
date: 2022-06-23 00:00:00
title: "PowerShell 技能连载 - 解锁多个文件"
description: PowerTip of the Day - Unblocking Multiple Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您从 Internet 下载文件，或将文件从不信任源复制到 NTFS 文件系统的驱动器时，Windows 将秘密的 NTFS 流添加到这些文件中，以作为额外的安全性层。

“锁定”的文件将无法执行，并且像 DLL 这样的“锁定”二进制文件无法被加载。这就是为什么在使用此类文件之前取消锁定这些文件的原因。从本质上讲，是通过删除隐藏的 NTFS 流来完成解密，该流将文件标记为来自“不受信任的来源”。

PowerShell 用 `Unblock-File` cmdlet 清除文件的隐藏的 NTFS 流。要解开多个文件，即整个子文件夹的完整内容，只需使用 `Get-ChildItem` 并将结果通过管道输送来解开文件：

```powershell
Get-ChildItem -Path $home\desktop -File -Recurse | Unblock-File
```

<!--本文国际来源：[Unblocking Multiple Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/unblocking-multiple-files)-->

