---
layout: post
date: 2021-01-25 00:00:00
title: "PowerShell 技能连载 - 检测未知的网络监听器"
description: PowerTip of the Day - Identifying Unknown Network Listeners
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，当您检查网络连接时，您只能看到远程访问者使用的IP地址。IP 地址通常没有通过 DNS 解析，因此您实际上并不知道谁连接了您的计算机。

如果您想找出谁拥有未知 IP 地址，可以使用免费的 RESTful 网络服务。此行代码将显示指定 IP 地址的所有权：

```powershell
PS> Invoke-RestMethod -Uri 'http://ipinfo.io/51.107.59.180/json'


ip       : 51.107.59.180
city     : Zürich
region   : Zurich
country  : CH
loc      : 47.3667,8.5500
org      : AS8075 Microsoft Corporation
postal   : 8001
timezone : Europe/Zurich
readme   : https://ipinfo.io/missingauth
```

将此命令与其他命令结合使用，可以找出与您的计算机进行通信的人员。例如，`Get-NetTcpConnection` 列出了您的网络连接，现在您可以查找谁是您所连接的 IP 地址背后的所有者。

在下面的示例中，`Get-NetTcpConnection` 返回所有当前活动的 HTTPS 连接（端口443）。远程 IP 被自动解析，因此您可以知道哪个软件正在保持连接，以及该软件正在与谁通信：

```powershell
$Process = @{
    Name='Process'
    Expression={
        # return process path
        (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path

        }
}

$IpOwner = @{
    Name='RemoteAuthority'
    Expression={
        $ip = $_.RemoteAddress
        $info = Invoke-RestMethod -Uri "http://ipinfo.io/$ip/json"
        '{0} ({1})' -f $info.Org, $info.City
    }
}

# get all connections to port 443 (HTTPS)
Get-NetTCPConnection -RemotePort 443 -State Established |
    # where there is a remote address
    Where-Object RemoteAddress |
    # and resolve IP and Process ID
    Select-Object -Property $IPOwner, RemoteAddress, OwningProcess, $Process
```

下面是一个实际示例：让我们转储本地管理员组。您可以按名称或不区分文化的 SID 来访问组：

    RemoteAuthority                               RemoteAddress  OwningProcess Process
    ---------------                               -------------  ------------- -------
    AS8075 Microsoft Corporation (Amsterdam)      52.114.74.221          14204 C:\Users\tobia\AppData\Local\Microsoft\Teams\current\Teams.exe
    AS8075 Microsoft Corporation (Hampden Sydney) 52.114.133.169         13736 C:\Users\tobia\AppData\Local\Microsoft\Teams\current\Teams.exe
    AS36459 GitHub, Inc. (Ashburn)                140.82.113.26          21588 C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
    AS8068 Microsoft Corporation (Redmond)        13.107.42.12            9432 C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE
    AS8075 Microsoft Corporation (Zürich)         51.107.59.180          14484 C:\Program Files\PowerShell\7\pwsh.exe
    AS8068 Microsoft Corporation (Redmond)        13.107.42.12            9432 C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE
    AS8075 Microsoft Corporation (San Antonio)    52.113.206.137         13736 C:\Users\tobia\AppData\Local\Microsoft\Teams\current\Teams.exe
    AS8075 Microsoft Corporation (Paris)          51.103.5.186           12752 C:\Users\tobia\AppData\Local\Microsoft\OneDrive\OneDrive.exe

有趣吧？

<!--本文国际来源：[Identifying Unknown Network Listeners](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-unknown-network-listeners)-->

