---
layout: post
date: 2018-05-22 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架：创建 QR 码"
description: 'PowerTip of the Day - PowerShell Gallery: Creating QR Codes'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何获取 PowerShellGet 并且在您的 PowerShell 版本中运行。现在我们看看 PowerShell 陈列架能够多么方便地扩展 PowerShell 的功能。

要创建一个 WiFi 热点的 QR 码，现在只需要几行代码：

```powershell
# adjust this to match your own WiFi
$wifi = "myAccessPoint"
$pwd = "topSecret12"


# QR Code will be saved here
$path = "$home\Desktop\wifiaccess.png"

# install the module from the gallery (only required once)
Install-Module QRCodeGenerator -Scope CurrentUser -Force
# create QR code
New-QRCodeWifiAccess -SSID $wifi -Password $pwd -OutPath $path

# open QR code image with an associated program
Invoke-Item -Path $path
```

这段代码首先下载并安装 QRCodeGenerator 模块，然后生成一个包含您提供的 WiFi 信息的特殊的 QR 码（您需要先调整内容适合您的 WiFi）。

生成的 PNG 图片可以使用大多数现代的智能设备扫描识别，即可使设备连接到 WiFi。

只需要将 QR 码打印几份，下一次迎接客人的时候，只需要提供打印件给客人，他们就可以方便地连上您的 WiFi。

<!--本文国际来源：[PowerShell Gallery: Creating QR Codes](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-creating-qr-codes)-->
