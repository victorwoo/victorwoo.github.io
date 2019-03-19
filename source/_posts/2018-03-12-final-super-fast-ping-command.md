---
layout: post
date: 2018-03-12 00:00:00
title: "PowerShell 技能连载 - 终极快速的 Ping 命令"
description: PowerTip of the Day - Final Super-Fast Ping Command
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能系列中，我们开发了一个名为 `Test-OnlineFast` 的新函数，可以在短时间内 ping 多台计算机。出于某些原因，最终版本并没有包含我们承诺的管道功能。以下是再次带给您的完整函数：

```powershell
function Test-OnlineFast
{
    param
    (
        # make parameter pipeline-aware
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]
        $ComputerName,

        $TimeoutMillisec = 1000
    )

    begin
    {
        # use this to collect computer names that were sent via pipeline
        [Collections.ArrayList]$bucket = @()

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
    }

    process
    {
        # add each computer name to the bucket
        # we either receive a string array via parameter, or
        # the process block runs multiple times when computer
        # names are piped
        $ComputerName | ForEach-Object {
            $null = $bucket.Add($_)
        }
    }

    end
    {
        # convert list of computers into a WMI query string
        $query = $bucket -join "' or Address='"

        Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" |
        Select-Object -Property Address, $IsOnline, $DNSName, $statusFriendlyText
    }

}
```

让我们首先来确认 `Test-OnlineFast` 是如何工作的。以下是一些示例。我们首先 ping 一系列计算机。您可以同时使用计算机名和 IP 地址：

```powershell
PS> Test-OnlineFast -ComputerName google.de, powershellmagazine.com, 10.10.10.200, 127.0.0.1

Address                Online DNSName                Status
-------                ------ -------                ------
127.0.0.1                True DESKTOP-7AAMJLF        Success
google.de                True google.de              Success
powershellmagazine.com   True powershellmagazine.com Success
10.10.10.200            False                        Request Timed Out
```

我们现在来 ping 一整个 IP 段。以下例子从我们公共的酒店 WLAN 中（请确保将 IP 段调整为您所在的网段）：

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

神奇的是超快的速度。ping 整个子网只花费了几秒钟。

<!--本文国际来源：[Final Super-Fast Ping Command](http://community.idera.com/powershell/powertips/b/tips/posts/final-super-fast-ping-command)-->
