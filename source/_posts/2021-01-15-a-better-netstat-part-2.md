---
layout: post
date: 2021-01-15 00:00:00
title: "PowerShell 技能连载 - 更好的 NetStat（第 2 部分）"
description: PowerTip of the Day - A Better NetStat (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们介绍了 `Get-NetTCPConnection` cmdlet，它是 Windows 系统上 netstat.exe 网络实用程序的更好替代方案。它可以列出打开的端口和连接，我们以列出所有与 HTTPS（端口443）的连接的示例作为总结：

```powershell
PS> Get-NetTCPConnection -RemotePort 443 -State Established

LocalAddress  LocalPort RemoteAddress  RemotePort State       AppliedSetting OwningProcess
------------  --------- -------------  ---------- -----       -------------- -------------
192.168.2.105 58640     52.114.74.221  443        Established Internet       14204
192.168.2.105 56201     52.114.75.149  443        Established Internet       9432
192.168.2.105 56200     52.114.142.145 443        Established Internet       13736
192.168.2.105 56199     13.107.42.12   443        Established Internet       12752
192.168.2.105 56198     13.107.42.12   443        Established Internet       9432
192.168.2.105 56192     40.101.81.162  443        Established Internet       9432
192.168.2.105 56188     168.62.58.130  443        Established Internet       10276
192.168.2.105 56181     168.62.58.130  443        Established Internet       10276
192.168.2.105 56103     13.107.6.171   443        Established Internet       9432
192.168.2.105 56095     13.107.42.12   443        Established Internet       9432
192.168.2.105 56094     13.107.43.12   443        Established Internet       9432
192.168.2.105 55959     140.82.112.26  443        Established Internet       21588
192.168.2.105 55568     52.113.206.137 443        Established Internet       13736
192.168.2.105 55555     51.103.5.186   443        Established Internet       12752
192.168.2.105 49638     51.103.5.186   443        Established Internet       5464
```

该列表本身并不是很有用，因为它不能解析 IP 地址，也不会告诉您哪些程序保持着连接。但是，借助一点 PowerShell 魔术，您可以解决以下问题：

```powershell
$Process = @{
    Name='Process'
    Expression={
        # return process path
        (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path

        }
}

$HostName = @{
    Name='Host'
    Expression={
        $remoteHost = $_.RemoteAddress
        try {
            # try to resolve IP address
            [Net.Dns]::GetHostEntry($remoteHost).HostName
        } catch {
            # if that fails, return IP anyway
            $remoteHost
        }
    }
}

# get all connections to port 443 (HTTPS)
Get-NetTCPConnection -RemotePort 443 -State Established |
    # where there is a remote address
    Where-Object RemoteAddress |
    # and resolve IP and process ID
    Select-Object -Property $HostName, OwningProcess, $Process
```

`Select-Object` 选择要显示的对象。它支持“计算属性”。 `$Process` 定义了一个名为 "`Process`" 的计算属性：它采用原始的 `OwningProcess` 属性，并通过 `Get-Process` 处理它的进程 ID，以获取应用程序的路径。

`$HostName` 中也会发生同样的情况：在此，用 .NET 的 `GetHostEntry()` 方法解析 IP 并返回解析的主机名。现在的结果如下所示：

    Host                            OwningProcess Process
    ----                            ------------- -------
    13.107.6.171                             9432 C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE
    1drv.ms                                  9432 C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE
    lb-140-82-113-26-iad.github.com         21588 C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
    1drv.ms                                  9432 C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE
    52.113.206.137                          13736 C:\Users\tobia\AppData\Local\Microsoft\Teams\current\Teams.exe
    51.103.5.186                            12752 C:\Users\tobia\AppData\Local\Microsoft\OneDrive\OneDrive.exe

不过这样做的成本可能很高，因为解析 IP 地址可能会花费很长时间，尤其是在查询超时时。在下一部分中，我们将介绍并行处理以加快处理速度。

<!--本文国际来源：[A Better NetStat (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/a-better-netstat-part-2)-->

