---
layout: post
date: 2019-05-03 00:00:00
title: "PowerShell 技能连载 - 查找最新的 PowerShell 6 发布"
description: PowerTip of the Day - Finding Latest PowerShell 6 Release
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 6 是开源的，所以经常发布新的更新。您随时可以访问 https://github.com/PowerShell/PowerShell/releases 来查看这些更新。

对于 PowerShell 来说，可以使这步操作自动化。以下是一小段读取 GitHub 发布的 RSS 供稿的代码，它能够正确地转换数据，然后取出这些更新以及下载信息，并按降序排列：

```powershell
$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'[Net.ServicePointManager]::SecurityProtocol = $AllProtocols $Updated = @{
    Name = 'Updated'    Expression = { $_.Updated -as [DateTime] }
}$Link = @{
    Name = 'URL'    Expression = { $_.Link.href }
}Invoke-RestMethod -Uri https://github.com/PowerShell/PowerShell/releases.atom -UseBasicParsing |  Sort-Object -Property Updated -Descending |  Select-Object -Property Title, $Updated, $Link
```

结果类似这样：

    title                                       Updated             URL
    -----                                       -------             ---
    v6.2.0 Release of PowerShell Core           28.03.2019 19:52:27 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0
    v6.2.0-rc.1 Release of PowerShell Core      05.03.2019 23:47:46 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0-rc.1
    v6.1.3 Release of PowerShell Core           19.02.2019 19:32:01 https://github.com/PowerShell/PowerShell/releases/tag/v6.1.3
    v6.2.0-preview.4 Release of PowerShell Core 28.01.2019 22:28:01 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0-preview.4
    v6.1.2 Release of PowerShell Core           15.01.2019 21:02:39 https://github.com/PowerShell/PowerShell/releases/tag/v6.1.2
    v6.2.0-preview.3 Release of PowerShell Core 11.12.2018 01:29:33 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0-preview.3
    v6.2.0-preview.2 Release of PowerShell Core 16.11.2018 02:52:53 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0-preview.2
    v6.1.1 Release of PowerShell Core           13.11.2018 20:55:45 https://github.com/PowerShell/PowerShell/releases/tag/v6.1.1
    v6.0.5 Release of PowerShell Core           13.11.2018 19:00:56 https://github.com/PowerShell/PowerShell/releases/tag/v6.0.5
    v6.2.0-preview.1 Release of PowerShell Core 18.10.2018 02:07:32 https://github.com/PowerShell/PowerShell/releases/tag/v6.2.0-preview.1

请注意，只有在 Windows 10 1803 之前才需要显式启用 SSL。

<!--本文国际来源：[Finding Latest PowerShell 6 Release](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-latest-powershell-6-release)-->

