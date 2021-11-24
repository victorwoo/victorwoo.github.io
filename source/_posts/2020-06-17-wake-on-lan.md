---
layout: post
date: 2020-06-17 00:00:00
title: "PowerShell 技能连载 - 局域网唤醒"
description: PowerTip of the Day - Wake On LAN
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
无需外部“局域网唤醒”工具了。如果要唤醒网络计算机，只需告诉 PowerShell 目标计算机的 MAC 地址即可。这是一个组成 magic packet 并唤醒机器的函数：

```powershell
function Invoke-WakeOnLan
{
  param
  (
    # one or more MAC addresses
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    # MAC address must be a following this regex pattern
    [ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')]
    [string[]]
    $MacAddress
  )

  begin
  {
    # instantiate a UDP client
    $UDPclient = [System.Net.Sockets.UdpClient]::new()
  }
  process
  {
    foreach ($_ in $MacAddress)
    {
      try {
        $currentMacAddress = $_

        # get byte array from MAC address
        $mac = $currentMacAddress -split '[:-]' |
          # convert the hex number into byte
          ForEach-Object {
            [System.Convert]::ToByte($_, 16)
          }

        #region compose the "magic packet"

        # create a byte array with 102 bytes initialized to 255 each
        $packet = [byte[]](,0xFF * 102)

        # leave the first 6 bytes untouched, and
        # repeat the target MAC address bytes in bytes 7 through 102
        6..101 | ForEach-Object {
          # $_ is indexing in the byte array,
          # $_ % 6 produces repeating indices between 0 and 5
          # (modulo operator)
          $packet[$_] = $mac[($_ % 6)]
        }

        #endregion

        # connect to port 4000 on broadcast address
        $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)

        # send the magic packet to the broadcast address
        $null = $UDPclient.Send($packet, $packet.Length)
        Write-Verbose "Sent magic packet to $currentMacAddress..."
      }
      catch
      {
        Write-Warning "Unable to send ${mac}: $_"
      }
    }
  }
  end
  {
    # release the UDP client and free its memory
    $UDPclient.Close()
    $UDPclient.Dispose()
  }
}
```

运行该函数后，可以通过以下方法唤醒计算机：

```powershell
Invoke-WakeOnLan -MacAddress '24:EE:9A:54:1B:E5', '98:E7:43:B5:B2:2F' -Verbose
```

要找出目标机器的MAC地址，请在目标机器上运行此行代码或通过远程处理：

```powershell
Get-CimInstance -Query 'Select * From Win32_NetworkAdapter Where NetConnectionStatus=2' | Select-Object -Property Name, Manufacturer, MacAddress
```

可以在这里找到更多信息：<https://powershell.one/code/11.html>。

<!--本文国际来源：[Wake On LAN](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/wake-on-lan)-->

