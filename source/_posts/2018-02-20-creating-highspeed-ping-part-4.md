---
layout: post
date: 2018-02-20 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第四部分）"
description: PowerTip of the Day - Creating Highspeed Ping (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用 WMI 快速 ping 多台计算机。那么今天我们将它封装为一个可复用的 PowerShell 函数。它可以快速地 ping 一台或多台计算机。

以下是函数代码：

```powershell
function Test-OnlineFast
{
    param
    (
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        $TimeoutMillisec = 1000
    )

    # convert list of computers into a WMI query string
    $query = $ComputerName -join "' or Address='"

    Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
}
```

现在要以指定的超时值 ping 多台计算机变得非常简单：

```powershell
PS> Test-OnlineFast -ComputerName microsoft.com, google.de

Address       StatusCode
-------       ----------
google.de              0
microsoft.com      11010
```

状态码 "0" 代表响应结果：主机在线。其他状态码代表失败。

默认情况下，`Test-OnlineFast` 的超时时间为 1000 毫秒，所以当一台计算机没有响应时，最多等待 1 秒。您可以通过 `-TimeoutMillseconds` 参数改变超时值。设置越长的超时值意味着命令的执行时间越长。所以您应该在系统足够响应的范围内使用尽可能短的超时时间。

另一个影响时间的变量是 DNS 解析：如果 DNS 解析速度慢，或者无法解析到名称，将增加总体时间。如果指定 IP 地址，就不会发生这种变慢现象。

以下是在几秒内 ping 200 个 IP 地址的例子：

```powershell
PS> $ComputerName = 1..255 | ForEach-Object { "10.62.13.$_" }

PS> Test-OnlineFast -ComputerName $ComputerName

Address      StatusCode
-------      ----------
10.62.13.1        11010
10.62.13.10           0
10.62.13.100          0
10.62.13.101      11010
10.62.13.102      11010
(...)
```

<!--本文国际来源：[Creating Highspeed Ping (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-highspeed-ping-part-4)-->
