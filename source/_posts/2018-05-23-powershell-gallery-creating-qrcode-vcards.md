---
layout: post
date: 2018-05-23 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架：创建二维码 vCard"
description: 'PowerTip of the Day - PowerShell Gallery: Creating QRCode vCards'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何获取 PowerShellGet 并在您的 PowerShell 版本中使用。现在我们来看看 PowerShell 陈列架能够多门方便地扩展 PowerShell 的功能。

下次您打印名片的时候，何不增加一个二维码呢？它使得增加联系人十分方便！大多数现代的设备都支持二维码，所以当您将相机 APP 对准一个二位码时，智能手机可以直接向这个联系人发送邮件，或者将他添加为您的联系人。

以下是创建 vCard 二维码的方法：

```powershell
# adjust this to match your own info
$first = "Tom"
$last = "Sawywer"
$company = "freelancer.com"
$email = "t.sawyer@freelancer.com"


# QR Code will be saved here
$path = "$home\Desktop\vCard.png"

# install the module from the Gallery (only required once)
Install-Module QRCodeGenerator -Scope CurrentUser -Force
# create QR code
New-QRCodeVCard -FirstName $first -LastName $last -Company $company -Email $email -OutPath $path

# open QR code image with an associated program
Invoke-Item -Path $path
```

<!--本文国际来源：[PowerShell Gallery: Creating QRCode vCards](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-creating-qrcode-vcards)-->
