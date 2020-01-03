---
layout: post
date: 2019-12-24 00:00:00
title: "PowerShell 技能连载 - 列出已安装的更新（第 1 部分）"
description: PowerTip of the Day - Listing Installed Updates (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Hotfix` 只会列出操作系统相关的 hotfix：

```powershell
Get-HotFix
```

实际上，它只是一个 WMI 查询的简单包装，结果是一样的：

```powershell
Get-CimInstance -ClassName Win32_QuickFixEngineering
```

一个更简单更完整的方法是查询系统事件日志获取所有安装的更新：

```powershell
Get-WinEvent @{
  Logname='System'
  ID=19
  ProviderName='Microsoft-Windows-WindowsUpdateClient'
} | ForEach-Object  {
  [PSCustomObject]@{
    Time = $_.TimeCreated
    Update  = $_.Properties.Value[0]
  }
}
```

显然，当系统事件日志清除之后，查询结果就不完整了。此外，该日志只是记录任何更新安装，因此随着时间的推移，新的更新可能取代旧的更新。

要保证获取到完整的已安装更新列表，您需要请求 Windows Update 客户端，从实际安装的更新中重建列表，这要消耗更多的时间：

```powershell
$result = (New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsInstalled=1").Updates |
  Select-Object LastDeploymentChangeTime, Title, Description, MsrcSeverity

$result | Out-GridView -Title 'Installed Updates'
```

<!--本文国际来源：[Listing Installed Updates (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-installed-updates-part-1)-->

