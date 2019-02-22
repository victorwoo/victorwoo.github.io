---
layout: post
date: 2018-03-13 00:00:00
title: "PowerShell 技能连载 - 正确地排序 IPv4 地址"
description: PowerTip of the Day - Sort IPv4 Addresses Correctly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个示例中我们发布了一个超快的名为 `Test-OnlieFast` 的函数，并且这个函数可以在短时间内 ping 整个 IP 段：

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

然而，IP 地址列并没有排序过。当然您可以使用 `Sort-Object` 来实现，但是由于地址中的数据是字符串格式，所以它会按字母排序。

以下是一个可以正确地对 IPv4 地址排序的简单技巧：

```powershell
PS> Test-OnlineFast -ComputerName $iprange | Sort-Object { $_.Address -as [Version]}
```

基本上，您通过 `Sort-Object` 将数据转换为 `Version` 对象，它刚好像 IPv4 地址一样，也是由四位数字组成。由于如果数据无法转换时，操作符 `-as` 将返回 `NULL` 结果，任何 IPv6 地址将会出现在列表的顶部（未排序）。

如果您错过了之前的 `Test-OnlineFast` 代码，以下再次把它贴出来：

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

<!--本文国际来源：[Sort IPv4 Addresses Correctly](http://community.idera.com/powershell/powertips/b/tips/posts/sort-ipv4-addresses-correctly)-->
