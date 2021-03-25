---
layout: post
date: 2021-03-22 00:00:00
title: "PowerShell 技能连载 - 识别网络访问的来源"
description: PowerTip of the Day - Identifying Origin of Network Access
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-NetTCPConnection` 返回所有当前的 TCP 网络连接，但是此 cmdlet 不会确切告诉您谁在连接到您的计算机。您仅得到 IP 地址：

```powershell
PS> Get-NetTCPConnection -RemotePort 443

LocalAddress  LocalPort RemoteAddress  RemotePort State       AppliedSetting OwningProcess
------------  --------- -------------  ---------- -----       -------------- ---------
192.168.2.110 60960     13.107.6.171   443        Established Internet       21824
192.168.2.110 60959     20.44.232.74   443        Established Internet       4540
192.168.2.110 60956     52.184.216.226 443        Established Internet       13204
```

使用计算属性，您可以重新计算返回的值，例如，将 IP 地址发送到公开真实来源的 Web 服务。使用相同的技术，您还可以转换在 `OwningProcess` 中找到的进程 ID，并返回维护连接的进程名称：

```powershell
$process = @{
  Name = 'ProcessName'
  Expression = { (Get-Process -Id $_.OwningProcess).Name }
}

$darkAgent = @{
  Name = 'ExternalIdentity'
  Expression = {
    $ip = $_.RemoteAddress
    (Invoke-RestMethod -Uri "http://ipinfo.io/$ip/json" -UseBasicParsing -ErrorAction Ignore).org

  }
}
Get-NetTCPConnection -RemotePort 443 -State Established |
  Select-Object -Property RemoteAddress, OwningProcess, $process, $darkAgent
```

结果提供了对连接的更多了解，并且该示例显示了所有 HTTPS 连接及其外部目标：

    RemoteAddress  OwningProcess ProcessName ExternalIdentity
    -------------  ------------- ----------- ----------------
    13.107.6.171           21824 WINWORD     AS8068 Microsoft Corporation
    52.113.194.132         15480 Teams       AS8068 Microsoft Corporation
    52.114.32.24           25476 FileCoAuth  AS8075 Microsoft Corporation
    142.250.185...         15744 chrome      AS15169 Google LLC
    52.114.32.24            3800 OneDrive    AS8075 Microsoft Corporation
    52.114.32.24            3800 OneDrive    AS8075 Microsoft Corporation
    45.60.13.212            9808 AgentShell  AS19551 Incapsula Inc
    18.200.231.29          15744 chrome      AS16509 Amazon.com, Inc.

<!--本文国际来源：[Identifying Origin of Network Access](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-origin-of-network-access)-->

