---
layout: post
date: 2023-05-25 00:00:17
title: "PowerShell 技能连载 - 挂载 ISO 文件"
description: PowerTip of the Day - Mounting ISO Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在我们之前的提示中，我们展示了如何轻松将本地文件夹转换为 ISO 文件镜像。今天，我们来看一下如何挂载（以及卸载）您自己和其他任何 ISO 文件，以便它们可以像本地文件系统驱动器一样使用。

挂载 ISO 文件很简单：

```powershell
# 确保您调整此路径，使其指向现有的ISO文件：
$Path = "$env:temp\myImageFile.iso"
$result = Mount-DiskImage -ImagePath $Path -PassThru
$result
```

执行此代码后，Windows 资源管理器中会出现一个新的光驱，可以像其他驱动器一样使用。基于 ISO 镜像的驱动器当然是只读的，因为它们的行为就像常规的 CD-ROM。

虽然 `Mount-DiskImage` 可以成功挂载 ISO 镜像，但它不会将分配的驱动器字母返回给您。如果您想从脚本内部访问 ISO 镜像的内容，下面是如何找出它分配的驱动器字母：

```powershell
# 确保您调整此路径，使其指向现有的ISO文件：
$Path = "$env:temp\myImageFile.iso"
$result = Mount-DiskImage -ImagePath $Path -PassThru
$result

$volume = $result | Get-Volume
$letter = $volume.Driveletter + ":\"

explorer $letter
```

在使用后卸载驱动器，请运行 `Dismount-DiskImage` 并指定您之前挂载的ISO文件的路径：

```powershell
Dismount-DiskImage -ImagePath $Path
```
<!--本文国际来源：[Mounting ISO Files](https://blog.idera.com/database-tools/powershell/powertips/mounting-iso-files/)-->

