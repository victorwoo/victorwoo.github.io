---
layout: post
date: 2018-02-21 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第五部分）"
description: PowerTip of the Day - Creating Highspeed Ping (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们创建了一个名为 `Test-OnlineFast` 的高速的新的 PowerShell 函数，它使用 WMI 来高速 ping 任意数量的计算机。今天我们将通过向 ping 的结果增加一些列额外的属性使它变得更有用。

先让我们检查 `Test-OnlineFast` 是如何工作的。以下是一些例子。我们先 ping 一系列计算机。您既可以使用计算机名也可以使用 IP 地址：

```powershell
PS> Test-OnlineFast -ComputerName google.de, powershellmagazine.com, 10.10.10.200, 127.0.0.1

Address                Online DNSName                Status
-------                ------ -------                ------
127.0.0.1                True DESKTOP-7AAMJLF        Success
google.de                True google.de              Success
powershellmagazine.com   True powershellmagazine.com Success
10.10.10.200            False                        Request Timed Out
```

我们现在 ping 整个 IP 地址段。以下例子是从我们的公共酒店 WLAN 中执行的（请将 IP 范围调整为您所在的网络）：

```powershell
PS> $iprange = 1..200 | ForEach-Object { "192.168.189.$_" }

PS> Test-OnlineFast -ComputerName $iprange

Address         Online DNSName                            Status
-------         ------ -------                            ------
192.168.189.200   True DESKTOP-7AAMJLF.fritz.box          Success
192.168.189.1     True fritz.box                          Success
192.168.189.134   True PCSUP03.fritz.box                  Success
192.168.189.29    True fritz.repeater                     Success
192.168.189.64    True android-6868316cec604d25.fritz.box Success
192.168.189.142   True Galaxy-S8.fritz.box                Success
192.168.189.65    True mbecker-netbook.fritz.box          Success
192.168.189.30    True android-7f35f4eadd9e425e.fritz.box Success
192.168.189.10   False                                    Request Timed Out
192.168.189.100  False                                    Request Timed Out
192.168.189.101  False                                    Request Timed Out
(...)
```

神奇的是它的超快速度。ping 整个子网只用了几秒。

现在，我们来看看这个函数。在前面的技能中我们解释了其中的一部分。这个版本向 ping 的结果增加了有用的属性，例如 `Online` 和 `DnsName`，它返回关于 ping 状态的友好文本，而不是幻数。所有这些是通过计算属性的哈希表实现的，基于 ping 返回的原始信息：

```powershell
function Test-OnlineFast
{
    param
    (
        # make parameter pipeline-aware
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        $TimeoutMillisec = 1000
    )

    # hash table with error code to text translation
    $StatusCode_ReturnValue =
    @{
        0='Success'
        11001='Buffer Too Small'
        11002='Destination Net Unreachable'
        11003='Destination Host Unreachable'
        11004='Destination Protocol Unreachable'
        11005='Destination Port Unreachable'
        11006='No Resources'
        11007='Bad Option'
        11008='Hardware Error'
        11009='Packet Too Big'
        11010='Request Timed Out'
        11011='Bad Request'
        11012='Bad Route'
        11013='TimeToLive Expired Transit'
        11014='TimeToLive Expired Reassembly'
        11015='Parameter Problem'
        11016='Source Quench'
        11017='Option Too Big'
        11018='Bad Destination'
        11032='Negotiating IPSEC'
        11050='General Failure'
    }

    # hash table with calculated property that translates
    # numeric return value into friendly text

    $statusFriendlyText = @{
        # name of column
        Name = 'Status'
        # code to calculate content of column
        Expression = {
            # take status code and use it as index into
            # the hash table with friendly names
            # make sure the key is of same data type (int)
            $StatusCode_ReturnValue[([int]$_.StatusCode)]
        }
    }

    # calculated property that returns $true when status -eq 0
    $IsOnline = @{
        Name = 'Online'
        Expression = { $_.StatusCode -eq 0 }
    }

    # do DNS resolution when system responds to ping
    $DNSName = @{
        Name = 'DNSName'
        Expression = { if ($_.StatusCode -eq 0) {
                if ($_.Address -like '*.*.*.*')
                { [Net.DNS]::GetHostByAddress($_.Address).HostName  }
                else
                { [Net.DNS]::GetHostByName($_.Address).HostName  }
            }
        }
    }

    # convert list of computers into a WMI query string
    $query = $ComputerName -join "' or Address='"

    Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" |
    Select-Object -Property Address, $IsOnline, $DNSName, $statusFriendlyText

}
```

<!--本文国际来源：[Creating Highspeed Ping (Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-highspeed-ping-part-5)-->
