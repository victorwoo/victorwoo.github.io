---
layout: post
date: 2020-06-03 00:00:00
title: "PowerShell 技能连载 - 解析 Windows 产品密钥（第 2 部分）"
description: PowerTip of the Day - Decoding Windows Product Key (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了如何向 WMI 请求 Windows 的部分产品密钥。如果您丢失了原始产品密钥，可以通过以下方法恢复完整密钥：

```powershell
function Get-WindowsProductKey{
  \# test whether this is Windows 7 or older  function Test-Win7  {
    $OSVersion = [System.Environment]::OSVersion.Version    ($OSVersion.Major -eq 6 -and $OSVersion.Minor -lt 2) -or    $OSVersion.Major -le 6  }

  \# implement decoder  $code = @'// original implementation: https://github.com/mrpeardotnet/WinProdKeyFinder
using System;
using System.Collections;

  public static class Decoder
  {
        public static string DecodeProductKeyWin7(byte[] digitalProductId)
        {
            const int keyStartIndex = 52;
            const int keyEndIndex = keyStartIndex + 15;
            var digits = new[]
            {
                'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'M', 'P', 'Q', 'R',
                'T', 'V', 'W', 'X', 'Y', '2', '3', '4', '6', '7', '8', '9',
            };
            const int decodeLength = 29;
            const int decodeStringLength = 15;
            var decodedChars = new char[decodeLength];
            var hexPid = new ArrayList();
            for (var i = keyStartIndex; i <= keyEndIndex; i++)
            {
                hexPid.Add(digitalProductId[i]);
            }
            for (var i = decodeLength - 1; i >= 0; i--)
            {
                // Every sixth char is a separator.
                if ((i + 1) % 6 == 0)
                {
                    decodedChars[i] = '-';
                }
                else
                {
                    // Do the actual decoding.
                    var digitMapIndex = 0;
                    for (var j = decodeStringLength - 1; j >= 0; j--)
                    {
                        var byteValue = (digitMapIndex << 8) | (byte)hexPid[j];
                        hexPid[j] = (byte)(byteValue / 24);
                        digitMapIndex = byteValue % 24;
                        decodedChars[i] = digits[digitMapIndex];
                    }
                }
            }
            return new string(decodedChars);
        }

        public static string DecodeProductKey(byte[] digitalProductId)
        {
            var key = String.Empty;
            const int keyOffset = 52;
            var isWin8 = (byte)((digitalProductId[66] / 6) & 1);
            digitalProductId[66] = (byte)((digitalProductId[66] & 0xf7) | (isWin8 & 2) * 4);

            const string digits = "BCDFGHJKMPQRTVWXY2346789";
            var last = 0;
            for (var i = 24; i >= 0; i--)
            {
                var current = 0;
                for (var j = 14; j >= 0; j--)
                {
                    current = current*256;
                    current = digitalProductId[j + keyOffset] + current;
                    digitalProductId[j + keyOffset] = (byte)(current/24);
                    current = current%24;
                    last = current;
                }
                key = digits[current] + key;
            }

            var keypart1 = key.Substring(1, last);
            var keypart2 = key.Substring(last + 1, key.Length - (last + 1));
            key = keypart1 + "N" + keypart2;

            for (var i = 5; i < key.Length; i += 6)
            {
                key = key.Insert(i, "-");
            }

            return key;
        }
   }'@  \# compile C#  Add-Type -TypeDefinition $code
  \# get raw product key  $digitalId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name DigitalProductId).DigitalProductId
  $isWin7 = Test-Win7  if ($isWin7)
  {
    \# use static C# method    [Decoder]::DecodeProductKeyWin7($digitalId)
  }
  else  {
    \# use static C# method:    [Decoder]::DecodeProductKey($digitalId)
  }
}
```

<!--本文国际来源：[Decoding Windows Product Key (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/decoding-windows-product-key-part-2)-->

