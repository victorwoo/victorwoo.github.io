---
layout: post
date: 2019-01-10 00:00:00
title: "PowerShell 技能连载 - 扫描端口"
description: PowerTip of the Day - Scanning Ports
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
以下是一个扫描本地或远程系统端口的一个直接的方法。您甚至可以指定一个超时值（以毫秒为单位）：

```powershell
function Get-PortInfo
{
    param
    (
        [Parameter(Mandatory)]
        [Int]
        $Port,

        [Parameter(Mandatory)]
        [Int]
        $TimeoutMilliseconds,

        [String]
        $ComputerName = $env:COMPUTERNAME
    )

    # try and establish a connection to port async
    $tcpobject = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpobject.BeginConnect($computername,$port,$null,$null)

    # wait for the connection no longer than $timeoutMilliseconds
    $wait = $connect.AsyncWaitHandle.WaitOne($timeoutMilliseconds,$false)

    # return rich information
    $result = @{
        ComputerName = $ComputerName
    }

    if(!$wait) {
        # timeout
        $tcpobject.Close()
        $result.Online = $false
        $result.Error = 'Timeout'
    } else {
        try {
            # try and complete the connection
            $null = $tcpobject.EndConnect($connect)
            $result.Online = $true
        }
        catch {
            $result.Online = $false
        }
        $tcpobject.Close()
    }
    $tcpobject.Dispose()

    [PSCustomObject]$result
}
```

扫描端口现在变得十分简单：

```powershell
PS> Get-PortInfo -Port 139 -TimeoutMilliseconds 1000

ComputerName    Online
------------    ------
DESKTOP-7AAMJLF   True


PS> Get-PortInfo -Port 139 -TimeoutMilliseconds 1000 -ComputerName storage2

Error   ComputerName Online
-----   ------------ ------
Timeout storage2      False
```

<!--more-->
本文国际来源：[Scanning Ports](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/scanning-ports)
