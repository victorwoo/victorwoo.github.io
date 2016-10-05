layout: post
date: 2014-10-02 11:00:00
title: "PowerShell 技能连载 - 通过 MAC 地址识别网卡厂家"
description: PowerTip of the Day - Identifying Network Vendors by MAC Address
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
_适用于 PowerShell 所有版本_

每个 MAC 地址唯一标识了一个网络设备。MAC 地址是由网络设备厂家分配的。所以您可以通过任何一个 MAC 地址反查出厂家信息。

您所需的只是一份大约 2MB 大小的 IEEE 厂家清单。以下是下载该清单的脚本：

    $url = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
    $outfile = "$home\vendorlist.txt"
    
    Invoke-WebRequest -Uri $url -OutFile $outfile

下一步，您可以使用该清单来识别厂家信息。首先获取 MAC 地址，例如：

    PS> getmac
    
    Physical Address    Transport Name                                            
    =================== ==========================================================
    5C-51-4F-62-F2-7D   \Device\Tcpip_{FF034A81-CBFE-4B11-9D81-FC8FC889A33C}      
    5C-51-4F-62-F2-81   Media disconnected  

取 MAC 地址的前 3 个 8 进制字符，例如 _5c-51-4f_，然后用它在下载的文件中查询：

    PS> Get-Content -Path $outfile | Select-String 5c-51-4f -Context 0,6
    
    >   5C-51-4F   (hex)        Intel Corporate
        5C514F     (base 16)        Intel Corporate
                        Lot 8, Jalan Hi-Tech 2/3
                      Kulim Hi-Tech Park
                      Kulim Kedah 09000
                      MALAYSIA

您不仅可以获取厂家名称（这个例子中是 Intel），而且还可以获取厂家的地址和所在区域。

<!--more-->
本文国际来源：[Identifying Network Vendors by MAC Address](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-network-vendors-by-mac-address)
