---
layout: post
date: 2023-05-01 08:01:00
title: "PowerShell 技能连载 - 永久删除硬盘内容"
description: PowerTip of the Day - Permanently Deleting Hard Drive Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在硬盘驱动器或USB闪存等存储介质上删除文件时，如您所知，数据并不会立即被删除。相反，数据只是未分配的，并将根据需要被新数据覆盖。在此之前，任何人都可以恢复已删除的数据。

为了防止对已删除的数据进行访问，在Windows上可以使用内置工具 `cipher.exe` 显式地覆盖所有未分配的存储空间。当您这样做时，您会立即意识到为什么默认情况下不这样做：即使是所有零位数也需要很长时间才能将数据存储到介质中。

该命令三次覆盖C:\驱动器上未分配的存储空间，首先用“0”、然后用“1”，最后用随机值。你最好投入一晚完成这个任务：

```powershell
cipher /w:C:\
```

以下是我们示例中使用的“/w”开关的官方描述：“从整个卷中可用未使用磁盘空间中移除数据。如果选择此选项，则忽略所有其他选项。指定目录可以位于本地卷中任何位置。如果它是一个挂载点或指向另一个卷中目录，则将删除该卷上的数据。
<!--本文国际来源：[Permanently Deleting Hard Drive Content](https://blog.idera.com/database-tools/powershell/powertips/permanently-deleting-hard-drive-content/)-->

