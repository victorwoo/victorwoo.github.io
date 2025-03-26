---
layout: post
date: 2022-10-31 00:00:00
title: "PowerShell 技能连载 - 获取卷 ID（第 2 部分）"
description: PowerTip of the Day - Get Volume IDs (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 及以上版本，您可以使用 `Get-Volume` 获取有关驱动器的卷 ID 和其他信息：

```powershell
PS> Get-Volume

DriveLetter FriendlyName FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining      Size
----------- ------------ -------------- --------- ------------ ----------------- -------------      ----
            WINRETOOLS   NTFS           Fixed     Healthy      OK                    315.58 MB    990 MB
C           OS           NTFS           Fixed     Healthy      OK                    154.79 GB 938.04 GB
            Image        NTFS           Fixed     Healthy      OK                    107.91 MB   12.8 GB
            DELLSUPPORT  NTFS           Fixed     Healthy      OK                    354.46 MB   1.28 GB
``

请注意，尽管您最初只会看到一小部分可用信息。但将数据发送到管道可以查看到所有信息，包括卷 ID：

```powershell
Get-Volume | Select-Object -Property *
```

这是一个示例：

```powershell
PS> Get-Volume | Select-Object -Property DriveLetter, FileSystemLabel, Size, Path

DriveLetter FileSystemLabel          Size Path
----------- ---------------          ---- ----
            WINRETOOLS         1038086144 \\?\Volume{733298ae-3d76-4f5f-acc4-50fdca0c6401}\
C           OS              1007210721280 \\?\Volume{861c48b0-d434-48d3-995a-0573c1336eb7}\
            Image             13739487232 \\?\Volume{9dc0ed9d-86fd-4cd5-9ed8-3249f57720ad}\
            DELLSUPPORT        1371533312 \\?\Volume{b0f36c9e-2372-47f9-8b84-cdf65447c9c6}\
```

<!--本文国际来源：[Get Volume IDs (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-volume-ids-part-2)-->

