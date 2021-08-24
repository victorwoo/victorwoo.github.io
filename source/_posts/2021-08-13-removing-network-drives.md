---
layout: post
date: 2021-08-13 00:00:00
title: "PowerShell 技能连载 - 移除网络驱动器"
description: PowerTip of the Day - Removing Network Drives
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
虽然 `Remove-PSDrive` 可以删除包括网络驱动器在内的所有类型的驱动器，但更改可能要等系统重新启动时才能生效。这当然是荒谬的。

这个任务是一个很好的例子，为什么 PowerShell 使控制台应用程序成为平等公民是有用的。事实上，即使在 2021 年，移除网络驱动器的最可靠方法也是使用旧的但经过验证的 net.exe。下面的示例删除网络驱动器号 Z：

```powershell
PS> net use z: /delete
z: was deleted successfully.
```

<!--本文国际来源：[Removing Network Drives](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/removing-network-drives)-->

